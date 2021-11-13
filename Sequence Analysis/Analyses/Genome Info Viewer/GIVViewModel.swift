//
//  GIVViewModel.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 11/11/21.
//

import Foundation
import SwiftUI

// V I E W M O D E L  ==============================================================

class GIVViewModel: ObservableObject {
  
  // Panel types
  enum Panel: String, CaseIterable {
    case GRAPH = "GIV"
    case GIV = "GIV XML Editor"
    case DTD = "XML DTD"
    case COLORS = "GIV Colors"
  }

  @Published var panel: Panel = .GRAPH  // Currently selected panel
  @Published var givXML: String = ""  // GIV XMLDocument as pretty print string

  var errorMsg: String? = nil           // When things go wrong
  var givXMLDocument: XMLDocument? = nil // GIV XMLDocument used in Graph panel
  var givFrame: GIVFrame?                // GIV frame rendered in the Graph panel
  var extent: CGFloat?
  
  var dtdText: String? {
    get {
      do {
        let dtdFilepath = Bundle.main.path(forResource: "giv", ofType: "dtd")
        return try String(contentsOfFile: dtdFilepath!)
      } catch {
        return "Could not load the 'giv.dtd' resource: \(error.localizedDescription)"
      }
    }
  }
    
  
  func update() -> Void {
            
    self.errorMsg = nil
    self.givXMLDocument = nil
    self.givFrame = nil

    createXML()
    validateXML()
    createGIVFrame()
  }

  
  // MARK: C R E A T E  X M L
  func createXML()  {
    
    // Unwrap the optional class members
    guard givXML.isEmpty == false else { return }
    
    do {
      givXMLDocument = try XMLDocument(xmlString: givXML, options: [.documentValidate])
    } catch {
      errorMsg = "Could not create or validate GIV XML: \(error.localizedDescription)"
      givXMLDocument = nil
    }

  }
    
  // MARK: V A L I D A T E
  
  func validateXML() {
    
    guard self.errorMsg == nil else {
      return
    }

    guard self.givXMLDocument != nil else {
      self.errorMsg = "GIV XML is empty or was not created"
      return
    }
    
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

