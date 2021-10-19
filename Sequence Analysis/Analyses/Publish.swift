//
//  PublishView.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/14/21.
//

import SwiftUI


struct PublishOptions {
  var format: String = "s"
  var blockSize: Int = 3
  var lineSize: Int = 30
  var obeyStopCodons: Bool = false
}

struct PublishView: View {
  
  @ObservedObject var sequence: Sequence
  @State var text: String = ""
  @State var blockSize: Double = 3
  @State var lineSize: Double = 60
//  @State var useStart: Bool = false
  @State var obeyStopCodons: Bool = false
  @State var format: String = "#-Sr_"
  
  @State var typing: Bool = false
  
  let maxBlockSize = 20

  var body: some View {
    
    // Pass in the state variables, it will be displayed when 'Publish' is finished
    DispatchQueue.main.async {
      
      let blckSize = Int(blockSize)
      let lneSize = Int(lineSize)
      
      var options = PublishOptions()
      options.format = format
      options.blockSize = (blckSize == maxBlockSize + 1) ? lneSize : blckSize
      options.lineSize = lneSize
      options.obeyStopCodons = obeyStopCodons
      
      text.removeAll()
      let _ = Publish(sequence, text: $text, options: options)
    }

    return VStack {
      
      HStack {
        
        // Block and Line size sliders with labels -------------------
        VStack(alignment: .leading, spacing: 5.0) {
          // Block sise slider
          VStack(alignment: .leading, spacing: 0.0) {
            HStack(alignment: .center, spacing: 5.0) {
              Text("Block size:")
              if Int(blockSize) == maxBlockSize + 1 {
                Text("No blocks")
              } else {
                Text(String(Int(blockSize)))
              }
            }
            Slider(
              value: $blockSize,
              in: 1...Double(maxBlockSize + 1)
            )
          }.frame(width:220)

          // Line size sider
          VStack(alignment: .leading, spacing: 0.0) {
            HStack(alignment: .center, spacing: 5.0) {
              Text("Line size:")
              Text(String(Int(lineSize)))
            }

            Slider(
              value: $lineSize,
              in: 1...Double(min(sequence.length, 132))
            )
          }.frame(width:220)
        }
//        SliderOptionsView(blockSize: $blockSize, maxBlockSize: maxBlockSize, lineSize: $lineSize, maxLineSize: sequence.length)
          .frame(width:240)
        
        Divider()
        Spacer()

        // Protein translation options --------------------------------
        VStack(alignment: .leading) {
          let canTranslate: Bool = "ABCDEFabcdef123456".filter { format.contains($0) }.count != 0
//          Toggle("Use cursor position as start", isOn: $useStart)
//            .disabled(!(canTranslate && sequence.isNucleic))
//          Text(useStart ? "true" : "false" ).hidden() // Swift 5.5  on macOS hack to refresh on toggle

          Toggle("Obey stop codons", isOn: $obeyStopCodons)
            .disabled(!(canTranslate && sequence.isNucleic))
          Text(obeyStopCodons ? "true" : "false" ).hidden() // Swift 5.5  on macOS hack to refresh on toggle
        }
//        TranslationOptionsView(isNucleic: sequence.isNucleic, format: format, obeyStopCodons: $obeyStopCodons)
        Spacer()
        Divider()

        //  Publish format ---------------------------------------------
        FormatView(format: $format)
      }.frame(maxHeight: 100)
      Divider()
      TextView(text: $text, isEditable: false)
    }
  }

  
  struct SliderOptionsView: View {
    @Binding var blockSize: Double
    var maxBlockSize: Int
    @Binding var lineSize: Double
    var maxLineSize: Int

    var body: some View {
      VStack(alignment: .leading, spacing: 5.0) {
        // Block sise slider
        VStack(alignment: .leading, spacing: 0.0) {
          HStack(alignment: .center, spacing: 5.0) {
            Text("Block size:")
            if Int(blockSize) == maxBlockSize + 1 {
              Text("No blocks")
            } else {
              Text(String(Int(blockSize)))
            }
          }
          Slider(
            value: $blockSize,
            in: 1...Double(maxBlockSize + 1)
          )
        }.frame(width:220)
        
        // Line size sider
        VStack(alignment: .leading, spacing: 0.0) {
          HStack(alignment: .center, spacing: 5.0) {
            Text("Line size:")
            Text(String(Int(lineSize)))
          }
            
          Slider(
            value: $lineSize,
            in: 1...Double(min(maxLineSize, 120))
          )
        }.frame(width:220)
      }


    }
  }

  
  
