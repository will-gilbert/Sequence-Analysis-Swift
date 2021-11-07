//
//  ORF_Nucleic.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 10/2/21.
//

import Foundation

class ORF_XMLParser : NSObject, XMLParserDelegate  {
  
  var defaultStyle: ElementStyle
  var elementStyles: [String : ElementStyle] = [:]
  var mapPanels: [String : [ [String : MapPanel] ] ] = [:]
  var givPanels: [String : GIVPanel] = [:]
  var theFrame: GIVFrame
  
  var currentFrame: String = ""
  var givPanelViews: [GIVPanel] {
    // Need to addMapPanel in order to retile
    get {
      givPanels["+1"]!.addMapPanel(mapPanels["+1"]![0]["codon"]!)
      givPanels["+1"]!.addMapPanel(mapPanels["+1"]![1]["orf"]!)

      givPanels["+2"]!.addMapPanel(mapPanels["+2"]![0]["codon"]!)
      givPanels["+2"]!.addMapPanel(mapPanels["+2"]![1]["orf"]!)

      givPanels["+3"]!.addMapPanel(mapPanels["+3"]![0]["codon"]!)
      givPanels["+3"]!.addMapPanel(mapPanels["+3"]![1]["orf"]!)

      return [givPanels["+1"]!, givPanels["+2"]!, givPanels["+3"]!]
    }
  }
  
  var givFrame: GIVFrame {
    get {
      theFrame.addGIVPanels(givPanelViews)
      return theFrame
    }
  }



  init(extent: Int) {
        
    // Create three forward frame glyph panels
    givPanels["+1"] = GIVPanel(extent: extent, color: "None", label: "Frame +1")
    givPanels["+2"] = GIVPanel(extent: extent, color: "None", label: "Frame +2")
    givPanels["+3"] = GIVPanel(extent: extent, color: "None", label: "Frame +3")

    defaultStyle = ElementStyle()
    defaultStyle.lblPosition = "Hidden"
    defaultStyle.barHeight = 10
    
    mapPanels["+1"] = []
    mapPanels["+2"] = []
    mapPanels["+3"] = []

    
    let startStoplayout = TileLayout(bouyancy: .floating, hGap: 0, vGap: 2)
    mapPanels["+1"]!.append(["codon" : MapPanel(extent: extent, layout: startStoplayout, color: "None")]) // start & stop
    mapPanels["+2"]!.append(["codon" : MapPanel(extent: extent, layout: startStoplayout, color: "None")]) // start & stop
    mapPanels["+3"]!.append(["codon" : MapPanel(extent: extent, layout: startStoplayout, color: "None")]) // start & stop

    let orfLayout = TileLayout(bouyancy: .floating, hGap: 2, vGap: 2)
    mapPanels["+1"]!.append(["orf" : MapPanel(extent: extent, layout: orfLayout, color: "None")]) // ORF
    mapPanels["+2"]!.append(["orf" : MapPanel(extent: extent, layout: orfLayout, color: "None")]) // ORF
    mapPanels["+3"]!.append(["orf" : MapPanel(extent: extent, layout: orfLayout, color: "None")]) // ORF
    
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
    case "ORF": createMapView(attributeDict)
    case "frame": doFrame(attributeDict)
    case "start-codon": doStartCodon(attributeDict)
    case "stop-codon": doStopCodon(attributeDict)
    case "orf": doORF(attributeDict)
    default: break
    }
  }
  
  private func createMapView(_ attributes: [String : String]) -> Void {
         
    // Create Element Style dictionary
    var elementStyle = ElementStyle()

    // S T A R T   C O D O N  -------------
    elementStyle.name = "Start Codon"
    elementStyle.barColor = "Navy"
    elementStyle.lblPosition = "Inside"
    elementStyle.barHeight = 16
    elementStyle.lblSize = 10
    elementStyle.lblColor = "White"
    elementStyles["start-codon"] = elementStyle
    
    // S T O P   C O D O N  ---------------
    elementStyle.name = "Stop Codon"
    elementStyle.barColor = "Magenta"
    elementStyle.lblColor = "Black"
    elementStyles["stop-codon"] = elementStyle
    
    // F O R W A R D   F R A M E   O R F   ---------------
    elementStyle.name = "ORF"
    elementStyle.barColor = "Green"
    elementStyle.lblPosition = "Below"
    elementStyle.barHeight = 8
    elementStyle.lblSize = 12
    elementStyle.lblColor = "Black"
    elementStyles["forward-frame-orf"] = elementStyle
  }
    
  private func doFrame(_ attributes: [String : String]) -> Void {
    let frame = attributes["frame"] ?? "+1"
    switch frame {
    case "+1": currentFrame = "+1"
    case "+2": currentFrame = "+2"
    case "+3": currentFrame = "+3"
    default: break
    }
  }
  
  private func doStartCodon(_ attributes: [String : String]) -> Void {
    guard let from  = Int(attributes["at"] ?? "") else { return }
    let codon = attributes["codon"] ?? "Start"
    let to = from + 2
    
    mapPanels[currentFrame]![0]["codon"]!.addTile(Glyph(element: Element(label: codon, start: from, stop: to), style: elementStyles["start-codon"] ?? defaultStyle))
  }
  
  private func doStopCodon(_ attributes: [String : String]) -> Void {
    guard let from  = Int(attributes["at"] ?? "") else { return }
    let codon = attributes["codon"] ?? "Stop"
    let to = from + 2
    mapPanels[currentFrame]![0]["codon"]!.addTile(Glyph(element: Element(label: codon, start: from, stop: to), style: elementStyles["stop-codon"] ?? defaultStyle))
  }
  
  private func doORF(_ attributes: [String : String]) -> Void {
    let from: Int = Int(attributes["from"] ?? "1") ?? 1
    let to: Int = Int(attributes["to"] ?? "1") ?? 1
    mapPanels[currentFrame]![1]["orf"]!.addTile(Glyph(element: Element(label: "ORF: \(from)-\(to)", start: from, stop: to), style: elementStyles["forward-frame-orf"] ?? defaultStyle))
  }


}
