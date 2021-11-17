//
//  LineNumberRulerView.swift
//  TextEditor (macOS)
//
//  Created by Will Gilbert on 8/26/21.
//

import AppKit

class LineNumberRulerView: NSRulerView {
      
  var font: NSFont! {
    didSet {
        self.needsDisplay = true
    }
  }
    
  init(textView: NSTextView) {
    
    super.init(scrollView: textView.enclosingScrollView!, orientation: NSRulerView.Orientation.verticalRuler)
    self.clientView = textView
    
    // Inital thickness to prevent a large amount of change when the final thickness is determined
    self.ruleThickness = 40
  }
    
  required init(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
    
  override func drawHashMarksAndLabels(in rect: NSRect) {
    
    let padding: CGFloat = 5

    // We must have there before doing anything with the ruler
    guard let textView = self.clientView as? NSTextView else { return }
    guard let layoutManager = textView.layoutManager else { return }
    
    
    // Create a wide enough gutter based on the number of lines
    let newLineRegex = try! NSRegularExpression(pattern: "\n", options: [])
    let lineCount = newLineRegex.numberOfMatches(in: textView.string, options: [], range:NSMakeRange(0, textView.string.count))
    
    // Text attributes for the ruler
    let lineNumberAttributes = [
      NSAttributedString.Key.font: textView.font! ,
      NSAttributedString.Key.foregroundColor: NSColor.lightGray
    ] as [NSAttributedString.Key : Any]

    let label = NSAttributedString(string: String(lineCount), attributes: lineNumberAttributes)
    self.ruleThickness = label.size().width + padding * 2

    
    // Closure which draws the line position into the ruler
    let relativePoint = self.convert(NSZeroPoint, from: textView)
    
    // Create the number drawing function 'drawlineNumber(String, CGFloat)'
    let drawLineNumber = {
      (lineNumberString:String, y:CGFloat) -> Void in
        let attributedString = NSAttributedString(string: lineNumberString, attributes: lineNumberAttributes)
        let x = self.ruleThickness - padding - attributedString.size().width
        attributedString.draw(at: NSPoint(x: x, y: relativePoint.y + y))
    }

    // Only update the ruler for what we can see in the frame
    let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: textView.textContainer!)
    let firstVisibleGlyphCharacterIndex = layoutManager.characterIndexForGlyph(at: visibleGlyphRange.location)
    
    // The line number for the first visible line
    var lineNumber = newLineRegex.numberOfMatches(in: textView.string, options: [], range: NSMakeRange(0, firstVisibleGlyphCharacterIndex)) + 1
    var glyphIndexForStringLine = visibleGlyphRange.location

    // Go through each line in the string.
    while glyphIndexForStringLine < NSMaxRange(visibleGlyphRange) {

      // Range of current line in the string.
      let characterRangeForStringLine = (textView.string as NSString).lineRange(
          for: NSMakeRange( layoutManager.characterIndexForGlyph(at: glyphIndexForStringLine), 0 )
      )
      let glyphRangeForStringLine = layoutManager.glyphRange(forCharacterRange: characterRangeForStringLine, actualCharacterRange: nil)
      
      var glyphIndexForGlyphLine = glyphIndexForStringLine
      var glyphLineCount = 0

      while ( glyphIndexForGlyphLine < NSMaxRange(glyphRangeForStringLine) ) {
        
        // See if the current line in the string spread across
        // several lines of glyphs
        var effectiveRange = NSMakeRange(0, 0)
        
        // Range of current "line of glyphs". If a line is wrapped,
        // then it will have more than one "line of glyphs"
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndexForGlyphLine, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)
        
        if glyphLineCount > 0 {
            drawLineNumber("-", lineRect.minY)
        } else {
            drawLineNumber("\(lineNumber)", lineRect.minY)
        }
        
        // Move to next glyph line
        glyphLineCount += 1
        glyphIndexForGlyphLine = NSMaxRange(effectiveRange)
      }

      glyphIndexForStringLine = NSMaxRange(glyphRangeForStringLine)
      lineNumber += 1
    }
    
    // Draw line number for the extra line at the end of the text
    if layoutManager.extraLineFragmentTextContainer != nil {
        drawLineNumber("\(lineNumber)", layoutManager.extraLineFragmentRect.minY)
    }
  }
}
