//
//  Structure.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 1/9/22.
//

import SwiftUI

enum Filter: String, CaseIterable, Identifiable {
  case RAW_DATA = "Raw Data"
  case RUNNING_AVERAGE = "Running Average"
  case MEDIAN_SIEVE = "Median Sieve"
  
  var id: Filter { self }
}

enum Prediction: String, CaseIterable, Identifiable {
  case ALPHA_HELIX = "Alpha Helix"
  case BETA_SHEET = "Beta Sheet"
  case BETA_TURN = "Beta Turn"
  case ALOM = "Transmembrane"
  case ANTIGENIC_SITES = "Antigenicity"
  case HYPROPHILIC = "Hydrophilic"
  case HYPROPATHY = "Hydropathy"
  case FRACTION_BURIED = "Fraction Buried"
  case FREE_ENERGY = "Free Energy"

  var id: Prediction { self }
  
  var description: String {
    switch self {
    case .ALPHA_HELIX: return "Chou & Fasman - Alpha Helix"
    case .BETA_SHEET: return "Chou & Fasman - Beta Sheet"
    case .BETA_TURN: return "Chou & Fasman - Beta Turn"
    case .ALOM: return "Klein, Kanehisa & DeLisi - Transmembrane Prediction"
    case .ANTIGENIC_SITES: return "Hopp and Woods - Antigenicity"
    case .HYPROPHILIC: return "Levitt - Hydrophilic"
    case .HYPROPATHY: return "Kyte & Doolittle - Hydropathy"
    case .FRACTION_BURIED: return "Chothia - Fraction Buried"
    case .FREE_ENERGY: return "Wolfenden et al. - Free Energy"
    }
  }
  
  var reference: String {
    switch self {
    case .ALPHA_HELIX: return "Chou, P.Y., and Fasman, G.D., Annu. Rev. Biochem. 47, 251-276, 1978"
    case .BETA_SHEET: return "Chou, P.Y., and Fasman, G.D., Annu. Rev. Biochem. 47, 251-276, 1978"
    case .BETA_TURN: return "Chou, P.Y., and Fasman, G.D., Annu. Rev. Biochem. 47, 251-276, 1978"
    case .ALOM: return "Klein, P., M Kanehisa, M., DeLisi, C., Biochim Biophys Acta. 1985 May 28;815(3):468-76"
    case .ANTIGENIC_SITES: return "Hopp, T.P., and Woods, K.R., Proc. Nat. Acad. Sci. USA 78, 3824-3828, 1981"
    case .HYPROPHILIC: return "Levitt, M., J. Mol. Biol. 104, 59-107, 1976"
    case .HYPROPATHY: return "Kyte, J., and Doolittle, R.F., J. Mol. Biol. 157, 105-132, 1982"
    case .FRACTION_BURIED: return "Chothia, C., J. Mol. Biol. 105, 1-14, 1976"
    case .FREE_ENERGY: return "Wolfenden, R., Andersson, L., Cullis, P.M., and Southgate, C.C.B., Biochemistry 20, 849-855, 1981"
    }
  }

