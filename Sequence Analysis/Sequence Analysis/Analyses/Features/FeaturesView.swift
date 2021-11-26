//
//  FeaturesView.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 11/14/21.
//

import SwiftUI

struct FeaturesView: View {
  
  @ObservedObject var sequenceState: SequenceState
  @ObservedObject var viewModel: FeaturesViewModel
    
  init(sequenceState: SequenceState) {
    self.sequenceState = sequenceState
    self.viewModel = sequenceState.featuresViewModel
  }

  
    var body: some View {
      
      viewModel.update()
      
      return VStack {
        VStack {
          HStack { panelPicker ; Spacer().frame(width: 15) ; copyToClipboardBtn }
        }
        .padding()
        .frame(height: 150)
        
        Divider()
                
        // Features Graph, XML and GIV  --------------------------
        switch viewModel.panel {
        case .GRAPH: givGraphPanel
          
        case .GIV:
          if let givXML = viewModel.givXML {
            TextView(text: givXML)
          } else if let errorMsg = viewModel.errorMsg {
            TextView(text: errorMsg)
          }

        case .XML:
          if let text = viewModel.text {
            TextView(text: text)
          } else if let errorMsg = viewModel.errorMsg {
            TextView(text: errorMsg)
          }
        }
      }
    }
  
  var panelPicker: some View {
    Picker("", selection: $viewModel.panel) {
      ForEach(FeaturesViewModel.Panel.allCases, id: \.self) { panelName in
        Text(panelName.rawValue).tag(panelName)
      }
    }
    .pickerStyle(SegmentedPickerStyle())
    .disabled(viewModel.xmlDocument == nil)
    .font(.title)
  }
  
  var copyToClipboardBtn: some View {
    Button(action: {
      
      var string: String? = nil
      switch viewModel.panel {
      case .XML: string = viewModel.text
      case .GIV: string = viewModel.givXML
      case .GRAPH: break
      }
      
      if let string = string {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
        sequenceState.givViewModel.givXML = string
      }
    }) {
      Image(systemName: "arrow.right.doc.on.clipboard")
    }
    .buttonStyle(BorderlessButtonStyle())
    .disabled( viewModel.panel == .GRAPH || (viewModel.text == nil && viewModel.givXML == nil))
    .help("Copy to Clipboard")
  }

  
  var givGraphPanel: some View {
    if let givFrame = viewModel.givFrame, let extent = viewModel.extent {
      return AnyView(GIVGraphView(givFrame: givFrame, extent: extent, glyphReporter: glyphReporter))
    } else if let errorMsg = viewModel.errorMsg {
      return AnyView(TextView(text: errorMsg))
    }
    return AnyView(EmptyView())
  }

  func glyphReporter() -> String {

    if let glyph = sequenceState.selectedFeatureGlyph {
      let element = glyph.element
      let style = glyph.style
      let name = element.label
      let size = "\(element.start)-\(element.stop) length: \(element.stop - element.start + 1)"
      let type = style.name
      return "\(name); \(size)bp; \(type)"
    } else {
      return " "
    }

  }

}

