//
//  Sequence+Modifiers.swift
//  SequenceEditor
//
//  Created by Will Gilbert on 9/2/21.
//

import Foundation

extension Sequence {
  
  static func DNAtoRNA(_ sequence: String) -> String {
    let newSequence = sequence.replacingOccurrences(of: "T", with: "U")
    return newSequence.replacingOccurrences(of: "t", with: "u")
  }
  
  static func RNAtoDNA(_ sequence: String) -> String {
    let newSequence = sequence.replacingOccurrences(of: "U", with: "T")
    return newSequence.replacingOccurrences(of: "u", with: "t")
  }
  
  static func reverseComp(_ sequence: String, type: SequenceType = .DNA ) -> String {
    guard sequence.count > 0 else {
      return ""
    }
    
    guard type != .PROTEIN else { return sequence }
    
    let compBase:[Character:Character] = [
      "A":"T", "C":"G", "G":"C", "T":"A", "U":"A",
      "a":"t", "c":"g", "g":"c", "t":"a", "u":"a",
      "N":"N", "n":"n",  "-":"-"
    ]
    
    var strand = Array(sequence)
    let length = strand.count;
    var swap: Int

    for  i in 0...((length - 1)/2) {
      swap = length - i - 1;
      // Both characters are valid nucleotides
      if let temp = compBase[(strand[i])], compBase[(strand[swap])] != nil {
        strand[i] = compBase[(strand[swap])]!
        strand[swap] = temp
      } else {
        strand[swap] = strand[i]
      }
    }
    
    // Convert Character array to String; Convert to RNA in case of A -> T compement
    var newSequence = String(strand)
    if (type == .RNA) {
      newSequence = Self.DNAtoRNA(newSequence);
    }

    return newSequence;
  }

  static func guessType(_ string: String) -> SequenceType {

    let strand = Array(string.uppercased())
    let seqLength = strand.count

    if seqLength == 0 { return .DNA }
    
    var a:Int = 0
    var c:Int = 0
    var g:Int = 0
    var t:Int = 0
    var u:Int = 0
    var n:Int = 0
    
    for i in (0..<seqLength) {
      n += 1
      switch strand[i] {
      case "A": a += 1
      case "C": c += 1
      case "G": g += 1
      case "T": t += 1
      case "U": u += 1
      case "N", "-": n -= 1
      default: break
      }
    }
    
    // In rare cases, a sequence or selection my be all N's or gaps
    // leading to a divide by zero error.  We'll assume that its a
    // DNA sequence or selection
    
    if n == 0 {return .DNA}
        
    if (((a + c + g + t + u) * 100) / n) > 85 {
        return (t > u) ? .DNA : .RNA
    } else {
      return .PROTEIN
    }
    
  }
  
  static func checksum(_ sequence: String) -> Int {
    
    var count: Int = 0
    var cs: Int = 0

    let strand = Array(sequence)
    let seqLength = strand.count

    for i in (0..<seqLength) {
      
      if let asciiValue = strand[i].asciiValue {
        count += 1
        cs += count * Int(asciiValue)
      }

      if (count == 57) {
          count = 0;
      }
    }

    return (cs % 10000);
  }
  
  static func molWt(_ sequence: String, type: SequenceType = .PROTEIN) -> Double {
    guard sequence.count > 0 else { return 0.0}

    var mw: Double = 0.0
    
    var lookup: [String: Double]
    
    switch type {
      case .PROTEIN, .PEPTIDE:
        lookup = loadAAweights()
      case .DNA, .RNA:
        lookup = LoadNAweights()
    case .UNDEFINED:
        return 0.0
    }
    
    let strand = Array(sequence.uppercased())
    for i in 0..<strand.count {
      if let wt = lookup[String(strand[i])] {
        mw += wt
      }
    }
    
    switch type {
    case .PROTEIN, .PEPTIDE:
      mw -= Double((strand.count - 1)) * 18.015;  // Remove water for each peptide bond
    case .DNA, .RNA:
      mw += Double((strand.count - 1)) * 61.0;    // Add a phosphate group between bases
    case .UNDEFINED:
        return 0.0
    }
    
    // Molecular Weight Tables ===========================
    
    func loadAAweights() -> [String: Double] {
      return [
        "A":89.09,  "C":121.15, "D":133.10, "E":147.13, "F":165.19,
        "G":75.07,  "H":155.16, "I":131.17, "K":146.19, "L":131.17,
        "M":149.21, "N":132.12, "P":115.13, "Q":146.15, "R":174.20,
        "S":105.09, "T":119.12, "V":117.15, "W":204.23, "Y":181.19,
        "B":132.61, "Z":146.64
      ]
    }
    
    func LoadNAweights() -> [String: Double] {
      return[
        "A":251.2, "C":227.2, "G":267.2, "T":243.2, "U":251.2,
        "N":247.2  // Unknown base, use average of ACGT
      ]
    }
    
    // ===================================================

    return mw
  }
  