  var values: [Character:Double] {
    switch self {
    case .ALPHA_HELIX:
      return ["A": 1.42, "R": 0.98, "N": 0.67, "D": 1.01, "C": 0.70, "Q": 1.11, "E": 1.51, "G": 0.57,
              "H": 1.00, "I": 1.08, "L": 1.21, "K": 1.16, "M": 1.45, "F": 1.13, "P": 0.57, "S": 0.77,
              "T": 0.83, "W": 1.08, "Y": 0.69, "V": 1.06, "B": 0.84, "Z": 1.31, "X": 1.00]
    
    case .BETA_SHEET:
      return ["A": 0.83, "R": 0.93, "N": 0.89, "D": 0.54, "C": 1.19, "Q": 1.10, "E": 0.37, "G": 0.75,
              "H": 0.87, "I": 1.60, "L": 1.30, "K": 0.74, "M": 1.05, "F": 1.38, "P": 0.55, "S": 0.75,
              "T": 1.19, "W": 1.37, "Y": 1.47, "V": 1.70, "B": 0.72, "Z": 0.74, "X": 1.00]

    case .BETA_TURN:
      return ["A": 0.66, "R": 0.95, "N": 1.56, "D": 1.46, "C": 1.19, "Q": 0.98, "E": 0.74, "G": 1.56,
              "H": 0.95, "I": 0.47, "L": 0.59, "K": 1.01, "M": 0.60, "F": 0.60, "P": 1.52, "S": 1.43,
              "T": 0.96, "W": 0.96, "Y": 1.14, "V": 0.50, "B": 1.51, "Z": 0.86, "X": 1.00]

    case .ALOM:
      return ["A":  1.8, "R": -4.5, "N": -3.5, "D": -3.5, "C":  2.5, "Q": -3.5, "E": -3.5, "G": -0.4,
              "H": -3.2, "I":  4.5, "L":  3.8, "K": -3.9, "M":  1.9, "F":  2.8, "P": -1.6, "S": -0.8,
              "T": -0.7, "W": -0.9, "Y": -1.3, "V":  4.2, "B": -3.5, "Z": -3.5, "X": -0.5]
      
    case .ANTIGENIC_SITES:
      return ["A": -0.5, "R":  3.0, "N":  0.2, "D":  3.0, "C": -1.0, "Q":  0.2, "E":  3.0, "G": 0.0,
              "H": -0.5, "I": -1.8, "L": -1.8, "K":  3.0, "M": -1.3, "F": -2.5, "P":  0.0, "S": 0.3,
              "T": -0.4, "W": -3.4, "Y": -2.3, "V": -1.5, "B":  1.6, "Z":  1.6, "X": -0.2]

    case .HYPROPHILIC:
      return ["A": -0.5, "R":  3.0, "N":  0.2, "D":  2.5, "C": -1.0, "Q":  0.2, "E":  2.5, "G": 0.0,
              "H": -0.5, "I": -1.8, "L": -1.8, "K":  3.0, "M": -1.3, "F": -2.5, "P": -1.4, "S": 0.3,
              "T": -0.4, "W": -3.4, "Y": -2.3, "V": -1.5, "B":  1.4, "Z":  1.4, "X": -0.4]

    case .HYPROPATHY:
      return ["A":  1.8, "R": -4.5, "N": -3.5, "D": -3.5, "C":  2.5, "Q": -3.6, "E": -3.5, "G": -0.4,
              "H": -3.2, "I":  4.5, "L":  3.8, "K": -3.9, "M":  1.9, "F":  2.8, "P": -1.6, "S": -0.8,
              "T": -0.7, "W": -0.9, "Y": -1.3, "V":  4.2, "B": -3.5, "Z": -3.5, "X": -0.049]

    case .FRACTION_BURIED:
      return ["A": 0.205, "R": 0.013, "N": 0.029, "D": 0.041, "C": 0.217, "Q": 0.010, "E": 0.034, "G": 0.181,
              "H": 0.019, "I": 0.187, "L": 0.159, "K": 0.006, "M": 0.114, "F": 0.145, "P": 0.044, "S": 0.079,
              "T": 0.083, "W": 0.044, "Y": 0.025, "V": 0.182, "B": 0.035, "Z": 0.022, "X": 0.091]

    case .FREE_ENERGY:
      return ["A":   1.94, "R": -19.94, "N": -9.68, "D": -10.95, "C":  -1.24, "Q": -9.38, "E": -10.20, "G":  2.39,
              "H": -10.27, "I":   2.15, "L":  2.28, "K":  -9.52, "M":  -1.48, "F": -0.76, "P":  -7.13, "S": -5.06,
              "T":  -4.88, "W":  -5.88, "Y": -6.11, "V":   1.99, "B": -10.32, "Z": -9.79, "X":  -5.09]
    }
  }

  var window: Int {
    switch self {
    case .ALPHA_HELIX: return 6
    case .BETA_SHEET: return 6
    case .BETA_TURN: return 7
    case .ALOM: return 17
    case .ANTIGENIC_SITES: return 6
    case .HYPROPHILIC: return 6
    case .HYPROPATHY: return 9
    case .FRACTION_BURIED: return 6
    case .FREE_ENERGY: return 6
    }
  }
  
