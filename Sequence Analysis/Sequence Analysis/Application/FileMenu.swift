//
//  FileMenu.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/9/21.
//

import SwiftUI

struct FileMenu: Commands {
 
  var appState : AppState
  @State private var showCreateNewSequence: Bool = false

  var body: some Commands {

    CommandGroup(after: CommandGroupPlacement.newItem, addition: {
      Divider()
//      Button("New Sequence")  { showCreateNewSequence = true }
//      .sheet(isPresented: $showCreateNewSequence){ NewSequenceView(appState: appState) }
//      .keyboardShortcut("n", modifiers: [.command, .option])

      Button("Remove All Sequences")  {
        removeAllSequences()
      }
      .keyboardShortcut(.delete, modifiers: [.command, .option])
    })
  }
  

  func removeAllSequences() {
    
    // https://www.appcoda.com/macos-programming-alerts/
    
    let alert = NSAlert()
    alert.messageText = "Are you sure you want to delete all of the sequences?"
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "Cancel")

    let response = alert.runModal()
      
    if response == .alertFirstButtonReturn {
      DispatchQueue.main.async {
        appState.removeAllSequences()
      }

    }
    
  }
}
  
