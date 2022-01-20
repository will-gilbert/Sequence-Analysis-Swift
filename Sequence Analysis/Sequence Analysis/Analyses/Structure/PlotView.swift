//
//  PlotView.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 1/12/22.
//

import SwiftUI

struct Datum: Hashable{
  let position: CGFloat
  let value: CGFloat
  
  init(_ position: Int, _ value: Double) {
    self.position = CGFloat(position)
    self.value = CGFloat(value)
  }
}

struct PlotData {
  let lower: Double
  let upper: Double
  let cutoff: Double
  let length: Int
  let gradient: LinearGradient

  let data: [Datum]

}

struct PlotView: View {
  
  let plotData: PlotData
    
  var body: some View {

    // Convert Doubles to CGFloats for Drawing methods
    let lower = CGFloat(plotData.lower)
    let upper = CGFloat(plotData.upper)
    let cutoff = CGFloat(plotData.cutoff)
    let length = CGFloat(plotData.length)

    return VStack {
      GeometryReader { reader in
        
        //  Calculate position of each datum position on the frame width
        //  Calculate height of graph based on the frame height
        let positionWidth = reader.size.width /  length
        let dataRange = reader.size.height / (upper - lower)
        let cutoffPx = (cutoff - lower) * dataRange

        // Draw each datum measurement
        ForEach(plotData.data, id: \.self) { datum in
         
          // Draw the value as a rectangle
          Path { path in

            // Calculate the horizontal position for this datum
            let positionPx = datum.position * positionWidth
            
            // Calculate the lower and upper for this datum
            let valuePx = (datum.value  - lower) * dataRange
            
            // Draw this datum as a rectangle from the cutoff to its value
            let origin = CGPoint(x: positionPx, y: reader.size.height - cutoffPx)
            let size = CGSize(width: positionWidth, height: cutoffPx - valuePx)
            path.addRect(CGRect(origin: origin, size: size))
            
            // Visualize the drawn rectanges overlayed with a color gradient
          }.fill(plotData.gradient)
        }
        
        // Draw the reference cutoff line in gray; Should blend into the data
        Path { p in
          p.move(to: .init(x: 0, y: reader.size.height - cutoffPx))
          p.addLine(to: .init(x: length * positionWidth, y: reader.size.height - cutoffPx))
        }.stroke(.gray, lineWidth: 1.0)
              
      }
    }.padding()
  }
}

