//
//  CodeStorageDelegate.swift
//  
//
//  Created by Manuel M T Chakravarty on 29/09/2020.
//
//  'NSTextStorageDelegate' for code views compute, collect, store, and update additional information about the text
//  stored in the 'NSTextStorage' that they serve. This is needed to quickly navigate the text (e.g., at which character
//  position does a particular line start) and to support code-specific rendering (e.g., syntax highlighting).

// FIXME: the aliases ought to be moved to some central place for os impedance matching

import AppKit



// MARK: -
// MARK: Visual debugging support

// FIXME: It should be possible to enable this via a defaults setting.
private let visualDebugging               = false
private let visualDebuggingEditedColour   = OSColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 0.3)
private let visualDebuggingLinesColour    = OSColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 0.3)
private let visualDebuggingTrailingColour = OSColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 0.3)
private let visualDebuggingTokenColour    = OSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)


// MARK: -
// MARK: Tokens

// Custom token attributes
//
extension NSAttributedString.Key {

  /// Custom attribute marking comment ranges.
  ///
  static let comment = NSAttributedString.Key("comment")

  /// Custom attribute marking lexical tokens.
  ///
  static let token = NSAttributedString.Key("token")
}

/// The supported comment styles.
///
enum CommentStyle {
  case singleLineComment
  case nestedComment
}

/// Information that is tracked on a line by line basis in the line map.
///
/// NB: We need the comment depth at the start and the end of each line as, during editing, lines are replaced in the
///     line map before comment attributes are recalculated. During this replacement, we lose the line info of all the
///     replaced lines.
///
struct LineInfo {

  var commentDepthStart: Int   // nesting depth for nested comments at the start of this line
  var commentDepthEnd:   Int   // nesting depth for nested comments at the end of this line

  // FIXME: we are not currently using the following three variables (they are maintained, but they are never useful).
  var angleBracketDiff:  Int   // increase or decrease of the nesting level of angle brackets on this line
  var roundBracketDiff:  Int   // increase or decrease of the nesting level of round brackets on this line
  var squareBracketDiff: Int   // increase or decrease of the nesting level of square brackets on this line
  var curlyBracketDiff:  Int   // increase or decrease of the nesting level of curly brackets on this line

}


// MARK: -
// MARK: Delegate class

class CodeStorageDelegate: NSObject, NSTextStorageDelegate {

  let language:          LanguageConfiguration
  private let tokeniser: Tokeniser<LanguageConfiguration.Token, LanguageConfiguration.State>? // cache the tokeniser

  private(set) var lineMap = LineMap<LineInfo>(string: "")


  /// If the last text change was a one-character addition, which completed a token, then that token is remembered here
  /// together with its range until the next text change.
  ///
  private var lastTypedToken: (type: LanguageConfiguration.Token, range: NSRange)?

  /// Flag that indicates that the current editing round is for a one-character addition to the text. This property
  /// needs to be determined before attribute fixing and the like.
  ///
  private var processingOneCharacterEdit: Bool?

  init(with language: LanguageConfiguration) {
    self.language  = language
    self.tokeniser = NSMutableAttributedString.tokeniser(for: language.tokenDictionary)
    super.init()
  }

  func textStorage(_ textStorage: NSTextStorage,
                   willProcessEditing editedMask: TextStorageEditActions,
                   range editedRange: NSRange,
                   changeInLength delta: Int)
  {
    processingOneCharacterEdit = delta == 1 && editedRange.length == 1
  }

