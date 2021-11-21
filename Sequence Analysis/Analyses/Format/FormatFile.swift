//
//  FormatFile.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 10/21/21.
//

import SwiftUI


enum FileFormat: String, CaseIterable, Identifiable {
  case FASTA = "Fasta"
  case RAW = "Sequence Only"
  case GCG = "GCG"
  case GENBANK = "GenBank and IBI"
  case EMBL = "EMBL and SwissProt"
  case PIR = "NBRF/PIR"
  case CODATA = "CODATA"

  var id: FileFormat { self }
  
  var fileType: String {
    switch self {
    case .FASTA: return "fasta"
    case .RAW: return "raw"
    case .GCG: return "gcg"
    case .GENBANK: return "gb"
    case .EMBL: return "embl"
    case .PIR: return "nbrf"
    case .CODATA: return "codata"
    }
  }

}

struct FormatFile {

  var sequence: Sequence
  var text: String = ""

  mutating func doFileFormat(_ format: FileFormat) -> String {

    guard sequence.string.count > 0 else {
      self.text.append("This sequence has no content")
      return text
    }
    
    switch format {
    case .FASTA: doFASTA()
    case .RAW: doRAW()
    case .GCG: doGCG()
    case .GENBANK: doGenbank()
    case .EMBL: doEMBL()
    case .PIR: doPIR()
    case .CODATA: doCODATA()
    }
    
    return text
    
  }

  func emptyPrefix(cursor:Int) -> String {return ""}

  mutating func doFASTA() {
    text.append(">")
    text.append(cleanUID())
    text.append(" ")
    text.append(sequence.title + "\n")
    writeSequence(lineSize: 50, blockSize: nil, prefix: emptyPrefix)
    text.append("*")
  }
  
  mutating func doRAW() {
    writeSequence(lineSize: 80,blockSize: nil, prefix: emptyPrefix)
  }
    
  mutating func doGCG() {
    text.append(sequence.title + "\n")
    text.append(cleanUID())
    text.append(" Length: \(sequence.length)  ")
    text.append(formatTime(Date(), formatPattern: "EEEE, MMM dd, yyyy"))
    text.append("  Check: \(sequence.checkSum) ..\n")
    
    func gcgPrefix(cursor: Int) -> String {
      return F.f(cursor, width: 9) + " "
    }
        
    writeSequence(lineSize: 50, blockSize: 10, prefix: gcgPrefix)
  }
  
  mutating func doGenbank() {
    text.append("LOCUS       ")
    text.append(cleanUID())
    text.append("         ")
    text.append(String(sequence.length))
    text.append( sequence.isNucleic ? " bp" : " aa" )
    text.append("        XXX   UPDATED  ")
    text.append(formatTime(Date(), formatPattern: "dd-MMM-yyyy HH:mm") + "\n")
    text.append("DEFINITION  " + sequence.title + "\n")
    text.append("ORIGIN\n")
    
    func genbankPrefix(cursor: Int) -> String {
      return F.f(cursor, width: 9) + " "
    }
        
    writeSequence(lineSize: 60, blockSize: 10, prefix: genbankPrefix)
    text.append("\n//\n")
  }

  mutating func doEMBL() {
    
    text.append("ID   ")
    text.append(cleanUID())
    text.append(" unannotated; ");
    text.append( sequence.isNucleic ? "DNA; " :  "PROTEIN; ");
    text.append(String(sequence.length))
    text.append( sequence.isNucleic ? " BP." : " AA." ); text.append("\n")
    text.append("DE   " + sequence.title + "\n")
    text.append("XX\n")
    text.append("DT   " + formatTime(Date(), formatPattern: "dd-MMM-yyyy HH:mm") + "\n")
    text.append("XX\n")
    text.append("SQ   Sequence   \(sequence.length)")
    text.append( sequence.isNucleic ? " BP;" : " AA;" ); text.append("\n")
    
    func emblPrefix(cursor: Int) -> String {
      return "     "
    }
        
    writeSequence(lineSize: 60, blockSize: 10, prefix: emblPrefix)
    text.append("\n//\n")
  }

  mutating func doPIR() {
    text.append((sequence.isNucleic) ? ">DL;" : ">P1;");
    text.append(cleanUID() + "\n")
    text.append(sequence.title + "\n")
    writeSequence(lineSize: 60, blockSize: 10, prefix: emptyPrefix)
    text.append("*")
  }
  
  mutating func doCODATA() {
    text.append("ENTRY    ");
    text.append(cleanUID())
    text.append("   #Type ");
    text.append(sequence.isNucleic ? "dna linear\n" : "Protein\n");
    text.append("TITLE    \(sequence.title)\n");
    text.append("DATE     ")
    text.append(formatTime(Date(), formatPattern: "dd-MMM-yyyy HH:mm") + "\n");
    text.append("SUMMARY  #Molecular-weight ")
    
    // Can't use F.f(Double) because we don't want a comma delimiter
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
 
    let number = NSNumber(value: sequence.molwt)
    if let formattedNumber = formatter.string(from: number) {
      text.append(formattedNumber)
    } else {
      text.append("NaN") // This should never happen
    }
    
    text.append("   ")
    text.append("#Length \(sequence.length)")
    text.append("  #Checksum ")
    text.append(String(sequence.checkSum) + "\n");
    text.append("SEQUENCE\n");

    func codataPrefix(cursor: Int) -> String {
      return F.f(cursor, width: 7) + " "
    }

    text.append("                5        10        15        20        25        30\n");
    writeSequence(lineSize: 30, blockSize: 1, prefix: codataPrefix)
    text.append("\n//\n")
  }

  
  mutating func writeSequence(lineSize: Int, blockSize: Int? = nil, prefix: (Int) -> String) {
    
    text.append(prefix(1))

    let strand = Array(sequence.string)
    var lineCount: Int = 0
    var blockCount: Int = 0

    for i  in 0..<strand.count {
      text.append(strand[i])
      lineCount += 1
      blockCount += 1

      if let blockSize = blockSize, blockCount == blockSize {
        text.append(" ");
          blockCount = 0
      }

      if lineCount == lineSize {
        text.append("\n");
        text.append(prefix(i + 2))
        lineCount = 0
      }
    }
    
  }
  
  func formatTime(_ date: Date, formatPattern: String) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.dateFormat = formatPattern
    return formatter.string(from: date)
  }
  
  
  func cleanUID() -> String {
    var uid = sequence.uid
    guard uid.count > 0 else {return "UNTITLED"}
    uid = uid.trimmingCharacters(in: .whitespaces)
    uid = uid.replacingOccurrences(of: " ", with: "_")
    return uid
  }
  
}
