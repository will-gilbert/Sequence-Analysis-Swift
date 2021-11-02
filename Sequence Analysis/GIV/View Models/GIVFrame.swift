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
  var size: CGSize = CGSize(width: 0, height: 0)
    
  var givPanels: Array<GIVPanel> = []

  init(extent: Int, hasRuler: Bool = true) {
    self.extent = CGFloat(extent)
    self.hasRuler = hasRuler
  }
      
  mutating func addGIVPanel(_ givPanel: GIVPanel) -> Void {
    size.width = givPanel.size.width
    size.height += givPanel.size.height
    self.givPanels.append(givPanel)
  }

  mutating func addGIVPanels(_ givPanels: [GIVPanel]) -> Void {
    givPanels.forEach { givPanel in
      addGIVPanel(givPanel)
    }
  }

}
