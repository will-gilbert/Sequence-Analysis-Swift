//
//  LanguageConfiguration.swift
//  
//
//  Created by Manuel M T Chakravarty on 03/11/2020.
//
//  Language configurations determine the linguistic characteristics that are important for the editing and display of
//  code in the respective languages, such as comment syntax, bracketing syntax, and syntax highlighting
//  characteristics.
//
//  We adapt a two-stage approach to syntax highlighting. In the first stage, basic context-free syntactic constructs
//  are being highlighted. In the second stage, contextual highlighting is performed on top of the highlighting from
//  stage one. The second stage relies on information from a code analysis subsystem, such as SourceKit.
//
//  Curent support here is only for the first stage.

import AppKit


/// Specifies the language-dependent aspects of a code editor.
///
public struct LanguageConfiguration {

  /// Supported flavours of tokens
  ///
  enum Token {
    case angleBracketOpen
    case angleBracketClose
    case roundBracketOpen
    case roundBracketClose
    case squareBracketOpen
    case squareBracketClose
    case curlyBracketOpen
    case curlyBracketClose
    case string
    case character
    case number
    case singleLineComment
    case nestedCommentOpen
    case nestedCommentClose
    case identifier
    case keyword

    var isOpenBracket: Bool {
      switch self {
      case .angleBracketOpen, .roundBracketOpen, .squareBracketOpen, .curlyBracketOpen, .nestedCommentOpen: return true
      default:                                                                           return false
      }
    }

    var isCloseBracket: Bool {
      switch self {
      case .angleBracketClose, .roundBracketClose, .squareBracketClose, .curlyBracketClose, .nestedCommentClose: return true
      default:                                                                               return false
      }
    }

    var matchingBracket: Token? {
      switch self {
      case .angleBracketOpen:   return .angleBracketClose
      case .roundBracketOpen:   return .roundBracketClose
      case .squareBracketOpen:  return .squareBracketClose
      case .curlyBracketOpen:   return .curlyBracketClose
      case .nestedCommentOpen:  return .nestedCommentClose
      case .angleBracketClose:  return .angleBracketOpen
      case .roundBracketClose:  return .roundBracketOpen
      case .squareBracketClose: return .squareBracketOpen
      case .curlyBracketClose:  return .curlyBracketOpen
      case .nestedCommentClose: return .nestedCommentOpen
      default:                  return nil
      }
    }

    var isComment: Bool {
      switch self {
      case .singleLineComment:  return true
      case .nestedCommentOpen:  return true
      case .nestedCommentClose: return true
      default:                  return false
      }
    }
  }

  /// Tokeniser state
  ///
  enum State: TokeniserState {
    case tokenisingCode
    case tokenisingComment(Int)   // the argument gives the comment nesting depth > 0

    enum Tag: Hashable { case tokenisingCode; case tokenisingComment }

    typealias StateTag = Tag

    var tag: Tag {
      switch self {
      case .tokenisingCode:       return .tokenisingCode
      case .tokenisingComment(_): return .tokenisingComment
      }
    }
  }

  /// Lexeme pair for a bracketing construct
  ///
  public typealias BracketPair = (open: String, close: String)

  /// Regular expression matching strings
  ///
  public let stringRegexp: String?

  /// Regular expression matching character literals
  ///
  public let characterRegexp: String?

  /// Regular expression matching numbers
  ///
  public let numberRegexp: String?

  /// Lexeme that introduces a single line comment
  ///
  public let singleLineComment: String?

  /// A pair of lexemes that encloses a nested comment
  ///
  public let nestedComment: BracketPair?

  /// Regular expression matching all identifiers (even if they are subgroupings)
  ///
  public let identifierRegexp: String?

  /// Reserved identifiers (this does not include contextual keywords)
  ///
  public let reservedIdentifiers: [String]

