//
//  ORF+MVM.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 10/26/21.
//

import SwiftUI

// M O D E L  =====================================================================

struct ORFItem: Hashable {
  let id = UUID()
  var regex: String
  var count: Int = 0
  
  init(_ regex: String) {
    self.regex = regex
  }
  
  func hash(into hasher: inout Hasher) {
      hasher.combine(id)
  }
  
  static func ==(lhs: ORFItem, rhs: ORFItem) -> Bool {
      return lhs.id == rhs.id
  }
}

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
  var xmlDocument: XMLDocument? = nil   // RegEx matches as XML
  var text: String = ""                 // Text contents for XML, JSON & GIV XML panels
  
  func update(sequence: Sequence, options: ORFOptions) -> Void {
        
    var orf = OpenReadingFrame(sequence, options: options, viewModel: self)
    if sequence.isNucleic {
      orf.createXML()
    }

    // Create the text for XML, JSON and GIV panels from the XML
    switch panel {
    case .XML: orf.xmlPanel()
    case .JSON: orf.jsonPanel()
    case .GIV: orf.givxmlPanel()
    default:
      text = "Unimplemented"
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
    ORF_CreateXML().createXML(sequence, options: options, viewModel: viewModel)
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

    var text: String = errorMsg != nil ? errorMsg! : ""

    if let xslt = xslt {
      do {
        let data = try viewModel.xmlDocument!.object(byApplyingXSLTString: xslt, arguments: nil)
        if let data = data as? XMLDocument {
          let prettyXML = data.xmlData(options: .nodePrettyPrint)
          text = String(data: prettyXML, encoding: .utf8) ?? "XML Transform could not be rendered (Pretty Print)"
        }
      } catch {
        text = error.localizedDescription
      }
    } else {
      text = "No contents read for '\(xsltfilename).xslt'"
    }
    
    viewModel.text = text
  }


}