  struct TranslationOptionsView: View {
    var isNucleic: Bool
    var format: String
    @Binding var obeyStopCodons: Bool
    
    var body: some View {
      VStack(alignment: .leading) {
        let canTranslate: Bool = "ABCDEFabcdef123456".filter { format.contains($0) }.count != 0
//          Toggle("Use cursor position as start", isOn: $useStart)
//            .disabled(!(canTranslate && sequence.isNucleic))
//          Text(useStart ? "true" : "false" ).hidden() // Swift 5.5  on macOS hack to refresh on toggle

        Toggle("Obey stop codons", isOn: $obeyStopCodons)
          .disabled(!(canTranslate && isNucleic))
        Text(obeyStopCodons ? "true" : "false" ).hidden() // Swift 5.5  on macOS hack to refresh on toggle
      }

    }
  }

  
  struct FormatView: View {
    @Binding var format: String
    
    var body: some View {
      VStack(alignment: .center)  {
        TextField("", text: $format)
          .frame(width:110)
        Text(format).hidden()   // Swift 5.5 on macOS hack to refresh on 'format' edit
      }.frame(width:160)
    }
  }
  
  
    
}



//struct Publish_Previews: PreviewProvider {
//
//  static var previews: some View {
//
//    let sequence = Sequence(String(repeating: "TTT", count: 10),
//                                   uid: "TEST-3",
//                                   title: "Cornavirus Spike Peptide",
//                                   type: .DNA)
//
//    return Group {
//      PublishView(sequence: sequence)
//        .environment(\.colorScheme, .light)
//        .previewDisplayName("Light Mode")
//    }
//  }
//}



private struct Publish {
  
  var sequence: Sequence
  @Binding var buffer: String
  
  var options: PublishOptions
  
  init(_ sequence: Sequence, text: Binding<String>, options: PublishOptions) {
    self.sequence = sequence
    self._buffer = text
    self.options = options
    
    // Protein can only use a subset of format symbols
    self.options.format = sequence.isNucleic ? options.format : options.format.filter{ ".-#sS_".range(of: String($0)) != nil }
    
    doFormat()
  }

  mutating func doFormat() {
    guard sequence.length > 0 else { buffer.append("The sequence has no contents") ; return }
    guard options.blockSize > 0 else { buffer.append("Block size cannot be zero") ; return }
    guard options.lineSize > 0 else { buffer.append("Line size cannot be zero") ; return }
    guard options.format.count > 0 else { buffer.append("Format string cannot be empty; Try 's+ra_'") ; return}

    buffer.append(sequence.description)
    buffer.append("\n\n")

    let strand: [Character] = Array(sequence.string)
    let blocksPerLine: Int = options.lineSize / options.blockSize

    var publisher = Publisher(strand: strand, blocksPerLine: blocksPerLine, options: options )
    publisher.createLines()
    publisher.writeLines(&buffer)
  }
}


private struct Publisher {
  
  let strand: [Character]
  let blocksPerLine: Int
  let options: PublishOptions
  let format: [Character]
  
  var lines: [String]
  
  init(strand: [Character], blocksPerLine: Int, options: PublishOptions ) {
    self.strand = strand
    self.blocksPerLine = blocksPerLine
    self.options = options
    
    // Create working variables for the Publisher
    format = Array(options.format)
    lines = Array(repeating: String(), count: format.count)
  }
  
