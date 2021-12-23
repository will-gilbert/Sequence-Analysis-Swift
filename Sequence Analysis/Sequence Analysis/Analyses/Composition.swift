//
//  Composition.swift
//  SequenceEditor (macOS)
//
//  Created by Will Gilbert on 9/14/21.
//

import SwiftUI

struct CompositionView: View {
  
  var sequenceState: SequenceState
  @ObservedObject var sequenceSelectionState: SequenceSelectionState

  @State var text: String = ""
  
  init(sequenceState: SequenceState) {
    self.sequenceState = sequenceState
    
    // Observe any changes in the sequence selection; Recalculate
    sequenceSelectionState = sequenceState.sequenceSelectionState
  }
    
  var body: some View {
    
    // Pass in a state variable, it will be displayed when 'Composition' is finished
    DispatchQueue.main.async {
      text.removeAll()
      
      var sequence = sequenceState.sequence
      
      if let selection = sequenceSelectionState.selection, selection.length > 0 {
          // Create a temporary sequence from the selection
          let start = selection.location
          let length = selection.length
          let title = sequence.title + " (\(start)-\(start + length - 1))"
          let strand = sequence.string.substring(from: start - 1 , length: length)
          
          sequence = Sequence(strand, uid: sequence.uid, title: title, type: sequence.type)
      }
      
      let _ = Composition(sequence, text: $text)
    }
    
    return TextView(text: $text, isEditable: false)
  }
  
}


// C O M P O S I T I O N  ===================================================================================

struct Composition {
  
  var sequence: Sequence
  @Binding var buffer: String
  
  init(_ sequence: Sequence, text: Binding<String>) {
    self.sequence = sequence
    self._buffer = text
    doComposition()
  }
    
    
  mutating func doComposition() {
    
    guard sequence.string.count > 0 else {
      buffer.append("This sequence has no content")
      return
    }
    
    buffer.append(sequence.description)
    buffer.append("\n\n")
  
    if(sequence.isNucleic) {
      doNucleic(Array(sequence.string.uppercased()))
    } else {
      doProtein(Array(sequence.string.uppercased()))
    }
  }
  
