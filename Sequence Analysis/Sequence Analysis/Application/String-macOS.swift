//
//  String-macOS.swift
//  SA-GIV (macOS)
//
//  Created by Will Gilbert on 9/6/21.
//

import AppKit

extension String {
  
  func sizeOf(fontSize: CGFloat) -> CGSize {
    
    let fontAttributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: fontSize)
    ]
    
    return self.size(withAttributes: fontAttributes)
  }
  
  enum TruncationPosition {
      case head
      case middle
      case tail
  }

  func truncated(limit: Int, position: TruncationPosition = .tail, leader: String = "...") -> String {
      guard self.count > limit else { return self }

      switch position {
      case .head:
          return leader + self.suffix(limit)
      case .middle:
          let headCharactersCount = Int(ceil(Float(limit - leader.count) / 2.0))

          let tailCharactersCount = Int(floor(Float(limit - leader.count) / 2.0))
          
          return "\(self.prefix(headCharactersCount))\(leader)\(self.suffix(tailCharactersCount))"
      case .tail:
          return self.prefix(limit) + leader
      }
  }

  // Borrowed from:
  //   https://github.com/amayne/SwiftString/blob/master/Pod/Classes/StringExtensions.swift
  
  func substring(from: Int, length: Int) -> String {
    let start = self.index(self.startIndex, offsetBy: from)
    let end = self.index(start, offsetBy: length)
    return String(self[start..<end])
  }
  
}
