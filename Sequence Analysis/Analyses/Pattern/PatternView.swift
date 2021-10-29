//
//  PatternView.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/14/21.
//

import SwiftUI

struct PatternView: View {
  
  // External classes; Injected via the initializer
  //@EnvironmentObject var sequenceState: SequenceState
  @ObservedObject var sequence: Sequence
  @ObservedObject var viewModel: PatternViewModel
  
  // View state variables
  @State private var newPattern: String = ""           // TextField to enter a pattern
  @State private var isEditing: Bool = false           // Editing an existing pattern, not a new pattern
  @State private var isHovering: Bool = false          // Use to move items in the list
  @State private var selectedItem: PatternItem? = nil  // Editing an existing pattern
  
  private var length: Int
  private var checkSum: Int

  init(sequence: Sequence, viewModel: PatternViewModel) {
    self.sequence = sequence
    self.viewModel = viewModel
    self.checkSum = sequence.checkSum
    self.length = sequence.length
  }

  // Save for reference: "ATG", "TAG|TAA|TGA", "(CG){2,}", "ATG([ACGT]{3,3})*?((TAG)|(TAA)|(TGA))"
  
  
  var body: some View {
     
    // Hopely I will learn a better way to update the View Model in the future
    if(length != sequence.length) { // Fast check on sequence change; Generaly used
      updateViewModel()
    } else if(checkSum != sequence.checkSum) { // Slower check e.g. shuffled sequence or T/U
      updateViewModel()
    }

    // V I E W  ========================================================================
    return VStack {
      
      // Pattern Options, above the divider -------------------------------------------------
      
      VStack(alignment: .leading) {
        HStack(alignment: .top) { patternList ; HStack{ editRegExField; clearAllBtn }; Spacer() }
        HStack { panelPicker; Spacer().frame(width: 15) ; copyToClipboardBtn } // ; copyToFileBtn ; Spacer() }
      }
      .padding()
      .frame(height: 200)
      
      Divider()
      
      // Graph, XML, JSON and GIV panels go below the divider ------------------
      
      switch viewModel.panel {
      case .GRAPH: GraphView(xmlDocument: viewModel.xmlDocument, sequence: viewModel.sequence)
      case .XML, .GIV, .JSON: TextView(text: viewModel.text)
      }
    }
  }

  var patternList: some View {
    List(selection: $selectedItem) {
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
            selectedItem = item
            isEditing = true
            newPattern = item.regex
          }
      }.onDelete(perform: { indexSet in
        viewModel.items.remove(atOffsets: indexSet)
        updateViewModel()
      })
      .onMove { indices, newOffset in
        viewModel.items.move(
          fromOffsets: indices, toOffset: newOffset
        )
        updateViewModel()
      }
    }
    .listStyle(DefaultListStyle())
    .border(Colors.get(color: "AGA 04").base , width: 4)
    .frame(width: 200, height: 150)
  }
  
  var editRegExField: some View {
    
    HStack {
      Text("RegEx pattern:")
      regExHelp
      TextField("", text: $newPattern,
        onCommit: {
          let string = newPattern.trimmingCharacters(in: .whitespaces)
          if string.count > 0 {
            if isEditing {
              if let item = selectedItem {
                if let index = viewModel.items.firstIndex(of: item) {
                  viewModel.items[index].regex = string
                  updateViewModel()
                  isEditing.toggle()
                }
              }
            } else {
              viewModel.addItem(pattern: string)
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
      updateViewModel()
    }) {
      Text("Clear all patterns")
    }.disabled(viewModel.items.isEmpty)

  }
  
  var regExHelp: some View {
    Button(action: {
      viewModel.showRegExLegend()
    }) {
      Image(systemName:"info.circle")
    }
    .help("What is a RegEx pattern?")
  }
  
  var panelPicker: some View {
    Picker("", selection: $viewModel.panel) {
      ForEach(PatternViewModel.Panel.allCases, id: \.self) { panelName in
        Text(panelName.rawValue).tag(panelName)
      }
    }
    .pickerStyle(SegmentedPickerStyle())
    .disabled(viewModel.sequence.length == 0)
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
    viewModel.update()
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

    init?(xmlDocument: XMLDocument?, sequence: Sequence) {
      
      guard xmlDocument != nil else { return nil}
      
      self.extent = CGFloat(sequence.length)
      
      self.patternParser = Pattern_XMLParser(extent: sequence.length)
      self.patternParser.parse(xmlDocument: xmlDocument!)
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

