//
//  CreateSequence.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 10/10/21.
//

import SwiftUI

struct CreateNewSequence {

  var appState : AppState

  func createWindow(width: CGFloat, height: CGFloat) -> NSWindow {
    
    return NSWindow(
      contentRect: CGRect(x: 0, y: 0, width: width, height: height),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )

  }

  func openWindow() {
    
    let window = createWindow(width: 0, height: 0)
    let contents = NewSequenceView(appState: appState, window: window)
    let _ = WindowController(window: window, contents: AnyView(contents))
    
    NSApp.runModal(for: window)
  }
}
    


  // https://developer.apple.com/documentation/appkit/nswindow
  struct NewSequenceView: View {
    
    var appState : AppState

    var window: NSWindow

    @State var uid: String = ""
    @State var title: String = ""
    @State var sequenceType: SequenceType = SequenceType.DNA
    
    @State var createRandom: Bool = false
    @State var randomLength: Int = 1200
    @State var randomAlphabet: String = "ATCG"
    
    let types = [SequenceType.DNA, SequenceType.RNA, SequenceType.PROTEIN, SequenceType.PEPTIDE]
    
    var body: some View {
      
      let tempUID = Sequence.nextUID()
            
     return Group {
        
        Section(header: SectionHeader(name: "New Sequence")) {
          Text("")
        }
        
        Section {
          VStack(alignment: .leading) {
            HStack {
              Text("Unique ID")
              TextField("\(tempUID)", text: $uid).frame(width: 100)
            }
            HStack {
              Text("Title")
              TextField("Untitled", text: $title)
            }
          }
        }

        Section {
            Picker("Type", selection: $sequenceType) {
              Text("DNA").tag(SequenceType.DNA)
              Text("RNA").tag(SequenceType.RNA)
              Text("Protein").tag(SequenceType.PROTEIN)
              Text("Peptide").tag(SequenceType.PEPTIDE)
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: sequenceType) { _ in
                switch sequenceType {
                case .DNA: randomAlphabet = Alphabet.DNA.rawValue
                case .RNA: randomAlphabet = Alphabet.RNA.rawValue
                case .PROTEIN, .PEPTIDE: randomAlphabet = Alphabet.PROTEIN.rawValue
                default: randomAlphabet = Alphabet.DNA.rawValue
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
              window.close()
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
                  title = "Radomized using \(randomAlphabet)"
                }
              }
              
              
              uid = uid.isEmpty ? tempUID : uid
              title = title.isEmpty ? "Untitled" : title
              let sequence = Sequence(string, uid: uid, title: title, type: sequenceType)
              let _ = appState.addSequence(sequence)
              window.close()

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
