//
//  SequenceTests.swift
//  Sequence EditorTests
//
//  Created by Will Gilbert on 8/31/21.
//

import XCTest
@testable import Sequence_Analysis

class SequenceTests: XCTestCase {
  

  func testNucleicProperties() {
    let sequence = Sequence("ACGT", type: .DNA)
    XCTAssert(sequence.isDNA)
    XCTAssertFalse(sequence.isProtein)
    XCTAssert(sequence.isNucleic)
    XCTAssertEqual(sequence.length, 4)
    sequence.uid = "XXXX"
    XCTAssertEqual(sequence.description, "XXXX Untitled DNA 4bp")
    XCTAssertEqual(sequence.checkSum, 748)
  }
  
  func testProteinProperties() {
    let sequence = Sequence("MKLV", type: .PROTEIN)
    XCTAssert(sequence.isProtein)
    XCTAssertFalse(sequence.isNucleic)
    XCTAssertEqual(sequence.length, 4)
    sequence.uid = "XXXX"
    XCTAssertEqual(sequence.description, "XXXX Untitled PROTEIN 4aa")
    XCTAssertEqual(sequence.checkSum, 799)
 }
 
  func testDescription() {
    let sequence = Sequence("ACGT", uid: "XXXX")
    XCTAssertEqual(sequence.description, "XXXX Untitled UNDEFINED 4")
    sequence.type = .DNA
    XCTAssertEqual(sequence.description, "XXXX Untitled DNA 4bp")
    sequence.title = "Testing the description"
    XCTAssertEqual(sequence.description, "XXXX Testing the description DNA 4bp")
    sequence.uid = "YYYY"
    XCTAssertEqual(sequence.description, "YYYY Testing the description DNA 4bp")
    sequence.type = .PROTEIN
    XCTAssertEqual(sequence.description, "YYYY Testing the description PROTEIN 4aa")
    sequence.type = .PEPTIDE
    XCTAssertEqual(sequence.description, "YYYY Testing the description PEPTIDE 4aa")
  }

  func testReverseComplement() {
    XCTAssert(Sequence.reverseComp("") == "")
    XCTAssert(Sequence.reverseComp("A") == "T")
    XCTAssert(Sequence.reverseComp("a") == "t")
    XCTAssert(Sequence.reverseComp("u") == "a")
    XCTAssert(Sequence.reverseComp("ata", type: .RNA) == "uau")
    XCTAssert(Sequence.reverseComp("AAAA") == "TTTT")
    XCTAssert(Sequence.reverseComp("AATAA") == "TTATT")
    XCTAssert(Sequence.reverseComp("AAATTT") == "AAATTT")
    XCTAssert(Sequence.reverseComp("CCCGGG") == "CCCGGG")
    XCTAssert(Sequence.reverseComp("CGCGCG") == "CGCGCG")
    XCTAssert(Sequence.reverseComp("ABCDE", type: .PROTEIN) == "ABCDE")
  }

  func testRNAtoDNA() {
    XCTAssert(Sequence.RNAtoDNA("") == "")
    XCTAssert(Sequence.RNAtoDNA("ACG") == "ACG")
    XCTAssert(Sequence.RNAtoDNA("acg") == "acg")
    XCTAssert(Sequence.RNAtoDNA("U") == "T")
    XCTAssert(Sequence.RNAtoDNA("u") == "t")
    XCTAssert(Sequence.RNAtoDNA("acgu") == "acgt")
    XCTAssert(Sequence.RNAtoDNA("ACGU") == "ACGT")
  }
  
  func testDNAtoRNA() {
    XCTAssert(Sequence.DNAtoRNA("") == "")
    XCTAssert(Sequence.DNAtoRNA("ACG") == "ACG")
    XCTAssert(Sequence.DNAtoRNA("acg") == "acg")
    XCTAssert(Sequence.DNAtoRNA("T") == "U")
    XCTAssert(Sequence.DNAtoRNA("t") == "u")
    XCTAssert(Sequence.DNAtoRNA("acgt") == "acgu")
    XCTAssert(Sequence.DNAtoRNA("ACGT") == "ACGU")
  }
  
