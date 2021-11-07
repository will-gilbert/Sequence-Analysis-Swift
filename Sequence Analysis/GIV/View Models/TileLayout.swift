//
//  TileLayout.swift
//  SA-GIV
//
//  Created by Will Gilbert on 7/18/21.
//

import SwiftUI

struct TileLayout {
  
  var buoyancy: Buoyancy = .floating
  var hGap: CGFloat = 3
  var vGap: CGFloat = 3
  
  
  init() {
    self.buoyancy = .floating
    self.hGap = 3
    self.vGap = 3
  }
  
  init(buoyancy: String, hGap: CGFloat = 3, vGap: CGFloat = 3) {
    self.buoyancy = Buoyancy.fromString(buoyancy)
    self.hGap = hGap
    self.vGap = vGap
  }

  init(buoyancy: Buoyancy, hGap: CGFloat = 3, vGap: CGFloat = 3) {
    self.buoyancy = buoyancy
    self.hGap = hGap
    self.vGap = vGap
  }


  func retile(tiles: [Tile]) -> CGSize {

    // There must be tiles lay them out
    guard tiles.count > 0 else { return CGSize.zero }

    // Sort the "tiles" array
    let sortedTiles = tiles.sorted { $0.origin.x < $1.origin.x }

    var bounds = CGSize.zero
    switch buoyancy {
    
      case .floating:
        bounds = packTiles(tiles: sortedTiles)

      case .sinking:
        bounds = packTiles(tiles: sortedTiles)
        let thickness = bounds.height
        flipTiles(tiles: tiles, thickness: thickness)
 
      case .stackDown:
        bounds = stackTiles(tiles: sortedTiles)
        
      case .stackUp:
        bounds = stackTiles(tiles: sortedTiles)
        let thickness = bounds.height
        flipTiles(tiles: tiles, thickness: thickness)
    }
    
    return bounds
  }
    
  private func flipTiles(tiles: [Tile], thickness: CGFloat)  {
    
    for tile in tiles {
      tile.origin.y = thickness - (tile.origin.y + tile.size.height)
    }
  }

  private func stackTiles(tiles: [Tile]) -> CGSize {
 
    var height: CGFloat = vGap
    var width: CGFloat = 0

    // Inialize the width, first tile with the hGap
    let leftEdge = tiles.first?.origin.x ?? 0

    for tile in tiles {
      tile.origin.y = height
      height += (tile.size.height + vGap)
      let newWidth = (tile.origin.x + tile.size.width) - leftEdge
      width = (newWidth > width) ? newWidth : width
    }
    
    return CGSize(width: width, height: height)
  }
    
  private func packTiles(tiles: [Tile]) -> CGSize {
    
    var height: CGFloat = 0
    var width: CGFloat = 0
        
    // Inialize the width, first tile with the hGap
    let leftEdge = tiles.first?.origin.x ?? 0

    // Place each element vertically, "edgeTiles" is an array which
    // holds all of the tiles placed so far which may block an incomming tile.
    // This array can be thought of as consisting of the tiles along the right
    // edge of the growing layout.
    
    var edgeTiles = Array<Tile?>()

    for tile in tiles {
            
      // For each tile, create a temporary, "aTile", from the array of ordered tiles.
      //   Compare against every tile along the left to right edge.
      //   Initialize 'top' coordinate to the vertical gap

      let aTile = Tile(origin: CGPoint(x: tile.origin.x, y: vGap), size: tile.size)
      
      for i in 0..<edgeTiles.count {
        
        // Ensure we have a non-nil edge tile; S/B always OK
        guard let edgeTile = edgeTiles[i] else { continue }
        
        // Get the tile edges here so as not to obfuscate the tile placement logic below
        
        let edgeTileTop = edgeTile.origin.y
        let edgeTileBottom = edgeTile.origin.y + edgeTile.size.height + vGap
        let edgeTileRight = edgeTile.origin.x + edgeTile.size.width + hGap

        let aTileBottom = aTile.origin.y + aTile.size.height + vGap
        let aTileLeft = aTile.origin.x - hGap
        
        // Tile Placement:
        //
        // 1) Check if current tile is to the right of the right edge
        //    of the this edge tile.  Remove the edge tile from the edgeTiles array
        //    by setting it "nil".  Keep looping with next edge tile.
        //
        // 2) Otherwise, can we slip this tile in above the current edge tile,
        //    if so break out of this edge testing loop and get the next tile.
        //
        // 3) If not, set this tile's top to just below the current edge tile
        //    and keep checking along any remaining edge tiles.
        //
        
        if (aTileLeft >= edgeTileRight) {
          edgeTiles[i] = nil
        } else {
          if (aTileBottom <= edgeTileTop) {
            break
          } else {
            aTile.origin.y = edgeTileBottom
          }
        }
      }
        
      // When we reach here, we have determined the place for the tile along the
      //  growing right edge. Add this tile to the edge in a two step process.

      // 1) Remove any "nil" tiles from 'edgeTiles', these are now to the left
      //    of the growing right edge. NB: There may be nothing to remove here.

      edgeTiles = edgeTiles.filter { $0 != nil }

      // 2) Place the current tile, 'aTile', along the right edge by adding it to the
      //    'edgeTiles' array.  Determine where to insert it by ...

      var index = 0
      for i in 0..<edgeTiles.count {
        guard let edgeTile = edgeTiles[i] else { continue }
        if (edgeTile.origin.y >= aTile.origin.y) {
         break
        }
        index = i + 1
      }
      
      edgeTiles.insert(aTile, at: index)
      
      // Update the position of the current tile using the temporary 'aTile' which
      //   has been added to right edge
      
      tile.origin.y = aTile.origin.y
        
      // Was this tile placed at the bottom of the growing edge?  If so, adjust the height
      //  of the mosaic.

      let currentThickness = tile.origin.y + aTile.size.height
      let currentWidth = (tile.origin.x + tile.size.width) - leftEdge

      height = (currentThickness > height) ? currentThickness : height
      width = (currentWidth > width) ? currentWidth : width
    }
    
    return CGSize(width: width + hGap, height: height + vGap)
  }
  
}