  var limits: (Double, Double, Double) {
    switch self {
    case .ALPHA_HELIX: return (upper: 1.45, lower: 0.70, cutoff: 1.07)
    case .BETA_SHEET: return (upper: 1.50, lower: 0.50, cutoff: 1.00)
    case .BETA_TURN: return (upper: 1.50, lower: 0.50, cutoff: 1.00)
    case .ALOM: return (upper: 6.00, lower: 0.00, cutoff: 0.00)
    case .ANTIGENIC_SITES: return (upper: 3.00, lower: -3.50, cutoff: 0.00)
    case .HYPROPHILIC: return (upper: 3.00, lower: -3.50, cutoff: 0.00)
    case .HYPROPATHY: return (upper: 4.50, lower: -4.50, cutoff: 0.00)
    case .FRACTION_BURIED: return (upper: 0.25, lower: 0.00, cutoff: 0.00)
    case .FREE_ENERGY: return (upper: 3.00, lower: -20.0, cutoff: 0.00)
    }
  }

}

class StructureViewModel: ObservableObject {

  // Panel types
  enum Panel: String, CaseIterable {
    case GRAPH = "Plot"
    case XML = "XML"
    case JSON = "JSON"
  }

  @Published var panel: Panel = .GRAPH             // Currently selected panel

  var sequence: Sequence?
  
  var prediction: Prediction = Prediction.ALPHA_HELIX
  var filter: Filter = Filter.RUNNING_AVERAGE

  var xmlDocument: XMLDocument?          // Structre Prediction data
  var plotData: PlotData?                // Data structure for secondary structure plot
  var errorMsg: String?
  var text: String?                     // Text contents for XML & JSON panels
  
  func update(sequence: Sequence, prediction: Prediction, filter: Filter) -> Void {
    self.sequence = sequence
    self.prediction = prediction
    self.filter = filter
    
    self.xmlDocument = nil
    self.plotData = nil
    self.errorMsg = nil
      
    guard sequence.string.count > 0 else {
      self.text = "This sequence has no content"
      return
    }
    
    doPrediction()
    
    // Create the text for XML, JSON and GIV panels from the XML
    switch panel {
    case .XML: xmlPanel()
    case .JSON: jsonPanel()
    default: break
    }


  }

  func doPrediction() -> Void {
    
    var data: [Double?]?

    switch prediction {
    case .ALOM:
      if let sequence = sequence {
        data = ALOM(sequence: sequence).analyze()
      } else {
        data = nil
      }

    case .ALPHA_HELIX, .BETA_SHEET, .BETA_TURN, .ANTIGENIC_SITES,
         .HYPROPHILIC, .HYPROPATHY, .FRACTION_BURIED, .FREE_ENERGY:
      switch filter {
      case .RAW_DATA: data = rawData(prediction: prediction)
      case .RUNNING_AVERAGE: data = runningAverage(prediction: prediction)
      case .MEDIAN_SIEVE: data = medianSieve(prediction: prediction)
      }

    }
    
    guard data != nil else {
      self.text = "Sequence is not long enough to do structure prediction"
      return
    }
    
    xmlDocument = createXML(data)
    plotData = createPlotData(data, prediction: prediction)
  }
  
  func rawData(prediction: Prediction) -> [Double?] {
    
    let strand = Array(sequence!.string.uppercased())
    let values = prediction.values
    
    var data = [Double?](repeating: nil, count: strand.count)
    for i in 0..<strand.count {
      if let value: Double = values[strand[i]] {
        data[i] = value
      }
    }
    
    return data
  }

  
  func runningAverage(prediction: Prediction) -> [Double?]? {
    
    // Unwrap the optional class members
    guard let sequence = self.sequence else { return nil }
    
    let strand: [Character] = Array(sequence.string.uppercased())
    let values: [Character:Double] = prediction.values
    let window: Int = prediction.window
    
    if strand.count < window * 2 {
      return nil
    }
    
    // Generate the score for the first window and then slide along
    //   by subtracting out the contribution of symbol "n" and adding
    //   the contribution of symbol "n+window"

    var score: Double = 0.0
    
    // Set the first window's value
    for n in 0..<window {
      if let value = values[strand[n]] {
        score += value
      }
    }
    // Create the return array and set the first value
    var data = [Double?](repeating: nil, count: strand.count)
    data[window/2] = score / Double(window)

    // Now slide along
    for n in 1..<(strand.count - window) {
      if let removeValue = values[strand[n]],
         let addValue = values[strand[n + window]] {
        score -= removeValue   // Subtract out value at "n"
        score += addValue      // Add in value at "n+window"
        data[n + (window / 2)] = score / Double(window)
      }
    }

    return data
  }
  
