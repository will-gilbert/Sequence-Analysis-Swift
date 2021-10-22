
import SwiftUI

struct AvailableSequencesList: View {
  
  @EnvironmentObject var appState: AppState
  @EnvironmentObject var windowState: WindowState
  
  let window: NSWindow?
  
  @State var isHovering: Bool = false

  var body: some View {
   
//    print(window?.isKeyWindow as Any )

    if let newSequenceState = appState.newSequenceState, let window = self.window {
      if window.isKeyWindow  {
      DispatchQueue.main.async {
        windowState.currentSequenceState = newSequenceState
        appState.newSequenceState = nil
      }}
    }
            
    return List(selection: $windowState.currentSequenceState) {
      ForEach(appState.sequenceStates, id: \.id) { sequenceState in
        if appState.showOnly.contains(sequenceState.sequence.type) {
          NavigationLink(
            destination:
              MainView()
              .environmentObject(sequenceState),
            tag: sequenceState,
            selection: $windowState.currentSequenceState
          ) {
            SequenceRow(sequence: sequenceState.sequence)
          }
          .tag(sequenceState)
          .onHover { hovering in
            isHovering = hovering
          }
          .moveDisabled(isHovering == false)
          .contextMenu {
            Button( action: {
              print("delete")
              print(sequenceState.sequence.uid as Any)
              if windowState.currentSequenceState == sequenceState {
                windowState.currentSequenceState = nil
              }
              appState.removeSequeneState(sequenceState)
            }){Text("Delete")}
          }
        }
      } // TODO Maybe remove this until we find out why it is logging and ERROR
      .onMove { indices, newOffset in
        appState.sequenceStates.move(
          fromOffsets: indices, toOffset: newOffset
        )
      }
    }
    .navigationTitle(windowState.currentSequenceState?.sequence.description ?? "")
    .listStyle(SidebarListStyle())
    .frame(minWidth: 200)
  }

}

