//
//  PatternParser.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 10/16/21.
//


import Foundation

class Pattern_XMLParser: NSObject, XMLParserDelegate {

  var defaultStyle: ElementStyle
  var elementStyles: [String : ElementStyle] = [:]
  let extent: Int
  
//  var mapPanel: MapPanel
//  var givPanel: GIVPanel
  
  var mapPanels: [MapPanel] = []
  var givPanels: [GIVPanel] = []
  var theFrame: GIVFrame

  var givFrame: GIVFrame {
    get {
      for (i, mapPanel) in mapPanels.enumerated() {
        givPanels[i].addMapPanel(mapPanel)
        theFrame.addGIVPanel(givPanels[i])
      }
      
      return theFrame
    }
  }

  
  init(extent: Int) {
    self.extent = extent
    
    defaultStyle = ElementStyle()
    defaultStyle.name = "Default" 
    defaultStyle.barColor = "Green"
    defaultStyle.lblPosition = "Inside"
    defaultStyle.barHeight = 16
    defaultStyle.lblSize = 10

//    let layout = TileLayout(bouyancy: .floating, hGap: 0, vGap: 2)
//    mapPanel = MapPanel(extent: extent, layout: layout, color: "Peach")
//    givPanel = GIVPanel(extent: extent, color: "Clear")
    theFrame = GIVFrame(extent: extent)
  }

  func parse(xmlDocument: XMLDocument) {
            
    let parser = XMLParser(data: xmlDocument.xmlData)
    parser.delegate = self
    let success = parser.parse()
    
    if success == false {
      if let error = parser.parserError {
        print("error:\(error)")
      } else {
        print("error: nil")
      }
    }

  }
  
  func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
    switch elementName {
    case "Pattern": createMapView(attributeDict)
    case "pattern": doPattern(attributeDict)
    case "match": doMatch(attributeDict)
    default: break
    }
  }
  
  private func createMapView(_ attributes: [String : String]) -> Void {
    // Create Element Style dictionary
    var elementStyle = ElementStyle()

    // P A T T E R N   M A T C H  -----------------
    elementStyle = ElementStyle()
    elementStyle.name = "Match"
    elementStyle.barColor = "Blue Gray"
    elementStyle.lblPosition = "Inside"
    elementStyle.barHeight = 16
    elementStyle.lblSize = 10
    elementStyles[elementStyle.name] = elementStyle
  }
  
  private func doPattern(_ attributes: [String : String]) -> Void {
    let regex = attributes["regex"] ?? ""
    let count = Int(attributes["count"] ?? "0") ?? 0

    let layout = TileLayout(bouyancy: .floating, hGap: 0, vGap: 2)
    mapPanels.append(MapPanel(extent: extent, layout: layout, color: "Peach"))
    let label = "\(regex)   (\(count))"
    givPanels.append(GIVPanel(extent: extent, color: "Clear", label: label))
  }


  private func doMatch(_ attributes: [String : String]) -> Void {
    guard mapPanels.count > 0 else { return }
    
    let label: String = attributes["label"] ?? ""
    let from: Int = Int(attributes["from"] ?? "1") ?? 1
    let to: Int = Int(attributes["to"] ?? "1") ?? 1
    
    mapPanels[mapPanels.count - 1].addTile(Glyph(element: Element(label: label, start: from, stop: to), style: elementStyles["Match"] ?? defaultStyle))
  }
  
}

