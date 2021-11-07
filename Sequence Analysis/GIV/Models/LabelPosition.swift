//
//  LabelPosition.swift
//  SA-GIV
//
//  Created by Will Gilbert on 8/6/21.
//

import SwiftUI

// Label Position ================================
enum LabelPosition: String, CaseIterable {
  case kLabelAboveBar = "above"
  case kLabelInsideBar = "inside"
  case kLabelBelowBar = "below"
  case kLabelHidden = "hidden"
}

extension LabelPosition {
  var description: String {
    return self.rawValue
  }
}
