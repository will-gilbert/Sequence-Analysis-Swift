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
  
  @Published var panel: Panel = .GRAPH             // Currently selected panel
  @Published var items: [PatternItem] = []         // Collection of RegEx patterns

  var sequence: Sequence
  
  var xmlDocument: XMLDocument?          // Start, stop and ORF as XML
  var errorMsg: String?
  
  var givXMLDocument: XMLDocument? = nil // GIV XMLDocument used in Graph panel
  var givXML: String?                    // GIV XMLDocument as pretty print string
  var givFrame: GIVFrame?                // GIV frame rendered in the Graph panel

  init(sequence: Sequence) {
    self.sequence = sequence
  }

  // Create the text for XML, JSON and GIV panels from the XML
  var text: String? {
    
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
      case .GIV: return self.givXML
      default: return "Unimplemented"
      }
    }
  }
  
  func update() -> Void {
  
    self.xmlDocument = nil
    self.errorMsg = nil
    self.givXMLDocument = nil
    self.givFrame = nil
    
    guard items.isEmpty == false else {
      self.errorMsg = "No Patterns listed"
      return
    }

    createXML()
    validateXML()
    transformXML()
    createGIVFrame()
    
  }


  
  
  func addItem(pattern: String) {
    items.append(PatternItem(pattern))
    update()
  }
  
  func addItemPattern(index: Int, pattern: String) {
    items[index].regex = pattern
    update()
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

  // MARK: C R E A T E X M L
  func createXML() -> Void {
        
    let root = XMLElement(name: "PATTERN")
    root.addAttribute(XMLNode.attribute(withName: "sequence", stringValue: sequence.shortDescription) as! XMLNode)
    root.addAttribute(XMLNode.attribute(withName: "length", stringValue: String(sequence.length)) as! XMLNode)
    
    let xml = XMLDocument(rootElement: root)
    let strand = sequence.string
    
    for item in self.items {
      
      let pattern = item.regex.filter { !" \t".contains($0) }
            
      do {
        let regex = try NSRegularExpression(pattern: pattern)
        let results = regex.matches(in: strand, range: NSRange(strand.startIndex..., in: strand))

        let patternNode = XMLElement(name: "pattern")
        patternNode.addAttribute(XMLNode.attribute(withName: "regex", stringValue: item.regex) as! XMLNode)
        patternNode.addAttribute(XMLNode.attribute(withName: "count", stringValue: String(results.count)) as! XMLNode)
        root.addChild(patternNode)
        
        // Update the pattern count in the view model
        let index = self.items.firstIndex(where: { $0.id == item.id })!
        self.items[index].count = results.count

        for result in results {

          let matchNode = XMLElement(name: "match")
          let range = Range(result.range, in: strand)
          let label = String(strand[range!]).truncated(limit: 15, position: .middle)
          let from: Int = result.range.location
          let to: Int = from + result.range.length - 1
          
          // Convert to one-based sequence numbering
          matchNode.addAttribute(XMLNode.attribute(withName: "label", stringValue: label ) as! XMLNode)
          matchNode.addAttribute(XMLNode.attribute(withName: "from", stringValue: String(from + 1)) as! XMLNode)
          matchNode.addAttribute(XMLNode.attribute(withName: "to", stringValue: String(to + 1)) as! XMLNode)
          patternNode.addChild(matchNode)
        }
        
      } catch {
        self.errorMsg = "'\(pattern) is not a valid expression; RE: RegEx for help"
        self.xmlDocument = nil
        return
      }
    }
      
    self.xmlDocument =  xml
  }

  
  
  
  // MARK: V A L I D A T E
  func validateXML() {
 
    guard self.errorMsg == nil else {
      return
    }

    guard self.xmlDocument != nil else {
      self.errorMsg = "Pattern XMLDocument is empty or was not created"
      return
    }
    
    do {
      let dtdFilepath = Bundle.main.path(forResource: "pattern", ofType: "dtd")
      let dtdString = try String(contentsOfFile: dtdFilepath!)
      let dtd = try XMLDTD(data: dtdString.data(using: .utf8)!)
      dtd.name = "PATTERN"
      self.xmlDocument!.dtd = dtd
    } catch {
      self.errorMsg = "Could not load the 'pattern.dtd' resource: \(error.localizedDescription)"
      self.xmlDocument = nil
    return
    }

    do {
      try self.xmlDocument!.validate()
    } catch {
      self.errorMsg = "Could not validate Pattern XML: \(error.localizedDescription)"
      self.xmlDocument = nil
      return
    }

  }
  
  // MARK: T R A N S F O R M
  
  func transformXML() {
  
    guard self.errorMsg == nil else {
      return
    }

    guard self.xmlDocument != nil else {
      self.errorMsg = "Pattern XMLDocument is empty or was not created"
      return
    }
    
    let xsltfilename = "pattern2giv"
    let xslt: String?
    
    if let filepath = Bundle.main.path(forResource: xsltfilename, ofType: "xslt") {
     do {
       xslt = try String(contentsOfFile: filepath)
     } catch {
       xslt = nil
       self.errorMsg = "Could not load '\(xsltfilename).xslt': \(error.localizedDescription)"
       self.xmlDocument = nil
       return
     }
    } else {
      xslt = nil;
      self.errorMsg = "Could not find '\(xsltfilename).xslt'"
      self.xmlDocument = nil
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
          self.xmlDocument = nil
          return
        }

        do {
          try self.givXMLDocument!.validate()
        } catch {
          self.errorMsg = "Could not validate GIV XML: \(error.localizedDescription)"
          self.xmlDocument = nil
          return
        }

        if let data = self.givXMLDocument {
          let prettyXML = data.xmlData(options: .nodePrettyPrint)
          self.givXML = String(data: prettyXML, encoding: .utf8) ?? "'\(xsltfilename).xslt' XSL transform could not be rendered (Pretty Print)"
        }
      } catch {
        self.errorMsg = error.localizedDescription
        self.xmlDocument = nil
      }
    } else {
      self.errorMsg = "No contents created from '\(xsltfilename).xslt'"
      self.xmlDocument = nil
    }
    
  }

  // MARK: G I V F R A M E
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

  // MARK: X M L
  func xmlPanel() -> String? {
 
    guard self.errorMsg == nil else {
      return nil
    }

    guard xmlDocument != nil else {
      return nil
    }
    
    var text: String?
      
    if let xmlDocument = xmlDocument {
      let data = xmlDocument.xmlData(options: .nodePrettyPrint)
      text = (String(data: data, encoding: .utf8) ?? "XML to text failed")
    }
    
    return text
  }
  // MARK:  J S O N
  func jsonPanel() -> String? {
  
    guard self.errorMsg == nil else {
      return nil
    }

    guard xmlDocument != nil else {
      return nil
    }
    
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
      return nil
    }
    
    var text: String?
    
    if let xslt = xslt {
        do {
          let data = try xmlDocument!.object(byApplyingXSLTString: xslt, arguments: nil)
          if let data = data as? Data {
            if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
               let prettyJSON = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
              text = String(decoding: prettyJSON, as: UTF8.self)
            } else {
              self.errorMsg = "JSON data malformed"
            }
          }
        } catch {
          self.errorMsg = error.localizedDescription
          return nil
        }
      } else {
        self.errorMsg = "No contents read for '\(xsltfilename).xslt"
        return nil
      }
    
    return text
  }


}

