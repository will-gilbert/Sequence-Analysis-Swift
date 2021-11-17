//
//  SequenceEditorView.swift
//
//  Created by Will Gilbert on 8/25/21.
//

import SwiftUI
import AppKit

struct SequenceEditorView: NSViewRepresentable {
 
  public struct Internals {
    public let textView: NSTextView
    public let scrollView: NSScrollView?
  }

   @Binding var text: String {
    didSet {
      onTextChange?(text)
    }
  }
  
  @Binding var selection: NSRange? {
    didSet {
      if let selection = selection {
        onSelectionChange?(selection)
      }
    }
  }

  let isEditable: Bool
  let fontSize: CGFloat
  let alphabet: String

  // Callbacks, Optional
  private(set) var onEditingChanged: OnEditingChangedCallback?
  private(set) var onCommit: OnCommitCallback?
  private(set) var onTextChange: OnTextChangeCallback?
  private(set) var onSelectionChange: OnSelectionChangeCallback?
  
  init(_ text: Binding<String>, alphabet: Alphabet, selection: Binding<NSRange?>, isEditable: Bool = true, fontSize: CGFloat = 14) {
    self._text = text
    self.alphabet = alphabet.rawValue
    self._selection = selection
    self.isEditable = isEditable
    self.fontSize = fontSize
  }

  // Creates the SwiftUI representable
  func makeNSView(context: Context) -> NSScrollView {
    
    let textView = FilteredTextView()
    textView.allowed = alphabet
    
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    
    textView.autoresizingMask = [.width]
    textView.allowsUndo = true
    textView.font = NSFont.monospacedSystemFont(ofSize: self.fontSize, weight: .regular)
    textView.textColor = NSColor.labelColor
    textView.isEditable = isEditable
    textView.isSelectable = true
            
    scrollView.documentView = textView
    textView.delegate = context.coordinator

    // Build line number ruler and attach callbacks
    let rulerView = SequenceRulerView(textView: textView)
      
    scrollView.verticalRulerView = rulerView
    scrollView.hasVerticalRuler = true
    scrollView.rulersVisible = true
    
    textView.postsFrameChangedNotifications = true
    NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: self, queue: nil, using: updateRuler)
    NotificationCenter.default.addObserver(forName: NSText.didChangeNotification, object: self, queue: nil, using: updateRuler)
    NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: scrollView.contentView, queue: nil, using: updateRuler)
    
    func updateRuler(notification: Notification) -> Void {
      rulerView.needsDisplay = true
    }

    return scrollView
  }

  // Invoked each time the UI changes
  func updateNSView(_ nsView: NSScrollView, context: Context) {
    
    if let textView = nsView.documentView as? NSTextView {
      
      // Update the text only if has changed
      if text != textView.string {
        textView.string = text
      }
      
      // For a non-nil range passed into the editor, set
      //   it as the current selection
      if let range = self.selection {
        context.coordinator.selectedTextRange = range
      }
      
      // For a non-nil text selection, update and scroll to it
      //   as it might have come from outside of the editor
      if let selectedTextRange = context.coordinator.selectedTextRange {
        textView.selectedRange = selectedTextRange
        textView.scrollRangeToVisible(selectedTextRange)
      }
    }
  }

  
  func makeCoordinator() -> Coordinator {
    Coordinator(self, isEditable: isEditable)
  }
 
  //====================================================================================================
  // MARK: - Coordinator

  class Coordinator: NSObject, NSTextViewDelegate {
    
    var parent: SequenceEditorView
    var selectedTextRange: NSRange? = nil

    init(_ parent: SequenceEditorView, isEditable: Bool) {
      self.parent = parent
    }
  
    
    func textShouldBeginEditing(_ textObject: NSText) -> Bool {
      return true
    }
    
    func textDidBeginEditing(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else {
            return
        }
      
        self.parent.text = textView.string
        parent.onEditingChanged?()
    }
    
    func textDidChange(_ notification: Notification) {
      guard let textView = notification.object as? NSTextView else {
          return
      }
      
      self.parent.text = textView.string
      self.selectedTextRange = textView.selectedRange
    }
    
    func textDidEndEditing(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else {
            return
        }
       
        self.parent.text = textView.string
        self.parent.onCommit?()
    }
    
    func textViewDidChangeSelection(_ notification: Notification) {
      guard let textView = notification.object as? NSTextView else {
        return
      }
      
      selectedTextRange = textView.selectedRange
      
      if var _ = parent.selection, let selectedTextRange = selectedTextRange {
        DispatchQueue.main.async {
          self.parent.selection?.location = selectedTextRange.location
          self.parent.selection?.length = selectedTextRange.length
        }
      }
      
      parent.onSelectionChange?(textView.selectedRange)
    }
  }
}

//====================================================================================================
// MARK: - Notificaiton Callbacks

// Create callbacks for NSTextView notification events
extension SequenceEditorView {
 
//  func introspect(callback: @escaping IntrospectCallback) -> Self {
//    var new = self
//    new.introspect = callback
//    return new
//  }

    func onSelectionChange(_ callback: @escaping (_ selectedRange: NSRange) -> Void) -> Self {
      var new = self
      new.onSelectionChange = { range in
        callback(range)
      }

      return new
    }

    func onCommit(_ callback: @escaping OnCommitCallback) -> Self {
      var new = self
      new.onCommit = callback
      return new
    }

    func onEditingChanged(_ callback: @escaping OnEditingChangedCallback) -> Self {
      var new = self
      new.onEditingChanged = callback
      return new
    }

    func onTextChange(_ callback: @escaping OnTextChangeCallback) -> Self {
      var new = self
      new.onTextChange = callback
      return new
    }
}

class FilteredTextView : NSTextView {
  
  var allowed: String?
      
  override func insertText(_ string: Any, replacementRange: NSRange) {
    
    guard allowed != nil else {
      print("No allowed characters have been set")
      return
    }
    
    // Cast the incoming 'Any' to a 'String'; 'allowed' can be force unwrapped here
    if let string = string as? String {
      if allowed!.contains(string) {
        super.insertText(string, replacementRange: replacementRange)
      }
    }
  }
  
  override func readSelection(from pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {
    
    print(type) // type is an array of allowed type
    
    //guard type == NSPasteboard.PasteboardType.string else { return false }
    
    return super.readSelection(from: pboard, type: type)
  }
  
  
}


