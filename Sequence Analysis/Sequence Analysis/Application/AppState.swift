//
//  AppState.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/8/21.
//

import SwiftUI

class AppState: NSObject, ObservableObject {
 
  @Published var sequenceStates = Array<SequenceState>()
  @Published var newSequenceState: SequenceState?
   
  @Published var showOnly: [SequenceType] = [
    SequenceType.DNA,
    SequenceType.RNA,
    SequenceType.PROTEIN,
    SequenceType.PEPTIDE,
    SequenceType.UNDEFINED
  ]
      
  var hasSequences: Bool {
    get {
      return sequenceStates.count > 0
    }
  }
  
  func addSequence(_ sequence: Sequence) -> SequenceState {
    let sequenceState = SequenceState(sequence)
    
    // Set default analysis
    sequenceState.defaultAnalysis =  (sequence.isNucleic) ? .ORF : .STRUCTURE
    self.sequenceStates.append(sequenceState)
    self.newSequenceState = sequenceState
    return sequenceState
  }
  
  func removeSequeneState(_ sequenceState: SequenceState) {
    if let index = sequenceStates.firstIndex(of: sequenceState) {
      self.sequenceStates.remove(at: index)
    }
  }
  
  func removeAllSequences() {
    sequenceStates.removeAll()
    // TODO - update each window to remove the current editor and analysis panels
  }
  
}