  // MARK: M E D I A N   S I E V E

  // The "Median Sieve Algorithm" is based on a paper by
  // J. Andrew Bangham, Analytical Biochemistry, 174, 142-145 (1988)

  func medianSieve(prediction: Prediction) -> [Double?]? {

    // Create an array of the raw values; Save window and length
    let data: [Double?] = rawData(prediction: prediction)
    let window: Int = prediction.window
    let length: Int = data.count
    
    // Copy raw data into a working array; Use zero for nil values
    var array: [Double] = [Double](repeating: 0.0, count: length)
    for i: Int in 0..<length {
      array[i] = data[i] ?? 0.0
    }
    
    // Filter with successive mesh sizes
    for mesh: Int in 2...window {
      array = sieve(array, mesh: mesh)
    }
                
    // Return median sieve data; Loop off the trailing padding
    return Array(array.prefix(length)) as [Double?]?
  }
  
  func sieve(_  inArray: [Double], mesh: Int) -> [Double] {
    
    let n: Int = inArray.count
    let pad: Int = mesh - 1
    let size: Int = n + (2 * pad)
    
    // Accomodate padding on both ends of the sequence data
    var array = [Double](repeating: 0.0, count: size)
    
    // Add the sequence data between the pads
    for i in 0..<n {
      array[pad + i] = inArray[i]
    }
 
    // Sample size for the sieve
    let s = (2 * mesh) - 1
    
    // Move a shifting window thru data, sort, take the median value

    for i in 0..<n {
      
      // Get a sample size copy of sequence data
      var temp: [Double] = [Double](repeating: 0.00, count: s)
      for j in 0..<s {
        temp[j] = array[i + j]
      }
      
      temp.sort(by: {$0 > $1} )

      // Save the median value from the sorted window
      array[i] = temp[mesh - 1];
    }
    
    return array
  }
    
  
  // MARK: C R E A T E  X M L
  func createXML(_ data: [Double?]?) -> XMLDocument?  {
    
    // Unwrap the optional class members
    guard let sequence = self.sequence else { return nil }
    guard let data = data else { return nil }

    let root = XMLElement(name: "STRUCTURE")
    root.addAttribute(XMLNode.attribute(withName: "sequence", stringValue: sequence.shortDescription) as! XMLNode)
    root.addAttribute(XMLNode.attribute(withName: "length", stringValue: String(sequence.length)) as! XMLNode)

    let xml = XMLDocument(rootElement: root)
    
    let algorithmNode = XMLElement(name: "algorithm")
    
    // 'description' is a CDATA node
    let descriptionNode = XMLNode(kind: .element, options: .nodeIsCDATA)
    descriptionNode.name = "description"
    descriptionNode.objectValue = prediction.description
    algorithmNode.addChild(descriptionNode)
    
    // 'reference' is a CDATA node
    let referenceNode = XMLNode(kind: .element, options: .nodeIsCDATA)
    referenceNode.name = "reference"
    referenceNode.objectValue = prediction.reference
    algorithmNode.addChild(referenceNode)

    // Algorithm parameters; ALOM does not use a filter; window is builtin
    if prediction.id != Prediction.ALOM {
      algorithmNode.addChild(XMLElement(name: "window", stringValue: String(prediction.window)) as XMLNode)
      algorithmNode.addChild(XMLElement(name: "filter", stringValue: filter.rawValue) as XMLNode)
    
      if filter == Filter.MEDIAN_SIEVE {
        let node = XMLNode(kind: .element, options: .nodeIsCDATA)
        node.name = "filter-reference"
        node.objectValue = "J. Andrew Bangham, Analytical Biochemistry, 174, 142-145 (1988)"
        algorithmNode.addChild(node)
      }
  
      if filter == Filter.RUNNING_AVERAGE {
        let node = XMLNode(kind: .element, options: .nodeIsCDATA)
        node.name = "filter-reference"
        node.objectValue = "https://en.wikipedia.org/wiki/Moving_average"
        algorithmNode.addChild(node)
      }

    }
    
    // Plot option, upper and lower; Significance cutoff level
    let plotNode = XMLElement(name: "plot")
    let (upper, lower, cutoff) = prediction.limits
    plotNode.addAttribute(XMLNode.attribute(withName: "lower", stringValue: String(lower)) as! XMLNode)
    plotNode.addAttribute(XMLNode.attribute(withName: "upper", stringValue: String(upper)) as! XMLNode)
    plotNode.addAttribute(XMLNode.attribute(withName: "cutoff", stringValue: String(cutoff)) as! XMLNode)

    // Plot data points
    let dataNode = XMLElement(name: "data")

    for i in 0..<data.count {
      
      let strand = Array(sequence.string.uppercased())
      
      if let datum:Double = data[i] {
        let valueNode = XMLElement(name: "datum")
        valueNode.addAttribute(XMLNode.attribute(withName: "position", stringValue: String(i+1)) as! XMLNode)
        valueNode.addAttribute(XMLNode.attribute(withName: "aa", stringValue:  String(strand[i])) as! XMLNode)
        valueNode.addAttribute(XMLNode.attribute(withName: "value", stringValue: F.f(datum, decimal: 2) ) as! XMLNode)
        dataNode.addChild(valueNode)
      }
    }
    
    // Assemble the XML Doument
    root.addChild(algorithmNode)
    root.addChild(plotNode)
    root.addChild(dataNode)
    
    return xml
  }
  
