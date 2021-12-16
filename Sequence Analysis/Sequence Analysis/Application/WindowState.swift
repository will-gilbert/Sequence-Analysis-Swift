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
  var selectedGlyph: Glyph? = nil
  
  var selectedAnalysis: AnalysisView.Analyses = .COMPOSITION
  
  @State var window: NSWindow?
  
  func selectGlyph(_ glyph: Glyph) {

    // Update the GIV view reporter
    DispatchQueue.main.async {
      self.selectedGlyph = glyph
      guard self.selectedAnalysis != .GIV else { return }
      guard let sequenceState = self.currentSequenceState else { return }

      switch self.selectedAnalysis {
      case .ORF: sequenceState.selectedORFGlyph = glyph
      case .PATTERN: sequenceState.selectedPatternGlyph = glyph
      case .FEATURES: sequenceState.selectedFeatureGlyph = glyph
      default: break
      }
    }

    // Update the sequence editor selection
    DispatchQueue.main.async {
      guard let sequenceState = self.currentSequenceState else { return }
      sequenceState.selection = NSRange(location: glyph.element.start-1, length: glyph.element.stop - glyph.element.start + 1)
    }
  }
  
  func activateGlyph(_ glyph: Glyph) {

    DispatchQueue.main.async {
      self.selectedGlyph = glyph

      guard self.selectedAnalysis == .ORF else { return }
      guard let sequenceState = self.currentSequenceState else { return }
      
      let range = NSRange(location: glyph.element.start-1, length: glyph.element.stop - glyph.element.start + 1)
      
      let from = range.location
      let to  = range.location + range.length

      let orf = String(Array(sequenceState.sequence.string)[from...to])
      let protein = Sequence.nucToProtein(orf)

      let uid = Sequence.nextUID()
      let title = "Translate from '\(sequenceState.sequence.uid)', \(from + 1)-\(to)"
      
      let _ = AppSequences.shared().createSequence(protein, uid: uid, title : title, type: .PROTEIN)
    }
  }

  
}
