//
//  Buoyancy.swift
//  SA-GIV (iOS)
//
//  Created by Will Gilbert on 11/5/21.
//

import SwiftUI

enum Buoyancy: String {
  case floating = "Floating"
  case sinking = "Sinking"
  case stackUp = "StackUp"
  case stackDown = "StackDown"
}

extension Buoyancy {
  
  var description: String {
    return self.rawValue
  }
  
  static func fromString(_ string: String) -> Buoyancy {
    switch string.lowercased() {
    case "floating": return .floating
    case "sinking": return .sinking
    case "stackup": return .stackUp
    case "stackdown": return .stackDown
    default: return .floating
    }

  }
}