  // MARK: X M L P A N E L
  func xmlPanel() {
    
    guard self.errorMsg == nil else {
      return
    }

    guard self.xmlDocument != nil else {
      self.errorMsg = "XML Document was not created or is empty"
      return
    }
    
    if let xmlDocument = self.xmlDocument {
      let data = xmlDocument.xmlData(options: .nodePrettyPrint)
      self.text = String(data: data, encoding: .utf8) ?? "XML to text failed"
    }
  }

  // MARK: J S O N P A N E L
  func jsonPanel() {
    
    guard self.errorMsg == nil else {
      return
    }

    guard self.xmlDocument != nil else {
      self.errorMsg = "XML Document is empty"
      return
    }
    self.text = "{}"

    let xsltfilename = "xml2json"
    let xslt: String?
        
    if let filepath = Bundle.main.path(forResource: xsltfilename, ofType: "xslt") {
     do {
       xslt = try String(contentsOfFile: filepath)
     } catch {
       xslt = nil; errorMsg = error.localizedDescription
     }
    } else {
      xslt = nil;
      self.errorMsg = "Could not find '\(xsltfilename).xslt'"
      self.text = nil
    }
    
    if let xslt = xslt {
        do {
          let data = try self.xmlDocument!.object(byApplyingXSLTString: xslt, arguments: nil)
          if let data = data as? Data {
            if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
               let prettyJSON = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
              self.text = String(decoding: prettyJSON, as: UTF8.self)
            } else {
              self.text = "JSON data malformed"
            }
          }
        } catch {
          self.errorMsg = error.localizedDescription
        }
      } else {
        self.errorMsg = "No contents read for '\(xsltfilename).xslt"
      }
  }

  // MARK: P L O T   D A T A
  
  func createPlotData(_ data: [Double?]? ,prediction: Prediction) -> PlotData? {
    
    guard let sequence = sequence else { return nil }
    guard let data = data else { return nil }

    var values = [Datum]()
    for i in 0..<min(data.count, sequence.string.count) {
      if let value:Double = data[i] {
        values.append(Datum(i, value))
      }
    }
    
    let (upper, lower, cutoff) = prediction.limits
    let cutoffStop = (cutoff - lower) / (upper - lower)
    var stops: [Gradient.Stop]
    
    switch prediction {
    case .ALPHA_HELIX, .BETA_SHEET, .BETA_TURN,
         .ANTIGENIC_SITES, .HYPROPHILIC, .HYPROPATHY, .FREE_ENERGY:
      stops = [Gradient.Stop(color: .red, location: 0.0),
               Gradient.Stop(color: .gray, location: cutoffStop),
               Gradient.Stop(color: .green, location: 1.0)]

    case .ALOM, .FRACTION_BURIED:
      stops = [Gradient.Stop(color: .gray, location: 0.0),
               Gradient.Stop(color: .blue, location: 1.0)]
    }
  
    let gradient = LinearGradient(stops: stops,
                                  startPoint: UnitPoint(x: 0.50, y: 1.00),
                                  endPoint: UnitPoint(x: 0.50, y: 0.0))

    let plotData = PlotData(
      lower: lower,upper: upper,cutoff: cutoff, length: data.count, gradient: gradient, data: values)

    return plotData
  }
  

}
