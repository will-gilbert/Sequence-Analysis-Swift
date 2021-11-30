//
//  CreateSequence.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 10/10/21.
//

import SwiftUI

struct NewSequenceView: View {
  

  @State var uid: String = ""
  @State var title: String = ""
  @State var sequenceType: SequenceType = SequenceType.DNA
  
  @State var createRandom: Bool = false
  @State var randomLength: Int = 1200
  @State var randomAlphabet: String = "ATCG"
  
  @Binding var isSheetVisible: Bool
  
  let tempUID = Sequence.nextUID()
  let types = [SequenceType.DNA, SequenceType.RNA, SequenceType.PROTEIN, SequenceType.PEPTIDE]
  
  var body: some View {
    
    return Group {
      
      Section(header: SectionHeader(name: "New Sequence")) {
        Text("")
      }
      
      Section {
        VStack(alignment: .leading) {
          HStack {
            Text("Unique ID")
            TextField(tempUID, text: $uid).frame(width: 100)
          }
          HStack {
            Text("Title")
            TextField("Untitled", text: $title)
          }
        }
      }

      Section {
        Picker("Type", selection: $sequenceType) {
          ForEach(types, id: \.self) { type in
            Text(type.rawValue).tag(type)
          }
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: sequenceType) { _ in
            switch sequenceType {
            case .DNA: randomAlphabet = Alphabet.DNA.rawValue
            case .RNA:  randomAlphabet =  Alphabet.RNA.rawValue
            case .PROTEIN, .PEPTIDE:   randomAlphabet =   Alphabet.PROTEIN.rawValue
            case .UNDEFINED:  randomAlphabet =  Alphabet.DNA.rawValue
          }
        }
      }
      
      Divider()
      
      HStack {
        Toggle("Create Random using:", isOn: $createRandom)
        TextField(randomAlphabet, text: $randomAlphabet)
          .disabled(createRandom == false)
      }
     HStack {
       Text("Sequence Length")
       TextField(String(randomLength), text: Binding(
          get: { String(randomLength) },
          set: { randomLength = Int($0) ?? 0 }
        ))
         .disabled(createRandom == false)
     }
     
      Spacer(minLength: 10)
              
      Section {
        HStack {
          Spacer()
          // C A N C E L  ============================
          Button(action: {
            isSheetVisible = false
            NSApp.mainWindow?.endSheet(NSApp.keyWindow!)
          }) {
            Text("Cancel")
          }.keyboardShortcut(.cancelAction)

          // O K  =====================================
          Button(action: {
            
            
            // New sequence
            var string: String = ""
            
            if createRandom {
              let letters = Array(randomAlphabet.uppercased())
              for _ in 0..<randomLength {
                string += String(letters[Int.random(in: 0..<letters.count)])
              }
        
              if(title.count == 0 ) {
                title = "Randomized using \(randomAlphabet)"
              }
            }
            
            uid = uid.isEmpty ? tempUID : uid
            title = title.isEmpty ? "Untitled" : title
//            let sequence = Sequence(string, uid: uid, title: title, type: sequenceType)
//            let _ = appState.addSequence(sequence)
            
            AppSequences.shared().createSequence(string, uid: uid, title : title, type: sequenceType)
            
            isSheetVisible = false
            NSApp.mainWindow?.endSheet(NSApp.keyWindow!)
            
          }) {
            Text("OK")
          }
          .keyboardShortcut(.defaultAction)
        }

      }
    }
    .padding(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
    .frame(width: 500, height: 275)
  }

  struct SectionHeader: View {
    var name: String
    var body: some View {
      Text(name)
        .font(.largeTitle)
    }
  }
  
}

