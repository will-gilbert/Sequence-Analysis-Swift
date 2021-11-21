//
//  Composition.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/14/21.
//

import SwiftUI


struct FormatView: View {
  
  @EnvironmentObject var sequenceState: SequenceState
  
  @State var text: String = ""

  var body: some View {
    
    // Pass in the state variables, it will be displayed when 'Format' is finished
    DispatchQueue.main.async {
      text.removeAll()
      var formatFile = FormatFile(sequence: sequenceState.sequence)
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
