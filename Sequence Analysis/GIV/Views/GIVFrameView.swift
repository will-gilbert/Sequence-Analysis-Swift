//
//  GIVFrameView.swift
//  SA-GIV
//
//  Created by Will Gilbert on 10/5/21.
//

import SwiftUI

struct GIVFrameView: View {

  let givFrame: GIVFrame
  let scale: CGFloat

  init(_ givFrame: GIVFrame, scale: CGFloat = 1.0) {
    self.givFrame = givFrame
    self.scale = scale
  }

  public var body: some View {
    let extent = givFrame.extent
    let height = givFrame.size.height
    let frgColor = givFrame.frgColor
    let bkgColor = givFrame.bkgColor

    return VStack(alignment: .leading, spacing: 0) {
      
      if givFrame.hasRuler {
        GIVRulerView(extent: extent, scale: scale, frgColor: frgColor)
      }
      
      ForEach(givFrame.givPanels, id: \.id) { givPanel in
        GIVPanelView(givPanel, scale: scale)
      }
      
      ForEach(givFrame.mapPanels, id: \.id) { mapPanel in
        MapPanelView(mapPanel, scale: scale)
      }
      
    }
    .background(Colors.get(color: bkgColor).base)
    .frame(width: extent * scale, height: height, alignment: .topLeading)
  }
}

struct GIVRulerView: View {
  
  let extent: CGFloat
  let scale: CGFloat
  let frgColor: String
  
  
  var body: some View {
    
    // Prevent crashes with very short sequences; Don't show a ruler
    guard extent > 100 else { return AnyView(EmptyView())  }
   
    // Need smarter math here!!  OK for now
    let factor: CGFloat = ceil(log2(extent))
    let ticksAt: CGFloat = extent > 5000 ? factor * 50.0 : 50
    let labelsAt: CGFloat = ticksAt * 5.0
    
    let tickExtent: Int = Int(extent / ticksAt)
    let labelExtent: Int = tickExtent - 1
    let color: Color = Colors.get(color: frgColor).base
    
    return AnyView( ZStack {
    
      // Baseline
      Path() { path in
        path.move(to: CGPoint(x: 0.0 , y: 25))
        path.addLine(to: CGPoint(x: extent * scale, y: 25))
      }
      .stroke(color)

      // Tick marks
      ForEach(1..<tickExtent){ i in
        let x = CGFloat(CGFloat(i) * ticksAt) * scale
        Path() { path in
          path.move(to: CGPoint(x: x, y: 15))
          path.addLine(to: CGPoint(x: x, y:25))
        }
        .stroke(color)
      }
      
      // Tick Labels
      ForEach(1..<labelExtent){ i in
        let x = CGFloat(CGFloat(i) * labelsAt) * scale

        Text("\(i * Int(labelsAt))")
          .foregroundColor(color)
          .background(Color.clear)
          .font(.system(size: 10))
          .position(x: x, y: 5.0)
      }

    }
    .frame(width: extent * scale, height: 30, alignment: .leading)
  )}
        
}
