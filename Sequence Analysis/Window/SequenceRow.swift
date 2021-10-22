import SwiftUI

struct SequenceRow: View {
  
  @ObservedObject var sequence: Sequence

  var body: some View {
    
   let edges = EdgeInsets(top: 3, leading: 3, bottom: 3, trailing: 3)
   let units = sequence.isNucleic ? "bp" : "aa"
   return VStack(alignment: .leading) {
     Group {
       if sequence.uid.count > 0 { Text(sequence.uid) }
       if sequence.title.count > 0 { Text(sequence.title).font(.headline) }
       Text("\(sequence.type.rawValue) \(sequence.length) \(units)").font(.caption)
     }
   }
   .padding(edges)
  }
}