  mutating func doNucleic(_ strand: [Character]) {
 
    let hasN: Bool = sequence.string.contains("N")

    if hasN {
        buffer.append(
            "   NB - These values may not be correct as the sequence contains\n        bases designated as N.\n\n")
    }

    let molwt: Double = sequence.molwt
    let revComp = Sequence.reverseComp(String(sequence.string))
    let reverseMolWt: Double = Sequence.molWt(revComp, type: sequence.type)
    
    buffer.append(" Molecular weight,ss: \(F.f(molwt,decimal: 1).trimmingCharacters(in: .whitespaces)) Daltons")
    buffer.append("\n")
    
    buffer.append(" Molecular weight,ds: \(F.f(molwt + reverseMolWt, decimal: 1).trimmingCharacters(in: .whitespaces)) Daltons")
    buffer.append("\n")
    
    buffer.append("           Simple Tm: ")

    if let tm = sequence.simpleTm {
      buffer.append("\(F.f(tm).trimmingCharacters(in: .whitespaces))°C")
    } else {
      buffer.append("----")
    }
    buffer.append("\n")
    buffer.append("\n")
    buffer.append(String(repeating: "-", count: hasN ? 76 : 61))
    buffer.append("\n\n")

 
    // m - Mononucleotide composition
    var m: [Int] =  Array(repeating: 0, count: 6)
    
    for aa in strand {
      m[Self.nuc2num(aa)] += 1
    }

    let uT = sequence.isDNA ? "T" : "U"
    
    buffer.append("       A: ")
    buffer.append(F.f(m[0], width: 10, flags: F.flag.LJ));
    buffer.append("  C: ")
    buffer.append(F.f(m[1], width: 10, flags: F.flag.LJ));
    buffer.append("  G: ")
    buffer.append(F.f(m[2], width: 10, flags: F.flag.LJ));
    buffer.append("  \(uT): ")
    buffer.append(F.f(m[3], width: 10, flags: F.flag.LJ));
    
    if m[4] > 0 {
      buffer.append("  N: ")
      buffer.append(F.f(m[4], width: 10, flags: F.flag.LJ));
    }
    buffer.append("\n\n")
    
    if m[5] > 0 {
      buffer.append(F.f("  N: ", width: hasN ? 42 : 32))
      buffer.append(F.f(m[5], width: 10, flags: F.flag.LJ))
      buffer.append("\n\n")

    }


    // Single Base composition
    let length = strand.count
    var percent: Double = length > 0 ? Double(m[0] * 100) / Double(length) : 0.0;
      buffer.append("       A: ")
    buffer.append(F.f(F.f(percent, decimal: 1) + "%", width: 10, flags: F.flag.LJ))

    percent = length > 0 ? Double(m[1] * 100) / Double(length) : 0.0
    buffer.append("  C: ")
    buffer.append(F.f(F.f(percent, decimal: 1, flags: F.flag.LJ) + "%", width: 10, flags: F.flag.LJ))

    percent = length > 0 ? Double( m[2] * 100) / Double(length) : 0.0
    buffer.append("  G: ")
    buffer.append(F.f(F.f(percent, decimal: 1, flags: F.flag.LJ) + "%", width: 10, flags: F.flag.LJ))

    percent = length > 0 ? Double( m[3] * 100) / Double(length) : 0.0
    buffer.append("  \(uT): ")
    buffer.append(F.f(F.f(percent,  decimal: 1, flags: F.flag.LJ) + "%", width: 10, flags: F.flag.LJ))

    if m[4] > 0 {
      percent = length > 0 ? Double( m[4] * 100) / Double(length) : 0.0
      buffer.append("  N: ")
      buffer.append(F.f(F.f(percent,  decimal: 1, flags: F.flag.LJ) + "%", width: 10, flags: F.flag.LJ))
    }
    buffer.append("\n\n")

    // A+T and C+G composition

    percent = length > 0 ? Double((m[0] + m[3]) * 100) / Double(length) : 0.0
    buffer.append(F.f("A+" + uT + ": ", width: (hasN ? 38 : 28)))
    buffer.append(F.f(m[0] + m[3], width: 5, flags: F.flag.LJ));
    buffer.append(F.f(F.f(percent, decimal: 1) + "%", width: 6, flags: F.flag.LJ))
    buffer.append("\n");

    percent = length > 0 ? Double((m[1] + m[2]) * 100) / Double(length) : 0.0
    buffer.append(F.f("C+G: ", width: (hasN ? 38 : 28)))
    buffer.append(F.f(m[1] + m[2], width: 5, flags: F.flag.LJ));
    buffer.append(F.f(F.f(percent, decimal: 1) + "%", width: 6, flags: F.flag.LJ))
    buffer.append("\n");
    
    // d - Dinucleotide composition ////////////////////////////
    var d: [Int] =  Array(repeating: 0, count: 37)
    
    if strand.count > 1 {
      for i in 0..<strand.count - 1 {
        d[
          Self.nuc2num(strand[i + 1]) * 6 +
            Self.nuc2num(strand[i])
        ] += 1
      }
    }
    
    func dinucleotide(_ dd: String) -> Void {
      
      if dd.contains("N") && (hasN == false) { return }

      let di = dd.replacingOccurrences(of: "T", with: uT)
      let strand = Array(di)
      let index = Self.nuc2num(strand[1]) * 6 +
                  Self.nuc2num(strand[0])
      
      buffer.append(F.f("\(di): ", width: (index % 6 == 0 ) ? 10 : di.count))
      buffer.append((index % 6 != 0 ) ? " " : "")
      buffer.append(F.f(d[index], width: 10, flags: F.flag.LJ))
    }

    buffer.append("\n\n")
    buffer.append(F.f("*****", width: (hasN ? 82 : 62), flags: F.flag.CJ))
    buffer.append("\n\n");

    // *A --------
    
    for b2 in "ACGTN" {
      for b1 in "ACGTN" {
        dinucleotide("\(b1)\(b2)")
      }
      buffer.append("\n");
    }

    // t - Trinucleotide composition ////////////////////////////
    
    // Build the trinucleotide array
    var t: [Int] =  Array(repeating: 0, count: 217)

    if strand.count > 2 {
      for i in 0..<strand.count - 2 {
        t[
          Self.nuc2num(strand[i + 2]) * 36 +
          Self.nuc2num(strand[i + 1]) * 6 +
          Self.nuc2num(strand[i])
        ] += 1
      }
    }

    // Display the trinucleotides in a table
    
    func trinucleotide(_ tt: String) -> Void {
      
      if tt.contains("N") && (hasN == false) { return }
            
      let ti = tt.replacingOccurrences(of: "T", with: uT)
      let strand = Array(ti)
      let index = Self.nuc2num(strand[2]) * 36 +
      Self.nuc2num(strand[1]) * 6 +
      Self.nuc2num(strand[0])
      
      var pad = ti.count
      switch (index) {
      case let index where index % 36 == 0: pad = 10         // Begins with "A"
      case let index where (index -  1) % 36 == 0: pad = 10  // Begins with "C"
      case let index where (index - 2) % 36 == 0: pad = 10   // Begins with "G"
      case let index where (index - 3) % 36 == 0: pad = 10   // Begins with "T"
      case let index where (index - 4) % 36 == 0: pad = 10   // Begins with "N"
      default: break
      }
      
      buffer.append(F.f("\(ti): ", width: pad))
      buffer.append(F.f(t[index], width: (pad == 10 ? 9 : 10), flags: F.flag.LJ))
    }

    buffer.append("\n")
    buffer.append(F.f("*****", width: (hasN ? 82 : 62), flags: F.flag.CJ))
    buffer.append("\n\n");
    
    
    for b1 in "ACGTN" {
      for b2 in "ACGTN" {
        for b3 in "ACGTN" {
          trinucleotide("\(b1)\(b3)\(b2)")
        }
        buffer.append("\n");
      }
      buffer.append("\n");
    }
  }
  
  // Base 6 encoded nucleotides /////////////////////////////////
  
