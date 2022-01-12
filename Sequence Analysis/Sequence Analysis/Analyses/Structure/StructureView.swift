//
//  StructureView.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/14/21.
//

import SwiftUI

struct StructureView: View {
  
  @ObservedObject var sequenceState: SequenceState
  @ObservedObject var sequenceSelectionState: SequenceSelectionState

  @ObservedObject var sequence: Sequence
  @ObservedObject var viewModel: StructureViewModel

  init(sequenceState: SequenceState) {
    self.sequenceState = sequenceState
    
    // Observe any changes in the sequence selection; Recalculate
    self.sequenceSelectionState = sequenceState.sequenceSelectionState
    
    self.sequence = sequenceState.sequence
    self.viewModel = sequenceState.structureViewModel

  }

  var body: some View {
    
    // One of the states or sequence has changed, rebuilt the view model then redraw the view
    updateViewModel()

    return VStack {
      VStack(alignment: .leading) {
        HStack() {
          Menu("Structure Predition") {
            ForEach(Prediction.allCases, id: \.self) { prediction in
              Button(action: {
                sequenceState.prediction = prediction
              }, label: {
                Text(prediction.rawValue)
              })
            }
          }.frame(width: 150)
          Spacer().frame(width:50)
          Picker("Filtering:", selection: $sequenceState.filterSelection) {
            ForEach(Filter.allCases, id: \.self) { filter in
              Text(filter.rawValue).tag(filter.id)
            }
          }
          .pickerStyle(.radioGroup)
          .horizontalRadioGroupLayout()
          Spacer()
        }
        Text(sequenceState.prediction.rawValue).font(.title)
        Text(sequenceState.prediction.reference).font(.title2)
        HStack { panelPicker ; Spacer().frame(width: 15) ; copyToClipboardBtn }
      }
      .padding()
      .frame(height: 150)

      Divider()

      // Graph, XML, JSON and GIV panels go below options --------------------------
      
      switch viewModel.panel {
      case .GRAPH:
        if let xmlDocument = viewModel.xmlDocument { // Next step: Get PlotData from ViewModel, parse XMLDocument
          
          let data = [
            Datum(1, 1.0),
            Datum(20, 1.1),
            Datum(30, 0.9),
            Datum(31, 0.9),
            Datum(32, 0.9),
            Datum(33, 0.9),
            Datum(40, 0.70),
            Datum(50, 1.45),
            Datum(120, 0.9)
          ]
          
          let gradient = Gradient(colors: [
            .red, .gray, .green
          ])

          let plotData = PlotData(lower: 0.70, upper: 1.45, cutoff: 1.07, length: 120, gradient: gradient, data: data)
          PlotView(plotData: plotData)
          
        } else {
          TextView(text: "ALOM - No plot yet")
        }
      case .XML, .JSON:
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
      ForEach(StructureViewModel.Panel.allCases, id: \.self) { panelName in
        Text(panelName.rawValue).tag(panelName)
      }
    }
    .pickerStyle(SegmentedPickerStyle())
    .disabled(sequence.length == 0)
    .font(.title)
  }
  
  var copyToClipboardBtn: some View {
    Button(action: {
      
      var string: String? = nil
      switch viewModel.panel {
      case .XML, .JSON: string = viewModel.text
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
    .disabled( viewModel.panel == .GRAPH )
    .help("Copy to Clipboard")
  }
  
  
  
  func updateViewModel() -> Void {
    viewModel.update(sequence: sequence,
                     prediction: sequenceState.prediction,
                     filter: sequenceState.filterSelection)
  }

}