  // NB: The choice of `didProcessEditing` versus `willProcessEditing` is crucial on macOS. The reason is that
  //     the text storage performs "attribute fixing" between `willProcessEditing` and `didProcessEditing`. If we
  //     modify attributes outside of `editedRange` (which we often do), then this triggers the movement of the
  //     current selection to the end of the entire text.
  //
  //     By doing the highlighting work *after* attribute fixing, we avoid affecting the selection. However, it now
  //     becomes *very* important to (a) refrain from any character changes and (b) from any attribute changes that
  //     result in attributes that need to be fixed; otherwise, we end up with an inconsistent attributed string.
  //     (In particular, changing the font attribute at this point is potentially dangerous.)
  func textStorage(_ textStorage: NSTextStorage,
                   didProcessEditing editedMask: TextStorageEditActions,
                   range editedRange: NSRange,  // Apple docs are incorrect here: this is the range *after* editing
                   changeInLength delta: Int)
  {
    guard let codeStorage = textStorage as? CodeStorage else { return }

    // If only attributes change, the line map and syntax highlighting remains the same => nothing for us to do
    guard editedMask.contains(.editedCharacters) else { return }

    if visualDebugging {
      let wholeTextRange = NSRange(location: 0, length: textStorage.length)
      textStorage.removeAttribute(.backgroundColor, range: wholeTextRange)
      textStorage.removeAttribute(.underlineColor, range: wholeTextRange)
      textStorage.removeAttribute(.underlineStyle, range: wholeTextRange)
    }


    lineMap.updateAfterEditing(string: textStorage.string, range: editedRange, changeInLength: delta)
    tokeniseAttributesFor(range: editedRange, in: textStorage)

    if visualDebugging {
      textStorage.addAttribute(.backgroundColor, value: visualDebuggingEditedColour, range: editedRange)
    }

    // If a single character was added, process token-level completion steps.
    if delta == 1 && processingOneCharacterEdit == true {
      tokenCompletion(for: codeStorage, at: editedRange.location)
    }
    processingOneCharacterEdit = nil
  }
}


// MARK: -
// MARK: Tokenisation

extension CodeStorageDelegate {

