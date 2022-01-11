//
//  Composition.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/14/21.
//

import SwiftUI


struct FormatView: View {
  
  @ObservedObject var sequenceState: SequenceState
  @ObservedObject var sequenceSelectionState: SequenceSelectionState

  @State var text: String = ""

  init(sequenceState: SequenceState) {
    self.sequenceState = sequenceState
    
    // Observe any changes in the sequence selection; Recalculate
    sequenceSelectionState = sequenceState.sequenceSelectionState
  }


  var body: some View {
  
    DispatchQueue.main.async {
      text.removeAll()
      
      var sequence = sequenceState.sequence
      
      if let selection = sequenceSelectionState.selection, selection.length > 0 {
        // Create a temporary sequence from the selection
        let start = selection.location
        let length = selection.length
        let title = sequence.title + " (\(start)-\(start + length - 1))"
        let strand = sequence.string.substring(from: start - 1 , length: length)
        
        sequence = Sequence(strand, uid: sequence.uid, title: title, type: sequence.type)
      }
      
      var formatFile = FormatFile(sequence: sequence)
      text = formatFile.doFileFormat(sequenceState.fileFormat)
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
    }
  }
  
}
