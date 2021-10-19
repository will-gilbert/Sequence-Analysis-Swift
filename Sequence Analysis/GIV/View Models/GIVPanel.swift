//
//  GIVPanel.swift
//  SA-GIV
//
//  Created by Will Gilbert on 10/5/21.
//

import SwiftUI

struct GIVPanel {

  let id = UUID()

  let startExtent: CGFloat = 0
  let stopExtent: CGFloat
  let color: Color
  var label: String?
  var size: CGSize = CGSize(width: 0, height: 0)
  
  let labelFontSize: CGFloat = 12
  
  var mapPanels: Array<MapPanel> = []

  init(extent: Int, color: String = "AGA 01") {
    self.stopExtent = CGFloat(extent)
    self.color = Colors.get(color: color).base
    self.label = nil
  }
  
  init(extent: Int, color: String = "AGA 01", label: String = "") {
    self.stopExtent = CGFloat(extent)
    self.color = Colors.get(color: color).base
    self.label = label
  }
  
  mutating func addMapPanel(_ mapPanel: MapPanel) -> Void {
    size.width = mapPanel.size.width
    size.height += mapPanel.size.height

    // Add some extra height for the label
    if let _ = label {
      size.height += labelFontSize * 1.5
    }

    self.mapPanels.append(mapPanel)
  }
  
  mutating func addMapPanels(_ mapPanels: [MapPanel]) -> Void {
    mapPanels.forEach { mapPanel in
      addMapPanel(mapPanel)
    }
  }

}
