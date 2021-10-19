//
//  Sequence.swift
//  SequenceEditor
//
//  Created by Will Gilbert on 8/31/21.
//

import Foundation

class Sequence : Identifiable, ObservableObject {
    
  static func nextUID() -> String {
    return String(UUID().uuidString.replacingOccurrences(of: "-", with: "").suffix(5))
  }
  
  let id = UUID()
    
  @Published var uid: String = ""
  @Published var title: String = ""
  @Published var string: String = ""
  
  var type: SequenceType = .UNDEFINED
  var alphabet: Alphabet = .DNA
  var allowDegenerate: Bool = false

  init(_ string: String, uid: String, title: String = "Untitled", type: SequenceType = .UNDEFINED) {
    self.uid = uid
    self.string = string
    self.title = title
    self.type = type
    
    switch type {
    case .DNA: alphabet = .DNA
    case .RNA: alphabet = .RNA
    case .PROTEIN, .PEPTIDE: alphabet = .PROTEIN
    default: alphabet = .DNA
    }
  }

  
  init(_ string: String, title: String = "Untitled", type: SequenceType = .UNDEFINED) {
    self.uid = "UID-\(Self.nextUID())"
    self.string = string
    self.title = title
    self.type = type
    
    switch type {
    case .DNA: alphabet = .DNA
    case .RNA: alphabet = .RNA
    case .PROTEIN, .PEPTIDE: alphabet = .PROTEIN
    default: alphabet = .DNA
    }

  }
 
  // MARK: - Readonly Sequence Properties
  
  var isProtein: Bool {
    get {
      return type == .PROTEIN || type == .PEPTIDE
    }
  }
  
  var isNucleic: Bool {
    get {
      return type == .DNA || type == .RNA
    }
  }
  
  var isDNA: Bool {
    get {
      return type == .DNA
    }
  }
  
  var isRNA: Bool {
    get {
      return type == .RNA
    }
  }

  var length: Int {
    get {
      return string.count
    }
  }
  
  var checkSum: Int {
    get {
      return Self.checksum(string)
    }
  }
  
  var molWt: Double {
    get {
      return Self.molWt(string, type: type)
    }
  }
  
  var description: String {
  
    // Read-only property: UID TITLE TYPE length aa|bp
    get {
      let tokens = [uid, title, type.rawValue, String(length) + lengthSuffix]
      return tokens.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
  }
  
  var shortDescription: String {
  
    // Read-only property: UID TITLE
    get {
      let tokens = [uid, title]
      return tokens.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
  }

  
  var lengthSuffix: String {
    
    get {
    switch type {
    case .PROTEIN, .PEPTIDE:
      return "aa"
    case .DNA, .RNA:
      return "bp"
    case .UNDEFINED:
      return ""
    }
  }
  
  }
  
  // MARK: - Sequence Modifiers
  
  func toDNA() -> Void {
    guard isRNA else { return }
    string = Self.DNAtoRNA(string)
    type = .DNA
  }
  
  func toRNA() -> Void {
    guard isDNA else { return }
    string = Self.RNAtoDNA(string)
    type = .RNA
  }
  
  func nucToProtein(doStops: Bool = true) {
    guard isNucleic else { return }
    string = Self.nucToProtein(string, doStops: doStops, type: type)
    type = .PROTEIN
  }
  
  func reverseComp() -> Void {
    guard isNucleic else { return }
    string = Self.reverseComp(string, type: type)
  }

  // MARK: - Sequence Chemical Properties
  
  var molwt: Double {
    return Self.molWt(string, type: type)
  }

  var gcPercent: Double? {
    guard isNucleic else { return nil }
    return Self.gcPercent(string, type: type)
  }
  
  var simpleTm: Double? {
    guard isDNA else { return nil }
    return Self.simpleTm(string, type: type)
  }
  
  var simpleConc: Double? {
    guard isDNA else { return nil }
    return Self.simpleConc(string, type: type)
  }
  
  var complexConc: Double? {
    guard isDNA else { return nil }
    return 0.0
  }

}

// MARK: - Extension: Equatable & Hashable

extension Sequence: Equatable, Hashable {
      
  func hash(into hasher: inout Hasher) {
      hasher.combine(id)
  }

  static func ==(lhs: Sequence, rhs: Sequence) -> Bool {
      return lhs.id == rhs.id
  }

}