  static func nuc2num(_ nuc: Character) -> Int {
    switch nuc {
      case "A": return 0;
      case "C": return 1;
      case "G": return 2;
      case "T", "U": return 3;
      case "N": return 4;
      default: return 5
    }
  }
  
  static func aa2num(_ aa: Character) -> Int {
    switch aa {
      case "A": return 0
      case "C": return 1
      case "D": return 2
      case "E": return 3
      case "F": return 4
      case "G": return 5
      case "H": return 6
      case "I": return 7
      case "K": return 8
      case "L": return 9
      case "M": return 10
      case "N": return 11
      case "P": return 12
      case "Q": return 13
      case "R": return 14
      case "S": return 15
      case "T": return 16
      case "V": return 17
      case "W": return 18
      case "Y": return 19
      case "B", "Z", "X": return 20;
      default: return 20
    }
  }

  
  mutating func doProtein(_ strand: [Character]) {
    
    // Create dictionary of amino acide usage
    var a = [ "A":0, "C":0, "D":0, "E":0, "F":0, "G":0, "H":0, "I":0, "K":0, "L":0,
              "M":0, "N":0, "P":0, "Q":0, "R":0, "S":0, "T":0, "V":0, "W":0, "Y":0]
    
    for aa in strand {
      let key = String(aa)
      if let current = a[key] {
        a.updateValue(current + 1, forKey: key)
      }
    }

    let molwt = sequence.molwt
    var aM: Int = a["W"]! * 5690
    aM += a["Y"]! * 1280
    aM += a["C"]! * 120
    
    buffer.append("    Molecular weight: \(F.f(molwt, decimal: 1)) Daltons\n")
    buffer.append("Ext. Coeff. at 280nm: ")
    buffer.append(String(aM))
    buffer.append("\n")
    
    buffer.append("            1 A(280): ")

    if (aM != 0) {
      buffer.append(F.f(Double(molwt)/Double(aM), decimal: 3))
    } else {
        buffer.append("---")
    }
    buffer.append("\n")
    
    buffer.append(" Amino Acid Composition\n")
    buffer.append(" ----------------------\n")
    buffer.append("\n")

    
    buffer.append("     A (Ala): \(F.f(a["A"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("  I (Ile): \(F.f(a["I"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("  R (Arg): \(F.f(a["R"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("\n")

    buffer.append("     C (Cys): \(F.f(a["C"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("  K (Lys): \(F.f(a["K"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("  S (Ser): \(F.f(a["S"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("\n")

    buffer.append("     D (Asp): \(F.f(a["D"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("  L (Leu): \(F.f(a["L"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("  T (Thr): \(F.f(a["T"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("\n")

    buffer.append("     E (Glu): \(F.f(a["E"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("  M (Met): \(F.f(a["M"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("  V (Val): \(F.f(a["V"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("\n")

    buffer.append("     F (Phe): \(F.f(a["F"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("  N (Asn): \(F.f(a["N"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("  W (Trp): \(F.f(a["W"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("\n")

    buffer.append("     G (Gly): \(F.f(a["G"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("  P (Pro): \(F.f(a["P"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("  Y (Tyr): \(F.f(a["Y"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("\n")

    buffer.append("     H (His): \(F.f(a["H"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("  Q (Gln): \(F.f(a["Q"]!, width: 10, flags: F.flag.LJ))")
    buffer.append("\n")
    buffer.append("\n")
    
    
    let basic: Int = a["K"]! + a["R"]!
    let acidic = a["D"]! + a["E"]!
    let hydrophobic = a["A"]! + a["I"]! + a["L"]! + a["F"]! + a["W"]! + a["V"]!
    let polar = a["N"]! + a["C"]! + a["Q"]! + a["S"]! + a["T"]! + a["Y"]!

    let length = strand.count
    var percent: Double = length > 0 ? Double(basic * 100) / Double(length) : 0.0
    buffer.append(F.f(basic, width: 8))
    buffer.append("  ")
    buffer.append(F.f(percent, decimal: 1))
    buffer.append("%")
    buffer.append(" Basic(+) amino acids, (K,R)\n")

    percent = length > 0 ? Double(acidic * 100) / Double(length) : 0.0
    buffer.append(F.f(acidic, width: 8))
    buffer.append("  ")
    buffer.append(F.f(percent, decimal: 1))
    buffer.append("%")
    buffer.append(" Acidic(-) amino acids, (D,E)\n")

    percent = length > 0 ? Double(hydrophobic * 100) / Double(length) : 0.0
    buffer.append(F.f(hydrophobic, width: 8))
    buffer.append("  ")
    buffer.append(F.f(percent,  decimal: 1))
    buffer.append("%")
    buffer.append(" Hydrophobic amino acids, (A,I,L,F,W,V)\n")

    percent = length > 0 ? Double(polar * 100) / Double(length) : 0.0
    buffer.append(F.f(polar, width: 8))
    buffer.append("  ")
    buffer.append(F.f(percent, decimal: 1))
    buffer.append("%")
    buffer.append(" Hydrophilic amino acids, (N,C,Q,S,T,Y)\n")
  }
}
