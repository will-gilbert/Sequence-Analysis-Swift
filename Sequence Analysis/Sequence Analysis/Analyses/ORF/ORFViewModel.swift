//
//  ORF+MVM.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 10/26/21.
//

import SwiftUI

// V I E W M O D E L  ==============================================================

class ORFViewModel: ObservableObject {
  
  // Panel types
  enum Panel: String, CaseIterable {
    case GRAPH = "ORF"
    case XML = "XML"
    case JSON = "JSON"
    case GIV = "GIV XML"
  }

  @Published var panel: Panel = .GRAPH  // Currently selected panel
  
  var sequence: Sequence?
  var options: ORFOptions?

  
  var xmlDocument: XMLDocument? = nil   // Start, stop and ORF as XML
  var errorMsg: String? = nil           // When things go wrong
  var text: String?                     // Text contents for XML & JSON panels
  
  var givXMLDocument: XMLDocument? = nil // GIV XMLDocument used in Graph panel
  var givXML: String?                    // GIV XMLDocument as pretty print string
  var givFrame: GIVFrame?                // GIV frame rendered in the Graph panel

  func update(sequence: Sequence, options: ORFOptions) -> Void {
        
    self.sequence = sequence
    self.options = options
    
    self.xmlDocument = nil
    self.errorMsg = nil
    self.givXMLDocument = nil
    self.givFrame = nil

    if sequence.isNucleic {
      createXML()
      validateXML()
      transforXML()
      createGIVFrame()
    }

    // Create the text for XML, JSON and GIV panels from the XML
    switch panel {
    case .XML: xmlPanel()
    case .JSON: jsonPanel()
    default: break
    }
  }
  
