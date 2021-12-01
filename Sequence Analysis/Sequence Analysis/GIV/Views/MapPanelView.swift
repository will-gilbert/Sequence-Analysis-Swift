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
    
    let extent = mapPanel.extent
    let height = mapPanel.size.height

    // NB: Subtract '1' from the x position becuase sequences
    //     are one-based and Views are zero-based
    
    return ZStack(alignment: .topLeading) {
      ForEach(mapPanel.tiles, id: \.self) { tile in
        if let glyph = tile as? Glyph {
          GlyphView(glyph: glyph, scale: scale)
            .offset(x: (glyph.origin.x - 1) * scale, y: glyph.origin.y)
        } else if let mosaic = tile as? Mosaic {
          MosaicView(mosaic: mosaic, scale: scale)
            .offset(x: (mosaic.origin.x - 1) * scale, y: mosaic.origin.y)
        }
          
      }
    }
    .frame(width: extent * scale, height: height, alignment: .topLeading)
    .background(mapPanel.color)
    }
}
