//
//  ALOM.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 1/14/22.
////
//  Replaces the amino acids by their hydrophobicities (Kyte-Doolittle values)
//  and finds the segment of 17 with maximum hydrophobicity. If average
//  hydrophobicity of this segment is smaller than the value determined by
//  discriminant analysis (1.582), the protein is classified as peripheral (or
//  non-membrane).  Otherwise, it is classified as integral and the segment of
//  17 (inner boundaries) is extended on both sides as far as possible - to
//  obtain outer boundaries of the membrane spanning segment.
//  Then additional transmembrane segments are found using the same rule.
//
//  For proteins classified as integral, the threshold is then lowered so that
//  segments with odds of peripheral:integral of up to 80:1 are classified
//  as probably transmembrane. This is to account for the cooperativity effect
//  described by Eisenberg et al., J. Mol. Biol. 179, 125-142 (1984).
//
//  This algoritm was converted to "C" from the original FORTRAN source code
//  by William Gilbert, October 1988
//
//  This algoritm was converted to Java from "C" source code
//  by William Gilbert, July 1997
//
//  This algoritm was converted to Swift from Java source code
//  by William Gilbert, January 2022
//
//  REFERENCE: P.Klein, M.Kanehisa and C.DeLisi: The detection and
//             classification of membrane spanning proteins.
//             Biochim. Biophys. Acta 815, 468-476 (1985)
//
//  https://www.sciencedirect.com/science/article/abs/pii/000527368590375X?via%3Dihub
//  https://www.researchgate.net/publication/11892511_Evaluation_of_Methods_for_the_Prediction_of_Membrane_Spanning_Regions
//
// ***************************************************************************
// Test routine using NCBI Protein database entry:
//   1493897702 bacteriorhodopsin [Halorubrum sp. RHB-C]
//
// Should produce 7 "peaks":
//
// 20-40   4.19    147-169 2.87
// 54-75   1.54    185-205 3.19
// 98-115  2.34    217-236 2.39
// 119-140 5.47
//
/*
MDPIALQAGYDLLGDGRPETLWLGIGTLLMIIGTFYFIARGWGVTDKEAREYYAITILVP
GIASAAYLSMFFGIGLTEVELVGGEVLDIYYARYADWLFTTPLLLLDLCLLAKVDRVTTG
TLIGVDALMIVTGLIGALSHTPLARYTWWLFSTIAFLFVLYYLLTSLRSAARERSEDVQS
TFNTLTALVAVLWTAYPILWIIGTEGAGVVGLGVETLAFMVLDVTAKVGFGFVLLRSRAI
LGDTEAPEPSAGAEASAAD
*/

import Foundation


class ALOM {
  
  // ALOM constants
  private static let A0: Double = 1.582
  private static let A1: Double = -1.0
  private static let maxHCoeff: Double = -9.02
  private static let maxHOffset: Double = 14.27
  private static let maxHLimit: Double = 80.0

  private var maxH: Double = 0.0
//  private var index: Int = 0;
  private var left: Int = 0, right: Int = 0
  
  private let predicton: Prediction = Prediction.ALOM
  private let length: Int
  private let window: Int

  // 'strand' is modified by the algorithm
  private var strand: [Character]


  init(sequence: Sequence) {
    self.length = sequence.string.count
    self.window = predicton.window
    self.strand = Array(sequence.string.uppercased())
  }
  
  func analyze() -> [Double?]? {
     
    guard length > (window * 2) else { return nil }
    
    var isHydrophobic: Bool = false
    
    // The return data
    var data = [Double?](repeating: 0.00, count: length)

    // Go thru the entire sequence, find the largest region of hydropilicty,
    //   extend that region, write it to the value array, set the region to
    //   all arginine, the repeat the process.
    
    while ( true ) {
      
      let (at, maxH) = findMaxHRegion()
      
      // Discriminant Analysis: Core of the ALOM algorithm
      let x = (ALOM.A1 * maxH) + ALOM.A0
      let x0 = (ALOM.maxHCoeff * maxH) + ALOM.maxHOffset
      let odds = exp(x0)
      
      // If 'x' less than zero, it's definitly hydrophobic, extend the
      //   region to see how far it goes. Otherwise, test to see if it's
      //   marginal or simply peripheral.

      if (x < 0.0) {

        isHydrophobic = true;
        extendHRegion(from: at);

        // Fill the value array

        for i in  left..<right {
          data[i] = -x0
        }

      } else {

        if ((isHydrophobic == false) || (odds > ALOM.maxHLimit)) {
              return data   // we're done
          } else {
            for i in  at..<(at + window) {
              data[i] = -x0;
            }
          }
      }
      
      // Set the current region to all Arginine, 'R',  to essentially
      //   eliminate this region from further calculations.

      for i in at..<(at + window) {
        strand[i] =  "R"
      }

    }

    return data
  }
  