  /// Tokenise the substring of the given text storage that contains the specified lines and set token attributes as
  /// needed.
  ///
  /// - Parameters:
  ///   - originalRange: The character range that contains all characters that have changed.
  ///   - textStorage: The text storage that contains the changed characters.
  ///
  /// Tokenisation happens at line granularity. Hence, the range is correspondingly extended.
  ///
  func tokeniseAttributesFor(range originalRange: NSRange, in textStorage: NSTextStorage) {
    guard let codeStorage = textStorage as? CodeStorage else { return }

    func tokeniseAndUpdateInfo(for line: Int, commentDepth: inout Int, lastCommentStart: inout Int?) {

      if let lineRange = lineMap.lookup(line: line)?.range {

        // Remove any existing `.comment` attribute on this line
        textStorage.removeAttribute(.comment, range: lineRange)

        // Collect all tokens on this line.
        // (NB: In the block, we are not supposed to mutate outside the attribute range; hence, we only collect tokens.)
        var tokens = Array<(token: LanguageConfiguration.Token, range: NSRange)>()
        codeStorage.enumerateTokens(in: lineRange){ (tokenValue, range, _) in

          tokens.append((token: tokenValue, range: range))

          if visualDebugging {

            textStorage.addAttribute(.underlineColor, value: visualDebuggingTokenColour, range: range)
            if range.length > 0 {
              textStorage.addAttribute(.underlineStyle,
                                       value: NSNumber(value: NSUnderlineStyle.double.rawValue),
                                       range: NSRange(location: range.location, length: 1))
            }
            if range.length > 1 {
              textStorage.addAttribute(.underlineStyle,
                                       value: NSNumber(value: NSUnderlineStyle.single.rawValue),
                                       range: NSRange(location: range.location + 1, length: range.length - 1))
            }
          }
        }

        var lineInfo = LineInfo(commentDepthStart: commentDepth,
                                commentDepthEnd: 0,
                                angleBracketDiff: 0,
                                roundBracketDiff: 0,
                                squareBracketDiff: 0,
                                curlyBracketDiff: 0)
        tokenLoop: for token in tokens {

          switch token.token {

          case .angleBracketOpen:
            lineInfo.angleBracketDiff += 1

          case .angleBracketClose:
            lineInfo.angleBracketDiff -= 1

          case .roundBracketOpen:
            lineInfo.roundBracketDiff += 1

          case .roundBracketClose:
            lineInfo.roundBracketDiff -= 1

          case .squareBracketOpen:
            lineInfo.squareBracketDiff += 1

          case .squareBracketClose:
            lineInfo.squareBracketDiff -= 1

          case .curlyBracketOpen:
            lineInfo.curlyBracketDiff += 1

          case .curlyBracketClose:
            lineInfo.curlyBracketDiff -= 1

          case .singleLineComment:  // set comment attribute from token start token to the end of this line
            let commentStart = token.range.location,
                commentRange = NSRange(location: commentStart, length: NSMaxRange(lineRange) - commentStart)
            textStorage.addAttribute(.comment, value: CommentStyle.singleLineComment, range: commentRange)
            break tokenLoop   // the rest of the tokens are ignored as they are commented out and we'll rescan on change

          case .nestedCommentOpen:
            if commentDepth == 0 { lastCommentStart = token.range.location }    // start of an outermost nested comment
            commentDepth += 1

          case .nestedCommentClose:
            if commentDepth > 0 {

              commentDepth -= 1

              // If we just closed an outermost nested comment, attribute the comment range
              if let start = lastCommentStart, commentDepth == 0
              {
                textStorage.addAttribute(.comment,
                                         value: CommentStyle.nestedComment,
                                         range: NSRange(location: start, length: NSMaxRange(token.range) - start))
                lastCommentStart = nil
              }
            }

          default:
            break
          }
        }

        // If the line ends while we are still in an open comment, we need a comment attribute up to the end of the line
        if let start = lastCommentStart, commentDepth > 0 {

          textStorage.addAttribute(.comment,
                                   value: CommentStyle.nestedComment,
                                   range: NSRange(location: start, length: NSMaxRange(lineRange) - start))

        }

        // Retain computed line information
        lineInfo.commentDepthEnd = commentDepth
        lineMap.setInfoOf(line: line, to: lineInfo)
      }
    }

    guard let tokeniser = tokeniser else { return }

    // Extend the range to line boundaries. Because we cannot parse partial tokens, we at least need to go to word
    // boundaries, but because we have line bounded constructs like comments to the end of the line and it is easier to
    // determine the line boundaries, we use those.
    let lines = lineMap.linesContaining(range: originalRange),
        range = lineMap.charRangeOf(lines: lines)

    // Determine the comment depth as determined by the preceeeding code. This is needed to determine the correct
    // tokeniser and to compute attribute information from the resulting tokens. NB: We need to get that info from
    // the previous line, because the line info of the current line was set to `nil` during updating the line map.
    let initialCommentDepth  = lineMap.lookup(line: lines.startIndex - 1)?.info?.commentDepthEnd ?? 0

    // Set the token attribute in range.
    let initialTokeniserState: LanguageConfiguration.State
      = initialCommentDepth > 0 ? .tokenisingComment(initialCommentDepth) : .tokenisingCode
    textStorage.tokeniseAndSetTokenAttribute(attribute: .token,
                                             with: tokeniser,
                                             state: initialTokeniserState,
                                             in: range)

    // For all lines in range, collect the tokens line by line, while keeping track of nested comments
    //
    // - `lastCommentStart` keeps track of the last start of an *outermost* nested comment.
    //
    var commentDepth     = initialCommentDepth
    var lastCommentStart = initialCommentDepth > 0 ? lineMap.lookup(line: lines.startIndex)?.range.location : nil
    for line in lines {
      tokeniseAndUpdateInfo(for: line, commentDepth: &commentDepth, lastCommentStart: &lastCommentStart)
    }

    // Continue to re-process line by line until there is no longer a change in the comment depth before and after
    // re-processing
    //
    var currentLine       = lines.endIndex
    var highlightingRange = range
    trailingLineLoop: while currentLine < lineMap.lines.count {

      if let lineEntry = lineMap.lookup(line: currentLine) {

        // If this line has got a line info entry and the expected comment depth at the start of the line matches
        // the current comment depth, we reached the end of the range of lines affected by this edit => break the loop
        if let depth = lineEntry.info?.commentDepthStart, depth == commentDepth { break trailingLineLoop }

        // Re-tokenise line
        let initialTokeniserState: LanguageConfiguration.State
          = commentDepth > 0 ? .tokenisingComment(commentDepth) : .tokenisingCode
        textStorage.tokeniseAndSetTokenAttribute(attribute: .token,
                                                 with: tokeniser,
                                                 state: initialTokeniserState,
                                                 in: lineEntry.range)

        // Collect the tokens and update line info
        tokeniseAndUpdateInfo(for: currentLine, commentDepth: &commentDepth, lastCommentStart: &lastCommentStart)

        // Keep track of the trailing range for debugging purpose
        highlightingRange = NSUnionRange(highlightingRange, lineEntry.range)

      }
      currentLine += 1
    }

    if visualDebugging {
      textStorage.addAttribute(.backgroundColor, value: visualDebuggingTrailingColour, range: highlightingRange)
      textStorage.addAttribute(.backgroundColor, value: visualDebuggingLinesColour, range: range)
    }
  }
}


