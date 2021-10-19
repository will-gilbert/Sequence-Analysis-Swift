//
//  FTests.swift
//  Sequence EditorTests
//
//  Created by Will Gilbert on 9/16/21.
//

import XCTest
@testable import Sequence_Analysis

class FTests: XCTestCase {
  
  override func setUp() {
  }

  func testIntegers() {
    XCTAssertEqual(F.f(Int(4)), "4")
    XCTAssertEqual(F.f(4), "4")
    XCTAssertEqual(F.f(4, width: 10), "         4")
    XCTAssertEqual(F.f(4, width: 10, flags: F.flag.RJ), "         4")
    XCTAssertEqual(F.f(4, width: 10, flags: F.flag.LJ), "4         ")
    XCTAssertEqual(F.f(4, width: 10, flags: F.flag.CJ), "    4     ")
    
  }
  
  func testDoubles() {
    XCTAssertEqual(F.f(Double(4)), "4.0")
    XCTAssertEqual(F.f(4.000), "4.0")
    XCTAssertEqual(F.f(4.0, decimal:2, width: 10, flags: F.flag.RJ), "      4.00")
    XCTAssertEqual(F.f(4.0, decimal:2, width: 10, flags: F.flag.LJ), "4.00      ")
    XCTAssertEqual(F.f(4.0, decimal:2, width: 10, flags: F.flag.CJ), "   4.00   ")
    XCTAssertEqual(F.f(400000.0), "400,000.0")
    XCTAssertEqual(F.f(400000.0, decimal: 4), "400,000.0000")
    XCTAssertEqual(F.f(400000.0, decimal: 0), "400,000")
  }
  
  func testString() {
    XCTAssertEqual(F.f("XX", width: 10), "        XX")
    XCTAssertEqual(F.f("XX", width: 10, flags:  F.flag.RJ), "        XX")
    XCTAssertEqual(F.f("XX", width: 10, flags:  F.flag.LJ), "XX        ")
    XCTAssertEqual(F.f("XX", width: 10, flags:  F.flag.CJ), "    XX    ")
  }
}
