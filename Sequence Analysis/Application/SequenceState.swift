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
  @Published var selection: NSRange?
  @Published var selectedORFGlyph: Glyph?
  @Published var selectedPatternGlyph: Glyph?
  @Published var fileFormat: FileFormat = FileFormat.FASTA
  
  var orfViewModel = ORFViewModel()
  var patternViewModel = PatternViewModel()

  var defaultAnalysis: AnalysisView.Analyses

  init(_ sequence: Sequence) {
    self.sequence = sequence
    defaultAnalysis = sequence.isNucleic ? .ORF : .COMPOSITION
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