  func testMolWt() {
    XCTAssertEqual(Sequence.molWt(""), 0.0)
    XCTAssertEqual(Sequence.molWt("A", type: .DNA), 251.2, accuracy: 0.1)
    XCTAssertEqual(Sequence.molWt("AA", type: .DNA), 563.4, accuracy: 0.1)
    XCTAssertEqual(Sequence.molWt("aa", type: .DNA), 563.4, accuracy: 0.1)
    XCTAssertEqual(Sequence.molWt("ACGT", type: .DNA), 1171.8, accuracy: 0.1)
    XCTAssertEqual(Sequence.molWt("AA", type: .PROTEIN), 160.165, accuracy: 0.1)
    XCTAssertEqual(Sequence.molWt("ACDEFGHIKLMNQRSTVWY", type: .PROTEIN), 2298.6, accuracy: 0.1)
  }

  func testNucToProtein() {
    // Empty sequence
    XCTAssertEqual(Sequence.nucToProtein(""), "")
    
    // Ony translate triplets
    XCTAssertEqual(Sequence.nucToProtein("AAA"), "K")
    XCTAssertEqual(Sequence.nucToProtein("AAAA"), "K")
    XCTAssertEqual(Sequence.nucToProtein("AAAAA"), "K")
    XCTAssertEqual(Sequence.nucToProtein("AAAAAA"), "KK")
    
    // Only translate DNA or RNA
    XCTAssertEqual(Sequence.nucToProtein("AAAAAA", doStops: false, type: .PROTEIN), "")
    XCTAssertEqual(Sequence.nucToProtein("AAAAAA", doStops: false, type: .PEPTIDE), "")
    
    // With and without stop codons
    XCTAssertEqual(Sequence.nucToProtein("GATATAATACAGGAGTGTTTAACCGACACGAAGGGGCTGACTGAGAAAGCATGACAGGGA"), "DIIQECLTDTKGLTEKA*QG")
    XCTAssertEqual(Sequence.nucToProtein("GATATAATACAGGAGTGTTTAACCGACACGAAGGGGCTGACTGAGAAAGCATGACAGGGA",
                                                                                          doStops: true), "DIIQECLTDTKGLTEKA")
    
    // ALL 64 codons, RNA
    XCTAssertEqual(Sequence.nucToProtein("AUG"), "M")                      // Methionine
    XCTAssertEqual(Sequence.nucToProtein("UGG"), "W")                      // Tryptophan
    XCTAssertEqual(Sequence.nucToProtein("AUUAUC"), "II")                  // Isoleucine
    XCTAssertEqual(Sequence.nucToProtein("UUUUUC"), "FF")                  // Phenylalanine
    XCTAssertEqual(Sequence.nucToProtein("CAUCAC"), "HH")                  // Histidine
    XCTAssertEqual(Sequence.nucToProtein("CAACAG"), "QQ")                  // Glutamine
    XCTAssertEqual(Sequence.nucToProtein("AAUAAC"), "NN")                  // Asparagine
    XCTAssertEqual(Sequence.nucToProtein("AAAAAG"), "KK")                  // Lysine
    XCTAssertEqual(Sequence.nucToProtein("GAUGAC"), "DD")                  // Aspartic acid
    XCTAssertEqual(Sequence.nucToProtein("GAAGAG"), "EE")                  // Glutamic acid
    XCTAssertEqual(Sequence.nucToProtein("UGUUGC"), "CC")                  // Cysteine
    XCTAssertEqual(Sequence.nucToProtein("UAUUAC"), "YY")                  // Tyrocine
    XCTAssertEqual(Sequence.nucToProtein("UAAUAGUGA"), "***")              // Stop
    XCTAssertEqual(Sequence.nucToProtein("GUUGUCGUAGUG"), "VVVV")          // Valine
    XCTAssertEqual(Sequence.nucToProtein("CCUCCCCCACCG"), "PPPP")          // Valine
    XCTAssertEqual(Sequence.nucToProtein("ACUACCACAACG"), "TTTT")          // Threonine
    XCTAssertEqual(Sequence.nucToProtein("GCUGCCGCAGCG"), "AAAA")          // Alanine
    XCTAssertEqual(Sequence.nucToProtein("GGUGGCGGAGGG"), "GGGG")          // Glycine
    XCTAssertEqual(Sequence.nucToProtein("UUAUUGCUUCUCCUACUG"), "LLLLLL")  // Leucine
    XCTAssertEqual(Sequence.nucToProtein("UCUUCCUCAUCGAGUAGC"), "SSSSSS")  // Serine
    XCTAssertEqual(Sequence.nucToProtein("CGUCGCCGACGGAGAAGG"), "RRRRRR")  // Arginine
    
    // ALL 64 codons, DNA
    XCTAssertEqual(Sequence.nucToProtein("ATG"), "M")                      // Methionine
    XCTAssertEqual(Sequence.nucToProtein("TGG"), "W")                      // Tryptophan
    XCTAssertEqual(Sequence.nucToProtein("ATTATC"), "II")                  // Isoleucine
    XCTAssertEqual(Sequence.nucToProtein("TTTTTC"), "FF")                  // Phenylalanine
    XCTAssertEqual(Sequence.nucToProtein("CATCAC"), "HH")                  // Histidine
    XCTAssertEqual(Sequence.nucToProtein("CAACAG"), "QQ")                  // Glutamine
    XCTAssertEqual(Sequence.nucToProtein("AATAAC"), "NN")                  // Asparagine
    XCTAssertEqual(Sequence.nucToProtein("AAAAAG"), "KK")                  // Lysine
    XCTAssertEqual(Sequence.nucToProtein("GATGAC"), "DD")                  // Aspartic acid
    XCTAssertEqual(Sequence.nucToProtein("GAAGAG"), "EE")                  // Glutamic acid
    XCTAssertEqual(Sequence.nucToProtein("TGTTGC"), "CC")                  // Cysteine
    XCTAssertEqual(Sequence.nucToProtein("TATTAC"), "YY")                  // Tyrocine
    XCTAssertEqual(Sequence.nucToProtein("TAATAGTGA"), "***")              // Stop
    XCTAssertEqual(Sequence.nucToProtein("GTTGTCGTAGUG"), "VVVV")          // Valine
    XCTAssertEqual(Sequence.nucToProtein("CCTCCCCCACCG"), "PPPP")          // Valine
    XCTAssertEqual(Sequence.nucToProtein("ACTACCACAACG"), "TTTT")          // Threonine
    XCTAssertEqual(Sequence.nucToProtein("GCTGCCGCAGCG"), "AAAA")          // Alanine
    XCTAssertEqual(Sequence.nucToProtein("GGTGGCGGAGGG"), "GGGG")          // Glycine
    XCTAssertEqual(Sequence.nucToProtein("TTATTGCTTCUCCTACUG"), "LLLLLL")  // Leucine
    XCTAssertEqual(Sequence.nucToProtein("TCTTCCTCATCGAGTAGC"), "SSSSSS")  // Serine
    XCTAssertEqual(Sequence.nucToProtein("CGTCGCCGACGGAGAAGG"), "RRRRRR")  // Arginine
  }
  
