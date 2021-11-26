//
//  PublishView.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 11/26/21.
//

import SwiftUI

struct PublishView: View {
  
  @ObservedObject var sequence: Sequence
  @State var text: String = ""
  @State var blockSize: Double = 3
  @State var lineSize: Double = 60
//  @State var useStart: Bool = false
  @State var obeyStopCodons: Bool = false
  @State var format: String = "#-Sr_"
  
  @State var typing: Bool = false
  
  let viewModel: PublishViewModel = PublishViewModel()

  let maxBlockSize = 20

  var body: some View {
    
    guard sequence.length > 0 else {  return AnyView(TextView(text: "This sequence has no content"))}
    
    // Pass in the state variables, it will be displayed when 'Publish' is finished
    DispatchQueue.main.async {
      
      let blckSize = Int(blockSize)
      let lneSize = Int(lineSize)
      
      var options = PublishOptions()
      options.format = format
      options.blockSize = (blckSize == maxBlockSize + 1) ? lneSize : blckSize
      options.lineSize = lneSize
      options.obeyStopCodons = obeyStopCodons
      
      text.removeAll()
      let _ = Publish(sequence, text: $text, options: options)
    }

    return AnyView ( VStack {
      
      HStack {
        
        // Block and Line size sliders with labels -------------------
        VStack(alignment: .leading, spacing: 5.0) {
                    blockSizeSlider
          lineSizeSlider
        }
        .frame(width:240)
        Divider()
        Spacer()
        proteinTranslationOptions
        Spacer()
        Divider()
        publishLayoutString
      }.frame(maxHeight: 100)
      
      Divider()
      
      // The results panel
      TextView(text: $text, isEditable: false)
    })
  }

  var blockSizeSlider: some View {
    VStack(alignment: .leading, spacing: 0.0) {
      HStack(alignment: .center, spacing: 5.0) {
        Text("Block size:")
        if Int(blockSize) == maxBlockSize + 1 {
          Text("No blocks")
        } else {
          Text(String(Int(blockSize)))
        }
      }
      Slider(
        value: $blockSize,
        in: 1...Double(maxBlockSize + 1)
      )
    }.frame(width:220)
  }
  
  var lineSizeSlider: some View {
    // Line size sider
    VStack(alignment: .leading, spacing: 0.0) {
      HStack(alignment: .center, spacing: 5.0) {
        Text("Line size:")
        Text(String(Int(lineSize)))
      }

      Slider(
        value: $lineSize,
        in: 1...Double(min(sequence.length, 132))
      )
    }.frame(width:220)
  }
  
  var proteinTranslationOptions: some View {
    VStack(alignment: .leading) {
      let canTranslate: Bool = "ABCDEFabcdef123456".filter { format.contains($0) }.count != 0

      Toggle("Obey stop codons", isOn: $obeyStopCodons)
        .disabled(!(canTranslate && sequence.isNucleic))
      Text(obeyStopCodons ? "true" : "false" ).hidden() // Swift 5.5  on macOS hack to refresh on toggle
    }
  }
  
  var publishLayoutString: some View {
    VStack(alignment: .center)  {
      HStack {
        TextField("", text: $format)
          .frame(width:110)
        Text(format).hidden()   // Swift 5.5 on macOS hack to refresh on 'format' edit
        Button(action: {
          viewModel.showPublishLegend()
        }) {
          Image(systemName:"info.circle")
        }
        .help("Publish string tokens")

      }
    }.frame(width:250)
  }
  
}


