//
//  Mosaic.swift
//  SA-GIV
//
//  Created by Will Gilbert on 8/24/21.
//

import SwiftUI

class Mosaic: Tile  {
  
  var label: String?
  var color: Color = Colors.get(color: "none").base
  var padding: CGFloat = 5
  
  var layout: TileLayout
  var tiles: [Tile] = []
  var retiled: Bool = false
  
  init() {
    self.layout = TileLayout(buoyancy: .floating)
    super.init(origin: CGPoint.zero, size: CGSize.zero)
  }
  
  init(label: String?, buoyancy: String, color: String, vGap: Int = 3, hGap: Int = 3) {
    self.label = label
    self.layout = TileLayout(buoyancy: Buoyancy.fromString(buoyancy), hGap: CGFloat(hGap), vGap: CGFloat(vGap))
    self.color = Colors.get(color: color).base
    
    super.init(origin: CGPoint.zero, size: CGSize.zero)
  }
  
  init(tiles: [Tile]) {
    self.tiles = tiles
    self.layout = TileLayout(buoyancy: .floating)
    super.init(origin: CGPoint.zero, size: CGSize.zero)
  }
  
  init(tiles: [Tile], layout: TileLayout, color: String, padding: CGFloat = 5) {
    self.tiles = tiles
    self.layout = layout
    self.color = Colors.get(color: color).base
    self.padding = padding
    super.init(origin: CGPoint.zero, size: CGSize.zero)
  }
  
  func addTile(_ tile: Tile) -> Void {
    tiles.append(tile)
  }

  func retile() {
    
    // No tiles
    guard tiles.count > 0 else { return }

    // Only retile a mosaic tiles once
    guard retiled == false else {return}
    
    // Recursive: Retile any 'Mosaic' tiles within this 'Mosaic'
    //  This is done to establish the size of any child mosaics
    for tile in tiles {
      if let mosaic = tile as? Mosaic {
        mosaic.retile()
      }
    }

    // Retile the tiles (mosaics and glyphs) in this mosaic;
    //   Afterwards, get its height and width, add padding around this mosaic
    let size = layout.retile(tiles: tiles)
    retiled = true

    self.size.height = size.height + padding * 2
    self.size.width = size.width + padding * 2

    // Set this mosaic's left (origin.x) based on its left most and top most tile
    self.origin.x = CGFloat(Int.max)
    self.origin.y = CGFloat(Int.max)
   
    for tile in tiles {
      self.origin.x = min(self.origin.x, tile.origin.x)  // Left most tile's 'x'
      self.origin.y = min(self.origin.y, tile.origin.y)  // Top most tile's 'y'
    }
    
    // Adjust all contained tiles for the mosaic origin and any padding
    for tile in tiles {
      tile.origin.x -= self.origin.x - padding
      tile.origin.y -= self.origin.y - padding
    }
      
    // Shift the mosaic origin in order to allow padding
    self.origin.x -= padding
    self.origin.y -= padding
  }
    
}
