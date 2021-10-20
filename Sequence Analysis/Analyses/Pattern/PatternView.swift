//
//  PatternView.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 9/14/21.
//

import SwiftUI

struct PatternView: View {
  
  enum PatternOutput: String, CaseIterable {
    case GRAPH = "Pattern Map"
    case XML = "XML"
    case JSON = "JSON"
    case GIV = "GIV XML"
  }

  @ObservedObject var sequence: Sequence
  
  @State var text: String = ""
  @State var patternOutput: PatternOutput = .GRAPH
  
  @State var xmlDocument: XMLDocument? = nil

  var body: some View {
    
    // Pass in the state variables, it will be displayed when 'Pattern' is finished
    let patterns = ["ATG", "TAG|TAA|TGA", "(CG){2,}", "ATG([ACGT]{3,3})*?((TAG)|(TAA)|(TGA))"]
    
    DispatchQueue.main.async {
      var pattern = Pattern(sequence, patterns: patterns, text: $text)
      xmlDocument = pattern.createXML()
    }
    
    return VStack {
      VStack {
        
        Text("Pattern options will go here")
        Text("... and here...")
        Text("... using: ATG, TAG|TAA|TGA, (CG){2,}")
        
        HStack {
          Picker("", selection: $patternOutput) {
            ForEach(PatternOutput.allCases, id: \.self) { output in
              Text(output.rawValue).tag(output)
            }
          }
          .pickerStyle(SegmentedPickerStyle())
          .disabled(sequence.length == 0)
          .font(.title)
          .frame(width: 400)
          Spacer()
          
          Button(action: {
            print("Copy to Clipboard")
          }) {
            Text("Copy to Clipboard")
          }.disabled( patternOutput == .GRAPH)
            
          Button(action: {
            print("Save to File")
          }) {
            Text("Save to File")
          }.disabled( patternOutput == .GRAPH)
          
        }
      }
      .padding()
      .frame(height: 100)
      
      Divider()
      
      if (xmlDocument != nil) {
        switch patternOutput {
        case .GRAPH: GraphView(xmlDocument: xmlDocument!, sequence: sequence)
        case .XML: XMLView(xmlDocument: xmlDocument!)
        case .JSON: JSONView(xmlDocument: xmlDocument!)
        case .GIV: GIVXMLView()
        }
      }
      
    }
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
//          Group {
//            Text(" Panel Width: \(panelWidth)")
//            Text("         min: \(minScale)")
//            Text("         max: \(maxScale)")
//            Text(" scrollWidth: \(scrollViewWidth)")
//          }

          HStack (spacing: 15) {
            Slider(
              value: $scale,
              in: minScale...maxScale
            ).disabled(minScale >= maxScale)
            
            Text("Pixels per BP: \(F.f(scale, decimal: 2))")
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

  // X M L  =====================================================================
  
  struct XMLView : View {
    var xmlDocument: XMLDocument
              
    var body: some View {
     let data = xmlDocument.xmlData(options: .nodePrettyPrint)
     let buffer:String? = String(data: data, encoding: .utf8)
            
     return TextView(text: buffer ?? "XML to text failed")
    }
  }

  // J S O N  ====================================================================
  
  struct JSONView: View {
    let xsltfilename = "xml2json"
    let xmlDocument: XMLDocument
    let xslt: String?
    var errorMsg: String? = nil
    
    init(xmlDocument: XMLDocument) {
      self.xmlDocument = xmlDocument
    
      if let filepath = Bundle.main.path(forResource: xsltfilename, ofType: "xslt") {
       do {
         self.xslt = try String(contentsOfFile: filepath)
       } catch {
         self.xslt = nil; errorMsg = error.localizedDescription
       }
      } else {
        self.xslt = nil; errorMsg = "Could not find '\(xsltfilename).xslt'"
      }
    }
    
    var body: some View {
      var text: String = errorMsg != nil ? errorMsg! : ""

      if let xslt = self.xslt {
        do {
          let data = try xmlDocument.object(byApplyingXSLTString: xslt, arguments: nil)
          if let data = data as? Data {
            if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
               let prettyJSON = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                text = String(decoding: prettyJSON, as: UTF8.self)
            } else {
                text = "JSON data malformed"
            }
          }
        } catch {
          text = error.localizedDescription
        }
      } else {
        text = "No contents read for '\(xsltfilename).xslt"
      }
      
      return TextView(text: text)
    }
  }

  // G I V   X M L  ==================================================================
  
  struct GIVXMLView  : View {
    var body: some View {
      Text("GIVXMLView")
    }
  }

}

private struct Pattern {
  
  let sequence: Sequence
  let patterns: [String]
  @Binding var buffer: String

  init(_ sequence: Sequence, patterns: [String], text: Binding<String>) {
    self.sequence = sequence
    self.patterns = patterns
    self._buffer = text
  }

  mutating func createXML() -> XMLDocument {
    return Pattern_CreateXML().createXML(sequence, patterns: patterns)
   }
}

