

import SwiftUI

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
                  print("Fetch an entry from the NCBI")
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

              // Edit the UID and/or title
              Button(action: {
                  print("Edit the UID and/or title")
              }) {
                  Image(systemName: "rectangle.and.pencil.and.ellipsis")
              }
              .disabled(windowState.currentSequenceState == nil)
              .help("Edit UID or Title")
          
              // Save the sequence per the format selected in "Format"
              Button(action: {
                  print("Save using the file format chosen in 'Format'")
              }) {
                  Image(systemName: "square.and.arrow.down")
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
        Text("Use the '+' to add a new or random sequence")
          .font(.title)
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

}
