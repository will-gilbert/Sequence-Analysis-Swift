//
//  SequenceEditorApp.swift
//  Shared
//
//  Created by Will Gilbert on 8/25/21.
//


import SwiftUI

@main
struct SequenceAnalysisApp: App {
  
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  @StateObject var appState = AppSequences.shared().appState

  var body: some Scene {
    WindowGroup {
      ContentView()
        .frame(minWidth: 700, minHeight: 630)
        .environmentObject(appState)
    }
    
    .windowToolbarStyle(UnifiedWindowToolbarStyle(showsTitle: true))
    .commands {
      FileMenu(appState: appState)
      SequenceMenu(appState: appState)
    }
    
//    Settings {
//      VStack {
//        Text("Sequence Analysis Preferences will go here")
//      }.frame(minWidth: 800, minHeight: 600)
//    }


  }
}

class AppDelegate: NSObject, NSApplicationDelegate {

  // Shutdown the app when the last window is closed
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}

// Move this to macOS code when creating an iPad app
struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
          self.window = view.window
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
