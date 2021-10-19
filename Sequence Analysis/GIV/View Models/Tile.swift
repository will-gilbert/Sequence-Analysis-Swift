//
//  Tile.swift
//  SA-GIV
//
//  Created by Will Gilbert on 7/18/21.
//

import SwiftUI

class Tile {

  let id = UUID()

  // Location of the tile in the View
  // These will be modified by the TileLayout instance; Hence 'var' properties
  var origin: CGPoint = CGPoint.zero
  var size: CGSize = CGSize.zero
  
  init(origin: CGPoint, size: CGSize) {
    self.origin = origin
    self.size = size
  }
}

extension Tile: Equatable, Hashable {
  
  func hash(into hasher: inout Hasher) {
      hasher.combine(id)
  }

  static func ==(lhs: Tile, rhs: Tile) -> Bool {
      return lhs.id == rhs.id
  }
}

