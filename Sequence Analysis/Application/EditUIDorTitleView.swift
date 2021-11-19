//
//  EditUIDorTitle.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 10/22/21.
//

import SwiftUI

// https://developer.apple.com/documentation/appkit/nswindow
struct EditUIDorTitleView: View {
  
  var sequenceState : SequenceState
  
  @State private var uid: String
  @State private var title: String

  @Binding var isSheetVisible: Bool

  init(sequenceState: SequenceState, isSheetVisible: Binding<Bool> ) {
    self.sequenceState = sequenceState
    _uid = State(initialValue: sequenceState.sequence.uid)
    _title = State(initialValue: sequenceState.sequence.title)
    self._isSheetVisible = isSheetVisible
  }

  var body: some View {
          
   return Group {
      
      Section(header: SectionHeader(name: "Edit UID or Title")) {
        Text("")
      }
      
      Section {
        VStack(alignment: .leading) {
          HStack {
            Text("Unique ID: ")
            TextField("", text: $uid).frame(width: 100)
          }
          HStack {
            Text("Title: ")
            TextField("", text: $title)
          }
        }
      }
     
      Divider()
     
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
            
            sequenceState.sequence.uid = uid
            sequenceState.sequence.title = title
            sequenceState.changed = true // On macOS use this to force an update to the 'NavigationTitle"
                          
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
    .frame(width: 500, height: 150)
  }

  struct SectionHeader: View {
    var name: String
    var body: some View {
      Text(name)
        .font(.largeTitle)
    }
  }
}
