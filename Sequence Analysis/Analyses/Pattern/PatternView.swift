//
//  PatternView.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/14/21.
//

import SwiftUI

struct PatternView: View {
  
  // External classes; Injected via the initializer
  @ObservedObject var sequence: Sequence
  @ObservedObject var viewModel: PatternViewModel
  
  // View state variables
  @State var newPattern: String = ""           // TextField to enter a pattern
  @State var isEditing: Bool = false           // Editing an existing pattern, not a new pattern
  @State var isHovering: Bool = false          // Use to move items in the list

  // Save for reference: "ATG", "TAG|TAA|TGA", "(CG){2,}", "ATG([ACGT]{3,3})*?((TAG)|(TAA)|(TGA))"

  var body: some View {
    
    // Update the pattern XML when the view is updated
    DispatchQueue.main.async {
      
      // Create the XML asynchronously using the View Model
      var pattern = Pattern(sequence, viewModel: viewModel)
      pattern.createXML()
      
      // Create the text for XML, JSON and GIV panels from the XML
      switch viewModel.panel {
      case .XML: pattern.xmlPanel()
      case .JSON: pattern.jsonPanel()
      case .GIV: pattern.givxmlPanel()
      default:
        viewModel.text = "Unimplemented"
      }

    }
    
    // V I E W  ========================================================================
    return VStack {
      
      // Pattern Options -------------------------------------------------
      
      VStack(alignment: .leading) {
        
        HStack(alignment: .top) {
          patternList
          HStack{
            editRegExField
            clearAllBtn
         }
          Spacer()
        }
        
        HStack {
          panelPicker
          Spacer().frame(width: 15)
          copyToClipboardBtn
          copyToFileBtn
          Spacer()
        }
      }
      .padding()
      .frame(height: 200)
      
      Divider()
      
      // Graph, XML, JSON and GIV panels go below options ------------------
      
      if (viewModel.xmlDocument != nil) {
        switch viewModel.panel {
        case .GRAPH: GraphView(xmlDocument: viewModel.xmlDocument!, sequence: sequence)
        case .XML, .GIV, .JSON: TextView(text: viewModel.text)
        }
      }
    }
    
  }

  var patternList: some View {
    List(selection: $viewModel.selectedItem) {
      ForEach(viewModel.items, id: \.id) { item in
          VStack(alignment: .leading) {
            HStack {
              Text(item.regex)
              Spacer()
              Text(String(item.count))
            }.tag(item.id)
            Divider()
          }
          .onHover { hovering in
            isHovering = hovering
          }
          .moveDisabled(isHovering == false)
          .onTapGesture {
            viewModel.selectedItem = item
            isEditing = true
            newPattern = item.regex
          }
      }.onDelete(perform: { indexSet in
        viewModel.items.remove(atOffsets: indexSet)
      })
      .onMove { indices, newOffset in
        viewModel.items.move(
          fromOffsets: indices, toOffset: newOffset
        )
      }
    }
    .listStyle(DefaultListStyle())
    .border(Colors.get(color: "AGA 04").base , width: 4)
    .frame(width: 200, height: 150)
  }
  
  var editRegExField: some View {
    
    HStack {
      Text("RegEx pattern:")
      TextField("", text: $newPattern,
        onCommit: {
          let string = newPattern.trimmingCharacters(in: .whitespaces)
          if string.count > 0 {
            if isEditing {
              if let item = viewModel.selectedItem {
                if let index = viewModel.items.firstIndex(of: item) {
                  viewModel.items[index].regex = string
                }
              }
            } else {
              viewModel.items.append(PatternItem(string))
            }
            newPattern = ""
          }
        }
      )
      .textFieldStyle(RoundedBorderTextFieldStyle())
      .padding()
      .frame(width: 200)
    }
  }

  var clearAllBtn: some View {
    Button(action: {
      newPattern = ""
      viewModel.items.removeAll()
    }) {
      Text("Clear all patterns")
    }.disabled(viewModel.items.isEmpty)

  }
  
  var panelPicker: some View {
    Picker("", selection: $viewModel.panel) {
      ForEach(PatternViewModel.Panel.allCases, id: \.self) { output in
        Text(output.rawValue).tag(output)
        //Divider()
      }
    }
    .pickerStyle(SegmentedPickerStyle())
    .disabled(sequence.length == 0)
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


  // G R A P H  =================================================================

  struct GraphView : View {
    
    @EnvironmentObject var sequenceState: SequenceState

    @State var scale: Double = 1.0

    let patternParser: Pattern_XMLParser
    let extent: CGFloat
    var givFrame: GIVFrame
    
    var height: CGFloat = 0.0
    var width: CGFloat = 0.0

    init(xmlDocument: XMLDocument, sequence: Sequence) {
      self.extent = CGFloat(sequence.length)
      
      self.patternParser = Pattern_XMLParser(extent: sequence.length)
      self.patternParser.parse(xmlDocument: xmlDocument)
      self.givFrame = patternParser.givFrame

      self.height = self.givFrame.size.height
      self.width = self.givFrame.size.width
    }
        
    var body: some View {
      
      // Protect against divide by zero
      if extent.isZero {
        return AnyView(EmptyView())
      } else {
      
                  
      return AnyView(
        GeometryReader { geometry in
     
        let panelWidth = geometry.size.width
        var minScale = panelWidth/extent
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
          
          if let glyph = sequenceState.selectedPatternGlyph {
            let element = glyph.element
            let style = glyph.style
            let name = element.label
            let size = "\(element.start)-\(element.stop) length: \(element.stop - element.start + 1)"
            let type = style.name
            Text("\(name); \(size)bp; \(type)")
          } else {
            Text(" ")
          }

        }.onAppear {
          minScale = geometry.size.width/Double(extent)
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

