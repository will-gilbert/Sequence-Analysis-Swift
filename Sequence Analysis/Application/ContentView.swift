//
//  ContentView.swift
//  Shared
//
//  Created by Will Gilbert on 8/25/21.
//

import SwiftUI

struct ContentView: View {
 
  @StateObject var windowState = WindowState()
  @State var window: NSWindow?
  
  var body: some View {
    return SequenceAnalysis(window: window)
      .background(Color.background)
      .environmentObject(windowState)
      .background(WindowAccessor(window: $window))
    }

}
  
