//
//  MapPanelView.swift
//  SA-GIV
//
//  Created by Will Gilbert on 7/17/21.
//

import SwiftUI

struct MapPanelView: View {
  
  let mapPanel: MapPanel
  let scale: CGFloat
  
  init(_ mapPanel: MapPanel, scale: CGFloat = 1.0) {
    self.mapPanel = mapPanel
    self.scale = scale
  }
    
  public var body: some View {

    return ZStack(alignment: .topLeading) {
      ForEach(mapPanel.tiles, id: \.self) { tile in
          
          if let glyph = tile as? Glyph {
            GlyphView(glyph: glyph, scale: scale)
              .offset(x: glyph.origin.x * scale, y: glyph.origin.y)
          } else if let mosaic = tile as? Mosaic {
            MosaicView(mosaic: mosaic, scale: scale)
              .offset(x: mosaic.origin.x * scale, y: mosaic.origin.y)
          }
          
        }
      }
    .frame(width: mapPanel.stopExtent * scale, height: mapPanel.size.height, alignment: .topLeading)
    .background(mapPanel.color)
    }
}
