//
//  GIVPanel.swift
//  SA-GIV
//
//  Created by Will Gilbert on 10/5/21.
//

import SwiftUI

struct GIVPanel {

  let id = UUID()

  let extent: CGFloat
  let color: Color
  var label: String?
  var size: CGSize = CGSize(width: 0, height: 0)
  
  let labelFontSize: CGFloat = 12
  
  var mapPanels: Array<MapPanel> = []

  init(extent: Int, color: String = "AGA 01") {
    self.extent = CGFloat(extent)
    self.color = Colors.get(color: color).base
    self.label = nil
  }
  
  init(extent: Int, color: String = "AGA 01", label: String?) {
    self.extent = CGFloat(extent)
    self.color = Colors.get(color: color).base
    self.label = label
  }
  
  mutating func addMapPanel(_ mapPanel: MapPanel) -> Void {
    size.width = mapPanel.size.width
    size.height += mapPanel.size.height

    // Add some extra height for the label
    if let _ = label {
      size.height += (labelFontSize * 2) + 3
    }

    self.mapPanels.append(mapPanel)
  }
  
  mutating func addMapPanels(_ mapPanels: [MapPanel]) -> Void {
    mapPanels.forEach { mapPanel in
      addMapPanel(mapPanel)
    }
  }

}
