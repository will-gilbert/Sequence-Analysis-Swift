//
//  PatternXML.swift
//  SequenceAnalysis
//
//  Created by Will Gilbert on 10/15/21.
//

import Foundation

struct Pattern_CreateXML {

  func createXML(_ sequence: Sequence, patterns: [PatternItem]) -> XMLDocument {
    
    let root = XMLElement(name: "Pattern")
    root.addAttribute(XMLNode.attribute(withName: "sequence", stringValue: sequence.shortDescription) as! XMLNode)
    root.addAttribute(XMLNode.attribute(withName: "length", stringValue: String(sequence.length)) as! XMLNode)
    
    let xml = XMLDocument(rootElement: root)
    let strand = sequence.string
    
    for patternItem in patterns {
      
      let pattern = patternItem.pattern
            
      do {
        let regex = try NSRegularExpression(pattern: pattern)
        let results = regex.matches(in: strand, range: NSRange(strand.startIndex..., in: strand))

        let patternNode = XMLElement(name: "pattern")
        patternNode.addAttribute(XMLNode.attribute(withName: "regex", stringValue: pattern) as! XMLNode)
        patternNode.addAttribute(XMLNode.attribute(withName: "count", stringValue: String(results.count)) as! XMLNode)
        root.addChild(patternNode)
          
        for result in results {

          let matchNode = XMLElement(name: "match")
          let range = Range(result.range, in: strand)
          let label = String(strand[range!]).truncated(limit: 15, position: .middle)
          let from: Int = result.range.location
          let to: Int = from + result.range.length - 1
          
          // Convert to one-based sequence numbering
          matchNode.addAttribute(XMLNode.attribute(withName: "label", stringValue: label ) as! XMLNode)
          matchNode.addAttribute(XMLNode.attribute(withName: "from", stringValue: String(from + 1)) as! XMLNode)
          matchNode.addAttribute(XMLNode.attribute(withName: "to", stringValue: String(to + 1)) as! XMLNode)
          patternNode.addChild(matchNode)
        }
        
      } catch {
        let patternNode = XMLElement(name: "pattern")
        let exception = "'\(pattern) is not a valid expression; RE: RegEx for help"
        patternNode.addAttribute(XMLNode.attribute(withName: "error", stringValue: exception) as! XMLNode)
        root.addChild(patternNode)
        continue
      }
    }
      
    return xml
  }
}
