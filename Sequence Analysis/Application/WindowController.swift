//
//  WindowController.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 10/10/21.
//

import SwiftUI

final class WindowController: NSWindowController, NSWindowDelegate {

  init(window: NSWindow, contents: AnyView) {

    window.isReleasedWhenClosed = true

    let hosting = NSHostingView(rootView: contents)
    window.contentView = hosting

    super.init(window: window)
    window.delegate = self
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func windowWillClose(_ notification: Notification) {
      NSApp.stopModal()
  }
}