  // Create single string from each format option
  mutating func createLines() {
    for i in 0..<format.count {

      switch format[i] {
      case "#": numberLine(line: i)
      case ".": dotLine(line: i)
      case "s", "S": seqLine(line: i)
      case "-", "+": dashLine(line: i)
      case "r", "R": compLine(line: i)
      case "a", "A": threeTransLine(line: i, frame: 0, reverse: false)
      case "b", "B": threeTransLine(line: i, frame: 1, reverse: false)
      case "c", "C": threeTransLine(line: i, frame: 2, reverse: false)
      case "d", "D": threeTransLine(line: i, frame: 2, reverse: true)
      case "e", "E": threeTransLine(line: i, frame: 1, reverse: true)
      case "f", "F": threeTransLine(line: i, frame: 0, reverse: true)
      case "1": oneTransLine(line: i, frame: 0, reverse: false)
      case "2": oneTransLine(line: i, frame: 1, reverse: false)
      case "3": oneTransLine(line: i, frame: 2, reverse: false)
      case "4": oneTransLine(line: i, frame: 2, reverse: true)
      case "5": oneTransLine(line: i, frame: 1, reverse: true)
      case "6": oneTransLine(line: i, frame: 0, reverse: true)
      case "_": blankLine(line: i)
      default: break
      }
    }
  }
  
  // Break each format line in order to render as a paged report
  mutating func writeLines(_ buffer: inout String) {
    
    let lineSize: Int = blocksPerLine * options.blockSize
    
    for cursor in stride(from: 0, to: strand.count - 1, by: lineSize ) {

      for line in 0..<format.count {
        let symbol = format[line]
        
        // Check here for spacing line, 'symbol:_' or empty translation line
        switch symbol {
        case "_": buffer.append("\n"); continue
        case "A","B","C","D","E","F",
             "a","b","c","d","e","f",
             "1","2","3","4","5","6":
          let upperBound = min(strand.count, cursor + (options.blockSize * blocksPerLine))
          let lineArray = Array(lines[line])
          let test = String(lineArray[cursor..<upperBound])
          if test.trimmingCharacters(in: .whitespaces).isEmpty {
            continue
          }
        default: break
        }
        
        // Left edge labels
        buffer.append(writeLeftSide(at: cursor, symbol: symbol))
        
        // Sequence content
        if format[line] == "#" {
          buffer.append(writeNumberLine(from: cursor))
        } else {
          buffer.append(writeContent(lines[line], symbol: symbol, from: cursor))
        }
        
        // Right edge labels
        var rightValue = cursor + lineSize
        rightValue = rightValue > strand.count ? strand.count : rightValue
        buffer.append(writeRightSide(at: rightValue, symbol: symbol))
        buffer.append("\n")
      }
    }
    
  }
  
  // We will format this line when we write it out; Placeholder here
  mutating func numberLine(line: Int)  {
    lines[line] = ""
  }
  mutating func dotLine(line: Int)  {
    for i in 0..<strand.count {
      lines[line].append((((i + 1) % 10) == 0) ? "." : " ");
    }
  }
  
  mutating func seqLine(line: Int)  {
    lines[line] = String(strand)
  }
  
  mutating func compLine(line: Int)  {
    let compBase:[Character:String] = [
      "A":"T", "C":"G", "G":"C", "T":"A", "U":"A",
      "a":"t", "c":"g", "g":"c", "t":"a", "u":"a",
      "N":"N", "n":"n",  "-":"-"
    ]

    for i in 0..<strand.count {
      lines[line].append(compBase[strand[i]] ?? "")
    }
  }
  
  mutating func dashLine(line: Int)  {
    for i in 0..<strand.count {
      lines[line].append((((i + 1) % 10) == 0) ? "+" : "-");
    }
  }
  
  mutating func threeTransLine(line: Int, frame: Int, reverse: Bool) {
    
    // Skip to start of translation; TODO
//    int i = 0;
//    while (((i + 1) < mTranslateFrom) && (i < mSequence.length)) {
//        theLine.append(' ');
//        i++;
//    }

    // Push the the in
    if (frame == 1) {
      lines[line].append(" ");
    } else if (frame == 2) {
      lines[line].append("  ")
    }
    
    for i in stride(from: 0, to: strand.count - (frame + 3) + 1, by: 3 ) {

      var codon: String = String(strand[i..<i + 3])
      
      if (reverse) {
        codon = Sequence.reverseComp(codon)
      }

      let aa: String = Sequence.codonToAA(codon);
      lines[line].append(Sequence.oneToThree(Character(aa)));

      // Stop translating
      if (options.obeyStopCodons && (aa == "*")) {
        break;
      }

    }
    
    // Pad out this line with spaces
    padLine(line);
  }
  
