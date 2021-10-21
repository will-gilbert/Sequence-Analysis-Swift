

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
                readSequenceFromFile()
              }) {
                  Image(systemName: "arrow.up.doc")
              }
              .help("Read a sequence file from disk")
              
              
              // Save the sequence per the format selected in "Format"
              Button(action: {
                saveSequenceToFile()
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
  
  
  func saveSequenceToFile() {
        
    if let sequenceState = windowState.currentSequenceState {
      var formatFile = FormatFile(sequence: sequenceState.sequence)
      let text: String = formatFile.doFileFormat(sequenceState.fileFormat)
      
      var filename: String = sequenceState.sequence.uid
      filename.append(".")
      filename.append(sequenceState.fileFormat.fileType)

      let panel = NSSavePanel()
      panel.nameFieldLabel = "Save sequence file as:"
      panel.nameFieldStringValue = filename
      panel.canCreateDirectories = true
      panel.allowedFileTypes  =
        ["fasta", "raw"," seq", "gcg", "gb", "genbank", "gbx", "embl",
         "nbrf", "pir"]

      panel.begin { response in
           if response == NSApplication.ModalResponse.OK, let fileUrl = panel.url {
             do {
                 try text.write(to: fileUrl, atomically: true, encoding: String.Encoding.utf8)
             } catch {
                 // failed to write file (bad permissions, bad filename etc.)
             }
           }
       }
    }
  }
  
  func readSequenceFromFile() {
    let panel = NSOpenPanel()
    
    panel.title = "Choose a text sequence file"
    panel.showsResizeIndicator    = true;
    panel.showsHiddenFiles        = false;
    panel.allowsMultipleSelection = false;
    panel.canChooseDirectories = false;
    panel.allowedFileTypes  =
      ["fasta", "raw","seq", "gcg", "gb", "genbank", "gbx", "embl",
       "nbrf", "pir"]
    
    if (panel.runModal() ==  NSApplication.ModalResponse.OK) {
      if let fileURL: URL = panel.url {
        let extention = fileURL.pathExtension
        
        var contents: String?
        do {
            contents = try String(contentsOf: fileURL, encoding: .utf8)
        }
        catch {
          return
        }
        
        guard contents != nil else { return }

        switch extention {
        case "fasta", "seq": parseFasta(contents!, filename: fileURL.lastPathComponent)
        case "raw": parseRaw(contents!, filename: fileURL.lastPathComponent)
        case "gcg": break
        case "gb", "genbank", "gbx": break
        case "embl": break
        case "nbrf", "pir": break
        default: break
        }
        
      } else {
        return
      }
    }
  }
  
  
  func parseFasta(_ contents: String, filename: String) {
    
    // Break the file into lines
    let lines: [String.SubSequence] = contents.split(whereSeparator: \.isNewline)
    
    // Get the indices of the '>' and first space
    let line = String(lines[0])
    let uidStart = line.index(line.startIndex, offsetBy: 1)
    let spaceIndex = line.firstIndex(of: " ")
    
    // This '.seq' might be a raw file i.e not '>' at the first position
    var uid = ""
    var title = "File: \(filename)"
    if let spaceIndex = spaceIndex {
      uid = String(line[uidStart..<spaceIndex])
      let titleStart = line.index(after: spaceIndex)
      title = String(line[titleStart...])
    } else {
      parseRaw(contents, filename: filename)
      return
    }

    // Concat the rest of the lines as the sequene strand
    var string: String = ""
    for (i, line) in lines.enumerated() {
      if i == 0 { continue}
      string.append(String(line).trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // Guess the sequence type from the contents and create the sequence
    let type = Sequence.guessType(string)
    let sequence = Sequence(string, uid: uid, title: title, type: type)
    let _ = appState.addSequence(sequence)
  }
  
  func parseRaw(_ contents: String, filename: String) {
    let uid = ""
    let title = "File: \(filename)"
    let string = contents.trimmingCharacters(in: .whitespacesAndNewlines)
    let type = Sequence.guessType(string)
    let sequence = Sequence(string, uid: uid, title: title, type: type)
    let _ = appState.addSequence(sequence)
  }

  
  
}
