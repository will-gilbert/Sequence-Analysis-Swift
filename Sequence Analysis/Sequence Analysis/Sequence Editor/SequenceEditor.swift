//
//  SequenceEditor.swift
//
//
//  Created by Will Gilbert on 8/31/21.
//

import SwiftUI

public typealias OnSelectionChangeCallback = (NSRange) -> Void
public typealias EmptyCallback = () -> Void
public typealias OnCommitCallback = EmptyCallback
public typealias OnEditingChangedCallback = EmptyCallback
public typealias OnTextChangeCallback = (_ editorContent: String) -> Void

struct SequenceEditor: View {
  
  @EnvironmentObject var appState: AppState
  @EnvironmentObject var windowState: WindowState
  @EnvironmentObject var sequenceState: SequenceState

//  var sequence: Sequence
  
  @State var caseToggle: Bool = false
    
  @State private var position: String = ""
  @State private var editorHasSelection: Bool = false
  private var length: Int = 0
  
  let symbolSize = CGFloat(13)
  let symbolWeight = Font.Weight.medium
    
  var body: some View {
    return VStack(alignment: .leading) {
      
      HStack {
        translateSelectionBtn
        caseChangeBtn
        rna2dna2rnaBtn
        reverseComplementBtn
        shuffleBtn
        copySequence
        
        Spacer()
        Text(position)
          .font(.system(size: symbolSize, weight: symbolWeight))

        Spacer()
        Text("Length: \(sequenceState.sequence.length)")
          .font(.system(size: symbolSize, weight: symbolWeight))

      }
      .padding(6)
      
      SequenceEditorView(
        $sequenceState.sequence.string,
        alphabet: sequenceState.sequence.alphabet,
        selection: $sequenceState.selection,
        isEditable: true,
        fontSize: 14
      )
      .onCommit {}
      .onEditingChanged {}
      .onTextChange { text in
        // Not sure why I need this. Bad things otherwise.
        //sequenceState.selection = nil
      }
      .onSelectionChange { (range: NSRange) in
                
        // Update outside of the UI thread
        DispatchQueue.main.async {
          editorHasSelection = range.length != 0
          if range.length == 0 {
            self.position = "Position: \(range.location + 1)"
          } else {
            self.position = "Selection: \(range.location + 1)-\(range.location + range.length), \(range.length) bp"
          }
        }
        
      }
    }
  }
  
  var caseChangeBtn: some View {
    Button(action: {
      DispatchQueue.main.async {
        if caseToggle {
          sequenceState.sequence.string = sequenceState.sequence.string.uppercased()
        } else {
          sequenceState.sequence.string = sequenceState.sequence.string.lowercased()
        }
        caseToggle.toggle()
        sequenceState.changed.toggle()
      }
    }) {
      Text("A") + Text(Image(systemName: "arrow.left.arrow.right")) + Text("a")
        .font(.system(size: symbolSize, weight: symbolWeight))
    }
    .disabled(sequenceState.sequence.length == 0)
    .help("Toggle Uppercase/Lowercase")
  }
  
  var translateSelectionBtn: some View {
    Button(action: {
          
      guard let range = sequenceState.selection else { return }
      
      let from = range.location
      let to  = range.location + range.length
      
      let orf = String(Array(sequenceState.sequence.string)[from...to])
      let protein = Sequence.nucToProtein(orf)

      let uid = Sequence.nextUID()
      let title = "Translate from '\(sequenceState.sequence.uid)', \(from + 1)-\(to)"
      let sequence = Sequence(protein, uid: uid, title: title, type: .PROTEIN)
      sequence.alphabet = .PROTEIN
      
      // Change the state in the main thread
      DispatchQueue.main.async {
        let newSequenceState = appState.addSequence(sequence)
        windowState.currentSequenceState = newSequenceState
      }
      
    }) {
      Text("NA➜AA")
        .font(.system(size: symbolSize, weight: symbolWeight))
    }
    .font(.system(size: symbolSize, weight: symbolWeight))
    .disabled(sequenceState.sequence.isProtein || editorHasSelection == false)
    .help("Translate Selection")
  }
  
  var rna2dna2rnaBtn: some View {
    Button(action: {
      DispatchQueue.main.async {
        let sequence = sequenceState.sequence.string
        if(sequenceState.sequence.isDNA) {
          sequenceState.sequence.string = Sequence.DNAtoRNA(sequence)
          sequenceState.sequence.type = .RNA
        } else {
          sequenceState.sequence.string = Sequence.RNAtoDNA(sequence)
          sequenceState.sequence.type = .DNA
        }
        sequenceState.changed.toggle()
      }
    }) {
      Text("T") + Text(Image(systemName: "arrow.left.arrow.right")) + Text("U")
    }
    .disabled(sequenceState.sequence.isProtein || sequenceState.sequence.length == 0)
    .font(.system(size: symbolSize, weight: symbolWeight))
    .help("DNA to/from RNA")
  }
  
  var reverseComplementBtn: some View {
    Button(action: {
      DispatchQueue.main.async {
        let sequence = sequenceState.sequence
        sequenceState.sequence.string = Sequence.reverseComp(sequence.string, type: sequence.type)
        sequenceState.changed.toggle()
      }
    }) {
      Image(systemName: "arrow.left.arrow.right")
    }
    .disabled(sequenceState.sequence.isProtein || sequenceState.sequence.length == 0)
    .font(.system(size: symbolSize, weight: symbolWeight))
    .help("Reverse Complement")
  }
  
  var shuffleBtn: some View {
    Button(action: {
      let strand = Array(sequenceState.sequence.string)
      let shuffled = strand.shuffled()
      sequenceState.sequence.string = String(shuffled)
      sequenceState.changed.toggle()
    }) {
      Image(systemName: "shuffle")
    }
    .disabled(sequenceState.sequence.length == 0)
    .font(.system(size: symbolSize, weight: symbolWeight))
    .help("Shuffle")
  }
  
  var copySequence: some View {
    Button(action: {
      print("Create a copy")
      let uid = sequenceState.sequence.uid
      let title = sequenceState.sequence.title
      let type = sequenceState.sequence.type
      let text = sequenceState.sequence.string
      let newSequence = Sequence(text, uid: uid, title: title, type: type)
      newSequence.alphabet = sequenceState.sequence.alphabet
      let _ = appState.addSequence(newSequence)
      
    }) {
      Image(systemName: "doc.on.doc")
    }
    .font(.system(size: symbolSize, weight: symbolWeight))
    .help("Create a copy")

  }
  
}
