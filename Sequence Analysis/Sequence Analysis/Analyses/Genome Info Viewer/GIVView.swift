//
//  GIVAnalysisView.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 11/11/21.
//

import SwiftUI

// V I E W  ========================================================================


struct GIVView: View {
  
  enum Example: String, CaseIterable, Identifiable {
    case CONTIG = "Contig with splice sites"
    case NESTED = "Nested Groups"

    var id: Example { self }
    
    var filename: String {
      switch self {
      case .CONTIG: return "contig.giv"
      case .NESTED: return "nested.giv"
      }
    }

  }

  

  @ObservedObject var viewModel: GIVViewModel
  @State private var currentExample: Example? = nil
  
  var body: some View {
    
    if viewModel.panel == .GRAPH {
      viewModel.update()
    }
    
    return VStack {
      VStack {
        panelPicker
        examplesMenu
      }
      Divider()
      // GIV XML Editor, Graph DTD and Colors panels go below options --------------------------
      switch viewModel.panel {
      case .GRAPH: givGraphPanel
      case .GIV: GIVEditorPanel(givXML: $viewModel.givXML)
      case .DTD: dtdPanel
      case .COLORS: ColorsPanel()
      }
    }
  }
  
  var examplesMenu: some View {
    HStack(alignment: .center) {
      Menu("GIVExamples:") {
        ForEach(Example.allCases, id: \.self) { example in
          Button(action: {
            currentExample = example
            loadExample()
          }, label: {
            Text(example.rawValue)
          })
        }
      }
      .frame(width: 150)
      .disabled(viewModel.panel != .GIV)
      
      // Currently selected example
      if let example = currentExample {
        Text(example.rawValue)
      }
      
      Spacer()

    }
  }
    
  func loadExample() -> Void {
    guard let example = currentExample else { return }
    
    do {
      let filepath = Bundle.main.path(forResource: example.filename, ofType: "xml")
      let string = try String(contentsOfFile: filepath!)
      viewModel.givXML = string
      
    } catch {
      viewModel.givXML =  "Could not load the '\(example.filename).xml' resource: \(error.localizedDescription)"
    }

  }

    
  var panelPicker: some View {
    HStack {
      Picker("", selection: $viewModel.panel) {
        ForEach(GIVViewModel.Panel.allCases, id: \.self) { panelName in
          Text(panelName.rawValue).tag(panelName)
        }
      }
      .pickerStyle(SegmentedPickerStyle())
      .font(.title)
    }
  }
  
  struct GIVEditorPanel: View {
     
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @Binding var givXML: String
    @State var showMinimap: Bool = false

    var body: some View {
      VStack {
        HStack {
          Spacer()
        }
        .padding(EdgeInsets(top: 0, leading: 32, bottom: 8, trailing: 32))

        TextEditorView($givXML)
      }
    }
  }
  
  // Show either the GIV graph or the error message
  var givGraphPanel: some View {
    if let givFrame = viewModel.givFrame, let extent = viewModel.extent {
       return AnyView(GIVGraphView(givFrame: givFrame, extent: extent))
    } else if let errorMsg = viewModel.errorMsg {
      return AnyView(TextView(text: errorMsg))
    }
    return AnyView(EmptyView())
  }

  // Show either the DTD or the error message if it could not be loaded
  var dtdPanel: some View {
    if let dtdText = viewModel.dtdText {
      return AnyView(TextView(text: dtdText))
    } else if let errorMsg = viewModel.errorMsg {
      return AnyView(TextView(text: errorMsg))
    }
    return AnyView(EmptyView())
  }
  
  
  struct ColorsPanel: View {
       
    var names: [String]

    init() {
      names = Colors.getNames().sorted()
      names = names.map {name in
        name.contains("aga") ? name.uppercased() : name.capitalized(with:  NSLocale.current)
      }
    }
    
    var body: some View {
      ScrollView {
        VStack {
          ForEach(names, id: \.self) { name in
            HStack {
              
              Button(action: {
                  let pasteboard = NSPasteboard.general
                  pasteboard.clearContents()
                  pasteboard.setString(name, forType: .string)
                }) {
                Image(systemName: "arrow.right.doc.on.clipboard")
              }
              .buttonStyle(BorderlessButtonStyle())
              
              Text(name)
                .font(.title)
                .frame(width: 250, height: 30, alignment: .leading)
              Color(Colors.get(color: name).base.cgColor!)
                .frame(height: 30)
            }
          }
        }
      }
    }
  }
    
}

  
