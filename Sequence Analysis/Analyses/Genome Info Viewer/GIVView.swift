//
//  GIVAnalysisView.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 11/11/21.
//

import SwiftUI

// V I E W  ========================================================================


struct GIVView: View {
  @Environment(\.colorScheme) private var colorScheme: ColorScheme

  
  @ObservedObject var viewModel: GIVViewModel
  @State private var showMinimap: Bool = false

  var body: some View {
    
    if viewModel.panel == .GRAPH {
      viewModel.update()
    }
    
    return VStack {
      VStack {
        HStack { panelPicker } //; Spacer().frame(width: 15) } //; copyToClipboardBtn } //; copyToFileBtn }
      }
      Divider()
      // GIV XML and Graph panels go below options --------------------------
      
      switch viewModel.panel {
        
      case .GIV:
//        TextEditor(text: $viewModel.givXML)
//          .font(.body)
        VStack {
          CodeEditor(
            text: $viewModel.givXML,
            language: .xml,
            layout: CodeEditor.LayoutConfiguration(showMinimap: showMinimap)
          )
          .environment(\.codeEditorTheme, colorScheme == .dark ? Theme.defaultDark : Theme.defaultLight)
          
          HStack {

            Spacer()

            Toggle("Show Minimap", isOn: $showMinimap)
              .toggleStyle(CheckboxToggleStyle())
              .padding([.top, .bottom])

          }
          .padding(EdgeInsets(top: 0, leading: 32, bottom: 8, trailing: 32))
        }


      case .GRAPH:
        if let givFrame = viewModel.givFrame, let extent = viewModel.extent {
           GraphView(givFrame: givFrame, extent: extent)
        } else if let errorMsg = viewModel.errorMsg {
          TextView(text: errorMsg)
        }
        
      case .DTD:
        if let dtdText = viewModel.dtdText {
          TextView(text: dtdText)
        }
      case .COLORS:  viewModel.colorsView
      }
    }
  }
    
    
  var panelPicker: some View {
    Picker("", selection: $viewModel.panel) {
      ForEach(GIVViewModel.Panel.allCases, id: \.self) { panelName in
        Text(panelName.rawValue).tag(panelName)
      }
    }
    .pickerStyle(SegmentedPickerStyle())
    .font(.title)
  }
  
  var copyToClipboardBtn: some View {
    Button(action: {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(viewModel.givXML, forType: .string)
    }) {
      Image(systemName: "arrow.right.doc.on.clipboard")
    }
    .disabled( viewModel.panel == .GRAPH)
    .help("Copy to Clipboard")
  }

//  var copyToFileBtn: some View {
//    Button(action: {
//      print("Save to File")
//    }) {
//      Image(systemName: "square.and.arrow.down")
//    }
//    .disabled( viewModel.panel == .GRAPH)
//    .help("Save to File")
//  }

    
    // O R F   G R A P H  ======================================================================

    struct GraphView: View {
   
      @State var scale: Double = 1.0

      let givFrame: GIVFrame
      let extent: CGFloat
      
      var height: CGFloat = 0.0
      var width: CGFloat = 0.0

      init(givFrame: GIVFrame, extent: CGFloat) {
        self.givFrame = givFrame
        self.extent = extent
        height = givFrame.size.height
        width = givFrame.size.width
      }
          
      var body: some View {
        
        // Protect against divide by zero
        if extent.isZero {
            return AnyView(EmptyView())
        } else {

        return AnyView(
          GeometryReader { geometry in
       
          let panelWidth = geometry.size.width
          var minScale = (panelWidth/extent < 1.0) ? 1.0 : panelWidth/extent
          let maxScale = log2(extent)
          let scrollViewWidth =  extent * scale

          VStack(alignment: .leading) {
            if minScale < maxScale {
              HStack (spacing: 15) {
                Slider(
                  value: $scale,
                  in: minScale...maxScale
                ).disabled(minScale >= maxScale)
                
                Text("Pixels per BP: \(F.f(scale, decimal: 2))")
              }
            }
            
            // The following nested 'GeometryReader' and 'mapPanelView.size' is
            //   a horrible hack to get the 'mapPanelView" to at the top of the
            //   'ScrollView';  Nested 'VStack' did not; Spent 2 days on this!
            //   Maybe a macOS SwiftUI bug, maybe not.
            //   TODO: Revisit in the future.
            
            // SCROLLVIEW ----------------------------------------------------------
            GeometryReader { g in
              ScrollView( [.vertical, .horizontal], showsIndicators: true) {
               
                VStack(spacing: 0) {
                  GIVFrameView(givFrame, scale: scale)
                }.frame(width: scrollViewWidth, height: height)

                // Create a bottom 'Spacer' as needed when the GIV panels do not fill the ScrollView
                if g.size.height > height {
                  Spacer()
                  .frame(height: g.size.height - height)
                }
              }
              .background(Colors.get(color: "AGA 01").base)
            }
            // SCROLLVIEW ----------------------------------------------------------
            
          }.onAppear {
            let windowWidth = geometry.size.width
            minScale = (windowWidth/Double(extent)) < 1.0 ? 1.0 : windowWidth/Double(extent)
            scale = minScale
          }.onChange(of: geometry.frame(in: .global).width) { value in
            minScale = value/Double(extent)
            scale = scale > minScale ? scale : minScale
          }
        })
        }
      }
    }
    
  }

  
