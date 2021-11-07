//
//  XMLView.swift
//  SA-GIV (iOS)
//
//  Created by Will Gilbert on 11/3/21.
//

import Foundation
import SwiftUI


struct XMLView: View {

  @State var scale: Double = 1.0

  let viewModel: GIVViewModel = GIVViewModel()
  var givFrame: GIVFrame?
  var extent: Int?
  var errorMsg: String?

  init() {
    let parser = GIV_XMLParser()
    
    if let xmlDocument = viewModel.getGIVDocument() {
      parser.parse(xmlDocument)
      givFrame = parser.givFrame
      extent = parser.extent
      errorMsg = parser.errorMsg
    } else if viewModel.errorMsg != nil {
        givFrame = nil
        extent = nil
        errorMsg = viewModel.errorMsg
    }
    
  }
  
  var body: some View {
    
    let extent: CGFloat = givFrame?.extent ?? CGFloat(0)
    let height: CGFloat = givFrame?.size.height ?? CGFloat(0)
    let fitToWidth: CGFloat = extent * scale

    // Was there an error message from the Parser
    if let errorMsg = self.errorMsg {
      return AnyView (
        VStack {
          Text(errorMsg)
        }.frame(width: 500, height: 100, alignment: .center)
      )
    }
      
    if givFrame == nil {
      return AnyView (
        VStack {
          Text("A GIV diagram could not be generated")
        }.frame(width: 500, height: 100, alignment: .center)
      )
    }

    
    return AnyView (
      GeometryReader { geometry in
   
        let windowWidth = geometry.size.width
        var minScale: Double = (windowWidth/Double(extent)) < 1.0 ? 1.0 : windowWidth/Double(extent)

        VStack(alignment: .leading) {
          
          VStack(alignment: .center) {
            Text("GIV Frame Zooming")
              .font(.title)
            Text(String("    Window: \(F.f(windowWidth, decimal: 0)) pixels"))
            Text(String("     Scale: \(F.f(scale, decimal: 3)) pixel/bp"))
            Text(String("    Extent: \(F.f(extent, decimal: 0)) bp"))
            Text(String("View Width: \(F.f(extent * scale, decimal: 0)) pixels"))
            Slider(
              value: $scale,
              in: minScale...10.0
            )
          }
          
          // SCROLLVIEW ----------------------------------------------------------
          GeometryReader { g in
            ScrollView( [.vertical, .horizontal], showsIndicators: true) {
             
              VStack(spacing: 0) {
                GIVFrameView(givFrame!, scale: scale)
              }.frame(width: fitToWidth, height: height)
              
              // Hacky way to force the GIV Panels to the top
              if g.size.height > height {
                Spacer()
                .frame(height: g.size.height - height)
              }

            }
          }
          // SCROLLVIEW ----------------------------------------------------------
          
        }.onAppear {
          let windowWidth = geometry.size.width
          minScale = (windowWidth/Double(extent)) < 1.0 ? 1.0 : windowWidth/Double(extent)
          scale = minScale
        }.onChange(of: geometry.frame(in: .global).width) { value in
          minScale = value/Double(extent)
          scale = scale > minScale ? scale : minScale
        }
      }
    )
  }

}

class GIVViewModel {
  
  var errorMsg: String?
  
  func getGIVDocument() -> XMLDocument? {
    
    let givfilename = "ORF2.giv"
    let xmlString: String?
        
    if let filepath = Bundle.main.path(forResource: givfilename, ofType: "xml") {
     do {
       xmlString = try String(contentsOfFile: filepath)
     } catch {
       xmlString = nil; print(error.localizedDescription)
     }
    } else {
      xmlString = nil;
      errorMsg = "Could not find '\(givfilename).xml' resource"
      return nil
    }
    
    if let xmlString = xmlString {
      do {
        
        let xmlDocument = try XMLDocument(xmlString: xmlString, options: [.documentValidate])
        
        do {
          let dtdFilepath = Bundle.main.path(forResource: "giv", ofType: "dtd")
          let dtdString = try String(contentsOfFile: dtdFilepath!)
          let dtd = try XMLDTD(data: dtdString.data(using: .utf8)!)
          dtd.name = "giv-frame"
          //print(dtd as Any)
          xmlDocument.dtd = dtd
        } catch {
          errorMsg = "Could not load the 'giv.dtd' resource: \(error.localizedDescription)"
          return nil

        }
        
        do {
          try xmlDocument.validate()
        } catch {
          errorMsg = "Could not validate GIV XML: \(error.localizedDescription)"
          return nil
        }
                
        return xmlDocument
      } catch {
        errorMsg = "Could not create or validate XML Docment: \(error.localizedDescription)"
        return nil
      }
    } else {
      return nil
    }
  }
  
}