  // **  NucToProtein  ***********************************************************
  //
  // This method translates a nucleotide sequence into a protein sequence.
  //
  // The translation continues until a stop codon or the end of the nucleotide
  // strand occurs.
  //
  //
  // Translation Algorithm:
  // ---------------------
  // In order to generate an index into the GCodes arrays each base in
  // the codon is looked up in "NonAmbigBases", if it's not found the
  // Index is increased such that it will be beyond the valid range.  If the
  // base is either T,C,A,G or U then Index is incremented according to the
  // amount in "Indx" depending on the base position in the codon.
  //
  // For example, consider the codon, ATG
  //
  //              T  C  A  G  U
  //              -------------
  // First base   0 16 32 48  0         A give  32
  // Second base  0  4  8 12  0         T gives  0
  // Third base   1  2  3  4  1         G gives  4
  //                                            --
  //                                            36
  //
  // By looking at the 36th character in "GCodes" we obtain an "M".
  //
  // This algorithm is used by the NBRF-PIR program NAQ from which it was
  // translated to "C" from FORTRAN.
  //
  // RESTRICTION: Will not translate "RAY" to the ambiguous amino acid "B"
  // or the codon "SAR" to the ambiguous amino acid "Z"
  //
  //
  // William A. Gilbert, 2021
  //
  // ******************************************************************************

  
  static func nucToProtein(_ sequence: String, doStops: Bool = false, type: SequenceType = .DNA) -> String {

    guard type == .DNA || type == .RNA else { return "" }
    guard sequence.count >= 3 else { return "" }

    let strand = Array(sequence)
    let seqLength = strand.count

    var protein = ""

    var base = 0

      while (base <= (seqLength - 3)) {

        let codon = String(strand[base..<base+3])

        let aa = codonToAA(codon)
        
        if aa == "*" && doStops {
          break
        } else {
          protein.append(codonToAA(codon))
        }
        
        base += 3;
      }
      
    return protein
  }
  
  static func codonToAA(_ codon: String) -> String {
    guard codon.count == 3 else { return "" }
    
    let inCodon = Array(codon.uppercased())

    // Ambiguous nucleotide weights i.e. binary equivalents
    //
    // A B C  D E F G  H I J K L  M  N O P Q  R S T U  V W  X Y Z
    // 8,7,4,11,0,0,2,13,0,0,3,0,12,15,0,0,0,10,6,1,1,14,9,15,5,0

    // Nucleotide look-up table weights
    let indx = [
       //  A   C   G   T  U
        [ 32, 16, 48, 0, 0 ], // inCodon[0]
        [  8,  4, 12, 0, 0 ], // inCodon[1]
        [  3,  2,  4, 1, 1 ]  // inCodon[2]
    ];

    let nonAmbigBases: [Character] = Array("ACGTU")
    let gCodes: [Character] = Array(" FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG")
    var index: Int = 0

    for i in 0...2 {
      if let pos = nonAmbigBases.firstIndex(of: inCodon[i]) {
        index += indx[i][pos];
      } else {
        index += 65;// Amibiguous bases pushes index out of range
      }
    }

    //
    // If less than 64 read the translation from the table.
    // Otherwise, must apply IUPAC codes.  TODO
    //
    
    var aa: String
    if (index <= 64) {
      aa = String(gCodes[index])
    } else{
      aa = "?"
    }

    return aa
  }

  
  static func oneToThree(_ char: Character) -> String {

    // Three letter amino acid abbreviations from the IUPAC single letters
    //
    // "???" is undefined, "Unk" is unknown.
    
    let base = String(char).uppercased()
    let three = [
      "A":"Ala", "B":"Asx", "C":"Cys", "D":"Asp", "E":"Glu", "F":"Phe", "G":"Gly",
      "H":"His", "I":"Ile", "K":"Lys", "L":"Leu", "M":"Met", "N":"Asn", "P":"Pro",
      "Q":"Gln", "R":"Arg", "S":"Ser", "T":"Thr", "V":"Val", "W":"Trp", "Y": "Tyr",
      "Z":"Glx", "*":"***", "-":"---", ".":"---"
    ]
    
    if let aa = three[base] {
      return aa
    } else {
      return "???"
    }
  }
  
