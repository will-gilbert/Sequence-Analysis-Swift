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
    VStack(alignment: .leading, spacing: 0) {
      
      if givFrame.hasRuler {
        GIVRulerView(extent: givFrame.extent, scale: scale)
      }
      
      ForEach(givFrame.givPanels, id: \.id) { givPanel in
        GIVPanelView(givPanel, scale: scale)
      }
      
    }.frame(width: givFrame.extent, height: givFrame.size.height, alignment: .topLeading)
  }
}

struct GIVRulerView: View {
  
  let extent: CGFloat
  let scale: CGFloat
  
  
  var body: some View {
   
    let ticksAt: CGFloat = 50
    let labelsAt: CGFloat = 100

    let tickExtent: Int = Int(extent/ticksAt)
    let labelExtent: Int = Int(extent/labelsAt)
    let offsetLeft: CGFloat = (extent * (1.0 - scale))/2  // This works, but why?
    
    return ZStack {
    
      // Baseline
      Path() { path in
        path.move(to: CGPoint(x: 0.0 , y: 25))
        path.addLine(to: CGPoint(x: extent * scale, y: 25))
      }
      .stroke(Color.black)

      // Tick marks
      ForEach(1..<tickExtent){ i in
        let x = CGFloat(CGFloat(i) * ticksAt) * scale
        Path() { path in
          path.move(to: CGPoint(x: x, y: 15))
          path.addLine(to: CGPoint(x: x, y:25))
        }
        .stroke(Color.black)
      }
      
      // Tick Labels
      ForEach(1..<labelExtent){ i in
        let x = CGFloat(CGFloat(i) * labelsAt) * scale

        Text("\(i*100)")
          .foregroundColor(.black)
          .background(Color.clear)
          .font(.system(size: 10))
          .position(x: x, y: 5.0)
      }

    }
    .offset(x: offsetLeft, y: 0)
    .frame(width: extent, height: 25, alignment: .topLeading)
    .background(Colors.get(color: "None").base)


  }
        
}