  // MARK: C R E A T E  X M L
  func createXML()  {
    
    // Unwrap the optional class members
    guard let sequence = self.sequence else { return }
    guard let options = self.options else { return }

    let orf = XMLElement(name: "ORF")
    orf.addAttribute(XMLNode.attribute(withName: "sequence", stringValue: sequence.shortDescription) as! XMLNode)
    orf.addAttribute(XMLNode.attribute(withName: "length", stringValue: String(sequence.length)) as! XMLNode)
    
    let xml = XMLDocument(rootElement: orf)

    for frame in 1...3 {
    
      let frameNode = XMLElement(name: "frame")
      frameNode.addAttribute(XMLNode.attribute(withName: "frame", stringValue: "\(frame)") as! XMLNode)
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
    self.xmlDocument =  xml
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

  // MARK: V A L I D A T E
  
  func validateXML() {
    
    guard self.errorMsg == nil else {
      return
    }

    guard self.xmlDocument != nil else {
      self.errorMsg = "ORF XMLDocument is empty or was not created"
      return
    }
    
    do {
      let dtdFilepath = Bundle.main.path(forResource: "orf", ofType: "dtd")
      let dtdString = try String(contentsOfFile: dtdFilepath!)
      let dtd = try XMLDTD(data: dtdString.data(using: .utf8)!)
      dtd.name = "ORF"
      self.xmlDocument!.dtd = dtd
    } catch {
      self.errorMsg = "Could not load the 'orf.dtd' resource: \(error.localizedDescription)"
      self.xmlDocument = nil
      return
    }

    do {
      try self.xmlDocument!.validate()
    } catch {
      self.errorMsg = "Could not validate ORF XML: \(error.localizedDescription)"
      self.xmlDocument = nil
      return
    }

  }
  
  // MARK: T R A N S F O R M
  
  func transforXML() {
    
    guard self.errorMsg == nil else {
      return
    }
    
    guard self.xmlDocument != nil else {
      self.errorMsg = "ORF XMLDocument is empty or was not created"
      return
    }

    let xsltfilename = "orf2giv"
    let xslt: String?
    
    if let filepath = Bundle.main.path(forResource: xsltfilename, ofType: "xslt") {
     do {
       xslt = try String(contentsOfFile: filepath)
     } catch {
       xslt = nil
       self.errorMsg = "Could not load '\(xsltfilename).xslt': \(error.localizedDescription)"
       return
     }
    } else {
      xslt = nil;
      self.errorMsg = "Could not find '\(xsltfilename).xslt'"
      return
    }

    if let xslt = xslt {
      do {
        
        let data = try self.xmlDocument!.object(byApplyingXSLTString: xslt, arguments: nil)
        self.givXMLDocument = data as? XMLDocument
        
        // Validate GIV XMLDocument
        
//        do {
//          let dtdFilepath = Bundle.main.path(forResource: "giv", ofType: "dtd")
//          let dtdString = try String(contentsOfFile: dtdFilepath!)
//          let dtd = try XMLDTD(data: dtdString.data(using: .utf8)!)
//          dtd.name = "giv-frame"
//          self.givXMLDocument!.dtd = dtd
//        } catch {
//          self.errorMsg = "Could not load the 'giv.dtd' resource: \(error.localizedDescription)"
//          self.givXMLDocument = nil
//          return
//        }
//
//        do {
//          try self.givXMLDocument!.validate()
//        } catch {
//          self.errorMsg = "Could not validate GIV XML: \(error.localizedDescription)"
//          self.givXMLDocument = nil
//          return
//        }
        
        if let data = self.givXMLDocument {
          let prettyXML = data.xmlData(options: .nodePrettyPrint)
          self.givXML = String(data: prettyXML, encoding: .utf8) ?? "'\(xsltfilename).xslt' XSL transform could not be rendered (Pretty Print)"
        }
      } catch {
        self.errorMsg = error.localizedDescription
      }
    } else {
      self.errorMsg = "No contents created from '\(xsltfilename).xslt'"
    }
    
  }

  // MARK: G I V  F R A M E
  
  func createGIVFrame() {
   
    guard self.errorMsg == nil else {
      return
    }

    guard self.givXMLDocument != nil else {
      self.errorMsg = "GIV XMLDocument is empty or was not created"
      return
    }

    let parser = GIVXMLParser()
    parser.parse(self.givXMLDocument!)
    self.givFrame = parser.givFrame
  }
  
  
  
  // MARK: X M L  P A N E L
  func xmlPanel() {
    
    guard self.errorMsg == nil else {
      return
    }

    guard self.xmlDocument != nil else {
      self.errorMsg = "XML Document was not created or is empty"
      return
    }
    
    if let xmlDocument = self.xmlDocument {
      let data = xmlDocument.xmlData(options: .nodePrettyPrint)
      self.text = String(data: data, encoding: .utf8) ?? "XML to text failed"
    }
  }

  
  // MARK: J S O N  P A N E L
  func jsonPanel() {
    
    guard self.errorMsg == nil else {
      return
    }

    guard self.xmlDocument != nil else {
      self.errorMsg = "XML Document is empty"
      return
    }
    self.text = "{}"

    let xsltfilename = "xml2json"
    let xslt: String?
        
    if let filepath = Bundle.main.path(forResource: xsltfilename, ofType: "xslt") {
     do {
       xslt = try String(contentsOfFile: filepath)
     } catch {
       xslt = nil; errorMsg = error.localizedDescription
     }
    } else {
      xslt = nil;
      self.errorMsg = "Could not find '\(xsltfilename).xslt'"
      self.text = nil
    }
    
    if let xslt = xslt {
        do {
          let data = try self.xmlDocument!.object(byApplyingXSLTString: xslt, arguments: nil)
          if let data = data as? Data {
            if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
               let prettyJSON = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
              self.text = String(decoding: prettyJSON, as: UTF8.self)
            } else {
              self.text = "JSON data malformed"
            }
          }
        } catch {
          self.errorMsg = error.localizedDescription
        }
      } else {
        self.errorMsg = "No contents read for '\(xsltfilename).xslt"
      }
  }
    
}

