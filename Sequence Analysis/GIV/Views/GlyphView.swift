//
//  GlyphCavas.swift
//  SA-GIV
//
//  Created by Will Gilbert on 7/28/21.
//

import SwiftUI

struct GlyphView: View {
  
  @EnvironmentObject var windowState: WindowState
  @EnvironmentObject var sequenceState: SequenceState

  let glyph: Glyph
  let scale: CGFloat
  
  var body: some View {
        
    // Simplfy the variable notation for 'bar' and 'bar border'
    let bar = glyph.bar
    let barWidth = bar.size.width * scale
    let barHeight = bar.size.height
    let x = bar.origin.x * scale
    let y = bar.origin.y

    // Border should be drawin inside of the bar
    let inset = glyph.bar.border/2
    let xInset = bar.origin.x + inset
    let yInset = bar.origin.y + inset
    let upperLeft = CGPoint(x: xInset, y: yInset)
    let upperRight = CGPoint(x: xInset + barWidth, y: yInset)
    let lowerRight = CGPoint(x: xInset + barWidth, y: yInset + barHeight)
    let lowerLeft = CGPoint(x: xInset, y: yInset + barHeight)
 
    var labelIsVisible: Bool = true
    
    if let label = glyph.label {
      
      switch label.position {
      case .kLabelAboveBar, .kLabelBelowBar:
        
        // Show the label if its width is less than scaled glyph width
        //  Otherwise we would have toretile the entire map panel.
        //  For now there will be some.
        labelIsVisible = label.size.width < (glyph.size.width * scale)

      case .kLabelInsideBar:
        
        // If the label doesn't fit inside of the bar horizontally
        //   or vertically, hide it
        labelIsVisible = label.size.width < (barWidth - bar.border * 2) &&
                         label.size.height < (barHeight - bar.border * 2)
        
      case .kLabelHidden:
        labelIsVisible = false
      }
    }
        
    
    return ZStack(alignment: .topLeading ) {
      
      // Bar
      Path() { path in
        path.move(to: CGPoint(x: x , y: y))
        path.addLine(to: CGPoint(x: x + barWidth, y: y))
        path.addLine(to: CGPoint(x: x + barWidth, y: y + barHeight))
        path.addLine(to: CGPoint(x: x, y: y + barHeight))
        path.addLine(to: CGPoint(x: x, y: y))
      }
      .fill(glyph.bar.color.base)
      
      // Very narrow glyphs should not have a border
      if(barWidth > bar.border * 2  && barHeight > bar.border * 2) {

        // Bar Border; upper left (lighter than bar)
        Path() { path in
          path.move(to: lowerLeft)
          path.addLine(to: upperLeft)
          path.addLine(to: upperRight)
        }
        .stroke(bar.color.lighter, lineWidth: bar.border)

        // Bar Border; lower right (Darker than bar)
        Path() { path in
          path.move(to: upperRight)
          path.addLine(to: lowerRight)
          path.addLine(to: lowerLeft)
        }
        .stroke(bar.color.darker, lineWidth: bar.border)
        
        // Optional label when visible, 'above', 'inside' or 'below'
        if let label = glyph.label, labelIsVisible {
          Text(verbatim: label.string)
            .foregroundColor(label.color)
            .font(.system(size: label.fontSize))
            .background(Color.clear)
            .offset(x: ((barWidth - label.size.width)/2), y: label.origin.y)
        }
      }
      
      // Tile hightlight -- TODO
      // Path(CGRect(x: 0, y: 0, width: glyph.size.width, height: glyph.size.height)).stroke(Color.red)
    }
    .frame(width: glyph.size.width * scale, height: glyph.size.height, alignment: .center)
    .onTapGesture {
      
      DispatchQueue.main.async {
        if windowState.selectedAnalysis == .ORF {
          sequenceState.selectedORFGlyph = glyph
        } else if windowState.selectedAnalysis == .PATTERN {
          sequenceState.selectedPatternGlyph = glyph
        }
        
        sequenceState.selection = NSRange(location: glyph.element.start-1, length: glyph.element.stop - glyph.element.start + 1)
      }

//      print("")
//      print("    Name: \(glyph.label?.string ?? "Untitled")")
//      print("  Origin: x: \(F.f(glyph.origin.x * scale)), y:\(glyph.origin.y)")
//      print("    Size: width: \(F.f(glyph.size.width *  scale)), height: \(glyph.size.height)")
//      print("Lbl size: width: \(F.f(glyph.label?.size.width ?? 0.0)), height: \(F.f(glyph.label?.size.height ?? 0.0))")
//      print("Bar size: width: \(F.f(barWidth, decimal: 1)), height: \(F.f(barHeight))")
//      print("   Color: \(glyph.bar.color.base)")
//      print(" Element: \(glyph.element.start)-\(glyph.element.stop), length: \(glyph.element.stop - glyph.element.start + 1)")
//      print("    Type: \(glyph.style.name)")
//      print("   Label: \(glyph.label!.position.rawValue.capitalized)")
    }
  }
}

