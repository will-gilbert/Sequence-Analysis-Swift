//
//  MapPanel.swift
//  SA-GIV
//
//  Created by Will Gilbert on 10/5/21.
//

import SwiftUI

struct MapPanel {
  
  let id = UUID()

  let startExtent: CGFloat = 0
  let stopExtent: CGFloat
  var tiles: Array<Tile> = []
  let layout: TileLayout
  var size: CGSize = CGSize(width: 0, height: 0)
  let color: Color
  var scale: CGFloat = 1.0

  init(extent: Int, layout: TileLayout = TileLayout(), color: String = "AGA 01") {
    self.stopExtent = CGFloat(extent)
    self.layout = layout
    self.color = Colors.get(color: color).base
  }
  
  mutating func addTile(_ tile: Tile) -> Void {
    self.tiles.append(tile)
    retile()
  }
  
  mutating func addTiles(_ tiles: [Tile]) -> Void {
    self.tiles.append(contentsOf: tiles)
    retile()
  }
  
  mutating func retile() {
    
    // Determine the origin.x and size of any mosaic based on its
    //  children Glyph/Mosaic tiles
    
    for tile in tiles {
      if let mosaic = tile as? Mosaic {
        mosaic.retile()
      }
    }

    size = self.layout.retile(tiles: tiles)
  }
  
  mutating func setPanelWidth(_ width: CGFloat) -> Void {
    // Zoom in/out the sequence length to the panel width
    scale = width/(stopExtent - startExtent)
  }
}
