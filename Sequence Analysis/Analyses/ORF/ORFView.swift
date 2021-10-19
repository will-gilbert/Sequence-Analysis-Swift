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


struct ORFView: View {
 
  enum ORFOutput: String, CaseIterable {
    case GRAPH = "ORF Map"
    case XML = "XML"
    case JSON = "JSON"
    case GIV = "GIV XML"
  }
      
  @ObservedObject var sequence: Sequence
  
  @State var minORFSize: Double = 17.0
  @State var startCodons: Bool = true
  @State var stopCodons: Bool = true
  @State var internalATG: Bool = true

  @State var text: String = ""
  @State var orfOutput: ORFOutput = .GRAPH
  
  @State var xmlDocument: XMLDocument? = nil
  
  var body: some View {

    // Pass in the state variables, it will be displayed when 'ORF' is finished
    DispatchQueue.main.async {
      
      var options = ORFOptions()
      options.minORFsize = Int(minORFSize)
      options.startCodons = startCodons
      options.stopCodons = stopCodons
      options.internalATG = internalATG
      
      var orf = OpenReadingFrame(sequence, text: $text, options: options)
      if sequence.isNucleic {
        xmlDocument = orf.createXML()
      }
    }
    
    return VStack {
      VStack {
        HStack {
          VStack(alignment: .leading, spacing: 3.0) {
              Toggle("Start codons", isOn: $startCodons)
              Text(startCodons ? "true" : "false" ).hidden() // Swift 5.5  on macOS hack to refresh on toggle
              Toggle("Stop codons", isOn: $stopCodons)
              Text(stopCodons ? "true" : "false" ).hidden() // Swift 5.5  on macOS hack to refresh on toggle
              Toggle("Internal 'ATG' as 'Met'", isOn: $internalATG)
              Text(internalATG ? "true" : "false" ).hidden() // Swift 5.5  on macOS hack to refresh on toggle
          }
          Spacer()
          Divider()
          Spacer()
            
          VStack { // min ORF size
            HStack(alignment: .center, spacing: 5.0) {
              Text("Min ORF size in aa:")
              Text(String(Int(minORFSize)))
            }
            
            Slider(
              value: $minORFSize,
              in: 1...120
            )

          }.frame(width: 220)
          Spacer()
         }
      
        
        HStack {
          Picker("", selection: $orfOutput) {
            ForEach(ORFOutput.allCases, id: \.self) { output in
              Text(output.rawValue).tag(output)
            }
          }
          .pickerStyle(SegmentedPickerStyle())
          .disabled(sequence.length == 0 || sequence.isProtein)
          .font(.title)
          .frame(width: 400)
          Spacer()
          
          Button(action: {
            print("Copy to Clipboard")
          }) {
            Text("Copy to Clipboard")
          }.disabled( orfOutput == .GRAPH || sequence.isProtein)
            
          Button(action: {
            print("Save to File")
          }) {
            Text("Save to File")
          }.disabled( orfOutput == .GRAPH || sequence.isProtein)
          
        }
      }
      .padding()
      .frame(height: 150)
      
      Divider()
      
      if (xmlDocument != nil) {
        switch orfOutput {
        case .GRAPH: GraphView(xmlDocument: xmlDocument!, sequence: sequence)
        case .XML: XMLView(xmlDocument: xmlDocument!)
        case .JSON: JSONView(xmlDocument: xmlDocument!)
        case .GIV: GIVXMLView(xmlDocument: xmlDocument!)
        }
      } else {
        Text("Sequence is protein, no ORF map can be created")
      }
    }
  }

  
  // O R F   M A P  ==============================================================================================

  struct GraphView: View {
 
    @EnvironmentObject var sequenceState: SequenceState

    @State var scale: Double = 1.0

    let orfParser: ORFParser
    let extent: CGFloat
    var givFrame: GIVFrame
    
    var height: CGFloat = 0.0
    var width: CGFloat = 0.0

    init(xmlDocument: XMLDocument, sequence: Sequence) {
      self.extent = CGFloat(sequence.length)
      
      orfParser = ORFParser(extent: sequence.length)
      orfParser.parse(xmlDocument: xmlDocument)
      givFrame = orfParser.givFrame

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
  
  // X M L  ======================================================================================================

  struct XMLView: View {
    var xmlDocument: XMLDocument
              
    var body: some View {
     let data = xmlDocument.xmlData(options: .nodePrettyPrint)
     let buffer:String? = String(data: data, encoding: .utf8)
            
     return TextView(text: buffer ?? "XML to text failed")
    }
  }
  
  // J S O N  ===================================================================================================
  
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

  // G I V   X M L  =============================================================================================

  struct GIVXMLView: View {
    
    let xsltfilename = "orf2giv"
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
          if let data = data as? XMLDocument {
            let prettyXML = data.xmlData(options: .nodePrettyPrint)
            text = String(data: prettyXML, encoding: .utf8) ?? "XML Transform could not be rendered (Pretty Print)"
          }
        } catch {
          text = error.localizedDescription
        }
      } else {
        text = "No contents read for '\(xsltfilename).xslt'"
      }
      
      return TextView(text: text)
    }
  }
}

private struct OpenReadingFrame {
  
  let sequence: Sequence
  @Binding var buffer: String
  let options: ORFOptions

  init(_ sequence: Sequence, text: Binding<String>, options: ORFOptions) {
    self.sequence = sequence
    self._buffer = text
    self.options = options
  }

  mutating func createXML() -> XMLDocument {
    return ORF_Nucleic().createXML(sequence, options: options)
   }
}





