//
//  SequenceRulerView.swift
//  SequenceEditor (macOS)
//
//  Created by Will Gilbert on 8/26/21.
//

import AppKit

class SequenceRulerView: NSRulerView {
      
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
    let rulerAttributes = [
      NSAttributedString.Key.font: textView.font!,
      NSAttributedString.Key.foregroundColor: NSColor.systemRed
    ] as [NSAttributedString.Key : Any]

    let label = NSAttributedString(string: count, attributes: rulerAttributes)
    self.ruleThickness = label.size().width + padding * 2

    // Closure which draws the sequence position into the ruler
    let drawSequenceNumber = {
      (sequencePosition:Int, y:CGFloat) -> Void in
        // Sequences are 1-based
        let string = String(sequencePosition + 1)
        let rulerString = NSAttributedString(string: string, attributes: rulerAttributes)
        let relativePoint = self.convert(NSZeroPoint, from: textView)
        let x = self.ruleThickness - padding - rulerString.size().width
        rulerString.draw(at: NSPoint(x: x, y: relativePoint.y + y))
      }

    // Only update the ruler for what we can see in the frame
    let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: textView.textContainer!)
    
    var glyphIndexForGlyphLine = 0
    while (glyphIndexForGlyphLine < NSMaxRange(visibleGlyphRange) ) {
      
      // Used to return the current
      var effectiveRange = NSMakeRange(0, 0)

      // Get the textView 'rect' for this line of glyphs; We only need its vertical position
      let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndexForGlyphLine, effectiveRange: &effectiveRange)

      // Draw the sequence number into the ruler
      drawSequenceNumber(glyphIndexForGlyphLine, lineRect.minY)

      // Move to next visible glyph line
      glyphIndexForGlyphLine = NSMaxRange(effectiveRange)
   }

  }
}
