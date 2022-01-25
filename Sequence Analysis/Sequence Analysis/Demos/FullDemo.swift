//
//  FullDemo.swift
//  SA-GIV
//
//  Created by Will Gilbert on 8/17/21.
//

import SwiftUI

struct FullDemo: View {
  
  @State var scale: Double = 1.0

  let extent: CGFloat
  let fullDemoData: FullDemoData
  var mapPanel: MapPanel
  
  var height: CGFloat = 0.0
  var width: CGFloat = 0.0
  
  init(extent: Int) {

    self.extent = CGFloat(extent)
    fullDemoData = FullDemoData(extent: extent)
    mapPanel = fullDemoData.mapPanel
    
    mapPanel.setPanelWidth(CGFloat(extent) * scale)

    height = mapPanel.size.height
    width = mapPanel.size.width
  }
  
  var body: some View {
    let fitToWidth: CGFloat = extent * scale

    return GeometryReader { geometry in
   
      let windowWidth = geometry.size.width
      var minScale: Double = (windowWidth/Double(extent)) < 1.0 ? 1.0 : windowWidth/Double(extent)
      
      VStack(alignment: .leading) {
        
        VStack(alignment: .center) {
          Text("Test Mixed Glyphs")
            .font(.title)
          Text(String("   Window: \(F.f(windowWidth, decimal: 0)) pixels"))
          Text(String("     Scale: \(F.f(scale, decimal: 3)) pixel/bp"))
          Text(String("    Extent: \(F.f(extent, decimal: 0)) bp"))
          Text(String("View width: \(F.f(extent * scale, decimal: 0)) pixels"))
          Slider(
            value: $scale,
            in: minScale...10.0
            // in: minScale...Double(extent/100.0)
          )
        }
        
        // The following nested 'GeometryReader' and 'mapPanelView.size' is
        //   a horrible hack to get the 'mapPanelView" to at the top of the
        //   'ScrollView';  Nested 'VStack' did not; Spent 2 days on this!
        //   Maybe a macOS SwiftUI bug, maybe not.
        //   TODO: Revisit in the future.

        // SCROLLVIEW ----------------------------------------------------------
          ScrollView( [.vertical, .horizontal], showsIndicators: true) {
            VStack(spacing: 0) {
              MapPanelView(mapPanel, scale: scale)
            }.frame(width: fitToWidth, height: height) // Scale the map container
            
            // Create a bottom 'Spacer' as needed when the map does not fill the ScrollView
            if geometry.size.height > height {
              Spacer()
              .frame(height: geometry.size.height - height)
            }
          }.background(mapPanel.color)
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
  }
        
}

struct FullDemoData {
  
  var mapPanel: MapPanel
  
  init(extent: Int) {

    let layout = TileLayout(buoyancy: .floating, hGap: 3, vGap: 3)
    mapPanel = MapPanel(extent: extent, layout: layout, color: "Peach")

    var tiles = Array<Tile>()
    
    var style = ElementStyle()
    style.name = "Randomized Element"
    style.barBorder = 2
    style.lblSize = 12

    for _ in 1...200 {

      let start = Int.random(in: 1...(extent - 60))
      let length = Int.random(in: 5...60 )

      let element = Element(label: "\(start)", start: start, stop: start + length)

      let colors = Colors.getNames()
      style.barColor = colors[Int.random(in:0..<colors.count)]

      style.barHeight = Int.random(in: 5...45)
      
      // Put most of the labels inside
      let lblPositions = ["Above", "Inside", "Inside", "Inside", "Below"]
      style.lblPosition = lblPositions[Int.random(in: 0..<lblPositions.count)]

      // Override some properties here for testing
//      style.barHeight = 20
//      style.barColor = "Green"
  //      style.lblPosition = "Inside"
      
      // Set the label color to the bar color if outside of the bar
      switch style.lblPosition {
        case "above", "below":
          style.lblColor = style.barColor
        default:
          style.lblColor = "black"
      }
      
      tiles.append(Glyph(element: element, style: style))
    }
    
    style.barColor = "AGA 06"
    style.lblPosition = "Hidden"
    style.barHeight = 10
    style.lblColor = "Black"
    
    var styles: [String: ElementStyle] = [:]
    
    var cornflowerElement = style
    cornflowerElement.name = "Cornflower Element"
    cornflowerElement.barColor = "Cornflower"
    styles["C"] = cornflowerElement
    
    var orangeElement = style
    orangeElement.name = "Orange Element"
    orangeElement.barColor = "Orange"
    styles["O"] = orangeElement

    var lavenderElement = style
    lavenderElement.name = "Lavender Element"
    lavenderElement.barColor = "Lavender"
    styles["L"] = lavenderElement

//     Nested mosaics here
    
    // Yellow Mosaic
    let yellowMosaic = Mosaic(label: "Yellow Mosaic", buoyancy: "StackUp", color: "Yellow")
    yellowMosaic.addTile(Glyph(element: Element(label: "100", start: 200, stop: 250), style: styles["C"] ?? style))
    yellowMosaic.addTile(Glyph(element: Element(label: "190", start: 190, stop: 230), style: styles["O"] ?? style))
    yellowMosaic.addTile(Glyph(element: Element(label: "220", start: 220, stop: 266), style: styles["C"] ?? style))
    yellowMosaic.addTile(Glyph(element: Element(label: "150", start: 150, stop: 250), style: styles["L"] ?? style))

    // Green Mosaic
    let greenMosaic = Mosaic(label: "Green Mosaic", buoyancy: "Floating", color: "green")
    greenMosaic.addTile(Glyph(element: Element(label: "100", start: 100, stop: 149), style: styles["L"] ?? style))
    greenMosaic.addTile(Glyph(element: Element(label: "140", start: 140, stop: 181), style: styles["C"] ?? style))
    greenMosaic.addTile(Glyph(element: Element(label: "170", start: 170, stop: 216), style: styles["O"] ?? style))
    greenMosaic.addTile(Glyph(element: Element(label: "150", start: 150, stop: 200), style: styles["C"] ?? style))
    greenMosaic.addTile(yellowMosaic)

    // Gray Mosaic
    let grayMosaic = Mosaic(label: "Gray Mosaic", buoyancy: "Floating", color: "AGA 01")
    grayMosaic.addTile(Glyph(element: Element(label: "50",  start:  50, stop: 175), style: styles["C"] ?? style))
    grayMosaic.addTile(Glyph(element: Element(label: "140", start: 140, stop: 181), style: styles["O"] ?? style))
    grayMosaic.addTile(Glyph(element: Element(label: "170", start: 170, stop: 216), style: styles["O"] ?? style))
    grayMosaic.addTile(Glyph(element: Element(label: "150", start: 150, stop: 200), style: styles["L"] ?? style))
    grayMosaic.addTile(greenMosaic)
    
    mapPanel.addTile(grayMosaic)
    mapPanel.addTiles(tiles)
  }

}

struct TestMixedHeights: View {

  var scale: Double

  var body: some View {
    let extent: Int = 120

    let layout = TileLayout(buoyancy: .stackDown, hGap: 2, vGap: 2)
    var mapPanel = MapPanel(extent: extent, layout: layout, color: "Peach")

    var glyphs = Array<Glyph>()
    var style = ElementStyle()
    style.lblPosition = "Inside"

    style.barHeight = 25
    glyphs.append(Glyph(element: Element(label: "1", start: 26, stop: 49), style: style))
    style.barHeight = 20
    glyphs.append(Glyph(element: Element(label: "2", start: 40, stop: 81), style: style))
    style.barHeight = 100
    glyphs.append(Glyph(element: Element(label: "3", start: 70, stop: 116), style: style))

    mapPanel.addTiles(glyphs)
    let fitToWidth: CGFloat = CGFloat(extent) * scale
    mapPanel.setPanelWidth(fitToWidth)

    return VStack {
      Text("Test Mixed Height Glyphs")
        .font(.title)
      MapPanelView(mapPanel)
    }.frame(width: fitToWidth)
  }
}


struct TestMixedRightEdge: View {

  var scale: Double

  var body: some View {
    let extent: Int = 120

    let layout = TileLayout(buoyancy: .stackDown, hGap: 2, vGap: 2)
    var mapPanel = MapPanel(extent: extent, layout: layout, color: "Peach")

    var glyphs = Array<Glyph>()
    var style = ElementStyle()

    style.lblPosition = "Inside"
    style.barHeight = 20
    glyphs.append(Glyph(element: Element(label: "1", start: 22, stop: 81), style: style))
    style.barHeight = 25
    glyphs.append(Glyph(element: Element(label: "2", start: 26, stop: 49), style: style))
    style.barHeight = 100
    glyphs.append(Glyph(element: Element(label: "3", start: 90, stop: 116), style: style))

    mapPanel.addTiles(glyphs)
    let fitToWidth: CGFloat = CGFloat(extent) * scale
    mapPanel.setPanelWidth(fitToWidth)

    return VStack {
      Text("Test Mixed Right Edge Glyphs")
        .font(.title)
      MapPanelView(mapPanel)
    }.frame(width: fitToWidth)
  }
}

struct TestThinGlyphs: View {

  var scale: Double

  var body: some View {
    
    let extent: Int = 120

    var glyphs = Array<Glyph>()
    var style = ElementStyle()
    style.lblPosition = "Inside"

    style.barHeight = 20
    glyphs.append(Glyph(element: Element(label: "1", start: 22, stop: 22), style: style))
    style.barHeight = 25
    glyphs.append(Glyph(element: Element(label: "2", start: 26, stop: 27), style: style))
    style.barHeight = 100
    glyphs.append(Glyph(element: Element(label: "3", start: 90, stop: 93), style: style))

    let layout = TileLayout(buoyancy: .floating, hGap: 2, vGap: 2)
    var mapPanel = MapPanel(extent: extent, layout: layout, color: "Peach")
    mapPanel.addTiles(glyphs)
    let fitToWidth: CGFloat = CGFloat(extent) * scale
    mapPanel.setPanelWidth(fitToWidth)

    return VStack {
      Text("Test Thin Glyphs")
        .font(.title)
      MapPanelView(mapPanel)
    }.frame(width: fitToWidth)
  }
}

