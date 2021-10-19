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
    VStack(alignment: .leading, spacing: 0) {
      ForEach(givFrame.givPanels, id: \.id) { givPanel in
        GIVPanelView(givPanel, scale: scale)
      }
    }.frame(width: givFrame.extent, height: givFrame.size.height)
  }
}


