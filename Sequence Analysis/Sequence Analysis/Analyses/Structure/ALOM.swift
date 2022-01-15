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
// ***************************************************************************
// Test routine using Protein database entry RAHSB Bacteriorhodopsin.
// Should produce 7 "peaks":
//
// 25-41   2.39    147-170 3.77
// 56-76   1.12    189-205 0.32
// 97-115  2.18    217-236 3.03
// 119-137 3.24
//
// MLELLPTAVEGVSQAQITGRPEWIWLALGTALM
// GLGTLYFLVKGMGVSDPDAKKFYAITTLVPAIAF
// TMYLSMLLGYGLTMVPFGGEQNPIYWARYADWLF
// TTPLLLLDLALLVDADQGTILALVGADGIMIGTG
// LVGALTKVYSYRFVWWAISTAAMLYILYVLFFGF
// TSKAESMRPEVASTFKVLRNVTVVLWSAYPVVWL
// IGSEGAGIVPLNIETLLFMVLDVSAKVGFGLILL
// RSRAIFGEAEAPEPSAGDGAAATSD


import Foundation


class ALOM {
    
  private static let a0: Double = 1.582
  private static let a1: Double = -1.0

  private var MaxH: Double = 0.0
  private var Index: Int = 0;
  private var Left: Int = 0, Right: Int = 0
  
  private let predicton: Prediction = Prediction.ALOM
  private var Seq: [Character]
  private let Len: Int
  private let Window: Int


  init(sequence: Sequence) {
    self.Len = sequence.string.count
    self.Window = predicton.window
    self.Seq = Array(sequence.string.uppercased())
  }
  
  func analyze() -> [Double?]? {
     
    guard Len > (Window * 2) else { return nil }
    
    
    let xlim: Double = 80.0
    var x: Double = 0.0
    var x0: Double = 0.0
    var xodds: Double = 0.0
    
    var IsHydrophobic: Bool = false
    
    // The return data
    var data = [Double?](repeating: 0.00, count: Len)

    // Go thru the entire sequence, find the largest region of hydropilicty,
    //   extend that region, write it to the value array, set the region to
    //   all arginine, the repeat the process.
    
    while ( true ) {
      
      YMax()
      
      x = (ALOM.a1 * MaxH) + ALOM.a0;
      x0 = (-9.02 * MaxH) + 14.27;
      xodds = exp(x0)
      
      // if 'x' less than zero, it's definitly hydrophobic, extend the
      // region to see how far it goes. Otherwise, test to see if it's
      // marginal or simply peripheral.

      if (x < 0.0) {

        IsHydrophobic = true;
        Extend();

        // Fill the value array

        for i in  Left..<Right {
          data[i] = -x0
        }

      } else {

          if ((IsHydrophobic == false) || (xodds > xlim)) {
              return data   // we're done
          } else {
            for i in  Index..<(Index + Window) {
              data[i] = -x0;
            }
          }
      }
      
      // Set the current region to all Arginine to essentially eliminate
      // this region from further calculations.

      for i in Index..<(Index + Window) {
          Seq[i] =  "R"
      }

    }

    return data
  }
  
  // * Ymax  ********************************************************************
  //
  // Find the region of maximum hydrophibicity for the entire sequence.  Return
  // the value and the range of this segment.
  //
  // ****************************************************************************

  func YMax() {
    
    var Pos: Int = 0
    var SumH: Double = 0.0
    var AveH: Double = 0.0
    
    
    // Array of Kyte & Doolittle hydrophobic values
     var SeqH = [Double](repeating: -0.5, count: Len)

    // Load up the SeqH array with the corresponding K&D values,

    let values = predicton.values
    for i in 0..<Seq.count {
      if let value: Double = values[Seq[i]] {
        SeqH[i] = value
      }
    }

    // Initialize some variables and get the value for the first window
    Pos = 0
    Index = 0
    SumH = 0.0

    for i: Int in 0..<Window {
        SumH += SeqH[i];
    }

    AveH = SumH / Double( Window)
    MaxH = AveH

    // Move the window along, adding values on the right, removing values
    // on the left, saving the largest hydrophilicity value and it's location.

    while ((Pos + Window) < Len) {
        SumH -= SeqH[Pos];
        SumH += SeqH[Pos + Window];
        AveH = SumH / Double(Window)
        Pos += 1

        if (AveH > MaxH) {
            MaxH = AveH;
            Index = Pos;
        }
    }

    // When we get to here we have determined the location and value of the
    //   largest hydrophilicity in Index and MaxH, respectively.
    
  }

  // *  Extend  ***********************************************************
  //
  // Given a maximum hydrophobic region at "Index" extend in both left and
  // right directions.  Return this extended region in "Left" and "Right"
  //
  // ***********************************************************************

  func Extend() {
    
    var y: Double = 0.0
    var avh: Double = 0.0


    // Move the window to the left, stop when the hydrophobicity
    // drops off.  Check to make sure you don't go beyond 0.

    Left = Index - 1

    while Left >= 0 {
      
      avh = Limit(17, Left)
      y = (ALOM.a1 * avh) + ALOM.a0

      if (y >= 0.0) {
            break
      }

      Left -= 1
    }

    Left += 1
    
    // Move the window to the right, stop when the hydrophobicity
    //   drops off.  Check to make sure you don't go off the end.

    Right = Index + Window

    while Right < Len {
      avh = Limit(Window, Right - Window)
      y = (ALOM.a1 * avh) + ALOM.a0

      if (y >= 0.0) {
            break
      }

        Right += 1
    }

    Right = (Right < Len) ? Right : (Len - 1)
    
  }
  
  // *  Limit  ******************************************************************
  //
  // Returns the average hydophobicity for the sequence segment starting
  // at "Left" and "Window" in length.  The calling routine, "Extend" will
  // make sure that Left+Window does not run off the end of the sequence.
  //
  // ****************************************************************************

  
  func Limit(_ inWindow: Int, _ Left: Int) -> Double {
    
    var avh: Double = 0.0;

    // Get some memory to hold the values for this segment.
    var SeqH: [Double] = [Double](repeating: 0.0, count: inWindow)

    
    // Fill 'SeqH' with K&D values for this segment
    let values = predicton.values
    for i in 0..<inWindow {
      if let value: Double = values[Seq[Left + i]] {
        SeqH[i] = value
      }
    }
    
    // Calculate the average K&D value for this segment
    avh = 0.0;

    for i in 0..<inWindow {
        avh += SeqH[i]
    }

    avh = avh / Double(inWindow)
    return avh
  }
  

}