// MARK: -
// MARK: Token completion

extension CodeStorageDelegate {

  /// Handle token completion actions after a single character was inserted.
  ///
  /// - Parameters:
  ///   - textStorage: The text storage where the edit action occured.
  ///   - index: The location within the text storage where the single chracter was inserted.
  ///
  /// Any change to the `textStorage` is deferred, so that this function can also be used in the middle of an
  /// in-progress, but not yet completed edit.
  ///
  func tokenCompletion(for codeStorage: CodeStorage, at index: Int) {

    /// If the given token is an opening bracket, return the lexeme of its matching closing bracket.
    ///
    func matchingLexemeForOpeningBracket(_ token: LanguageConfiguration.Token) -> String? {
      if token.isOpenBracket, let matching = token.matchingBracket, let lexeme = language.lexeme(of: matching)
      {
        return lexeme
      } else {
        return nil
      }
    }

    /// Determine whether the ranges of the two tokens are overlapping.
    ///
    func overlapping(_ previousToken: (type: LanguageConfiguration.Token, range: NSRange),
                     _ currentToken: (type: LanguageConfiguration.Token, range: NSRange)?) -> Bool
    {
      if let currentToken = currentToken {
        return NSIntersectionRange(previousToken.range, currentToken.range).length != 0
      } else { return false }
    }


    let string             = codeStorage.string,
        char               = string.utf16[string.index(string.startIndex, offsetBy: index)],
        previousTypedToken = lastTypedToken,
        currentTypedToken  : (type: LanguageConfiguration.Token, range: NSRange)?

    // Determine the token (if any) that the right now inserted character belongs to
    currentTypedToken = codeStorage.token(at: index)

    lastTypedToken = currentTypedToken    // this is the default outcome, unless explicitly overridden below

    // The just entered character is right after the previous token and it doesn't belong to a token overlapping with
    // the previous token
    if let previousToken = previousTypedToken, NSMaxRange(previousToken.range) == index,
       !overlapping(previousToken, currentTypedToken) {

      let completingString: String?

      // If the previous token was an opening bracket, we may have to autocomplete by inserting a matching closing
      // bracket
      if let matchingPreviousLexeme = matchingLexemeForOpeningBracket(previousToken.type)
      {

        if let currentToken = currentTypedToken {

          if currentToken.type == previousToken.type.matchingBracket {

            // The current token is a matching closing bracket for the opening bracket of the last token => nothing to do
            completingString = nil

          } else if let matchingCurrentLexeme = matchingLexemeForOpeningBracket(currentToken.type) {

            // The current token is another opening bracket => insert matching closing for the current and previous
            // opening bracket
            completingString = matchingCurrentLexeme + matchingPreviousLexeme

          } else {

            // Insertion of a unrelated or non-bracket token => just complete the previous opening bracket
            completingString = matchingPreviousLexeme

          }

        } else {

          // If a opening curly brace or nested comment bracket is followed by a line break, add another line break
          // before the matching closing bracket.
          if let unichar = Unicode.Scalar(char),
             CharacterSet.newlines.contains(unichar),
             previousToken.type == .curlyBracketOpen || previousToken.type == .nestedCommentOpen
          {

            // Insertion of a newline after a curly bracket => complete the previous opening bracket prefixed with an extra newline
            completingString = String(unichar) + matchingPreviousLexeme

          } else {

          // Insertion of a character that doesn't complete a token => just complete the previous opening bracket
          completingString = matchingPreviousLexeme

          }
        }

      } else { completingString = nil }

      // Defer inserting the completion
      if let string = completingString {

        lastTypedToken = nil    // A completion renders the last token void
        codeStorage.cursorInsert(string: string, at: index + 1)

      }
    }
  }
}


