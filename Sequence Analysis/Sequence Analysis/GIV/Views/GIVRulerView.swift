//
//  GIVRulerView.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 11/19/21.
//

import SwiftUI

struct GIVRulerView: View {
  
  let extent: CGFloat
  let scale: CGFloat
  let frgColor: String
  
  var body: some View {
    
    let pixelsPerTick: CGFloat = 50 // Tick every 50 pixels
    let ticksPerLabel: Int = 2  // Label every other tick
    
    // Prevent crashes with very short sequences; Don't show a ruler
    //guard extent > 100 else { return AnyView(EmptyView())  }
       
    let tickSize = (1/scale) * pixelsPerTick
    
    // Convert to an easier to read number by rounding
    let x = ceil(log10(tickSize) - 1 )
    let pow10x = pow(10, x)
    let ticksAtEvery = ceil(tickSize / pow10x) * pow10x
    let labelsAtEvery: CGFloat = ticksAtEvery * CGFloat(ticksPerLabel)
    
    // Total ticks; total labels
    let totalTicks: Int = Int(extent / ticksAtEvery)
    let totalLabels: Int = Int(totalTicks / ticksPerLabel)
    let color: Color = Colors.get(color: frgColor).base
    
    guard totalTicks > 1 else {return AnyView(EmptyView())}
    guard totalLabels > 1 else {return AnyView(EmptyView())}

    return AnyView( ZStack {
    
      // Baseline
      Path() { path in
        path.move(to: CGPoint(x: 0.0 , y: 25))
        path.addLine(to: CGPoint(x: extent * scale, y: 25))
      }
      .stroke(color)

      // Tick marks
      ForEach(1..<totalTicks, id: \.self) { i in
        let x = CGFloat(i) * ticksAtEvery * scale
        Path() { path in
          path.move(to: CGPoint(x: x, y: 15))
          path.addLine(to: CGPoint(x: x, y:25))
        }
        .stroke(color)
      }
      
      // Tick Labels
      ForEach(1..<totalLabels, id: \.self){ i in
        let x = CGFloat(i) * labelsAtEvery * scale

        Text("\(i * Int(labelsAtEvery))")
          .foregroundColor(color)
          .background(Color.clear)
          .font(.system(size: 10))
          .position(x: x, y: 5.0)
      }

    }.onAppear {
    }
    .frame(width: extent * scale, height: 30, alignment: .leading)

  )}
        
}
