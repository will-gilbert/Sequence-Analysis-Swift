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
  var text: String = ""                 // Text contents for XML & JSON panels
  
  var givXMLDocument: XMLDocument? = nil // GIV XMLDocument used in Graph panel
  var givXML: String = ""                // GIV XMLDocument as pretty print string
  var givFrame: GIVFrame?                // GIV frame rendered in the Graph panel

  func update(sequence: Sequence, options: ORFOptions) -> Void {
        
    self.sequence = sequence
    self.options = options

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

  
  func transforXML() {
    
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
        
        if let data = self.givXMLDocument {
          let prettyXML = data.xmlData(options: .nodePrettyPrint)
          self.givXML = String(data: prettyXML, encoding: .utf8) ?? "'\(xsltfilename).xslt' XSL transform could not be rendered (Pretty Print)"
        }
      } catch {
        self.text = error.localizedDescription
      }
    } else {
      self.text = "No contents created from '\(xsltfilename).xslt'"
    }
    
  }

  func validateXML() {

    guard self.xmlDocument != nil else {
      self.errorMsg = "ORF XMLDocument is empty or was not created"
      return
    }
    
    do {
      let dtdFilepath = Bundle.main.path(forResource: "orf", ofType: "dtd")
      let dtdString = try String(contentsOfFile: dtdFilepath!)
      let dtd = try XMLDTD(data: dtdString.data(using: .utf8)!)
      dtd.name = "ORF"
      //print(dtd as Any)
      self.xmlDocument!.dtd = dtd
    } catch {
      self.errorMsg = "Could not load the 'orf.dtd' resource: \(error.localizedDescription)"
      return
    }

    do {
      try self.xmlDocument!.validate()
    } catch {
      self.errorMsg = "Could not validate ORF XML: \(error.localizedDescription)"
      return
    }

  }
  
  func createGIVFrame() {
   
    guard self.givXMLDocument != nil else {
      self.errorMsg = "GIV XMLDocument is empty or was not created"
      return
    }

    let parser = GIV_XMLParser()

    parser.parse(self.givXMLDocument!)
    self.givFrame = parser.givFrame
//      extent = parser.extent
//      errorMsg = parser.errorMsg

  }
  
  
  
  // X M L  =====================================================================
  func xmlPanel() {
    
    guard self.xmlDocument != nil else {
      self.text = "XML Document is empty"
      return
    }
    
    if let xmlDocument = self.xmlDocument {
      let data = xmlDocument.xmlData(options: .nodePrettyPrint)
      self.text = String(data: data, encoding: .utf8) ?? "XML to text failed"
    }
  }

  
  // J S O N  ====================================================================
  func jsonPanel() {
    
    guard self.xmlDocument != nil else {
      self.text = "XML Document is empty"
      return
    }
    self.text = "{}"

    let xsltfilename = "xml2json"
    let xslt: String?
    var errorMsg: String? = nil
        
    if let filepath = Bundle.main.path(forResource: xsltfilename, ofType: "xslt") {
     do {
       xslt = try String(contentsOfFile: filepath)
     } catch {
       xslt = nil; errorMsg = error.localizedDescription
     }
    } else {
      xslt = nil;
      errorMsg = "Could not find '\(xsltfilename).xslt'"
    }
    
    if errorMsg != nil {
      self.text = errorMsg!
      return
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
          self.text = error.localizedDescription
        }
      } else {
        self.text = "No contents read for '\(xsltfilename).xslt"
      }
  }
    
}