struct Stack<Element> {
  fileprivate var array: [Element] = []
  
  func count() -> Int {
    return array.count
  }
  
  func isEmpty() -> Bool {
    return array.isEmpty
  }

  mutating func push(_ element: Element) {
    array.append(element)
  }
  
  mutating func pop() -> Element? {
    return array.popLast()
  }
  
  func peek() -> Element? {
    return array.last
  }
}

class GIV_XMLParser : NSObject, XMLParserDelegate {
      
  let defaultStyle: ElementStyle = ElementStyle()
  var elementStyles: [String : ElementStyle] = [:]
  var depth = 0
  var depthIndent: String {
      return [String](repeating: "  ", count: self.depth).joined()
  }

  var givFrame: GIVFrame?
  var givPanel: GIVPanel?
  var mapPanel: MapPanel?
  var elementStyle: ElementStyle?
  var foundCharacters: String?
  var mosaicStack: Stack<Mosaic> = Stack<Mosaic>()
  var glyph: Glyph?
  
  var extent: Int?
  var errorMsg: String?

  func parse(_ xmlDocument: XMLDocument) {
    let parser = XMLParser(data: xmlDocument.xmlData)
    parser.delegate = self
    
    let success = parser.parse()
    if success == false {
      //print("error:\(parser.parserError!)")
      errorMsg = "GIV Parser Error: \(parser.parserError!)"
    }
  }
  
  // Start XML Element
  func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

    print("\(self.depthIndent)\(elementName)")
    self.depth += 1
    
    if errorMsg != nil { return }

