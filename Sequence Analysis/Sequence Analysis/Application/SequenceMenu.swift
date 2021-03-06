import SwiftUI

struct SequenceMenu: Commands {
 
  @ObservedObject var appState : AppState
  
  var body: some Commands {

    CommandMenu("Sequence") {
      
      Menu("Show") {
        Button("All") { showAll() }.keyboardShortcut("1", modifiers: [.command, .option])
        Button("Only Nucleic") { showNucleic() }.keyboardShortcut("2", modifiers: [.command, .option])
        Button("Only Protein") { showProtein() }.keyboardShortcut("3", modifiers: [.command, .option])
      }
    }
  }

  func showAll() -> Void {
    DispatchQueue.main.async {
      appState.showOnly.removeAll()
      appState.showOnly.append( contentsOf: [
        SequenceType.DNA,
        SequenceType.RNA,
        SequenceType.PROTEIN,
        SequenceType.PEPTIDE
      ])
    }
  }
    
  func showNucleic() -> Void {
    DispatchQueue.main.async {
      appState.showOnly.removeAll()
      appState.showOnly.append( contentsOf: [
        SequenceType.DNA,
        SequenceType.RNA
      ])
    }
  }
  
  
  func showProtein() -> Void {
    DispatchQueue.main.async {
      appState.showOnly.removeAll()
      appState.showOnly.append( contentsOf: [
        SequenceType.PROTEIN,
        SequenceType.PEPTIDE,
      ])
    }
  }

}
