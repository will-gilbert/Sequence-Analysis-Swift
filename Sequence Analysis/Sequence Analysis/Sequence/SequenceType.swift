//
//  SequenceType.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/13/21.
//

import Foundation

enum SequenceType: String, CaseIterable, Identifiable {
  case UNDEFINED = "UNDEFINED"
  case PROTEIN = "PROTEIN"
  case PEPTIDE = "PEPTIDE"
  case DNA = "DNA"
  case RNA = "RNA"
  
  var id: SequenceType { self }
}