  /// Yields the lexeme of the given token under this language configuration if the token has got a unique lexeme.
  ///
  func lexeme(of token: Token) -> String? {
    switch token {
    case .angleBracketOpen:   return "<"
    case .angleBracketClose:  return ">"
    case .roundBracketOpen:   return "("
    case .roundBracketClose:  return ")"
    case .squareBracketOpen:  return "["
    case .squareBracketClose: return "]"
    case .curlyBracketOpen:   return "{"
    case .curlyBracketClose:  return "}"
    case .string:             return nil
    case .character:          return nil
    case .number:             return nil
    case .singleLineComment:  return singleLineComment
    case .nestedCommentOpen:  return nestedComment?.open
    case .nestedCommentClose: return nestedComment?.close
    case .identifier:         return nil
    case .keyword:            return nil
    }
  }
}

extension LanguageConfiguration {

  /// Empty language configuration
  ///
  public static let none = LanguageConfiguration(stringRegexp: nil,
                                                 characterRegexp: nil,
                                                 numberRegexp: nil,
                                                 singleLineComment: nil,
                                                 nestedComment: nil,
                                                 identifierRegexp: nil,
                                                 reservedIdentifiers: [])

}

// Helpers
private let binary    = "(?:[01]_*)+"
private let octal     = "(?:[0-7]_*)+"
private let decimal   = "(?:[0-9]_*)+"
private let hexal     = "(?:[0-9A-Fa-f]_*)+"
private let optNeg    = "(?:\\B-|\\b)"
private let exponent  = "[eE](?:[+-])?" + decimal
private let hexponent = "[pP](?:[+-])?" + decimal

private let idHeadChar   // from the Swift 5.4 reference
  = "["
  + "[a-zA-Z_]"
  + "[\u{00A8}\u{00AA}\u{00AD}\u{00AF}\u{00B2}–\u{00B5}\u{00B7}–\u{00BA}]"
  + "[\u{00BC}–\u{00BE}\u{00C0}–\u{00D6}\u{00D8}–\u{00F6}\u{00F8}–\u{00FF}]"
  + "[\u{0100}–\u{02FF}\u{0370}–\u{167F}\u{1681}–\u{180D}\u{180F}–\u{1DBF}]"
  + "[\u{1E00}–\u{1FFF}]"
  + "[\u{200B}–\u{200D}\u{202A}–\u{202E}\u{203F}–\u{2040}\u{2054}\u{2060}–\u{206F}]"
  + "[\u{2070}–\u{20CF}\u{2100}–\u{218F}\u{2460}–\u{24FF}\u{2776}–\u{2793}]"
  + "[\u{2C00}–\u{2DFF}\u{2E80}–\u{2FFF}]"
  + "[\u{3004}–\u{3007}\u{3021}–\u{302F}\u{3031}–\u{303F}\u{3040}–\u{D7FF}]"
  + "[\u{F900}–\u{FD3D}\u{FD40}–\u{FDCF}\u{FDF0}–\u{FE1F}\u{FE30}–\u{FE44}]"
  + "[\u{FE47}–\u{FFFD}]"
  + "[\u{10000}–\u{1FFFD}\u{20000}–\u{2FFFD}\u{30000}–\u{3FFFD}\u{40000}–\u{4FFFD}]"
  + "[\u{50000}–\u{5FFFD}\u{60000}–\u{6FFFD}\u{70000}–\u{7FFFD}\u{80000}–\u{8FFFD}]"
  + "[\u{90000}–\u{9FFFD}\u{A0000}–\u{AFFFD}\u{B0000}–\u{BFFFD}\u{C0000}–\u{CFFFD}]"
  + "[\u{D0000}–\u{DFFFD}\u{E0000}–\u{EFFFD}]"
  + "]"
private let idBodyChar   // from the Swift 5.4 reference
  = "["
  + "[0-9]"
  + "[\u{0300}–\u{036F}\u{1DC0}–\u{1DFF}\u{20D0}–\u{20FF}\u{FE20}–\u{FE2F}]"
  + "]"

