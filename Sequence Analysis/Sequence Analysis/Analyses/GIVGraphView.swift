//
//  GIVGraphView.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 11/26/21.
//

import SwiftUI

struct GIVGraphView: View {

  @State var scale: Double = 1.0

  let givFrame: GIVFrame
  let extent: CGFloat
  
  var height: CGFloat = 0.0
  var width: CGFloat = 0.0

  init(givFrame: GIVFrame, extent: CGFloat) {
    self.givFrame = givFrame
    self.extent = extent
    height = givFrame.size.height
    width = givFrame.size.width
  }
      
  var body: some View {
    
    // Protect against divide by zero
    if extent.isZero {
        return AnyView(EmptyView())
    } else {

    return AnyView(
      GeometryReader { geometry in
   
      let panelWidth = geometry.size.width
      var minScale = panelWidth/extent
      let maxScale = minScale * log2(extent)
      let scrollViewWidth =  extent * scale

      VStack(alignment: .leading) {
        HStack (spacing: 15) {
          Slider(
            value: $scale,
            in: minScale...maxScale
          ).disabled(minScale >= maxScale)
          
          Text("Scale: \(F.f(scale, decimal: 2))")
        }
        
        // The following nested 'GeometryReader' and 'mapPanelView.size' is
        //   a horrible hack to get the 'mapPanelView" to at the top of the
        //   'ScrollView';  Nested 'VStack' did not; Spent 2 days on this!
        //   Maybe a macOS SwiftUI bug, maybe not.
        //   TODO: Revisit in the future.
        
        // SCROLLVIEW ----------------------------------------------------------
        GeometryReader { g in
          ScrollView( [.vertical, .horizontal], showsIndicators: true) {
           
            VStack(spacing: 0) {
              GIVFrameView(givFrame, scale: scale)
            }.frame(width: scrollViewWidth, height: height)

            // Create a bottom 'Spacer' as needed when the GIV panels do not fill the ScrollView
            if g.size.height > height {
              Spacer()
              .frame(height: g.size.height - height)
            }
          }
          .background(Colors.get(color: "AGA 01").base)
        }
        // SCROLLVIEW ----------------------------------------------------------
        
      }.onAppear {
        let panelWidth = geometry.size.width
        scale = panelWidth/extent
      }.onChange(of: geometry.frame(in: .global).width) { value in
        minScale = value/Double(extent)
        scale = scale > minScale ? scale : minScale
      }
    })
    }
  }
}
