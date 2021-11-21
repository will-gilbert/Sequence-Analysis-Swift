//
//  F.swift
//  SequenceEditor (macOS)
//
//  Created by Will Gilbert on 9/15/21.
//

import SwiftUI

class F {
  
  static let DEFAULT = Int.max

  enum flag {
    case RJ // Right Justify
    case LJ // Left Justify
    case CJ // Center Justify
  }
  
  // Integer
  static func f(_ value: Int, width: Int = DEFAULT, flags: F.flag = .RJ) -> String {
    let numberAsString = String(value)
    return width == DEFAULT ? numberAsString : F.f(numberAsString, width: width, flags: flags)
  }
  
  // CGFloat
  static func f(_ value: CGFloat, decimal: Int = 1, width: Int = DEFAULT, flags: F.flag = .RJ) -> String {
    return F.f( Double(value), decimal: decimal, width: width, flags: flags)
  }

  // Double
  static func f(_ value: Double, decimal: Int = 1, width: Int = DEFAULT, flags: F.flag = .RJ) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = decimal
    formatter.maximumFractionDigits = decimal
 
    let number = NSNumber(value: value)
    if let formattedNumber = formatter.string(from: number) {
      return width == DEFAULT ? formattedNumber : F.f(formattedNumber, width: width, flags: flags)
    } else {
      return "NaN"
    }
  }
  
  // String
  static func f(_ value: String, width: Int, flags: F.flag = .RJ) -> String {
    
    var formattedValue = value
    let size = value.count
      
    guard size < width else {return formattedValue}

    switch flags {
      case .LJ:
        formattedValue = value + String(repeating: " ", count: width - size)
      case .RJ:
        formattedValue = String(repeating: " ", count: width - size) + value
      case .CJ:
        formattedValue = String(repeating: " ", count: (width-size)/2 ) + value
        formattedValue = formattedValue + String(repeating: " ", count: width - formattedValue.count)
    }
    
    return formattedValue
    
  }
  
}