private func group(_ regexp: String) -> String { "(?:" + regexp + ")" }
private func alternatives(_ alts: [String]) -> String { alts.map{ group($0) }.joined(separator: "|") }

private let xmlReservedIds =
  ["DOCTYPE", "ENTITY", "ELEMENT", "ATTLIST",
   "map-panel", "giv-frame", "giv-panel", "style-for-type", "group", "element",
  "<?xml", "IMPLIED", "REQUIRED", "PCDATA", "CDATA", "<", ">", "/>"]

extension LanguageConfiguration {

  /// Language configuration for XML formerly Haskell (including GHC extensions)
  ///
  public static let xml = LanguageConfiguration(stringRegexp: "\"(?:\\\\\"|[^\"])*+\"|\'(?:\\\\\'|[^\'])*+\'",
                                                    characterRegexp: nil, //"'(?:\\\\'|[^']|\\\\[^']*+)'",
                                                    numberRegexp:
                                                      optNeg +
                                                      group(alternatives([
                                                        "0[bB]" + binary,
                                                        "0[oO]" + octal,
                                                        "0[xX]" + hexal,
                                                        "0[xX]" + hexal + "\\." + hexal + hexponent + "?",
                                                        decimal + "\\." + decimal + exponent + "?",
                                                        decimal + exponent,
                                                        decimal
                                                      ])),
                                                    singleLineComment: "<!--",
                                                    nestedComment: (open: "<!--", close: "-->"),
                                                    identifierRegexp:
                                                      idHeadChar +
                                                      group(alternatives([
                                                        idHeadChar,
                                                        idBodyChar,
                                                        "'"
                                                      ])) + "*",
                                                    reservedIdentifiers: xmlReservedIds)

}

private let swiftReservedIds =
  ["actor", "associatedtype", "async", "await", "as", "break", "case", "catch", "class", "continue", "default", "defer",
   "deinit", "do", "else", "enum", "extension", "fallthrough", "fileprivate", "for", "func", "guard", "if", "import",
   "init", "inout", "internal", "in", "is", "let", "operator", "precedencegroup", "private", "protocol", "public",
   "repeat", "rethrows", "return", "self", "static", "struct", "subscript", "super", "switch", "throws", "throw", "try",
   "typealias", "var", "where", "while"]

extension LanguageConfiguration {

  /// Language configuration for Swift
  ///
  public static let swift = LanguageConfiguration(stringRegexp: "\"(?:\\\\\"|[^\"])*+\"",
                                                  characterRegexp: nil,
                                                  numberRegexp:
                                                    optNeg +
                                                    group(alternatives([
                                                      "0b" + binary,
                                                      "0o" + octal,
                                                      "0x" + hexal,
                                                      "0x" + hexal + "\\." + hexal + hexponent + "?",
                                                      decimal + "\\." + decimal + exponent + "?",
                                                      decimal + exponent,
                                                      decimal
                                                    ])),
                                                  singleLineComment: "//",
                                                  nestedComment: (open: "/*", close: "*/"),
                                                  identifierRegexp:
                                                    alternatives([
                                                      idHeadChar +
                                                        group(alternatives([
                                                          idHeadChar,
                                                          idBodyChar,
                                                        ])) + "*",
                                                      "`" + idHeadChar +
                                                        group(alternatives([
                                                          idHeadChar,
                                                          idBodyChar,
                                                        ])) + "*`",
                                                      "\\\\$" + decimal,
                                                      "\\\\$" + idHeadChar +
                                                        group(alternatives([
                                                          idHeadChar,
                                                          idBodyChar,
                                                        ])) + "*"
                                                    ]),
                                                  reservedIdentifiers: swiftReservedIds)

}

extension LanguageConfiguration {

