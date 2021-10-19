//
//  MosaicView.swift
//  SA-GIV
//
//  Created by Will Gilbert on 8/24/21.
//

import SwiftUI

struct MosaicView: View {
  
  let mosaic: Mosaic
  let scale: CGFloat
  
  var body: some View {
    
    ZStack(alignment: .topLeading ) {
      
      ForEach(mosaic.tiles, id: \.self) { tile in
        
        if let glyph = tile as? Glyph {
          GlyphView(glyph: glyph, scale: scale)
            .offset(x: glyph.origin.x * scale, y: glyph.origin.y)
        } else if let mosaic = tile as? Mosaic {
          MosaicView(mosaic: mosaic, scale:scale)
            .offset(x: mosaic.origin.x * scale, y: mosaic.origin.y)
        }
      }
      
    }
    // Draw the mosaic and its color as the ZStack frame
    .frame(width: mosaic.size.width * scale, height: mosaic.size.height, alignment: .topLeading)
    .background(mosaic.color)
  }
}
