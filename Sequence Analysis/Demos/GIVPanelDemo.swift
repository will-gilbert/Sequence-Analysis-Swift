//
//  GIVPanelDemo.swift
//  SA-GIV
//
//  Created by Will Gilbert on 10/5/21.
//

import SwiftUI

struct GIVPanelDemo: View {
  
  @State var scale: Double = 1.0

  let extent: CGFloat
  let givPanelData: GIVPanelData
  
  let givFrame: GIVFrame
  var height: CGFloat = 0.0
  var width: CGFloat = 0.0
  
  init(extent: Int) {
    self.extent = CGFloat(extent)
    givPanelData = GIVPanelData(extent: extent)
    givFrame = givPanelData.givFrame
    
    height = givFrame.size.height
    width = givFrame.size.width
  }

  var body: some View {

    let fitToWidth: CGFloat = extent * scale
    
    return GeometryReader { geometry in
   
      var minScale: Double = geometry.size.width/Double(extent)
      
      VStack(alignment: .leading) {
        
        VStack(alignment: .center) {
          Text("GIV Frame Zooming")
            .font(.title)
          Text(String("Window: \(F.f(geometry.size.width, decimal: 0))"))
          Text(String("Scale: \(F.f(scale, decimal: 0))"))
          Text(String("Extent: \(F.f(extent, decimal: 0))"))
          Text(String("FitToWidth: \(F.f(extent * scale, decimal: 0))"))
          Slider(
            value: $scale,
            in: minScale...10.0
          )
        }
        
        // SCROLLVIEW ----------------------------------------------------------
        GeometryReader { g in
          ScrollView( [.vertical, .horizontal], showsIndicators: true) {
           
            VStack(spacing: 0) {
              GIVFrameView(givFrame, scale: scale)
            }.frame(width: fitToWidth, height: height)
            
            // Hacky way to force the GIV Panels to the top
            if g.size.height > height {
              Spacer()
              .frame(height: g.size.height - height)
            }

          }
          .background(Colors.get(color: "Peach").base )
        }
        // SCROLLVIEW ----------------------------------------------------------
        
      }.onAppear {
        minScale = geometry.size.width/Double(extent)
        scale = minScale
      }.onChange(of: geometry.frame(in: .global).width) { value in
        minScale = value/Double(extent)
        scale = scale > minScale ? scale : minScale
      }
    }
  }
  
}

struct GIVPanelData {
  
  var givFrame: GIVFrame
    
  init(extent: Int) {
    self.givFrame = GIVFrame(extent: extent)
    
    let colors = Colors.getNames()
    
    for i in 1...3 {
      var givPanel = GIVPanel(extent: extent, color: "Clear", label: "GIV Panel \(i)")
      let layout = TileLayout(buoyancy: .floating, hGap: 2, vGap: 2)

      for _ in 0...3 {
        let color = colors[Int.random(in:0..<colors.count)]
        var mapPanel = MapPanel(extent: extent, layout: layout, color: color)

        for _ in 0..<10 {
          mapPanel.addTile(randomGlyph(extent: extent))
        }
        givPanel.addMapPanel(mapPanel)
      }
      
      givFrame.addGIVPanel(givPanel)
    }
    
  }
        
  func randomGlyph(extent: Int) -> Glyph {
    let start = Int.random(in: 1...(extent - 20))
    let length = Int.random(in: 5...20 )

    return Glyph(element: Element(label: "1", start: start, stop: start + length))
  }


}
