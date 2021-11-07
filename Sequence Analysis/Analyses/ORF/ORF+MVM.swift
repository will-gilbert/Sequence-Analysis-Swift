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
  
  var xmlDocument: XMLDocument? = nil   // Start, stop and ORF as XML
  var errorMsg: String? = nil
  var text: String = ""                 // Text contents for XML & JSON panels
  
  var givXMLDocument: XMLDocument? = nil
  var givXML: String = ""
  var givFrame: GIVFrame?

  func update(sequence: Sequence, options: ORFOptions) -> Void {
        
    var orf = OpenReadingFrame(sequence, options: options, viewModel: self)
    
    if sequence.isNucleic {
      orf.createXML()
      orf.validateXML()
      orf.transforXML()
      orf.createGIVFrame()
    }

    // Create the text for XML, JSON and GIV panels from the XML
    switch panel {
    case .XML: orf.xmlPanel()
    case .JSON: orf.jsonPanel()
    default: break
    }

  }
  
}

struct OpenReadingFrame {
  
  let sequence: Sequence
  let options: ORFOptions
  let viewModel: ORFViewModel

  init(_ sequence: Sequence, options: ORFOptions, viewModel: ORFViewModel) {
    self.sequence = sequence
    self.options = options
    self.viewModel = viewModel
  }

  mutating func createXML()  {

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
    viewModel.xmlDocument =  xml
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

  
  mutating func transforXML() {
    
    guard viewModel.xmlDocument != nil else {
      viewModel.errorMsg = "ORF XMLDocument is empty or was not created"
      return
    }
    
    let xsltfilename = "orf2giv"
    let xslt: String?
    
    if let filepath = Bundle.main.path(forResource: xsltfilename, ofType: "xslt") {
     do {
       xslt = try String(contentsOfFile: filepath)
     } catch {
       xslt = nil
       viewModel.errorMsg = "Could not load '\(xsltfilename).xslt': \(error.localizedDescription)"
       return
     }
    } else {
      xslt = nil;
      viewModel.errorMsg = "Could not find '\(xsltfilename).xslt'"
      return
    }

    if let xslt = xslt {
      do {
        
        let data = try viewModel.xmlDocument!.object(byApplyingXSLTString: xslt, arguments: nil)
        viewModel.givXMLDocument = data as? XMLDocument
        
        if let data = viewModel.givXMLDocument {
          let prettyXML = data.xmlData(options: .nodePrettyPrint)
          viewModel.givXML = String(data: prettyXML, encoding: .utf8) ?? "'\(xsltfilename).xslt' XSL transform could not be rendered (Pretty Print)"
        }
      } catch {
        viewModel.text = error.localizedDescription
      }
    } else {
      viewModel.text = "No contents created from '\(xsltfilename).xslt'"
    }
    
  }

  mutating func validateXML() {

    guard viewModel.xmlDocument != nil else {
      viewModel.errorMsg = "ORF XMLDocument is empty or was not created"
      return
    }
    
    do {
      let dtdFilepath = Bundle.main.path(forResource: "orf", ofType: "dtd")
      let dtdString = try String(contentsOfFile: dtdFilepath!)
      let dtd = try XMLDTD(data: dtdString.data(using: .utf8)!)
      dtd.name = "ORF"
      //print(dtd as Any)
      viewModel.xmlDocument!.dtd = dtd
    } catch {
      viewModel.errorMsg = "Could not load the 'orf.dtd' resource: \(error.localizedDescription)"
      return
    }

    do {
      try viewModel.xmlDocument!.validate()
    } catch {
      viewModel.errorMsg = "Could not validate ORF XML: \(error.localizedDescription)"
      return
    }

  }
  
  mutating func createGIVFrame() {
   
    guard viewModel.givXMLDocument != nil else {
      viewModel.errorMsg = "GIV XMLDocument is empty or was not created"
      return
    }

    let parser = GIV_XMLParser()

    parser.parse(viewModel.givXMLDocument!)
    viewModel.givFrame = parser.givFrame
//      extent = parser.extent
//      errorMsg = parser.errorMsg

  }
  
  
  
  // X M L  =====================================================================
  func xmlPanel() {
    
    guard viewModel.xmlDocument != nil else {
      viewModel.text = "XML Document is empty"
      return
    }
    
    if let xmlDocument = viewModel.xmlDocument {
      let data = xmlDocument.xmlData(options: .nodePrettyPrint)
      viewModel.text = String(data: data, encoding: .utf8) ?? "XML to text failed"
    }
  }

  
  // J S O N  ====================================================================
  func jsonPanel() {
    
    guard viewModel.xmlDocument != nil else {
      viewModel.text = "XML Document is empty"
      return
    }
    viewModel.text = "{}"

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
      viewModel.text = errorMsg!
      return
    }
    
    if let xslt = xslt {
        do {
          let data = try viewModel.xmlDocument!.object(byApplyingXSLTString: xslt, arguments: nil)
          if let data = data as? Data {
            if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
               let prettyJSON = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
              viewModel.text = String(decoding: prettyJSON, as: UTF8.self)
            } else {
              viewModel.text = "JSON data malformed"
            }
          }
        } catch {
          viewModel.text = error.localizedDescription
        }
      } else {
        viewModel.text = "No contents read for '\(xsltfilename).xslt"
      }
  }
  
  // G I V   X M L  =============================================================================================
/*
  func givxmlPanel() {

    guard viewModel.xmlDocument != nil else {
      viewModel.text = "XML Document is empty"
      return
    }

    let xsltfilename = "orf2giv"
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
      viewModel.text = errorMsg!
      return
    }

    viewModel.text = errorMsg != nil ? errorMsg! : ""

    if let xslt = xslt {
      do {
        let data = try viewModel.xmlDocument!.object(byApplyingXSLTString: xslt, arguments: nil)
        if let data = data as? XMLDocument {
          let prettyXML = data.xmlData(options: .nodePrettyPrint)
          viewModel.givXML = String(data: prettyXML, encoding: .utf8) ?? "XML Transform could not be rendered (Pretty Print)"
        }
      } catch {
        viewModel.text = error.localizedDescription
      }
    } else {
      viewModel.text = "No contents read for '\(xsltfilename).xslt'"
    }
    
  }
*/
  
}

