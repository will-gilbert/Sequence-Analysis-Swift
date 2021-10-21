

import SwiftUI
import AppKit

struct SequenceAnalysis: View {
  
  @EnvironmentObject var appState: AppState
  @EnvironmentObject var windowState: WindowState

  let window: NSWindow?

  var body: some View {
        
    return NavigationView {
      self.availableSequences
        .frame(minWidth: 200, maxWidth: 300, minHeight: 300, alignment: .leading)
        .padding()
        .toolbar {

          ToolbarItemGroup(placement: .navigation) {
            HStack(spacing: 3) {
              
              //  NCBI Entrez
              Button(action: {
                FetchFromNCBI(appState: appState).newSequence()
              }) {
                  Image(systemName: "network")
              }.help("Fetch an entry from the NCBI")
              
              // Add a sequence
              Button(action: {
                CreateNewSequence(appState: appState).newSequence()
              }) {
                  Image(systemName: "plus")
              }
              .help("Add a new sequence")
          
              // Read a sequence file
              Button(action: {
                  print("Read a sequence file")
              }) {
                  Image(systemName: "arrow.up.doc")
              }
              .help("Read a sequence file from disk")
              
              
              // Save the sequence per the format selected in "Format"
              Button(action: {
                  print("Save using the file format chosen in 'Format'")
              }) {
                  Image(systemName: "arrow.down.doc")
              }
              .disabled(windowState.currentSequenceState == nil)
              .help("Save using the file format chosen in 'Format'")

              // Save the sequence per the format selected in "Format"
              Button(action: {
                windowState.editorIsVisible.toggle()
              }) {
                Image(systemName: windowState.editorIsVisible ? "eye" : "eye.slash")
              }
              .disabled(windowState.currentSequenceState == nil)
              .help("Show/Hide the sequence editor")
              
              // Edit the UID and/or title
              Button(action: {
                  print("Edit the UID and/or title")
              }) {
                  Image(systemName: "rectangle.and.pencil.and.ellipsis")
              }
              .disabled(windowState.currentSequenceState == nil)
              .help("Edit UID or Title")

              Spacer(minLength: 15)
              
              Button(action: {
                if let seqeunceState = windowState.currentSequenceState {
                  appState.removeSequeneState(seqeunceState)
                  windowState.currentSequenceState = nil
                }
              }) {
                  Image(systemName: "trash")
              }
              .disabled(windowState.currentSequenceState == nil)
              .help("Remove seqeunce from the sidebar")

              Spacer(minLength: 20)
            }
          }
        }
        .presentedWindowToolbarStyle(ExpandedWindowToolbarStyle())
      VStack {
        Text("Use the \(Image(systemName:"plus")) button to add a new or random sequence or")
        Text("use the \(Image(systemName:"network")) button to fetch an entry from the NCBI.")
        Text("")
        Text("Most buttons have a tooltip when you hover over them.")
      }.font(.body)
    }
    .frame(maxWidth: .infinity)
    .frame(maxHeight: .infinity)
  }
    
  // List of Sequences; Nucleic and Protein
  var availableSequences: some View {
    AvailableSequencesList(window: window)
    .toolbar {
      // Show/Hide the list of available sequences
      ToolbarItem {
        Button(action: toggleSideBar) {
          Label("Hide/Show Sidebar", systemImage: "sidebar.left")
        }
      }
//      ToolbarItem {
//        Button(action:{}) {
//          Label("Hide/Show Sequences", systemImage: "list.dash")
//        }
//      }
    }
  }
  
  func toggleSideBar() {
    NSApp.keyWindow?.firstResponder?.tryToPerform(
      #selector(NSSplitViewController.toggleSidebar),
      with: nil)
  }
  
  func createAddMessage() -> String {
    let imageAttachment = NSTextAttachment()
    imageAttachment.image = NSImage(named: "trash")

    let fullString = NSMutableAttributedString(string: "Press the ")
    fullString.append(NSAttributedString(attachment: imageAttachment))
    fullString.append(NSAttributedString(string: " button"))
    return fullString.string
  }

}
