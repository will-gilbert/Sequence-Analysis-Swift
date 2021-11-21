//
//  MacEditorTextView.swift
//  MacTextView
//
//  Created by Will Gilbert on 8/25/21.
//
//  https://oliver-epper.de/posts/wrap-nstextview-in-swiftui/

import SwiftUI
import AppKit

struct TextEditorView: NSViewRepresentable {
  
  @Binding var text: String
  let isEditable: Bool
  let fontSize: CGFloat
  
  init(_ text: Binding<String>, isEditable: Bool = true, fontSize: CGFloat = 14) {
    self._text = text
    self.isEditable = isEditable
    self.fontSize = fontSize
  }

  func makeCoordinator() -> Coordinator {
    return Coordinator(self, isEditable: isEditable)
  }
    
  class Coordinator: NSObject, NSTextStorageDelegate {
    
    private var parent: TextEditorView
    var shouldUpdateText: Bool = true

    init(_ parent: TextEditorView, isEditable: Bool) {
      self.parent = parent
      self.shouldUpdateText = isEditable
    }
      
    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        
      guard shouldUpdateText == true else {
        return
      }
      
      let edited = textStorage.attributedSubstring(from: editedRange).string
      let insertIndex = parent.text.utf16.index(parent.text.utf16.startIndex, offsetBy: editedRange.lowerBound)
      
      func numberOfCharactersToDelete() -> Int {
          editedRange.length - delta
      }
      
      let endIndex = parent.text.utf16.index(insertIndex, offsetBy: numberOfCharactersToDelete())
      self.parent.text.replaceSubrange(insertIndex..<endIndex, with: edited)
    }
  }

  func makeNSView(context: Context) -> NSScrollView {
 
    let textView = NSTextView()
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    
    textView.autoresizingMask = [.width]
    textView.allowsUndo = true
    textView.font = NSFont.monospacedSystemFont(ofSize: self.fontSize, weight: .regular)

    scrollView.documentView = textView
    textView.textStorage?.delegate = context.coordinator

    // Build line number ruler and attach callbacks
    let lineNumberView = LineNumberRulerView(textView: textView)
      
    scrollView.verticalRulerView = lineNumberView
    scrollView.hasVerticalRuler = true
    scrollView.rulersVisible = true
    
    textView.postsFrameChangedNotifications = true
    NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: self, queue: nil, using: updateLineNumberRuler)
    NotificationCenter.default.addObserver(forName: NSText.didChangeNotification, object: self, queue: nil, using: updateLineNumberRuler)
    NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: scrollView.contentView, queue: nil, using: updateLineNumberRuler)
    
    func updateLineNumberRuler(notification: Notification) -> Void {
        lineNumberView.needsDisplay = true
    }
    
    return scrollView
  }



  func updateNSView(_ nsView: NSScrollView, context: Context) {
    
    // This scrollbar contains an NSTextView, cast it from an NSView
    if let textView = nsView.documentView as? NSTextView {
      if text != textView.string {
        context.coordinator.shouldUpdateText = false
        textView.string = text
        context.coordinator.shouldUpdateText = true
      }
    }
  }
}

