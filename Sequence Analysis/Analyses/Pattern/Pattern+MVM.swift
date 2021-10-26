//
//  Pattern.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 10/25/21.
//

import SwiftUI

// M O D E L  =====================================================================

struct PatternItem: Hashable {
  let id = UUID()
  var regex: String
  var count: Int = 0
  
  init(_ regex: String) {
    self.regex = regex
  }
  
  func hash(into hasher: inout Hasher) {
      hasher.combine(id)
  }
  
  static func ==(lhs: PatternItem, rhs: PatternItem) -> Bool {
      return lhs.id == rhs.id
  }
}

// V I E W M O D E L  ==============================================================
class PatternViewModel: ObservableObject {
  
  // Panel types
  enum Panel: String, CaseIterable {
    case GRAPH = "Pattern"
    case XML = "XML"
    case JSON = "JSON"
    case GIV = "GIV XML"
  }
  
  @Published var items: [PatternItem] = []         // Collection of RegEx patterns
  @Published var selectedItem: PatternItem? = nil  // Editing an existing pattern
  @Published var panel: Panel = .GRAPH             // Currently selected panel
  @Published var xmlDocument: XMLDocument? = nil   // RegEx matches as XML
  @Published var text: String = ""                 // Text for XML, JSON & GIV XML panels
}


struct Pattern {
  
  let sequence: Sequence
  let viewModel: PatternViewModel

  init(_ sequence: Sequence, viewModel: PatternViewModel) {
    self.sequence = sequence
    self.viewModel = viewModel
  }

  mutating func createXML() {
    return Pattern_CreateXML().createXML(sequence, viewModel: viewModel)
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
  
  // G I V   X M L  ==================================================================
  func givxmlPanel() {
    viewModel.text = "GIVXMLView"
  }

}
