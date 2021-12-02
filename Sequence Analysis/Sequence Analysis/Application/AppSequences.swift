//
//  AppSequences.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 11/30/21.
//



class AppSequences {
  
  // Setup the Singleton via Globals
  private static var sharedAppSequences: AppSequences = {
      let appSequences = AppSequences()
      return appSequences
  }()
  
  class func shared() -> AppSequences {
      return sharedAppSequences
  }

  //--------------------------------------------------------------
  
  let appState: AppState
  
  init() {
    self.appState = AppState()
  }
  
  func createSequence(_ string: String, uid: String? = nil, title : String = "Untitled", type: SequenceType = SequenceType.DNA) -> SequenceState{
        
    let sequence = Sequence(string,
                            uid: uid ?? Sequence.nextUID(),
                            title: title,
                            type: type)
    return appState.addSequence(sequence)
  }

}
