//
//  WindowState.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/8/21.
//

import SwiftUI

class WindowState: ObservableObject {
  
  @EnvironmentObject var appState: AppState
  
  @Published var currentSequenceState: SequenceState? = nil
  @Published var editorIsVisible: Bool = false
  var selectedGlyph: Glyph? = nil
  
  var selectedAnalysis: AnalysisView.Analyses = .COMPOSITION
  
  
  @State var window: NSWindow?
  
  func selectGlyph(_ glyph: Glyph) {
    
    selectedGlyph = glyph

    DispatchQueue.main.async {
      
      guard self.selectedAnalysis != .GIV else { return }
      guard let sequenceState = self.currentSequenceState else { return }
      guard let glyph = self.selectedGlyph else { return }

      switch self.selectedAnalysis {
      case .ORF: sequenceState.selectedORFGlyph = glyph
      case .PATTERN: sequenceState.selectedPatternGlyph = glyph
      case .FEATURES: sequenceState.selectedFeatureGlyph = glyph
      default: break
      }

      sequenceState.selection = NSRange(location: glyph.element.start-1, length: glyph.element.stop - glyph.element.start + 1)
    }
  }
  
//  func activateGlyph(_ glyph: Glyph) {
//
//    selectedGlyph = glyph
//
//    DispatchQueue.main.async {
//
//      guard self.selectedAnalysis == .ORF else { return }
//      guard let sequenceState = self.currentSequenceState else { return }
//      guard let glyph = self.selectedGlyph else { return }
      
//      let range = NSRange(location: glyph.element.start-1, length: glyph.element.stop - glyph.element.start + 1)
      
//      let from = range.location
//      let to  = range.location + range.length
//
//      let orf = String(Array(sequenceState.sequence.string)[from...to])
//      let protein = Sequence.nucToProtein(orf)
//
//      let uid = Sequence.nextUID()
//      let title = "Translate from '\(sequenceState.sequence.uid)', \(from + 1)-\(to)"
//      let sequence = Sequence(protein, uid: uid, title: title, type: .PROTEIN)
//      sequence.alphabet = .PROTEIN

//      let newSequenceState = self.appState.addSequence(sequence)
//      self.currentSequenceState = newSequenceState
//    }
//  }

  
}
