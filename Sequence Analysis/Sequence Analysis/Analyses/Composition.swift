//
//  Composition.swift
//  SequenceEditor (macOS)
//
//  Created by Will Gilbert on 9/14/21.
//

import SwiftUI

struct CompositionView: View {
  
  @ObservedObject var sequence: Sequence
  @State var text: String = ""
    
  var body: some View {
    
    // Pass in a\ state variable, it will be displayed when 'Composition' is finished
    DispatchQueue.main.async {
      text.removeAll()
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

    buffer.append("\n\n")
    buffer.append(F.f("*****", width: (hasN ? 82 : 62), flags: F.flag.CJ))
    buffer.append("\n\n");

    // *A --------
    buffer.append(F.f("AA: ", width: 10))
    buffer.append(F.f(d[0], width: 10, flags: F.flag.LJ))
    buffer.append(" CA: ")
    buffer.append(F.f(d[1], width: 10, flags: F.flag.LJ))
    buffer.append(" GA: ")
    buffer.append(F.f(d[2], width: 10, flags: F.flag.LJ))
    buffer.append(" \(uT)A: ")
    buffer.append(F.f(d[3], width: 10, flags: F.flag.LJ))

    if hasN {
      buffer.append(" NA: ")
      buffer.append(F.f(d[4], width: 10, flags: F.flag.LJ))
    }
    buffer.append("\n");

    // *C --------

    buffer.append(F.f("AC: ", width: 10))
    buffer.append(F.f(d[6], width: 10, flags: F.flag.LJ));
    buffer.append(" CC: ")
    buffer.append(F.f(d[7], width: 10, flags: F.flag.LJ));
    buffer.append(" GC: ")
    buffer.append(F.f(d[8], width: 10, flags: F.flag.LJ));
    buffer.append(" \(uT)C: ")
    buffer.append(F.f(d[9],  width: 10, flags: F.flag.LJ));

    if hasN {
        buffer.append(" NC: ")
    buffer.append(F.f(d[10], width: 10, flags: F.flag.LJ));
    }

    buffer.append("\n");

    // *G --------

    buffer.append(F.f("AG: ", width: 10))
    buffer.append(F.f(d[12], width: 10, flags: F.flag.LJ));
    buffer.append(" CG: ")
    buffer.append(F.f(d[13], width: 10, flags: F.flag.LJ));
    buffer.append(" GG: ")
    buffer.append(F.f(d[14], width: 10, flags: F.flag.LJ));
    buffer.append(" \(uT)G: ")
    buffer.append(F.f(d[15], width: 10, flags: F.flag.LJ));

    if hasN {
       buffer.append(" NG: ")
      buffer.append(F.f(d[16], width: 10, flags: F.flag.LJ))
    }

    buffer.append("\n")

    // *T/U --------

    buffer.append(F.f("A\(uT): ", width: 10))
    buffer.append(F.f(d[18], width: 10, flags: F.flag.LJ));
    buffer.append(" C\(uT): ")
    buffer.append(F.f(d[19], width: 10, flags: F.flag.LJ));
    buffer.append(" G\(uT): ")
    buffer.append(F.f(d[20], width: 10, flags: F.flag.LJ));
    buffer.append(" \(uT)\(uT): ")
    buffer.append(F.f(d[21], width: 10, flags: F.flag.LJ));

    if (hasN) {
        buffer.append(" NT: ")
    buffer.append(F.f(d[22], width: 10, flags: F.flag.LJ));
    }
    buffer.append("\n");

    // *N -------
    if hasN {
      buffer.append(F.f("AN: ", width: 10))
      buffer.append(F.f(d[24], width: 10, flags: F.flag.LJ));
      buffer.append(" CN: ")
      buffer.append(F.f(d[25], width: 10, flags: F.flag.LJ));
      buffer.append(" GN: ")
      buffer.append(F.f(d[26], width: 10, flags: F.flag.LJ));
      buffer.append(" \(uT)N: ")
      buffer.append(F.f(d[27], width: 10, flags: F.flag.LJ));
      buffer.append(" NN: ")
      buffer.append(F.f(d[28], width: 10, flags: F.flag.LJ));
      buffer.append("\n");
    }
    buffer.append("\n");

    // t - Trinucleotide composition ////////////////////////////
    var t: [Int] =  Array(repeating: 0, count: 217)

    if strand.count > 2 {
      for i in 0..<strand.count - 2 {
        t[
          Self.nuc2num(strand[i]) * 36 +
          Self.nuc2num(strand[i + 1]) * 6 +
          Self.nuc2num(strand[i + 2])
        ] += 1
      }
    }

    buffer.append("\n\n")
    buffer.append(F.f("*****", width: (hasN ? 82 : 62), flags: F.flag.CJ))
    buffer.append("\n\n");

    buffer.append("     AAA: ")
    buffer.append(F.f(t[0], width: 10, flags: F.flag.LJ));
    buffer.append("ACA: ")
    buffer.append(F.f(t[6], width: 10, flags: F.flag.LJ));
    buffer.append("AGA: ")
    buffer.append(F.f(t[12], width: 10, flags: F.flag.LJ));
    buffer.append("A\(uT)A: ")
    buffer.append(F.f(t[18], width: 10, flags: F.flag.LJ));

    if (hasN) {
        buffer.append("ANA: ")
          buffer.append(F.f(t[24], width: 10, flags: F.flag.LJ))
    }
    buffer.append("\n");

    buffer.append("     AAC: ")
    buffer.append(F.f(t[1], width: 10, flags: F.flag.LJ));
    buffer.append("ACC: ")
    buffer.append(F.f(t[7], width: 10, flags: F.flag.LJ));
    buffer.append("AGC: ")
    buffer.append(F.f(t[13], width: 10, flags: F.flag.LJ));
    buffer.append("A\(uT)C: ")
    buffer.append(F.f(t[19], width: 10, flags: F.flag.LJ));

    if hasN {
        buffer.append("ANC: ")
    buffer.append(F.f(t[25], width: 10, flags: F.flag.LJ));
    }

    buffer.append("\n");

    buffer.append("     AAG: ")
    buffer.append(F.f(t[2], width: 10, flags: F.flag.LJ));
    buffer.append("ACG: ")
    buffer.append(F.f(t[8], width: 10, flags: F.flag.LJ));
    buffer.append("AGG: ")
    buffer.append(F.f(t[14], width: 10, flags: F.flag.LJ));
    buffer.append("A\(uT)G: ")
    buffer.append(F.f(t[20], width: 10, flags: F.flag.LJ));

    if hasN {
      buffer.append("ANG: ")
      buffer.append(F.f(t[26], width: 10, flags: F.flag.LJ))
    }

    buffer.append("\n");

    buffer.append("     AA\(uT): ")
    buffer.append(F.f(t[3], width: 10, flags: F.flag.LJ));
    buffer.append("AC\(uT): ")
    buffer.append(F.f(t[9], width: 10, flags: F.flag.LJ));
    buffer.append("AG\(uT): ")
    buffer.append(F.f(t[15], width: 10, flags: F.flag.LJ));
    buffer.append("A\(uT)\(uT): ")
    buffer.append(F.f(t[21], width: 10, flags: F.flag.LJ));

    if hasN {
      buffer.append("AN\(uT): ")
      buffer.append(F.f(t[27], width: 10, flags: F.flag.LJ))
    }
    buffer.append("\n");

    if hasN {
      buffer.append("     AAN: ")
      buffer.append(F.f(t[4], width: 10, flags: F.flag.LJ));
      buffer.append("ACN: ")
      buffer.append(F.f(t[10], width: 10, flags: F.flag.LJ));
      buffer.append("AGN: ")
      buffer.append(F.f(t[16], width: 10, flags: F.flag.LJ));
      buffer.append("A\(uT)N: ")
      buffer.append(F.f(t[22], width: 10, flags: F.flag.LJ));
      buffer.append("ANN: ")
      buffer.append(F.f(t[28], width: 10, flags: F.flag.LJ))
      buffer.append("\n");
    }
    
    buffer.append("\n");
    buffer.append("     CAA: ")
    buffer.append(F.f(t[36], width: 10, flags: F.flag.LJ));
    buffer.append("CCA: ")
    buffer.append(F.f(t[42], width: 10, flags: F.flag.LJ));
    buffer.append("CGA: ")
    buffer.append(F.f(t[48], width: 10, flags: F.flag.LJ));
    buffer.append("C\(uT)A: ")
    buffer.append(F.f(t[54], width: 10, flags: F.flag.LJ));

    if hasN {
      buffer.append("CNA: ")
      buffer.append(F.f(t[60], width: 10, flags: F.flag.LJ));
    }
    buffer.append("\n");

    buffer.append("     CAC: ")
    buffer.append(F.f(t[37], width: 10, flags: F.flag.LJ));
    buffer.append("CCC: ")
    buffer.append(F.f(t[43], width: 10, flags: F.flag.LJ));
    buffer.append("CGC: ")
    buffer.append(F.f(t[49], width: 10, flags: F.flag.LJ));
    buffer.append("C\(uT)C: ")
    buffer.append(F.f(t[55], width: 10, flags: F.flag.LJ));

    if hasN {
      buffer.append("CNC: ")
      buffer.append(F.f(t[61], width: 10, flags: F.flag.LJ))
    }
    buffer.append("\n");

    buffer.append("     CAG: ")
    buffer.append(F.f(t[38], width: 10, flags: F.flag.LJ));
    buffer.append("CCG: ")
    buffer.append(F.f(t[44], width: 10, flags: F.flag.LJ));
    buffer.append("CGG: ")
    buffer.append(F.f(t[50], width: 10, flags: F.flag.LJ));
    buffer.append("C\(uT)G: ")
    buffer.append(F.f(t[56], width: 10, flags: F.flag.LJ));

    if hasN {
      buffer.append("CNG: ")
      buffer.append(F.f(t[62], width: 10, flags: F.flag.LJ));
    }
    buffer.append("\n");

    buffer.append("     CA\(uT): ")
    buffer.append(F.f(t[39], width: 10, flags: F.flag.LJ));
    buffer.append("CC\(uT): ")
    buffer.append(F.f(t[45], width: 10, flags: F.flag.LJ));
    buffer.append("CG\(uT): ")
    buffer.append(F.f(t[51], width: 10, flags: F.flag.LJ));
    buffer.append("C\(uT)\(uT): ")
    buffer.append(F.f(t[57], width: 10, flags: F.flag.LJ));

    if hasN {
      buffer.append("CN\(uT): ")
      buffer.append(F.f(t[63], width: 10, flags: F.flag.LJ));
    }
    buffer.append("\n");

    if hasN {
      buffer.append("     CAN: ")
      buffer.append(F.f(t[40], width: 10, flags: F.flag.LJ));
      buffer.append("CCN: ")
      buffer.append(F.f(t[46], width: 10, flags: F.flag.LJ));
      buffer.append("CGN: ")
      buffer.append(F.f(t[58], width: 10, flags: F.flag.LJ));
      buffer.append("C\(uT)N: ")
      buffer.append(F.f(t[58], width: 10, flags: F.flag.LJ));
      buffer.append("CNN: ")
      buffer.append(F.f(t[64], width: 10, flags: F.flag.LJ));
      buffer.append("\n");
    }

    buffer.append("\n");

    buffer.append("     GAA: ")
    buffer.append(F.f(t[72], width: 10, flags: F.flag.LJ));
    buffer.append("GCA: ")
    buffer.append(F.f(t[78], width: 10, flags: F.flag.LJ));
    buffer.append("GGA: ")
    buffer.append(F.f(t[84], width: 10, flags: F.flag.LJ));
    buffer.append("GTA: ")
    buffer.append(F.f(t[90], width: 10, flags: F.flag.LJ));

    if hasN {
      buffer.append("GNA: ")
      buffer.append(F.f(t[96], width: 10, flags: F.flag.LJ));
    }

    buffer.append("\n");

    buffer.append("     GAC: ")
    buffer.append(F.f(t[73], width: 10, flags: F.flag.LJ));
    buffer.append("GCC: ")
    buffer.append(F.f(t[79], width: 10, flags: F.flag.LJ));
    buffer.append("GGC: ")
    buffer.append(F.f(t[85], width: 10, flags: F.flag.LJ));
    buffer.append("G\(uT)C: ")
    buffer.append(F.f(t[91], width: 10, flags: F.flag.LJ));

    if hasN {
      buffer.append("GNC: ")
      buffer.append(F.f(t[97], width: 10, flags: F.flag.LJ));
    }

    buffer.append("\n");

    buffer.append("     GAG: ")
    buffer.append(F.f(t[74], width: 10, flags: F.flag.LJ));
    buffer.append("GCG: ")
    buffer.append(F.f(t[80], width: 10, flags: F.flag.LJ));
    buffer.append("GGG: ")
    buffer.append(F.f(t[86], width: 10, flags: F.flag.LJ));
    buffer.append("G\(uT)G: ")
    buffer.append(F.f(t[92], width: 10, flags: F.flag.LJ));

    if hasN {
      buffer.append("GNG: ")
      buffer.append(F.f(t[98], width: 10, flags: F.flag.LJ));
    }

    buffer.append("\n");

    buffer.append("     GA\(uT): ")
    buffer.append(F.f(t[75], width: 10, flags: F.flag.LJ));
    buffer.append("GC\(uT): ")
    buffer.append(F.f(t[81], width: 10, flags: F.flag.LJ));
    buffer.append("GG\(uT): ")
    buffer.append(F.f(t[87], width: 10, flags: F.flag.LJ));
    buffer.append("G\(uT)\(uT): ")
    buffer.append(F.f(t[93], width: 10, flags: F.flag.LJ));

    if hasN {
       buffer.append("GNT: ")
      buffer.append(F.f(t[99], width: 10, flags: F.flag.LJ));
    }
    buffer.append("\n");
    
    if hasN {
      buffer.append("     GAN: ")
      buffer.append(F.f(t[76], width: 10, flags: F.flag.LJ));
      buffer.append("GCN: ")
      buffer.append(F.f(t[82], width: 10, flags: F.flag.LJ));
      buffer.append("GGN: ")
      buffer.append(F.f(t[88], width: 10, flags: F.flag.LJ));
      buffer.append("G\(uT)N: ")
      buffer.append(F.f(t[94], width: 10, flags: F.flag.LJ));
      buffer.append("GNN: ")
      buffer.append(F.f(t[100], width: 10, flags: F.flag.LJ));
      buffer.append("\n");
    }

    buffer.append("\n");

    buffer.append("     \(uT)AA: ")
    buffer.append(F.f(t[108], width: 10, flags: F.flag.LJ));
    buffer.append("\(uT)CA: ")
    buffer.append(F.f(t[114], width: 10, flags: F.flag.LJ));
    buffer.append("\(uT)GA: ")
    buffer.append(F.f(t[120], width: 10, flags: F.flag.LJ));
    buffer.append("\(uT)\(uT)A: ")
    buffer.append(F.f(t[126], width: 10, flags: F.flag.LJ));

    if hasN {
      buffer.append("\(uT)NA: ")
      buffer.append(F.f(t[132], width: 10, flags: F.flag.LJ));
    }

    buffer.append("\n");

    buffer.append("     \(uT)AC: ")
    buffer.append(F.f(t[109], width: 10, flags: F.flag.LJ));
    buffer.append("\(uT)CC: ")
    buffer.append(F.f(t[115], width: 10, flags: F.flag.LJ));
    buffer.append("\(uT)GC: ")
    buffer.append(F.f(t[121], width: 10, flags: F.flag.LJ));
    buffer.append("\(uT)\(uT)C: ")
    buffer.append(F.f(t[127], width: 10, flags: F.flag.LJ));

    if hasN {
      buffer.append("\(uT)NC: ")
      buffer.append(F.f(t[133], width: 10, flags: F.flag.LJ));
    }

    buffer.append("\n");

    buffer.append("     \(uT)AG: ")
    buffer.append(F.f(t[100], width: 10, flags: F.flag.LJ));
    buffer.append("\(uT)CG: ")
    buffer.append(F.f(t[116], width: 10, flags: F.flag.LJ));
    buffer.append("\(uT)GG: ")
    buffer.append(F.f(t[122], width: 10, flags: F.flag.LJ));
    buffer.append("\(uT)\(uT)G: ")
    buffer.append(F.f(t[128], width: 10, flags: F.flag.LJ));

    if hasN {
      buffer.append("\(uT)NG: ")
      buffer.append(F.f(t[134], width: 10, flags: F.flag.LJ));
    }

    buffer.append("\n");

    buffer.append("     \(uT)A\(uT): ")
    buffer.append(F.f(t[111], width: 10, flags: F.flag.LJ));
    buffer.append("\(uT)C\(uT): ")
    buffer.append(F.f(t[117], width: 10, flags: F.flag.LJ));
    buffer.append("\(uT)G\(uT): ")
    buffer.append(F.f(t[123], width: 10, flags: F.flag.LJ));
    buffer.append("\(uT)\(uT)\(uT): ")
    buffer.append(F.f(t[129], width: 10, flags: F.flag.LJ));

    if hasN {
      buffer.append("\(uT)N\(uT): ")
      buffer.append(F.f(t[135], width: 10, flags: F.flag.LJ))
    
    }
    buffer.append("\n");

    if hasN {
        buffer.append("     \(uT)AN: ")
      buffer.append(F.f(t[112], width: 10, flags: F.flag.LJ));
        buffer.append("\(uT)CN: ")
      buffer.append(F.f(t[118], width: 10, flags: F.flag.LJ));
        buffer.append("\(uT)GN: ")
      buffer.append(F.f(t[124], width: 10, flags: F.flag.LJ));
        buffer.append("\(uT)\(uT)N: ")
      buffer.append(F.f(t[130], width: 10, flags: F.flag.LJ));
        buffer.append("\(uT)NN: ")
      buffer.append(F.f(t[136], width: 10, flags: F.flag.LJ));
        buffer.append("\n");
    }


    buffer.append("\n");

    if hasN {
        buffer.append("     NAA: ")
        buffer.append(F.f(t[144], width: 10, flags: F.flag.LJ));
        buffer.append("NCA: ")
      buffer.append(F.f(t[150], width: 10, flags: F.flag.LJ));
        buffer.append("NGA: ")
      buffer.append(F.f(t[156], width: 10, flags: F.flag.LJ));
        buffer.append("NTA: ")
      buffer.append(F.f(t[162], width: 10, flags: F.flag.LJ));
        buffer.append("NNA: ")
      buffer.append(F.f(t[168], width: 10, flags: F.flag.LJ));
        buffer.append("\n");

        buffer.append("     NAC: ")
      buffer.append(F.f(t[145], width: 10, flags: F.flag.LJ));
        buffer.append("NCC: ")
      buffer.append(F.f(t[151], width: 10, flags: F.flag.LJ));
        buffer.append("NGC: ")
      buffer.append(F.f(t[157], width: 10, flags: F.flag.LJ));
        buffer.append("NTC: ")
      buffer.append(F.f(t[163], width: 10, flags: F.flag.LJ));
        buffer.append("NNC: ")
      buffer.append(F.f(t[169], width: 10, flags: F.flag.LJ));
        buffer.append("\n");

        buffer.append("     NAG: ")
      buffer.append(F.f(t[146], width: 10, flags: F.flag.LJ));
        buffer.append("NCG: ")
      buffer.append(F.f(t[152], width: 10, flags: F.flag.LJ));
        buffer.append("NGG: ")
      buffer.append(F.f(t[158], width: 10, flags: F.flag.LJ));
        buffer.append("NTG: ")
      buffer.append(F.f(t[164], width: 10, flags: F.flag.LJ));
        buffer.append("NNG: ")
      buffer.append(F.f(t[170], width: 10, flags: F.flag.LJ));
        buffer.append("\n");

        buffer.append("     NAT: ")
      buffer.append(F.f(t[147], width: 10, flags: F.flag.LJ));
        buffer.append("NCT: ")
      buffer.append(F.f(t[153], width: 10, flags: F.flag.LJ));
        buffer.append("NGT: ")
      buffer.append(F.f(t[159], width: 10, flags: F.flag.LJ));
        buffer.append("NTT: ")
      buffer.append(F.f(t[165], width: 10, flags: F.flag.LJ));
        buffer.append("NNT: ")
      buffer.append(F.f(t[171], width: 10, flags: F.flag.LJ));
        buffer.append("\n");

        buffer.append("     NAN: ")
      buffer.append(F.f(t[148], width: 10, flags: F.flag.LJ));
        buffer.append("NCN: ")
      buffer.append(F.f(t[154], width: 10, flags: F.flag.LJ));
        buffer.append("NGN: ")
      buffer.append(F.f(t[160], width: 10, flags: F.flag.LJ));
        buffer.append("NTN: ")
      buffer.append(F.f(t[166], width: 10, flags: F.flag.LJ));
        buffer.append("NNN: ")
      buffer.append(F.f(t[172], width: 10, flags: F.flag.LJ));
        buffer.append("\n");

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
