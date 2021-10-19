//
//  Glyph.swift
//  SA-GIV
//
//  Created by Will Gilbert on 7/18/21.
//

import SwiftUI

class Glyph : Tile {

  // Padding around a label which is inside of a bar or a tile
  static let padding = EdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1)

  let element: Element
  var style: ElementStyle
  var bar: Glyph.Bar
  var label: Glyph.Label?

  init(element: Element, style: ElementStyle = ElementStyle()) {

    self.element = element
    self.style = style
    
    // limit border to 0...2
    let barBorder = style.barBorder <= 2 ? style.barBorder : 2
      
    self.bar = Bar(
      origin: CGPoint.zero,
      size: CGSize(width: CGFloat(element.width), height: CGFloat(style.barHeight)),
      color: Colors.get(color: style.barColor),
      border: CGFloat(barBorder)
    )
    
    // Set 'Tile' superclass size to the 'bar'; Will update based on the label position
    super.init(origin: CGPoint(x: element.start, y: 0),  size: self.bar.size)

    // String the string, white space and new lines
    let string = element.label.trimmingCharacters(in: .whitespacesAndNewlines)

    label = createLabel(string: string, style: style)
  }
  
  private func createLabel(string: String, style: ElementStyle) -> Label? {

    // Do we even have a label?
    guard string.count > 0 else { return nil }
    
    // Convert plain text ElementStyle to Swift values e.g CGPoint, CGSize, Color
    var label = Label(
      string: string,
      origin: CGPoint.zero,
      size: string.sizeOf(fontSize: CGFloat(style.lblSize)),
      position: LabelPosition(rawValue: style.lblPosition.lowercased()) ?? .kLabelInsideBar,
      color: Colors.get(color: style.lblColor).darker,
      fontSize: CGFloat(style.lblSize)
    )

    // Set tile size based on the 'label' position;
    // Position the bar and label vertically in the tile
    
    switch label.position {

      case .kLabelAboveBar:
        
        // Set the tile height to the height of the 'Label' plus the 'Bar'; Same as for "Below"
        self.size.height = bar.size.height + label.size.height + Self.padding.bottom

        // The 'bar' is below the 'label'; Set the bar & lable 'origin.y' values
        bar.origin.y = label.size.height + Self.padding.bottom
        label.origin.y = 0
 
      case .kLabelInsideBar:
      
      // Set the tile height is the bar height, maybe already set
        self.size.height = bar.size.height
        
      // Center the label inside the bar  vertically
        label.origin.y = (bar.size.height - label.size.height)/2

      case .kLabelBelowBar:
        
        // Set the tile height to the height of the 'Label' plus the 'Bar'
        self.size.height = bar.size.height + label.size.height + Self.padding.top
        
        // The bar is above the label; Set the bar & lable 'origin.y' values
        bar.origin.y = 0
        label.origin.y = bar.size.height + Self.padding.top

      case .kLabelHidden:
        label.visible = false
    }

    return label
  }

  struct Bar {
    var origin: CGPoint          // CGPoint(x:y)
    var size: CGSize             // CGSize(width:height)
    let color: TriColor
    let border: CGFloat          // 0...2; Possibly a "bool" eventually
  }

  struct Label {
   let string: String
   var origin: CGPoint           // CGPoint(x:y)
   let size: CGSize              // CGSize(width:height)
   let position: LabelPosition   // Above, Below, Inside, Hidden
   let color: Color
   let fontSize: CGFloat
   var visible: Bool = true
  }

}


