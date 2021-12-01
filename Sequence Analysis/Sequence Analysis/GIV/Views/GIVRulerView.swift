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

    // Don't show a ruler for very short sequences;
    guard extent > 80 else {return AnyView(EmptyView())}

    // Specify the tick and label density
    let pixelsPerTick: CGFloat = 50 // Tick every 50 pixels
    let ticksPerLabel: Int = 2      // Label every other tick
    let tickSize = pixelsPerTick/scale
    
    // Convert to an easier to read tick label number by rounding
    let x = ceil(log10(tickSize) - 1 )
    let pow10x = pow(10, x)
    let ticksAtEvery = ceil(tickSize / pow10x) * pow10x
    let labelsAtEvery: CGFloat = ticksAtEvery * CGFloat(ticksPerLabel)
    
    // Total ticks; total labels
    let totalTicks: Int = Int(extent / ticksAtEvery) + 1
    let totalLabels: Int = Int(totalTicks / ticksPerLabel)
    let color: Color = Colors.get(color: frgColor).base
    
    return AnyView( ZStack {
    
      // Baseline
      Path() { path in
        path.move(to: CGPoint(x: 0.0 , y: 25))
        path.addLine(to: CGPoint(x: (extent) * scale, y: 25))
      }
      .stroke(color)

      // Tick marks
      ForEach(1..<totalTicks, id: \.self) { i in
        let x = (CGFloat(i) * ticksAtEvery - 1) * scale
        Path() { path in
          path.move(to: CGPoint(x: x, y: 15))
          path.addLine(to: CGPoint(x: x, y:25))
        }
        .stroke(color)
      }
      
      // Tick Labels
      ForEach(1..<totalLabels, id: \.self){ i in
        let x = (CGFloat(i) * labelsAtEvery - 1) * scale

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