  // * findMaxHRegion  **********************************************************
  //
  // Find the region of maximum hydrophibicity for the entire sequence.  Return
  // the value and the range of this segment.
  //
  // ****************************************************************************

  func findMaxHRegion() -> (at: Int, maxH: Double) {
    
    var pos: Int = 0
    var sumH: Double = 0.0
    var aveH: Double = 0.0
    
    // Array of Kyte & Doolittle hydrophobic values; -0.5 for missing values
     var seqH = [Double](repeating: -0.5, count: length)

    // Load up the 'seqH' array with the corresponding K&D values,
    let values = predicton.values
    for i in 0..<strand.count {
      if let value: Double = values[strand[i]] {
        seqH[i] = value
      }
    }

    // Initialize some variables and get the value for the first window
    var at: Int = 0

    // Calculate the average hydrophocity for the starting window
    for i: Int in 0..<window {
      sumH += seqH[i];
    }

    aveH = sumH / Double( window)
    maxH = aveH

    // Move the window along, adding values on the right, removing values
    // on the left, saving the largest hydrophilicity value and it's location.

    while ((pos + window) < length) {
      sumH -= seqH[pos];
      sumH += seqH[pos + window];
      aveH = sumH / Double(window)
      pos += 1

      // Largest hydrophobicity region so far
      if (aveH > maxH) {
        maxH = aveH;
        at = pos;
      }
    }

    // When we get to here we have determined the location and value of the
    //   largest hydrophilicity in 'at' and 'maxH', respectively.
    
    return (at, maxH)
    
  }

  // *  extendHRegion  ***********************************************************
  //
  // Given a maximum hydrophobic region at "index" extend in both left and
  // right directions.  Return this extended region in "left" and "right"
  //
  // ***********************************************************************

  func extendHRegion(from: Int) {
    
    var y: Double = 0.0
    var avh: Double = 0.0

    // Move the window to the left, stop when the hydrophobicity
    // drops off.  Check to make sure you don't go beyond 0.

    left = from - 1

    while left >= 0 {
      
      avh = averageHWindow(from: left, size: window)
      y = (ALOM.A1 * avh) + ALOM.A0

      if (y >= 0.0) {
            break
      }

      left -= 1
    }

    left += 1
    
    // Move the window to the right, stop when the hydrophobicity
    //   drops off.  Check to make sure you don't go off the end.

    right = from + window

    while right < length {
      avh = averageHWindow(from: right - window, size: window)
      y = (ALOM.A1 * avh) + ALOM.A0

      if (y >= 0.0) {
            break
      }

      right += 1
    }

    right = (right < length) ? right : (length - 1)
    
  }
  
  // *  averageHWindow  *********************************************************
  //
  // Returns the average hydophobicity for the sequence segment starting
  // at "from" and "size" in length.  The calling routine, "extendHRegion" will
  // make sure that 'from + size' does not run off the end of the sequence.
  //
  // ****************************************************************************
  
  func averageHWindow(from: Int, size: Int) -> Double {
    
    var avh: Double = 0.0

    // Get some memory to hold the values for this segment.
    var seqH: [Double] = [Double](repeating: 0.0, count: size)
    
    // Fill 'seqH' with K&D values for this segment
    let values = predicton.values
    for i in 0..<size {
      if let value: Double = values[strand[from + i]] {
        seqH[i] = value
      }
    }
    
    // Calculate the average K&D value for this segment
    avh = 0.0;

    for i in 0..<size {
        avh += seqH[i]
    }

    avh = avh / Double(size)
    return avh
  }
  

}
