

import SwiftUI
import AppKit

struct SequenceAnalysis: View {
  
  @EnvironmentObject var appState: AppState
  @EnvironmentObject var windowState: WindowState

  @State private var showCreateNewSequence: Bool = false
  @State private var showFetchFromNCBI: Bool = false

  
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
              Button(action: { showFetchFromNCBI = true }) {
                  Image(systemName: "network")
              }
              .sheet(isPresented: $showFetchFromNCBI){ NCBIFetchView(appState: appState) }
              .help("Fetch an entry from the NCBI,  ⌘-E")
              .keyboardShortcut("e", modifiers: .command)

              // Add a sequence
              Button(action: { showCreateNewSequence = true } ) {
                  Image(systemName: "plus")
              }
              .sheet(isPresented: $showCreateNewSequence){ NewSequenceView(appState: appState) }
              .help("Add a new sequence,  ⌥⌘-N")
              .keyboardShortcut("n", modifiers: [.option, .command])

              // Read a sequence file
              Button(action: {
                readSequenceFromFile()
              }) {
                  Image(systemName: "arrow.up.doc")
              }
              .help("Read a sequence file in .raw, .seq, .fasta, .gcg, .nbrf, .pir format")
              
              
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
              .help("Show/Hide the sequence editor, ⌘-S")
              .keyboardShortcut("s", modifiers: .command)
              
              // Edit the UID and/or title
              Button(action: {
                if let sequenceState = windowState.currentSequenceState {
                  EditUIDorTitle(sequenceState: sequenceState).openWindow()
                }
              }) {
                  Image(systemName: "rectangle.and.pencil.and.ellipsis")
              }
              .disabled(windowState.currentSequenceState == nil)
              .help("Edit UID or Title")

              Spacer(minLength: 15)
              
              Button(action: {
                if let sequenceState = windowState.currentSequenceState {
                  appState.removeSequeneState(sequenceState)
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
      HelpMessage()
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
    panel.allowedFileTypes  = ["fasta", "raw","seq", "gcg", "nbrf", "pir"]  // TODO "gb", "genbank", "gbx", "embl"
    
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
        case "gcg": parseGCG(contents!, filename: fileURL.lastPathComponent)
        case "gb", "genbank", "gbx": break
        case "embl": break
        case "nbrf", "pir": parseNBRF(contents!)
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
    var strand: String = ""
    for (i, line) in lines.enumerated() {
      if i == 0 { continue}
      strand.append(String(line))
    }
    
    strand = strand.trimmingCharacters(in: .whitespacesAndNewlines)
                   .replacingOccurrences(of: " ", with: "")


    // Guess the sequence type from the contents and create the sequence
    let type = Sequence.guessType(strand)
    let sequence = Sequence(strand, uid: uid, title: title, type: type)
    let _ = appState.addSequence(sequence)
  }
  
  func parseRaw(_ contents: String, filename: String) {
    let uid = ""
    let title = "File: \(filename)"
    let strand = contents.trimmingCharacters(in: .whitespacesAndNewlines)
                         .replacingOccurrences(of: " ", with: "")
    let type = Sequence.guessType(strand)
    let sequence = Sequence(strand, uid: uid, title: title, type: type)
    let _ = appState.addSequence(sequence)
  }

  func parseGCG(_ contents: String, filename: String) {
    
    var uid = ""
    let title = "File: \(filename)"

    // Break the file into lines
    let lines: [String.SubSequence] = contents.split(whereSeparator: \.isNewline)
    
    // Find the magic dots '..' to find the UID
    var lineNumber: Int = 0
    for (i, line) in lines.enumerated() {
      let magicDots = line.range(of: "..")
      if magicDots == nil {
        continue // magic dots '..' not found yet
      } else {
        // extract the UID; Beginning to first space
        if let spaceIndex = line.firstIndex(of: " ") {
          uid = String(line[line.startIndex..<spaceIndex])
          lineNumber = i // sequence after this line to the end
          break
        }
      }
    }
    
    var strand: String = ""
    for (i, line) in lines.enumerated() {
      if i <= lineNumber { continue }
      let prefix = line.index(line.startIndex, offsetBy: 10)
      strand.append(String(line[prefix...]))
    }
    
    strand = strand.trimmingCharacters(in: .whitespacesAndNewlines)
                   .replacingOccurrences(of: " ", with: "")

    // Guess the sequence type from the contents and create the sequence
    let type = Sequence.guessType(strand)
    let sequence = Sequence(strand, uid: uid, title: title, type: type)
    let _ = appState.addSequence(sequence)
    
  }

  func parseNBRF(_ contents: String) {
      
    // Break the file into lines
    let lines: [String.SubSequence] = contents.split(whereSeparator: \.isNewline)
    
    // The title is the second line
    let title = String(lines[1])
    
    // Get the index of the ';' and get the UID
    let line = String(lines[0])
    let uidStart = line.index(line.startIndex, offsetBy: 4)
    let uid: String = String(line[uidStart...])

    // Get the sequence type indicator; DNA or PROTEIN for now
    let typeStart = line.index(line.startIndex, offsetBy: 1)
    let semiColonIndex = line.firstIndex(of: ";")
    var type: SequenceType = .DNA
    if let semiColonIndex = semiColonIndex {
      let typeMarker = line[typeStart..<semiColonIndex]
      if typeMarker == "P1" {
        type = .PROTEIN
      }
    }
    
    // the sequence is everything up to an '*' character
    var strand: String = ""
    for (i, line) in lines.enumerated() {
      if i <= 1 { continue }
      if let endIndex = line.firstIndex(of: "*") {
        strand.append(String(line[line.startIndex..<endIndex]))
        break
      } else {
        strand.append(String(line))
      }
    }

    // Remove any whitespace and new lines
    strand = strand.trimmingCharacters(in: .whitespacesAndNewlines)
                   .replacingOccurrences(of: " ", with: "")

    // Create the sequence and add it the application
    let sequence = Sequence(strand, uid: uid, title: title, type: type)
    let _ = appState.addSequence(sequence)
    
  }

  
}
