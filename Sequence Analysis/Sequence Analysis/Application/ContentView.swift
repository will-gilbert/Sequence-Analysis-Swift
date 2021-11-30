//
//  ContentView.swift
//
//  Created by Will Gilbert on 8/25/21.
//

import SwiftUI

struct ContentView: View {
 
  @StateObject var windowState = WindowState()
  @State var window: NSWindow?
  
  var body: some View {
    return SequenceAnalysis(window: window)
      .environmentObject(windowState)
      .background(WindowAccessor(window: $window))
    }

}


struct HelpMessage: View {
  
  var body: some View {
    VStack {
      Text("Use the \(Image(systemName:"plus")) button to add a new or random sequence or")
      Text("use the \(Image(systemName:"network")) button to fetch an entry from the NCBI.")
      Text("")
      Text("Use the \(Image(systemName:"arrow.up.doc")) button to read a sequence file")
      Text("in .raw, .seq, .fasta, .gcg, .nbrf, .pir format")
      Text("")
      Text("Most buttons have a tooltip when you hover over them.")
    }.font(.body)
  }
}
  
