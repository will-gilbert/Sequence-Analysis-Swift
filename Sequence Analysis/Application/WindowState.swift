//
//  WindowState.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/8/21.
//

import SwiftUI

class WindowState: ObservableObject {
  @Published var currentSequenceState: SequenceState? = nil
  @Published var editorIsVisible: Bool = false
  var selectedAnalysis: AnalysisView.Analyses = .COMPOSITION

  @State var window: NSWindow?
}
