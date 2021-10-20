//
//  ORF_Nucleic.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 10/2/21.
//

import Foundation


struct ORF_CreateXML {

  func createXML(_ sequence: Sequence, options: ORFOptions) -> XMLDocument {

    let orf = XMLElement(name: "ORF")
    orf.addAttribute(XMLNode.attribute(withName: "sequence", stringValue: sequence.shortDescription) as! XMLNode)
    orf.addAttribute(XMLNode.attribute(withName: "length", stringValue: String(sequence.length)) as! XMLNode)
    
    let xml = XMLDocument(rootElement: orf)

    for frame in 1...3 {
    
      let frameNode = XMLElement(name: "frame")
      frameNode.addAttribute(XMLNode.attribute(withName: "frame", stringValue: "+\(frame)") as! XMLNode)
      orf.addChild(frameNode)
      
      // Start codons
      if options.startCodons {
        let startCodons: [Int] = findStartCodons(sequence, frame: frame)
        startCodons.forEach { at in
          let start = sequence.string.index(sequence.string.startIndex, offsetBy: at)
          let end = sequence.string.index(start, offsetBy: 2)
          let codon = String(sequence.string[start...end])

          let codonNode = XMLElement(name: "start-codon")
          codonNode.addAttribute(XMLNode.attribute(withName: "at", stringValue: String(at + 1)) as! XMLNode)
          codonNode.addAttribute(XMLNode.attribute(withName: "codon", stringValue: codon) as! XMLNode)
        frameNode.addChild(codonNode)
        }
      }
      
      // Stop codons
      if options.stopCodons {
        let stopCodons: [Int] = findStopCodons(sequence, frame: frame)
        stopCodons.forEach { at in
          let start = sequence.string.index(sequence.string.startIndex, offsetBy: at)
          let end = sequence.string.index(start, offsetBy: 2)
          let codon = String(sequence.string[start...end])

          let codonNode = XMLElement(name: "stop-codon")
          codonNode.addAttribute(XMLNode.attribute(withName: "at", stringValue: String(at + 1)) as! XMLNode)
          codonNode.addAttribute(XMLNode.attribute(withName: "codon", stringValue: codon) as! XMLNode)
          frameNode.addChild(codonNode)
        }
      }
      
      // Start -> Stop ORF
      let orfs: [(Int,Int)] = findStartStopORFs(sequence, frame: frame, options: options)
        orfs.forEach { (from, to) in
          let orfNode = XMLElement(name: "orf")
          orfNode.addAttribute(XMLNode.attribute(withName: "from", stringValue: String(from + 1)) as! XMLNode)
          orfNode.addAttribute(XMLNode.attribute(withName: "to", stringValue: String(to)) as! XMLNode)  // Don't include the STOP codon in the ORF
        frameNode.addChild(orfNode)
      }
    }
    return xml
  }
  
  func findStartCodons(_ sequence: Sequence, frame: Int) -> [Int] {
    var positions: [Int] = []
    
    let strand = Array(sequence.string)
    var i = frame - 1
    while i < strand.count - 2 {
      let codon = String(strand[i..<i+3])
      if codon == "ATG" {
        positions.append(i)
      }
      if codon == "AUG" {
        positions.append(i)
      }
      i += 3 // Next codon
    }
    
    return positions
  }
  
  func findStopCodons(_ sequence: Sequence, frame: Int) -> [Int] {
    var positions: [Int] = []
    
    let strand = Array(sequence.string)
    var i = frame - 1
    while i < strand.count - 2 {
      let codon = String(strand[i..<i+3])
      if codon == "TAA" || codon == "TGA" || codon == "TAG" {
        positions.append(i)
      }
      if codon == "UAA" || codon == "UGA" || codon == "UAG" {
        positions.append(i)
      }
      i += 3 // Next codon
    }
    
    return positions
  }
  
  func findStartStopORFs(_ sequence: Sequence, frame: Int, options: ORFOptions) -> [(Int,Int)] {
    
    let minORFSize: Int = options.minORFsize
    let internalATG: Bool = options.internalATG
    
    var orfs: [(Int,Int)] = []
    
    let strand = Array(sequence.string)
    var i = frame - 1
    while i < strand.count - 2 {
      let codon = String(strand[i..<i+3])
      if codon == "ATG" || codon == "AUG" {
        if let nextStop = findNextStopCodon(strand, from: i + 3) {
          if(Int(Double(nextStop - i + 1)/3.0) >= minORFSize) {
            orfs.append( (i, nextStop) )
          }
          if internalATG {
            i = nextStop
          }
        }
        
      }
      i += 3 // Next codon
    }
        
    return orfs
  }
  
  func findNextStopCodon(_ strand: [Character], from: Int) -> Int? {
    
    var stop: Int? = nil
    
    var i = from
    while i < strand.count - 2 {
      let codon = String(strand[i..<i+3])
      if codon == "TAA" || codon == "TGA" || codon == "TAG" || codon == "UAA" || codon == "UGA" || codon == "UAG" {
        stop = i
        break
      }
      i += 3
    }
    return stop
  }

}
