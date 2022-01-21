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
  
  @State private var scale: Double = 1.0
  
  let plotData: PlotData
    
  var body: some View {
    
    // Convert Doubles to CGFloats for the drawing methods
    let lower = CGFloat(plotData.lower)
    let upper = CGFloat(plotData.upper)
    let cutoff = CGFloat(plotData.cutoff)
    let extent = CGFloat(plotData.length)

    return GeometryReader { g in
    
      // Generate constant for the zooming and scrolling
      let height = g.size.height
      let panelWidth = g.size.width
      var minScale = panelWidth/extent
      let maxScale = minScale * log2(extent)
      let scrollViewWidth = extent * scale
      
      VStack(alignment: .leading) {
        
        HStack (spacing: 15) {
          Slider(
            value: $scale,
            in: minScale...maxScale
          ).disabled(minScale >= maxScale)

          Text("Scale: \(F.f(scale, decimal: 2))")
        }
        
        // Calculate each datum position on the panel width
        // Calculate height of each datum based on the panel height
        let positionWidth = scale //(panelWidth / extent)
        let dataRange = height / (upper - lower)
        let cutoffPx = (cutoff - lower) * dataRange
          
        ScrollView( .horizontal, showsIndicators: true) {

            // ZStack is very important here!
            ZStack(alignment: .topLeading) {
              
              // Draw each datum measurement and a rectangle
              ForEach(plotData.data, id: \.self) { datum in
               
                // Draw the value as a rectangle
                Path { path in

                  // Calculate the horizontal position for this datum
                  let positionPx = datum.position * positionWidth
                  
                  // Calculate the lower and upper for this datum
                  let valuePx = (datum.value  - lower) * dataRange
                  
                  // Draw this datum as a rectangle from the cutoff to its value
                  let origin = CGPoint(x: positionPx, y: height - cutoffPx)
                  let size = CGSize(width: positionWidth, height: cutoffPx - valuePx)
                  path.addRect(CGRect(origin: origin, size: size))
                  
                  // Visualize the drawn rectanges overlayed with a color gradient
                }.fill(plotData.gradient)
              }
              
              // Draw the reference cutoff line in gray; Should blend into the data rectangles
              Path { p in
                p.move(to: .init(x: 0, y: height - cutoffPx))
                p.addLine(to: .init(x: extent * positionWidth, y: height - cutoffPx))
              }.stroke(.gray, lineWidth: 1.0)
            
          // Panel size for ScrollView
          }.frame(width: scrollViewWidth, height: height)
          
        }.onAppear {
            // Set the inital zoom, that is, scale
            let panelWidth = g.size.width
            scale = panelWidth/extent
          }.onChange(of: g.frame(in: .global).width) { value in
            // Change the zoom if the panel size changes
            minScale = value/Double(extent)
            scale = scale > minScale ? scale : minScale
          }
        
      }
    }.padding(EdgeInsets(top: 0, leading: 0, bottom: 50, trailing: 0))
  }
      
}

