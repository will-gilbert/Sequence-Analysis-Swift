//
//  PI.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/14/21.
//

// pKa values for polar amino acids:
//                  NH3    D     E     H     C     Y      K      R      S     T      COOH
// Original SA     8.56   3.91  4.25  6.50  8.30 10.95  10.79  12.50   N/A   N/A     3.56
// JAMBW           9.69   3.86  4.25  6.00  8.33 10.00  10.50  12.40   N/A   N/A     2.34
// Merck Manual  varies   3.65  4.25  6.00 10.29 10.06  10.52  12.48  13.6  13.6   varies
// Stryer          8.00   4.40  4.40  6.50  8.50 10.00  10.00  12.00   N/A   N/A     3.10


import SwiftUI

struct IsoElectricView: View {
  
  var sequenceState: SequenceState
  @ObservedObject var sequenceSelectionState: SequenceSelectionState
  @State var text: String = ""
  
  init(sequenceState: SequenceState) {
    self.sequenceState = sequenceState
    
    // Observe any changes in the sequence selection; Recalculate
    sequenceSelectionState = sequenceState.sequenceSelectionState
  }

  var body: some View {
  
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
      
      let _ = IsoElectricReport(sequence, text: $text)
    }
    
    return TextView(text: $text, isEditable: false)
  }
}

struct IsoElectricReport {
  
  var sequence: Sequence
  @Binding var buffer: String
  
  init(_ sequence: Sequence, text: Binding<String>) {
    self.sequence = sequence
    self._buffer = text
    
    doPI()
  }

  mutating func doPI() {
    
    buffer.append(sequence.description)
    buffer.append("\n\n")

    guard sequence.isProtein else {buffer.append("pI can only be calculated on protein sequences"); return }
      
    // Get pI data =======
    let pIData = IsoElectricPoint.pIData(sequence,  start: 2.0, stop: 12.0, step: 0.5)

    buffer.append("  pI: ")
    if let pI = IsoElectricPoint.calculate(pIData) {
      buffer.append(F.f(pI, decimal: 2))
    } else {
      buffer.append("----")
    }
    buffer.append("\n\n")

    // pI table
    
    buffer.append(" Charge at pH\n")
    buffer.append(" ------------\n")

    let third: Int = pIData.count / 3

    for i in 0..<third {
      
      var pH = pIData[i][0]
      var charge = pIData[i][1];
      buffer.append("     ")
      buffer.append(F.f("pH=\(pH):", width: 9, flags: F.flag.LJ))
      buffer.append(F.f(charge, decimal: 2, width: 7))
      buffer.append("       ");
      
      pH = pIData[i + third][0];
      charge = pIData[i + third][1];
      buffer.append(F.f("pH=\(pH):", width: 9, flags: F.flag.LJ))
      buffer.append(F.f(charge, decimal: 2, width: 7))
      buffer.append("       ");
      
      pH = pIData[i + third + third][0];
      charge = pIData[i + third + third][1];
      buffer.append(F.f("pH=\(pH):", width: 9, flags: F.flag.LJ))
      buffer.append(F.f(charge, decimal: 2, width: 7))
      buffer.append("\n");
    }

  }

}

class IsoElectricPoint {
  
  static func calculate(_ data: [[Double]]) -> Double? {
  
    // The net charge array must start out positive
    // and go negative otherwise no pI

    guard data.count > 1 else { return nil }
    guard data[0][1] > 0.0 else { return nil }
    guard data[data.count - 1][1] < 0.0 else { return nil }

    var iso: Double? = nil
    
    // Find the two points where the net charge goes from
    // positive to negative.

    var lastPh: Double = data[0][0];
    var lastCharge: Double = data[0][1];

    // Ensure that 'i' does not exceed data.count
    var i: Int = 1
    while (i < data.count && data[i][1] > 0.0) {
        lastPh = data[i][0];
        lastCharge = data[i][1]
        i += 1
    }

    let rangePh: Double = data[i][0] - lastPh;
    let rangeCharge: Double = data[i][1] - lastCharge;
    iso = lastPh - (lastCharge * rangePh / rangeCharge)
    return iso
  }
  
