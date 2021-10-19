//
//  GIVPanel.swift
//  SA-GIV
//
//  Created by Will Gilbert on 10/2/21.
//

import SwiftUI

struct GIVPanelView: View {

  let givPanel: GIVPanel
  let scale: CGFloat

  init(_ givPanel: GIVPanel, scale: CGFloat = 1.0) {
    self.givPanel = givPanel
    self.scale = scale
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      
      // Optional show a label for this GIV Panel
      if let label = givPanel.label {
        Text(label)
          .padding(3)
          .font(.system(size: givPanel.labelFontSize, weight: .semibold))
      }
      ForEach(givPanel.mapPanels, id: \.id) { mapPanel in
        MapPanelView(mapPanel, scale: scale)
      }
    }.frame(width: givPanel.stopExtent, height: givPanel.size.height)
      .background(givPanel.color)
    }
}