  func token(_ token: LanguageConfiguration.Token)
    -> (token: LanguageConfiguration.Token, transition: ((LanguageConfiguration.State) -> LanguageConfiguration.State)?)
  {
    return (token: token, transition: nil)
  }

  func incNestedComment(state: LanguageConfiguration.State) -> LanguageConfiguration.State {
    switch state {
    case .tokenisingCode:           return .tokenisingComment(1)
    case .tokenisingComment(let n): return .tokenisingComment(n + 1)
    }
  }

  func decNestedComment(state: LanguageConfiguration.State) -> LanguageConfiguration.State {
    switch state {
    case .tokenisingCode:          return .tokenisingCode
    case .tokenisingComment(let n)
          where n > 1:             return .tokenisingComment(n - 1)
    case .tokenisingComment(_):    return .tokenisingCode
    }
  }

  var tokenDictionary: TokenDictionary<LanguageConfiguration.Token, LanguageConfiguration.State> {

    var tokenDictionary = TokenDictionary<LanguageConfiguration.Token, LanguageConfiguration.State>()

    // Populate the token dictionary for the code state (tokenising plain code)
    //
    var codeTokenDictionary = [TokenPattern: TokenAction<LanguageConfiguration.Token, LanguageConfiguration.State>]()

    codeTokenDictionary.updateValue(token(.angleBracketOpen), forKey: .string("<"))
    codeTokenDictionary.updateValue(token(.angleBracketClose), forKey: .string(">"))
    codeTokenDictionary.updateValue(token(.roundBracketOpen), forKey: .string("("))
    codeTokenDictionary.updateValue(token(.roundBracketClose), forKey: .string(")"))
    codeTokenDictionary.updateValue(token(.squareBracketOpen), forKey: .string("["))
    codeTokenDictionary.updateValue(token(.squareBracketClose), forKey: .string("]"))
    codeTokenDictionary.updateValue(token(.curlyBracketOpen), forKey: .string("{"))
    codeTokenDictionary.updateValue(token(.curlyBracketClose), forKey: .string("}"))
    
    if let lexeme = stringRegexp { codeTokenDictionary.updateValue(token(.string), forKey: .pattern(lexeme)) }
    if let lexeme = characterRegexp { codeTokenDictionary.updateValue(token(.character), forKey: .pattern(lexeme)) }
    if let lexeme = numberRegexp { codeTokenDictionary.updateValue(token(.number), forKey: .pattern(lexeme)) }
    if let lexeme = singleLineComment {
      codeTokenDictionary.updateValue(token(Token.singleLineComment), forKey: .string(lexeme))
    }
    if let lexemes = nestedComment {
      codeTokenDictionary.updateValue((token: .nestedCommentOpen, transition: incNestedComment),
                                      forKey: .string(lexemes.open))
      codeTokenDictionary.updateValue((token: .nestedCommentClose, transition: decNestedComment),
                                      forKey: .string(lexemes.close))
    }
    if let lexeme = identifierRegexp { codeTokenDictionary.updateValue(token(Token.identifier), forKey: .pattern(lexeme)) }
    for reserved in reservedIdentifiers {
      codeTokenDictionary.updateValue(token(.keyword), forKey: .word(reserved))
    }

    tokenDictionary.updateValue(codeTokenDictionary, forKey: .tokenisingCode)

    // Populate the token dictionary for the comment state (tokenising within a nested comment)
    //
    var commentTokenDictionary = [TokenPattern: TokenAction<LanguageConfiguration.Token, LanguageConfiguration.State>]()

    if let lexemes = nestedComment {
      commentTokenDictionary.updateValue((token: .nestedCommentOpen, transition: incNestedComment),
                                         forKey: .string(lexemes.open))
      commentTokenDictionary.updateValue((token: .nestedCommentClose, transition: decNestedComment),
                                         forKey: .string(lexemes.close))
    }

    tokenDictionary.updateValue(commentTokenDictionary, forKey: .tokenisingComment)

    return tokenDictionary
  }
}