  static func pIData(_ sequence: Sequence, start: Double, stop: Double, step: Double) -> [[Double]] {
    
    let steps = Int((stop - start) / step) + 1;
    var data = Array(repeating: Array(repeating: 0.0, count: 2), count: steps)


    
    guard sequence.length > 0 else {
      // Empty data in case there is no sequence
      for i in 0..<steps {
        let pH: Double = start + (step * Double(i));
        data[i][0] = pH;
        data[i][1] = Double.nan
      }
      return data
    }
    
    
    let strand = Array(sequence.string.uppercased())
    // Create dictionary of charged amino acids
    var a = [ "C":0, "D":0, "E":0, "H":0, "K":0, "N":0, "R":0, "S":0, "T":0, "Y":0]
    
    for aa in strand {
      let key = String(aa)
      if let current = a[key] { // <-- Here will only update values from the dictionary
        a.updateValue(current + 1, forKey: key)
      }
    }
        
    for i in 0..<steps {
      let pH: Double = start + (step * Double(i));
      data[i][0] = pH;
      data[i][1] = currentPH(pH: pH, a: a);
    }

    return data
  }
  
  static func currentPH(pH: Double, a: [String:Int] ) -> Double {
    
    let hPlus: Double = pow(10.0, pH);
    var netCharge: Double = 0.0;

    // Amino-terminus, (NH3-)
    netCharge += chargeAtPH(currentPH: hPlus, pK: 8.00, charge: 0, numberOfAAs: 1)
 
    // Asp, D
    netCharge += chargeAtPH(currentPH: hPlus, pK: 3.65, charge: -1, numberOfAAs: a["D"])

    // Glu, E
    netCharge += chargeAtPH(currentPH: hPlus, pK: 4.25, charge: -1, numberOfAAs: a["E"])

    // His, H
    netCharge += chargeAtPH(currentPH: hPlus, pK: 6.00, charge: 0, numberOfAAs: a["H"])

    // Cys, C
    netCharge += chargeAtPH(currentPH: hPlus, pK: 10.29, charge: -1, numberOfAAs: a["C"])

    // Tyr, Y
    netCharge += chargeAtPH(currentPH: hPlus, pK: 10.06, charge: -1, numberOfAAs: a["Y"])

    // Lys, K
    netCharge += chargeAtPH(currentPH: hPlus, pK: 10.52, charge: 0, numberOfAAs: a["K"])

    // Arg, R
    netCharge += chargeAtPH(currentPH: hPlus, pK: 12.48, charge: 0, numberOfAAs: a["R"])

    // Ser, S
    netCharge += chargeAtPH(currentPH: hPlus, pK: 13.60, charge: -1, numberOfAAs: a["S"])

    // Thr, T
    netCharge += chargeAtPH(currentPH: hPlus, pK: 13.60, charge: -1, numberOfAAs: a["T"])
    
    // Carboxyl-terminus, (-COOH)
    netCharge += chargeAtPH(currentPH: hPlus, pK: 3.10, charge: -1, numberOfAAs: 1)

    return netCharge
  }
  
  static func chargeAtPH(currentPH: Double, pK: Double, charge: Int, numberOfAAs: Int?) -> Double {

    guard numberOfAAs != nil else { return 0.0 }
    
    let no: Double = Double(numberOfAAs!)
    let bChrg: Double = Double(charge)

    var bhb:Double, fraction1:Double, fraction2:Double, chrg1:Double, chrg2:Double, hbb:Double

    bhb = currentPH / pow(10.0, pK);
    fraction1 = bhb / (1.0 + bhb);
    chrg1 = bChrg * no * fraction1
    hbb = 1 / bhb;
    fraction2 = hbb / (1 + hbb);
    chrg2 = (1 + bChrg) * no * fraction2

    return chrg1 + chrg2
    
  }
}
