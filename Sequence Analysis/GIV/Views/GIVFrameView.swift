//
//  GIVFrameView.swift
//  SA-GIV
//
//  Created by Will Gilbert on 10/5/21.
//

import SwiftUI

struct GIVFrameView: View {

  let givFrame: GIVFrame
  let scale: CGFloat

  init(_ givFrame: GIVFrame, scale: CGFloat = 1.0) {
    self.givFrame = givFrame
    self.scale = scale
  }

  public var body: some View {
    let extent = givFrame.extent
    let height = givFrame.size.height
    let frgColor = givFrame.frgColor
    let bkgColor = givFrame.bkgColor

    return VStack(alignment: .leading, spacing: 0) {
      
      if givFrame.hasRuler {
        GIVRulerView(extent: extent, scale: scale, frgColor: frgColor)
      }
      
      ForEach(givFrame.givPanels, id: \.id) { givPanel in
        GIVPanelView(givPanel, scale: scale)
      }
      
      ForEach(givFrame.mapPanels, id: \.id) { mapPanel in
        MapPanelView(mapPanel, scale: scale)
      }
      
    }
    .background(Colors.get(color: bkgColor).base)
    .frame(width: extent * scale, height: height, alignment: .topLeading)
  }
}