  func testOneToThree() {
    XCTAssertEqual(Sequence.oneToThree("A"), "Ala")
    XCTAssertEqual(Sequence.oneToThree("B"), "Asx")
    XCTAssertEqual(Sequence.oneToThree("C"), "Cys")
    XCTAssertEqual(Sequence.oneToThree("D"), "Asp")
    XCTAssertEqual(Sequence.oneToThree("E"), "Glu")
    XCTAssertEqual(Sequence.oneToThree("F"), "Phe")
    XCTAssertEqual(Sequence.oneToThree("G"), "Gly")
    XCTAssertEqual(Sequence.oneToThree("I"), "Ile")
    XCTAssertEqual(Sequence.oneToThree("J"), "???")
    XCTAssertEqual(Sequence.oneToThree("K"), "Lys")
    XCTAssertEqual(Sequence.oneToThree("L"), "Leu")
    XCTAssertEqual(Sequence.oneToThree("M"), "Met")
    XCTAssertEqual(Sequence.oneToThree("N"), "Asn")
    XCTAssertEqual(Sequence.oneToThree("O"), "???")
    XCTAssertEqual(Sequence.oneToThree("P"), "Pro")
    XCTAssertEqual(Sequence.oneToThree("Q"), "Gln")
    XCTAssertEqual(Sequence.oneToThree("R"), "Arg")
    XCTAssertEqual(Sequence.oneToThree("S"), "Ser")
    XCTAssertEqual(Sequence.oneToThree("T"), "Thr")
    XCTAssertEqual(Sequence.oneToThree("U"), "???")
    XCTAssertEqual(Sequence.oneToThree("V"), "Val")
    XCTAssertEqual(Sequence.oneToThree("W"), "Trp")
    XCTAssertEqual(Sequence.oneToThree("X"), "???")
    XCTAssertEqual(Sequence.oneToThree("Y"), "Tyr")
    XCTAssertEqual(Sequence.oneToThree("Z"), "Glx")
    XCTAssertEqual(Sequence.oneToThree("*"), "***")
    XCTAssertEqual(Sequence.oneToThree("."), "---")
  }
  
