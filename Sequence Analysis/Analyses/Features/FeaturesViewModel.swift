//
//  FeaturesViewModel.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 11/14/21.
//

import SwiftUI

class FeaturesViewModel: ObservableObject {
  
  // Panel types
  enum Panel: String, CaseIterable {
    case GRAPH = "Features"
    case XML = "XML"
    case GIV = "GIV XML"
  }

  @Published var panel: Panel = .GRAPH  // Currently selected panel

  var xmlDocument: XMLDocument? = nil   // Start, stop and ORF as XML
  var errorMsg: String? = nil           // When things go wrong
  var text: String?                     // Text contents for XML panel
  
  var givXMLDocument: XMLDocument? = nil // GIV XMLDocument used in Graph panel
  var givXML: String?                    // GIV XMLDocument as pretty print string
  var givFrame: GIVFrame?                // GIV frame rendered in the Graph panel
  var extent: CGFloat?

  func update() -> Void {
        
    
    self.errorMsg = nil
    self.givXMLDocument = nil
    self.givFrame = nil

    transforXML()
    createGIVFrame()

    // Create the text for XML, JSON and GIV panels from the XML
    switch panel {
    case .XML: xmlPanel()
    default: break
    }

  }

  // MARK: X M L  P A N E L
  func xmlPanel() {
    
    guard self.errorMsg == nil else {
      return
    }

    guard self.xmlDocument != nil else {
      self.errorMsg = "Features document was not created or is empty"
      return
    }
    
    if let xmlDocument = self.xmlDocument {
      let data = xmlDocument.xmlData(options: .nodePrettyPrint)
      self.text = String(data: data, encoding: .utf8) ?? "XML to text failed"
    }
  }

  
  // MARK: T R A N S F O R M
  
  func transforXML() {
    
    guard self.errorMsg == nil else {
      return
    }
    
    guard self.xmlDocument != nil else {
      self.errorMsg = "Features XMLDocument is empty or was not created"
      return
    }

    let xsltfilename = "genbank"
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
        
        do {
          let dtdFilepath = Bundle.main.path(forResource: "giv", ofType: "dtd")
          let dtdString = try String(contentsOfFile: dtdFilepath!)
          let dtd = try XMLDTD(data: dtdString.data(using: .utf8)!)
          dtd.name = "giv-frame"
          self.givXMLDocument!.dtd = dtd
        } catch {
          self.errorMsg = "Could not load the 'giv.dtd' resource: \(error.localizedDescription)"
          self.givXMLDocument = nil
          return
        }

        do {
          try self.givXMLDocument!.validate()
        } catch {
          self.errorMsg = "Could not validate GIV XML: \(error.localizedDescription)"
          self.givXMLDocument = nil
          return
        }
        
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
      self.errorMsg = "GIV XML is empty"
      return
    }

    let parser = GIVXMLParser()
    parser.parse(self.givXMLDocument!)
    
    // Save the 'extent' for use in the View
    if let extent: Int = parser.extent {
      self.extent = CGFloat(extent)
    }
    
    if let givFrame = parser.givFrame {
      self.givFrame = givFrame
    }
  }

  
  
}
