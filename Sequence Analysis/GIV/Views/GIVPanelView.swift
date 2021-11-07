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
    
    let extent = givPanel.extent
    let height = givPanel.size.height
    let fontSize = givPanel.labelFontSize
    
    return VStack(alignment: .leading) {
      
      // Optional show a label for this GIV Panel
      if let label = givPanel.label {
        Text(label)
          .padding(.top, fontSize)
          .padding(.leading, 3)
          .font(.system(size: fontSize, weight: .semibold))
          .frame(width: 500, height: fontSize * 1.5, alignment: .leading)
      }

      
      ForEach(givPanel.mapPanels, id: \.id) { mapPanel in
        MapPanelView(mapPanel, scale: scale)
      }
      

    }
    .background(givPanel.color)
    .padding(.top, 5)
    .frame(width: extent * scale, height: height, alignment: .leading)
  }
}



