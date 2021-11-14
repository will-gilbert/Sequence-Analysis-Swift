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
      
      //print("Features: Redraw View")
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
       return AnyView(GraphView(givFrame: givFrame, extent: extent))
    } else if let errorMsg = viewModel.errorMsg {
      return AnyView(TextView(text: errorMsg))
    }
    return AnyView(EmptyView())
  }


  // F E A T U R E S   G R A P H  ======================================================================

  struct GraphView: View {
    
    @EnvironmentObject var sequenceState: SequenceState

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
          
          if let glyph = sequenceState.selectedFeatureGlyph {
            let element = glyph.element
            let style = glyph.style
            let name = element.label
            let size = "\(element.start)-\(element.stop) length: \(element.stop - element.start + 1)"
            let type = style.name

//            if type == "ORF" {
//              let aa: Int = Int(Double(element.stop - element.start + 1)/3.0)
//              Text("\(name); \(size)bp (\(aa)aa); \(type)")
//            } else {
              Text("\(name); \(size)bp; \(type)")
//            }
          } else {
            Text(" ")
          }

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

