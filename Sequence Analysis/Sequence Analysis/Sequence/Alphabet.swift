//
//  Alphabet.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/16/21.
//

//
//  SequenceType.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/13/21.
//

import Foundation

enum Alphabet: String, CaseIterable, Identifiable {
  case DNA = "ATCGN"
  case RNA = "AUCGN"
  case PROTEIN = "ACDEFGHIKLMNPQRSTVWY"
  
  var id: Alphabet { self }
  
}

//private static let IUPAC: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ-";
//private static let IUPAC_PROTEIN: String = "ACDEFGHIKLMNPQRSTVWY";
//private static let IUPAC_PROTEIN_DEGENERATE = "ACDEFGHIKLMNPQRSTVWY-BZX";
//private static let IUPAC_DNA: String = "ATCGN";
//private static let IUPAC_DNA_DEGENERATE: String = "ATCG-RYBDHVKMSWN";
//private static let IUPAC_RNA: String = "AUCGN";
//private static let IUPAC_RNA_DEGENERATE = "AUCG-RYWSKMBDHVN";
