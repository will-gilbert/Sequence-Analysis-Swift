//
//  LineNumberRulerView.swift
//  SequenceEditor (macOS)
//
//  Created by Will Gilbert on 8/26/21.
//

import AppKit

extension NSTextView {
  
  private static var _myComputedProperty = [String:LineNumberRulerView]()

    var lineNumberView:LineNumberRulerView {
      get {
        let key = String(format: "%p", unsafeBitCast(self, to: Int.self))
        return NSTextView._myComputedProperty[key] ?? LineNumberRulerView(textView: self)
      }
      set(newValue) {
        let key = String(format: "%p", unsafeBitCast(self, to: Int.self))
        NSTextView._myComputedProperty[key] = newValue
      }
    }
  
  func setUpLineNumberView() {
      
    if font == nil {
        font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    }
        
    if let scrollView = enclosingScrollView {
          
      lineNumberView = LineNumberRulerView(textView: self)
        
      scrollView.verticalRulerView = lineNumberView
      scrollView.hasVerticalRuler = true
      scrollView.rulersVisible = true
    }
      
    postsFrameChangedNotifications = true
    NotificationCenter.default.addObserver(self, selector: #selector(lnv_frameDidChange), name: NSView.frameDidChangeNotification, object: self)
    NotificationCenter.default.addObserver(self, selector: #selector(lnv_textDidChange), name: NSText.didChangeNotification, object: self)
  }
    
  @objc func lnv_frameDidChange(notification: NSNotification) {
        lineNumberView.needsDisplay = true
    }
    
  @objc func lnv_textDidChange(notification: NSNotification) {
        lineNumberView.needsDisplay = true
    }
}


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
    
    let count = String(textView.string.count)
    
    // Text attributes for the ruler
    let lineNumberAttributes = [
      NSAttributedString.Key.font: textView.font!,
      NSAttributedString.Key.foregroundColor: NSColor.red
    ] as [NSAttributedString.Key : Any]

    let label = NSAttributedString(string: count, attributes: lineNumberAttributes)
    self.ruleThickness = label.size().width + padding * 2

        // Closure which draws the sequence position into the ruler
    let relativePoint = self.convert(NSZeroPoint, from: textView)
    let drawLineNumber = { (lineNumberString:String, y:CGFloat) -> Void in
        let attString = NSAttributedString(string: lineNumberString, attributes: lineNumberAttributes)
        let x = self.ruleThickness - padding - attString.size().width
        attString.draw(at: NSPoint(x: x, y: relativePoint.y + y))
      }

    // Only update the ruler for what we can see in the frame
    let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: textView.textContainer!)


    // Current chracter position at the left edge (zero-based)
    var glyphIndexForStringLine = 0

    // Go through each visible line in the frame
    while glyphIndexForStringLine < NSMaxRange(visibleGlyphRange) {

        // Range of current line in the string.
        let characterRangeForStringLine = (textView.string as NSString).lineRange (
            for: NSMakeRange( layoutManager.characterIndexForGlyph(at: glyphIndexForStringLine), 0 )
        )
      
        let glyphRangeForStringLine = layoutManager.glyphRange(forCharacterRange: characterRangeForStringLine, actualCharacterRange: nil)
        var glyphIndexForGlyphLine = glyphIndexForStringLine

        while ( glyphIndexForGlyphLine < NSMaxRange(glyphRangeForStringLine) ) {
          
          var effectiveRange = NSMakeRange(0, 0)

          // Get the location of the current line of charaters ; We need its vertical offset in the frame
          let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndexForGlyphLine, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)

          // Draw the sequence number into the ruler; Sequences are 1-based
          drawLineNumber("\(glyphIndexForGlyphLine + 1)", lineRect.minY)

          // Move to next character line
          glyphIndexForGlyphLine = NSMaxRange(effectiveRange)
          

        }

        // Update the current character aka glyph position
        glyphIndexForStringLine = NSMaxRange(glyphRangeForStringLine)
    }
  }
}