  func testGCPercent() {
    XCTAssertEqual(try XCTUnwrap(Sequence.gcPercent("C")), 100.0)
    XCTAssertEqual(try XCTUnwrap(Sequence.gcPercent("CG")), 100.0)
    XCTAssertEqual(try XCTUnwrap(Sequence.gcPercent("CGCGA")), 80.0)
    XCTAssertEqual(try XCTUnwrap(Sequence.gcPercent("AT")), 0.0)

    XCTAssertEqual(try XCTUnwrap(Sequence.gcPercent("c", type: .RNA)), 100.0)
    XCTAssertEqual(try XCTUnwrap(Sequence.gcPercent("cg", type: .RNA)), 100.0)
    XCTAssertEqual(try XCTUnwrap(Sequence.gcPercent("cgcga", type: .RNA)), 80.0)
    XCTAssertEqual(try XCTUnwrap(Sequence.gcPercent("at", type: .RNA)), 0.0)
    
    if let _ = Sequence.gcPercent("at", type: .PROTEIN) {
      XCTFail("Expected nil cg%")
    }
    
    if let _ = Sequence.gcPercent("at", type: .PEPTIDE) {
      XCTFail("Expected nil cg%")
    }

  }
  
  func testSimpleTm() {

    XCTAssertEqual(try XCTUnwrap(Sequence.simpleTm("ACGTACGTA")), 26.0)
    XCTAssertEqual(try XCTUnwrap(Sequence.simpleTm("ACGT--ACGTA")), 26.0)
    XCTAssertEqual(try XCTUnwrap(Sequence.simpleTm("ACGTACGTA*")), 26.0)
    XCTAssertEqual(try XCTUnwrap(Sequence.simpleTm("ACGTACGTACGTACGTACGT")), 60.0)

    // Over 110C
    if let _ = Sequence.simpleTm("ACGTACGTACGTACGTACGTACGTACGTAGCTAAACGTT") {
      XCTFail("Expected nil Tm")
    }
    
    // Too short, must be >8
    if let _ = Sequence.simpleTm("ACGTACGT") {
      XCTFail("Expected nil Tm")
    }

    if let _ = Sequence.simpleTm("au", type: .RNA) {
      XCTFail("Expected nil Tm")
    }
    
    if let _ = Sequence.simpleTm("at", type: .PROTEIN) {
      XCTFail("Expected nil Tm")
    }

    if let _ = Sequence.simpleTm("at", type: .PEPTIDE) {
      XCTFail("Expected nil Tm")
    }
  }
  
  func testSimpleConc() {

    XCTAssertEqual(try XCTUnwrap(Sequence.simpleConc("ACGTACGTACGTACGTACGTACGTACGTAGCTAAACGTT")), 28.0, accuracy: 0.1)
    XCTAssertEqual(try XCTUnwrap(Sequence.simpleConc("ACGTACGTA")), 26.7, accuracy: 0.1)


    if let _ = Sequence.simpleConc("at", type: .RNA) {
      XCTFail("Expected nil ug/OD")
    }

    if let _ = Sequence.simpleConc("at", type: .PROTEIN) {
      XCTFail("Expected nil ug/OD")
    }

    if let _ = Sequence.simpleConc("at", type: .PEPTIDE) {
      XCTFail("Expected nil ug/OD")
    }
  }
  
  func testComplexConc() {

    XCTAssertEqual(try XCTUnwrap(Sequence.complexConc("ACGTACGTACGTACGTACGTACGTACGTAGCTAAACGTT")), 30.8, accuracy: 0.1)
    XCTAssertEqual(try XCTUnwrap(Sequence.complexConc("AA")), 20.5, accuracy: 0.1)
    XCTAssertEqual(try XCTUnwrap(Sequence.complexConc("ACGT")), 29.0, accuracy: 0.1)

    // Must be at least 2 bases
    if let _ = Sequence.complexConc("a") {
      XCTFail("Expected nil ug/OD")
    }

    if let _ = Sequence.complexConc("at", type: .RNA) {
      XCTFail("Expected nil ug/OD")
    }

    if let _ = Sequence.complexConc("at", type: .PROTEIN) {
      XCTFail("Expected nil ug/OD")
    }

    if let _ = Sequence.complexConc("at", type: .PEPTIDE) {
      XCTFail("Expected nil ug/OD")
    }
  }

}