  static func gcPercent(_ sequence: String, type: SequenceType = .DNA) -> Double? {
    guard type == .DNA || type == .RNA else { return nil}
    guard sequence.count > 0 else { return nil }

    var c = 0, g = 0, total = 0
    
    sequence.uppercased().forEach { char in
      total += 1
      switch char {
        case "C": c += 1
        case "G": g += 1
        case "-", ".", "*": total -= 1 // Don't count gaps or stops
        default: break
      }
    }
      
    return (Double(c + g) / Double(total)) * 100.0
  }
  
  static func simpleTm(_ sequence: String, type: SequenceType = .DNA) -> Double? {
    guard type == .DNA  else { return nil}
    guard sequence.count > 8  else { return nil }
    
    var a = 0, c = 0, g = 0, t = 0, n = 0, total = 0;

    sequence.uppercased().forEach { char in
      total += 1
      switch char {
        case "A": a += 1
        case "C": c += 1
        case "G": g += 1
        case "T": t += 1
        case "N": n += 1
        case "-", ".", "*": total -= 1 // Don't count gaps or stops
        default: break
      }
    }
    
    var tm: Double? = (2.0 * Double(a + t)) + (4.0 * Double(c + g)) + (3.0 * Double(n))
    
    if tm! > 110.0 {
      tm = nil
    }
    
    return tm
  }

  static func simpleConc(_ sequence: String, type: SequenceType = .DNA) -> Double? {
    guard type == .DNA else { return nil}
    guard sequence.count >= 1 else {return nil}

    var a = 0.0, c = 0.0, g = 0.0, t = 0.0, n = 0.0

    sequence.uppercased().forEach { char in
      switch char {
        case "A": a += 1.0
        case "C": c += 1.0
        case "G": g += 1.0
        case "T": t += 1.0
        case "N": n += 1.0
        default: break
      }
    }


    let x = (15400.0 * a) + (7400.0 * c) + (11500.0 * g) + (8700.0 * t) + (10750.0 * n);
    let y = (312.0 * a) + (288.0 * c) + (328.0 * g) + (303.0 * t) + (307.75 * n) - 61.0

    return 1 / (x / (1000 * y))
  }
  
  
  static func complexConc(_ sequence: String, type: SequenceType = .DNA) -> Double? {
    guard type == .DNA else { return nil}
    guard sequence.count >= 2 else {return nil}

    let pec: [String:Int] = [
      "AA":13700, "AC":10600, "AG":12500, "AT":11400, "AN":12050,
      "CA":10600, "CC":7300,  "CG":9000,  "CT":7600,  "CN":8625,
      "GA":12600, "GC":8800,  "GG":10800, "GT":10000, "GN":10550,
      "TA":11700, "TC":8100,  "TG":9500,  "TT":8400,  "TN":9425,
      "NA":12150, "NC":8700,  "NG":10450, "NT":9350,  "NN":10162
    ]
    
    var a = 0.0, c = 0.0, g = 0.0, t = 0.0, n = 0.0
    var pairs = 0, singles = 0
    let strand = Array(sequence.uppercased())
    let size = strand.count

    for i in 0..<size {

      if (i < (size - 1)) {
        if let value = pec[String(strand[i..<(i + 2)])] {
          pairs += value
        }
      }
     
      if ((i > 0) && (i < (size - 1))) {
        switch strand[i] {
          case "A": singles += 15400
          case "C": singles += 7400
          case "G": singles += 11500
          case "T": singles += 8700
          case "N": singles += 10750
          default: break
        }
      }

      // Count eligable bases
      switch strand[i] {
        case "A": a += 1.0
        case "C": c += 1.0
        case "G": g += 1.0
        case "T": t += 1.0
        case "N": n += 1.0
        default: break
      }
    }

    let x = (2 * pairs) - singles
    let y = (312.0 * a) + (288.0 * c) + (328.0 * g) + (303.0 * t) + (307.75 * n) - 61.0

    return 1 / ( Double(x) / (1000 * y))
  }

  
}
