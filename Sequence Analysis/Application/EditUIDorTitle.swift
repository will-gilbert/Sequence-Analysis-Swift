//
//  EditUIDorTitle.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 10/22/21.
//

import SwiftUI

struct EditUIDorTitle {

  var sequenceState : SequenceState

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
    let contents = EditUIDorTitleView(sequenceState: sequenceState, window: window)
    let _ = WindowController(window: window, contents: AnyView(contents))
    
    NSApp.runModal(for: window)
  }
}
    


  // https://developer.apple.com/documentation/appkit/nswindow
  struct EditUIDorTitleView: View {
    
    var sequenceState : SequenceState
    var window: NSWindow
    
    @State var uid: String
    @State var title: String

    init(sequenceState: SequenceState, window: NSWindow) {
      self.sequenceState = sequenceState
      self.window = window
      uid = sequenceState.sequence.uid
      title = sequenceState.sequence.title
    }

    var body: some View {
      
            
     return Group {
        
        Section(header: SectionHeader(name: "Edit UID or Title")) {
          Text("")
        }
        
        Section {
          VStack(alignment: .leading) {
            HStack {
              Text("Unique ID")
              TextField("", text: $uid).frame(width: 100)
            }
            HStack {
              Text("Title")
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
              window.close()
            }) {
              Text("Cancel")
            }.keyboardShortcut(.cancelAction)

            // O K  =====================================
            Button(action: {
              
              sequenceState.sequence.uid = uid
              sequenceState.sequence.title = title
              sequenceState.changed = true // On macOS use this to force an update to the 'NavigationTitle"
                            
              window.close()

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