  mutating func oneTransLine(line: Int, frame: Int, reverse: Bool)  {
    
    // Skip to start of translation; TODO
//    int i = 0;
//    while (((i + 1) < mTranslateFrom) && (i < mSequence.length)) {
//        theLine.append(' ');
//        i++;
//    }

    // Push the the in
    if (frame == 1) {
      lines[line].append(" ");
    } else if (frame == 2) {
      lines[line].append("  ")
    }
    
    for i in stride(from: 0, to: strand.count - (frame + 3) + 1, by: 3 ) {

      var codon: String = String(strand[i..<i + 3])
      
      if (reverse) {
        codon = Sequence.reverseComp(codon)
      }

      let aa: String = Sequence.codonToAA(codon);
      lines[line].append(" ")
      lines[line].append(aa)
      lines[line].append(" ")

      // Stop translating at first STOP codon
      if (options.obeyStopCodons && (aa == "*")) {
        break;
      }

    }
    
    // Pad out this line with spaces
    padLine(line);

  }
  
  
  mutating func blankLine(line: Int)  {
    for _ in 0..<strand.count {
      lines[line].append(" ");
    }
  }
  
  mutating func writeLeftSide(at: Int, symbol: Character) -> String {
  
    var buffer: String = ""
    var leftNum = at + 1
    
    switch symbol {
    case "+","S","R": buffer.append(F.f(leftNum, width: 6))
    case "A","B","C","D","E","F":
      leftNum = Int(floor(Double(leftNum + 3) / 3.0))
      buffer.append(F.f(leftNum, width: 6))
    default:  buffer.append(F.f(" ", width: 6))
    }
  
    buffer.append(" ")
    return buffer
  }

  mutating func writeNumberLine(from: Int) -> String {
    var buffer: String = ""

    var blckSize: Int = 0;
    var blcksPerLine: Int = 0;
    var base: Int = from + 1

    var lastLbl: Int = base - 1
    var numberOfBlocks: Int = 0

    while base <= strand.count {

        // Write a number every 10 characters
        if ((base % 10) == 0) {

          let size: Int = F.f(base).count
          let space = (base - lastLbl) + numberOfBlocks;

            if (space >= size) {

              if (space > size) {
                buffer.append(F.f(" ", width: space - size));
              }

              buffer.append(F.f(base));
            } else {
              buffer.append(F.f(" ", width: space));
            }

            numberOfBlocks = 0;
            lastLbl = base;
        }

        blckSize += 1

        if (blckSize == options.blockSize) {
            numberOfBlocks += 1
            blcksPerLine += 1
            blckSize = 0;
        }


      if (blcksPerLine == blocksPerLine) {
            break;
      }

        base += 1
    }
    
    return buffer
  }
  
  
  mutating func writeContent(_ line: String, symbol: Character, from: Int) -> String {
    
    var buffer: String = ""
    let lineArray = Array(line)

    var blckSize: Int = 0;
    var blcksPerLine: Int = 0;
    var i: Int = from

    while i < strand.count {
      buffer.append(lineArray[i])
      blckSize += 1
      
      if (blckSize == options.blockSize) {
        buffer.append(" ");
        blcksPerLine += 1;
        blckSize = 0;
      }
      
      if blcksPerLine == blocksPerLine {
          break
      }

      i += 1
    }
  
    // Pad a space after last incomplete block
    if blckSize != 0 {
      buffer.append(" ")
    }
    
    return buffer
  }
  
  mutating func writeRightSide(at: Int, symbol: Character) -> String {
    var buffer: String = ""
    
    switch symbol {
    case "+","S","R": buffer.append(F.f(at, width: 6, flags: F.flag.LJ))
    case "A","B","C","D","E","F":
      let rightNum = Int(floor(Double(at - 1 + 3) / 3.0))
      buffer.append(F.f(rightNum, width: 6, flags: F.flag.LJ))
    default: break
    }
  
    buffer.append(" ")

    return buffer
  }

  mutating func padLine(_ line: Int) -> Void {

    let pad: Int = strand.count - lines[line].count
    
    if (pad > 0) {
      lines[line].append(F.f(" ", width: pad))
    }
  }

  
}
