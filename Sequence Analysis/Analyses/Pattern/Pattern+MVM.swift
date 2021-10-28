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
  
  let sequence: Sequence
  @Published var panel: Panel = .GRAPH             // Currently selected panel
  @Published var items: [PatternItem] = []         // Collection of RegEx patterns
  var xmlDocument: XMLDocument? = nil              // RegEx matches as XML

  init(sequence: Sequence) {
    self.sequence = sequence
  }

  // Create the text for XML, JSON and GIV panels from the XML
  var text: String {
    
    get {
      guard items.isEmpty == false else {
        return "No Patterns listed"
      }

      if xmlDocument == nil {
        update()
      }
      
      switch panel {
      case .XML: return xmlPanel()
      case .JSON: return jsonPanel()
      case .GIV: return givxmlPanel()
      default: return "Unimplemented"
      }
    }
  }
  
  func addItem(pattern: String) {
    items.append(PatternItem(pattern))
    update()
  }
  
  func addItemPattern(index: Int, pattern: String) {
    items[index].regex = pattern
    update()
  }
  
  func update() -> Void {
    // Update the Pattern XML when the view is updated
    var pattern = Pattern(sequence, viewModel: self)
    pattern.createXML()
  }
  
  func showRegExLegend() {
    
    let window: NSWindow =  NSWindow(
      contentRect: CGRect(x: 0, y: 0, width: 0, height: 0),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.center()
    window.title = "Regular Expressions (RegEx) in Sequences"
    let contents = InfoWindowContent(window: window)
    let windowController = WindowController(window: window, contents: AnyView(contents))
    windowController.showWindow(self)
  }

  struct InfoWindowContent: View {
   
    var window: NSWindow

    var body: some View {
      VStack {
        HStack{
          Text(legend)
            .font( .system(size: 14, weight: .regular, design: .monospaced) )
        }

        Spacer()
        
        // Button panel ===============================
        Section {
          HStack {
            Spacer()

            // O K  =--------------------------------
            Button(action: {
              window.close()
            }) {
              Text("Done")
            }
            .keyboardShortcut(.defaultAction)
          }
        }
        // Button panel ===============================

      }
      .padding(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
      .frame(width: 600, height: 250)
    }
    
    var legend: String = """
        Example                  : Meaning
        -------------------------:-----------------------------------
        ATG                      : A literal string e.g. Start codon
        TAG|TAA|TGA              : Any one; e.g. any Stop codon
        C{2}                     : Two 'C's
        C{2,}                    : Two or more 'C's
        C{2,5}                   : Two to five 'C's
        (CG){2,}                 : Two or more 'CG' pairs
        A.T.                     : Dot matches any character
        ATG(.{3})*?(TAG|TAA|TGA) : An Open Reading Frame
        """
  }

  
  
  
  // X M L  =====================================================================
  func xmlPanel() -> String {
    
    guard xmlDocument != nil else {
      return("XML Document is empty")
    }
    
    var text: String = "XML to text failed"
    
    if let xmlDocument = xmlDocument {
      let data = xmlDocument.xmlData(options: .nodePrettyPrint)
      text = (String(data: data, encoding: .utf8) ?? "XML to text failed")
    }
    
    return text
  }
  
  
  // J S O N  ====================================================================
  func jsonPanel() -> String {
    
    guard xmlDocument != nil else {
      return("XML Document is empty")
    }
    
    var text = "{}"

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
      return errorMsg!
    }
    
    if let xslt = xslt {
        do {
          let data = try xmlDocument!.object(byApplyingXSLTString: xslt, arguments: nil)
          if let data = data as? Data {
            if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
               let prettyJSON = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
              return(String(decoding: prettyJSON, as: UTF8.self))
            } else {
              text = "JSON data malformed"
            }
          }
        } catch {
          text = error.localizedDescription
        }
      } else {
        text = "No contents read for '\(xsltfilename).xslt"
      }
      return text
  }
  
  // G I V   X M L  ==================================================================
  func givxmlPanel() -> String {
    return("GIVXMLView")
  }

}


struct Pattern {
  
  let sequence: Sequence
  let viewModel: PatternViewModel

  init(_ sequence: Sequence, viewModel: PatternViewModel) {
    self.sequence = sequence
    self.viewModel = viewModel
  }

  mutating func createXML() {
    Pattern_CreateXML().createXML(sequence, viewModel: viewModel)
  }
  

}
