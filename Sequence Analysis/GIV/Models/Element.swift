//
//  Node.swift
//  SA-GIV
//
//  Created by Will Gilbert on 7/17/21.
//

struct Element {
  var label: String
  var start: Int   // sequence position, start;  1-based
  var stop: Int    // sequence position, end; 1-based
  
  init(label: String, start: Int, stop: Int, style: String = "") {
    self.label = label
    
    // 'start' must be less than 'stop'
    (self.start, self.stop) = start < stop ? (start, stop) : (stop, start)
  }
  
  var width: Int {
    self.stop - self.start + 1
  }
  
}
