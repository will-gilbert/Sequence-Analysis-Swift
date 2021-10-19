//
//  Composition.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/14/21.
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
}


struct FormatView: View {
  
  @EnvironmentObject var sequenceState: SequenceState
  
  @State var text: String = ""

  var body: some View {
    
    // Pass in the state variables, it will be displayed when 'Format' is finished
    DispatchQueue.main.async {
      text.removeAll()
      let _ = Format(sequenceState.sequence, format: sequenceState.fileFormat, text: $text)
    }
    
    return VStack {
      HStack(alignment: .center) {
        Menu("File Format:") {
          ForEach(FileFormat.allCases, id: \.self) { fileFormat in
            Button(action: {
              sequenceState.fileFormat = fileFormat
            }, label: {
              Text(fileFormat.rawValue)
            })
          }
        }.frame(width: 150)
        Text(sequenceState.fileFormat.rawValue)
        Spacer()
      }
      Divider()
      TextView(text: $text, isEditable: false)
        .background(Color.white)
    }
  }
  
}

private struct Format {
  
  let sequence: Sequence
  let format: FileFormat

  @Binding var buffer: String
  func emptyPrefix(cursor:Int) -> String {return ""}

  init(_ sequence: Sequence, format: FileFormat, text: Binding<String>) {
    self.sequence = sequence
    self.format = format
    self._buffer = text
    doFileFormat(format)
  }


  mutating func doFileFormat(_ format: FileFormat) {
    guard sequence.string.count > 0 else { buffer.append("The sequence has no contents") ; return }
    
    switch format {
    case .FASTA: doFASTA()
    case .RAW: doRAW()
    case .GCG: doGCG()
    case .GENBANK: doGenbank()
    case .EMBL: doEMBL()
    case .PIR: doPIR()
    case .CODATA: doCODATA()
    }
  }
  
   mutating func doFASTA() {
    buffer.append(">")
    buffer.append(cleanUID())
    buffer.append(" ")
    buffer.append(sequence.title + "\n")
    writeSequence(lineSize: 50, blockSize: nil, prefix: emptyPrefix)
    buffer.append("*")
  }
  
  mutating func doRAW() {
    writeSequence(lineSize: 80,blockSize: nil, prefix: emptyPrefix)
  }
    
  mutating func doGCG() {
    buffer.append(sequence.title + "\n")
    buffer.append(cleanUID())
    buffer.append(" Length: \(sequence.length)  ")
    buffer.append(formatTime(Date(), formatPattern: "EEEE, MMM dd, yyyy"))
    buffer.append("  Check: \(sequence.checkSum) ..\n")
    
    func gcgPrefix(cursor: Int) -> String {
      return F.f(cursor, width: 9) + " "
    }
        
    writeSequence(lineSize: 50, blockSize: 10, prefix: gcgPrefix)
  }
  
  mutating func doGenbank() {
    buffer.append("LOCUS       ")
    buffer.append(cleanUID())
    buffer.append("         ")
    buffer.append(String(sequence.length))
    buffer.append( sequence.isNucleic ? " bp" : " aa" )
    buffer.append("        XXX   UPDATED  ")
    buffer.append(formatTime(Date(), formatPattern: "dd-MMM-yyyy HH:mm") + "\n")
    buffer.append("DEFINITION  " + sequence.title + "\n")
    buffer.append("ORIGIN\n")
    
    func genbankPrefix(cursor: Int) -> String {
      return F.f(cursor, width: 9) + " "
    }
        
    writeSequence(lineSize: 60, blockSize: 10, prefix: genbankPrefix)
    buffer.append("\n//\n")
  }

  mutating func doEMBL() {
    
    buffer.append("ID   ")
    buffer.append(cleanUID())
    buffer.append(" unannotated; ");
    buffer.append( sequence.isNucleic ? "DNA; " :  "PROTEIN; ");
    buffer.append(String(sequence.length))
    buffer.append( sequence.isNucleic ? " BP." : " AA." ); buffer.append("\n")
    buffer.append("DE   " + sequence.title + "\n")
    buffer.append("XX\n")
    buffer.append("DT   " + formatTime(Date(), formatPattern: "dd-MMM-yyyy HH:mm") + "\n")
    buffer.append("XX\n")
    buffer.append("SQ   Sequence   \(sequence.length)")
    buffer.append( sequence.isNucleic ? " BP;" : " AA;" ); buffer.append("\n")
    
    func emblPrefix(cursor: Int) -> String {
      return "     "
    }
        
    writeSequence(lineSize: 60, blockSize: 10, prefix: emblPrefix)
    buffer.append("\n//\n")
  }

  mutating func doPIR() {
    buffer.append((sequence.isNucleic) ? ">DL;" : ">P1;");
    buffer.append(cleanUID() + "\n")
    buffer.append(sequence.title + "\n")
    writeSequence(lineSize: 60, blockSize: 10, prefix: emptyPrefix)
    buffer.append("*")
  }
  
  mutating func doCODATA() {
    buffer.append("ENTRY    ");
    buffer.append(cleanUID())
    buffer.append("   #Type ");
    buffer.append(sequence.isNucleic ? "dna linear\n" : "Protein\n");
    buffer.append("TITLE    \(sequence.title)\n");
    buffer.append("DATE     ")
    buffer.append(formatTime(Date(), formatPattern: "dd-MMM-yyyy HH:mm") + "\n");
    buffer.append("SUMMARY  #Molecular-weight ")
    
    // Can't use F.f(Double) because we don't want a comma delimiter
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
 
    let number = NSNumber(value: sequence.molwt)
    if let formattedNumber = formatter.string(from: number) {
      buffer.append(formattedNumber)
    } else {
      buffer.append("NaN") // This should never happen
    }
    
    buffer.append("   ")
    buffer.append("#Length \(sequence.length)")
    buffer.append("  #Checksum ")
    buffer.append(String(sequence.checkSum) + "\n");
    buffer.append("SEQUENCE\n");

    func codataPrefix(cursor: Int) -> String {
      return F.f(cursor, width: 7) + " "
    }

    buffer.append("                5        10        15        20        25        30\n");
    writeSequence(lineSize: 30, blockSize: 1, prefix: codataPrefix)
    buffer.append("\n//\n")
  }

  
  mutating func writeSequence(lineSize: Int, blockSize: Int? = nil, prefix: (Int) -> String) {
    
    buffer.append(prefix(1))

    let strand = Array(sequence.string)
    var lineCount: Int = 0
    var blockCount: Int = 0

    for i  in 0..<strand.count {
      buffer.append(strand[i])
      lineCount += 1
      blockCount += 1

      if let blockSize = blockSize, blockCount == blockSize {
          buffer.append(" ");
          blockCount = 0
      }

      if lineCount == lineSize {
        buffer.append("\n");
        buffer.append(prefix(i + 2))
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