    switch elementName {
    case "giv-frame": startGIVFrame(attributeDict)
    case "giv-panel": startGIVPanel(attributeDict)
    case "map-panel": startMapPanel(attributeDict)
    case "style-for-type": startStyleForType(attributeDict)
    case "group": startGroup(attributeDict)
    case "element": startElement(attributeDict)
    default: break
    }
  }
  
  func parser(_ parser: XMLParser, foundCharacters string: String) {
    self.foundCharacters = string
  }

  
  // End XML Element
  func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
      
    self.depth -= 1

    // An error has occured don't finish the current element
    guard errorMsg == nil else { return }
    
    switch elementName {
    case "giv-frame": endGIVFrame()
    case "giv-panel": endGIVPanel()
    case "map-panel": endMapPanel()
    case "style-for-type": endStyleForType()
    case "group": endGroup()
    case "element": endElement()
    default: break
    }
  }

  private func startGIVFrame(_ attributes: [String : String]) -> Void {
   
    if let string = attributes["extent"] {
      if let intValue = Int(string) {
        self.extent = intValue
      } else {
        self.errorMsg = "The XML element 'giv-frame' has an invalid 'extent' attribute of '\(string)'"
        self.givFrame = nil
      }
    } else {
      self.errorMsg = "The XML element 'giv-frame' has no 'extent' attribute"
      self.givFrame = nil
      return
    }
    
    var hasRuler: Bool = true
    if let string = attributes["ruler"] {
      if let boolValue = Bool(string) {
        hasRuler = boolValue
      }
    }
    
    let frgColor: String = attributes["frg-color"] ?? "Black"
    let bkgColor: String = attributes["bkg-color"] ?? "AGA 01"

    if let extent = self.extent {
      self.givFrame = GIVFrame(extent: extent, hasRuler: hasRuler, bkgColor: bkgColor, frgColor: frgColor)
    }
    
  }
  
  // On an error, set the GIV Frame to nil so that
  //  the error message will be used in the view.
  private func endGIVFrame() {
    if self.errorMsg != nil {
      givFrame = nil
    }
  }
  
  
  private func startGIVPanel(_ attributes: [String : String]) -> Void {
    
    guard errorMsg == nil else { return }
        
    let bkgColor: String = attributes["bkg-color"] ?? "None"
    let label: String? = attributes["label"]

    if let extent = self.extent {
      self.givPanel = GIVPanel(extent: extent, color: bkgColor, label: label)
    } else {
      self.errorMsg = "The XML element 'giv-panel'; 'extent' is invalid or missing"
      self.givFrame = nil
      return
    }
  }
  
  private func endGIVPanel() {
    if self.givFrame != nil, let givPanel = self.givPanel {
      self.givFrame!.addGIVPanel(givPanel)
      self.givPanel = nil
    }

  }
  
  private func startMapPanel(_ attributes: [String : String]) -> Void {
   
    let bkgColor: String = attributes["bkg-color"] ?? "AGA 01"
    let buoyancyString: String = attributes["buoyancy"] ?? "Floating"
    let hGap: CGFloat = CGFloat(Int(attributes["h-gap"] ?? "3") ?? 3)
    let vGap: CGFloat = CGFloat(Int(attributes["v-gap"] ?? "3") ?? 3)
    
    var buoyancy: Buoyancy
    switch buoyancyString.lowercased() {
    case "sinking":
      buoyancy =  .sinking
    case "floating":
      buoyancy = .floating
    case "stackup":
      buoyancy = .stackUp
    case "stackdown":
      buoyancy = .stackDown
    default:
      buoyancy = .sinking
    }
    
    let tileLayout = TileLayout(buoyancy: buoyancy, hGap: hGap, vGap: vGap)
    if self.extent != nil {
      self.mapPanel = MapPanel(extent: self.extent!, layout: tileLayout, color: bkgColor)
    }
  }

  private func endMapPanel() {
    
    if self.givPanel != nil {
      self.givPanel!.addMapPanel(mapPanel!)
    } else if self.givFrame != nil {
      self.givFrame!.addMapPanel(mapPanel!)
    }
    self.mapPanel = nil
    elementStyles.removeAll()
  }
  
  private func startStyleForType(_ attributes: [String : String]) -> Void {
    
    self.elementStyle = ElementStyle()

    self.elementStyle!.barHeight = Int(attributes["bar-height"] ?? "20") ?? 20
    self.elementStyle!.barBorder = Int(attributes["bar-border"] ?? "1") ?? 1
    self.elementStyle!.barColor = attributes["bar-color"] ?? "Green"
    self.elementStyle!.lblPosition = attributes["lbl-position"] ?? "Inside"
    self.elementStyle!.lblSize = Int(attributes["font-size"] ?? "10") ?? 15
    self.elementStyle!.lblColor = attributes["lbl-color"] ?? "Black"
  }
  
  private func endStyleForType() {
    
    if self.elementStyle != nil {
      if let string = self.foundCharacters {
        self.elementStyle!.name = string
      } else {
        self.elementStyle!.name = "default"
      }
      
      self.elementStyles[self.elementStyle!.name] = self.elementStyle
      self.elementStyle = nil
    }
  }

  // GIV 'Mosaic' tile
  private func startGroup(_ attributes: [String : String]) -> Void {
  
    
    let label: String? = attributes["label"]
    let bkgColor: String = attributes["bkg-color"] ?? "None"
    let buoyancy: String = attributes["buoyancy"] ?? "Floating"
    let hGap: Int = Int(attributes["h-gap"]!)!
    let vGap: Int = Int(attributes["v-gap"]!)!
    
    self.mosaicStack.push(Mosaic(label: label, buoyancy: buoyancy, color: bkgColor, vGap: vGap, hGap: hGap))
  }
  
  private func endGroup() {
    let mosaic = mosaicStack.pop()
    if mosaicStack.isEmpty() == false {
      let parentMosaic = mosaicStack.peek()
      parentMosaic?.addTile(mosaic!)
    } else if self.mapPanel != nil {
      self.mapPanel!.addTile(mosaic!)
   }
  }

  private func startElement(_ attributes: [String : String]) -> Void {
    
    // Extract the attributes; Use defaults if missing
    let label: String = attributes["label"] ?? ""
    let type: String = attributes["type"] ?? "default"
    
    var from: Int?
    if let fromAttr: String = attributes["from"] {
      if let value = Int(fromAttr) {
          from = value
      } else {
        errorMsg = "Element '\(label)' has an invalid 'from' attribute of '\(fromAttr)'"
        return
      }
    } else {
      self.errorMsg = "Element '\(label)' has no 'from' attribute"
      return
    }
    
    var to: Int?
    if let toAttr: String = attributes["to"] {
      if let value = Int(toAttr) {
          to = value
      } else {
        errorMsg = "Element '\(label)' has an invalid 'to' attribute of '\(toAttr)'"
        return
      }
    } else {
      self.errorMsg = "Element '\(label)' has no 'to' attribute"
      return
    }

    // Instance an element
    let element = Element(label: label, start: from!, stop: to!)
    
    // Get its rendering style; 'default' if not found
    var elementStyle = elementStyles[type]
    if elementStyle == nil {
      elementStyle = defaultStyle
    }
    
    // Encapsulate the element in a Glyph
    self.glyph = Glyph(element: element, style: elementStyle!)
  }

  private func endElement() {
    // Add this element to either a 'Group' or the 'Map Panel'
    if mosaicStack.peek() != nil {
      let mosaic = mosaicStack.peek()
      mosaic!.addTile(self.glyph!)
    } else if self.mapPanel != nil {
      self.mapPanel!.addTile(self.glyph!)
    }
    // Handled this glyph/element; Set up for the next one
    self.glyph = nil
  }

  
}
