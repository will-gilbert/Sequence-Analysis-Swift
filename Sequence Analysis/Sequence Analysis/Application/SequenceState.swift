//
//  ORFViewModel.swift
//  Sequence Analysis (iOS)
//
//  Created by Will Gilbert on 10/6/21.
//

import SwiftUI

class SequenceState: ObservableObject {
  let id = UUID()
  
  @Published var sequence: Sequence
  @Published var changed: Bool = false // TODO: This hack is used to force a refresh of the sequence editor, hmmmmm
  @Published var fileFormat: FileFormat = FileFormat.FASTA
  
  @Published var selectedORFGlyph: Glyph?
  @Published var selectedPatternGlyph: Glyph?
  @Published var selectedFeatureGlyph: Glyph?
  
  var sequenceSelectionState = SequenceSelectionState()

  var orfViewModel = ORFViewModel()
  var featuresViewModel = FeaturesViewModel()
  var patternViewModel: PatternViewModel
  var givViewModel = GIVViewModel()

  var defaultAnalysis: AnalysisView.Analyses

  // This needs to be here instead of within the sequence editor so that selections
  //   are changed in all windows for this sequence
  //
  // Could not 'Publish" this selection as it created an infinite
  //   loop with the 'SequenceEditorView'. Used 'sequenceSelectionState'
  //   instead as an 'ObservableObject' for the analyses
  var editorSelection: NSRange? = NSRange(location:0, length:0)
  
  init(_ sequence: Sequence) {
    self.sequence = sequence
    defaultAnalysis = sequence.isNucleic ? .ORF : .COMPOSITION
    patternViewModel = PatternViewModel(sequence: sequence)
  }
}

// MARK: - Extension: Equatable & Hashable

extension SequenceState: Equatable, Hashable {
      
  func hash(into hasher: inout Hasher) {
      hasher.combine(id)
  }

  static func ==(lhs: SequenceState, rhs: SequenceState) -> Bool {
      return lhs.id == rhs.id
  }

}

class SequenceSelectionState: ObservableObject {
  @Published var selection: NSRange? = nil
}
