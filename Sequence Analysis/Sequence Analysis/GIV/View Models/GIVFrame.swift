//
//  GIVFrame.swift
//  SA-GIV
//
//  Created by Will Gilbert on 10/5/21.
//

import SwiftUI

struct GIVFrame {

  let extent: CGFloat
  let hasRuler: Bool
  let bkgColor: String
  let frgColor: String
  
  var size: CGSize = CGSize(width: 0, height: 0)
    
  var givPanels: Array<GIVPanel> = []
  var mapPanels: Array<MapPanel> = []

  init(extent: Int, hasRuler: Bool = true, bkgColor: String = "AGA 01", frgColor: String = "Black" ) {
    self.extent = CGFloat(extent)
    self.hasRuler = hasRuler
    self.bkgColor = bkgColor
    self.frgColor = frgColor
    if hasRuler {
      size.height = 35
    }
  }
 
  mutating func addGIVPanels(_ givPanels: [GIVPanel]) -> Void {
    givPanels.forEach { givPanel in
      addGIVPanel(givPanel)
    }
  }

  mutating func addGIVPanel(_ givPanel: GIVPanel) -> Void {
    size.width = givPanel.size.width
    size.height += givPanel.size.height
    self.givPanels.append(givPanel)
  }

  mutating func addMapPanels(_ mapPanels: [MapPanel]) -> Void {
    mapPanels.forEach { mapPanel in
      addMapPanel(mapPanel)
    }
  }

  mutating func addMapPanel(_ mapPanel: MapPanel) -> Void {
    size.width = mapPanel.size.width
    size.height += mapPanel.size.height
    self.mapPanels.append(mapPanel)
  }



}
