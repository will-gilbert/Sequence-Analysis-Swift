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
        VStack {
          Text("Use the \(Image(systemName:"plus")) button to add a new or random sequence or")
          Text("use the \(Image(systemName:"network")) button to fetch an entry from the NCBI.")
          Text("")
          Text("Most buttons have a tooltip when you hover over them.")
        }
        .font(.body)
        .frame(width: 400)
      }
    }
    .navigationTitle(navigationTitle)
  }
}

