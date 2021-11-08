//
//  ORFView.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/14/21.
//

import Foundation
import SwiftUI


struct ORFOptions {
  var minORFsize: Int = 30
  var startCodons: Bool = true
  var stopCodons: Bool = true
  var internalATG: Bool = true
}

// V I E W  ========================================================================

struct ORFView: View {
       
  @ObservedObject var sequence: Sequence
  @ObservedObject var viewModel: ORFViewModel
  
  @State private var minORFSize: Double = 17.0
  @State private var startCodons: Bool = true
  @State private var stopCodons: Bool = true
  @State private var internalATG: Bool = true
  
  var body: some View {
    
    // One of the states or sequence has changed, rebuilt the view model then redraw the view
    //print("ORF: Redraw View")
    updateViewModel()
    
    return VStack {
      VStack {
        HStack { toggleButtons; Spacer(); Divider() ; Spacer() ; minORFSlider ; Spacer() }
        HStack { panelPicker ; Spacer().frame(width: 15) ; copyToClipboardBtn } //; copyToFileBtn }
      }
      .padding()
      .frame(height: 150)
      
      Divider()
      
      // Graph, XML, JSON and GIV panels go below options --------------------------
      
      if (viewModel.xmlDocument != nil) {
        switch viewModel.panel {
        case .GRAPH: GraphView(givFrame: viewModel.givFrame!, sequence: sequence)
        case .XML, .JSON: TextView(text: viewModel.text)
        case .GIV:
          TextView(text: viewModel.givXML)
        }
      }
    }
  }
  
  
  var toggleButtons: some View {
    VStack(alignment: .leading, spacing: 3.0) {
      Toggle("Start codons", isOn: $startCodons)
        .foregroundColor(Colors.get(color: "Navy").base)
      Toggle("Stop codons", isOn: $stopCodons)
        .foregroundColor(Colors.get(color: "Magenta").base)
      Toggle("Internal 'ATG' as 'Met'", isOn: $internalATG)
        .foregroundColor(Colors.get(color: "Navy").base)

    }
  }
  
  var minORFSlider: some View {
    VStack { // min ORF size
      HStack(alignment: .center, spacing: 5.0) {
        Text("Minimum ORF size in aa:")
        Text(String(Int(minORFSize)))
      }
      .foregroundColor(Colors.get(color: "Green").base)
      
      Slider(
        value: $minORFSize,
        in: 1...120
      )

    }.frame(width: 220)
  }
  
  var panelPicker: some View {
    Picker("", selection: $viewModel.panel) {
      ForEach(ORFViewModel.Panel.allCases, id: \.self) { panelName in
        Text(panelName.rawValue).tag(panelName)
      }
    }
    .pickerStyle(SegmentedPickerStyle())
    .disabled(sequence.length == 0 || sequence.isProtein)
    .font(.title)
  }
  
  var copyToClipboardBtn: some View {
    Button(action: {
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.setString(viewModel.text, forType: .string)
    }) {
      Image(systemName: "arrow.right.doc.on.clipboard")
    }
    .disabled( viewModel.panel == .GRAPH)
    .help("Copy to Clipboard")
  }

  var copyToFileBtn: some View {
    Button(action: {
      print("Save to File")
    }) {
      Image(systemName: "square.and.arrow.down")
    }
    .disabled( viewModel.panel == .GRAPH)
    .help("Save to File")
  }

  
  func updateViewModel() -> Void {
    
    // Pass in the state variables, it will be displayed when 'ORF' is finished
    var options = ORFOptions()
    options.minORFsize = Int(minORFSize)
    options.startCodons = startCodons
    options.stopCodons = stopCodons
    options.internalATG = internalATG
    
    viewModel.update(sequence: sequence, options: options)
  }

  
  // O R F   M A P  ==============================================================================================

  struct GraphView: View {
 
    @EnvironmentObject var sequenceState: SequenceState

    @State var scale: Double = 1.0

    let givFrame: GIVFrame
    let extent: CGFloat
    
    var height: CGFloat = 0.0
    var width: CGFloat = 0.0

    init(givFrame: GIVFrame, sequence: Sequence) {
      self.givFrame = givFrame
      self.extent = CGFloat(sequence.length)
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
            .background(Colors.get(color: "Peach").base)
          }
          // SCROLLVIEW ----------------------------------------------------------
          
          if let glyph = sequenceState.selectedORFGlyph {
            let element = glyph.element
            let style = glyph.style
            let name = element.label
            let size = "\(element.start)-\(element.stop) length: \(element.stop - element.start + 1)"
            let type = style.name

            if type == "ORF" {
              let aa: Int = Int(Double(element.stop - element.start + 1)/3.0)
              Text("\(name); \(size)bp (\(aa)aa); \(type)")
            } else {
              Text("\(name); \(size)bp; \(type)")
            }
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






