//
//  MainView.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/8/21.
//

import SwiftUI

struct MainView: View {

  @EnvironmentObject var windowState: WindowState
  @EnvironmentObject var sequenceState: SequenceState

  var body: some View {
    
    var navigationTitle = "Sequence Analysis"
    if windowState.currentSequenceState != nil {
      navigationTitle = sequenceState.sequence.shortDescription
    }
    
    return VSplitView {
      if windowState.currentSequenceState != nil {
        if (windowState.editorIsVisible) {
          SequenceEditor()
            .frame(minHeight: 250)
        }
        AnalysisView(selectedAnalysis: sequenceState.defaultAnalysis)
          .padding()
      } else {
        EmptyView()
      }
    }
    .navigationTitle(navigationTitle)
  }
}

