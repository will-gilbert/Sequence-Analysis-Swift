//
//  FetchFromNCBI.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 10/20/21.
//

// https://www.youtube.com/watch?v=Ahrix9JsaIU
//
// https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch?db=nucleotide&id=NM_000485.2&rettype=fasta
// https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch?db=protein&id=NP_061820.1&rettype=fasta
//
// https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch?db=nucleotide&id=NM_000485.2&retmode=xml
// https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch?db=nucleotide&id=NM_000485.2&retmode=json //This is ASN.1

// >NP_061820.1 cytochrome c [Homo sapiens]
// MGDVEKGKKIFIMKCSQCHTVEKGGKHKTGPNLHGLFGRKTGQAPGYSYTAANKNKGIIWGEDTLMEYLE
// NPKKYIPGTKMIFVGIKKKEERADLIAYLKKATNE

import SwiftUI

struct FetchFromNCBI {

  var appState : AppState

  func createWindow(width: CGFloat, height: CGFloat) -> NSWindow {
    
    return NSWindow(
      contentRect: CGRect(x: 0, y: 0, width: width, height: height),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )

  }

  func newSequence() {
    
    let window = createWindow(width: 0, height: 0)
    let contents = NCBIFetchView(appState: appState, window: window)
    let _ = WindowController(window: window, contents: AnyView(contents))
    
    NSApp.runModal(for: window)
  }
}
    


  // https://developer.apple.com/documentation/appkit/nswindow
  struct NCBIFetchView: View {
    
    var appState : AppState
    var window: NSWindow

    @State var entrezID: String = ""
    @State var sequenceType: SequenceType = SequenceType.DNA

    @State private var alertIsShowing = false
    @State var errorMsg: String = ""

        
    let types = [SequenceType.DNA, SequenceType.PROTEIN]
    
    var body: some View {
                  
     return Group {
        
        Section(header: SectionHeader(name: "Fetch from the NCBI")) {
          Text("")
        }
        
        Section {
            HStack {
            Text("Entrez ID")
            TextField("NM_000485.2", text: $entrezID)
          }
          Text("Examples: NM_000485 NP_061820 11128019")
            .font(.footnote)
        }

        Section {
            Picker("Database", selection: $sequenceType) {
              Text("Nucleic").tag(SequenceType.DNA)
              Text("Protein").tag(SequenceType.PROTEIN)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        Divider()
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
              
              var urlString: String = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch?"
              urlString.append("db=")
              urlString.append( sequenceType == .DNA ? "nucleotide" : "protein" )
              urlString.append("&id=")
//              urlString.append("NM_000485")
              urlString.append(entrezID)
              urlString.append("&retmode=xml")
                            
              if let url = URL(string: urlString) {
                do {
                  let contents = try String(contentsOf: url)
                  let xmlDocument = try XMLDocument(xmlString: contents)
                  let parser = NCBI_XMLParser()
                  parser.parse(xmlDocument: xmlDocument)
                  if let string = parser.sequenceString {
                    let title = parser.sequenceTitle ?? "Untitled"
                    let sequence = Sequence(string.uppercased(), uid: entrezID, title: title, type: sequenceType)
                    let _ = appState.addSequence(sequence)
                  } else if let error = parser.errorMsg {
                    alertIsShowing = true
                    errorMsg = error
                    errorMsg.append("\n\nTry the ")
                    errorMsg.append( sequenceType == .DNA ? "Protein" : "Nucleic" )
                    errorMsg.append(" database.")
                  }
                  
                } catch {
                  alertIsShowing = true
                  errorMsg = "Contents could not be loaded"
                }
              } else {
                alertIsShowing = true
                errorMsg = "Bad URL"
              }
              
              window.close()

            }) {
              Text("OK")
            }
            .keyboardShortcut(.defaultAction)
          }
          .alert(isPresented: $alertIsShowing) {
            Alert(title: Text("Fetch from NCBI"), message: Text(errorMsg), dismissButton: .default(Text("OK")))
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

class NCBI_XMLParser: NSObject, XMLParserDelegate {

  var currentElement: String = ""
  var sequenceString: String? = nil
  var sequenceTitle: String? = nil
  var errorMsg: String? = nil

  func parse(xmlDocument: XMLDocument) {
            
    let parser = XMLParser(data: xmlDocument.xmlData)
    parser.delegate = self
    let success = parser.parse()
    
    if success == false {
      if let error = parser.parserError {
        print("error:\(error)")
      } else {
        print("error: nil")
      }
    }
  }
  
  func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
    currentElement = elementName
  }
  
  func parser(_ parser: XMLParser, foundCharacters string: String) {
    
    let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    
    if data.isEmpty == false {
      switch currentElement {
      case "GBSeq_sequence": sequenceString = data
      case "GBSeq_definition":
        sequenceTitle = data
      case "ERROR":
        errorMsg = data
        if let error = errorMsg {
          if let range = error.range(of: "proxy_stream():") {
            errorMsg = String(error[range.upperBound...])
          }
        }
      default:
        break
      }
    }
  }
}
