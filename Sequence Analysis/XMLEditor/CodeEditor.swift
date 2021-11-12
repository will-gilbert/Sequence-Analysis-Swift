//
//  CodeEditor.swift
//
//  Created by Manuel M T Chakravarty on 23/08/2020.
//
//  SwiftUI 'CodeEditor' view

import SwiftUI


/// SwiftUI code editor based on TextKit.
///
/// SwiftUI `Environment`:
/// * Environment value `codeEditorTheme`: determines the code highlighting theme to use
///
public struct CodeEditor {

  /// Specification of the editor layout.
  ///
  public struct LayoutConfiguration: Equatable {

    /// Show the minimap if possible. (Currently only supported on macOS.)
    ///
    public let showMinimap: Bool

    /// Creates a layout configuration.
    ///
    /// - Parameter showMinimap: Whether to show the minimap if possible. It may not be possible on all supported OSes.
    ///
    public init(showMinimap: Bool) {
      self.showMinimap = showMinimap
    }

    public static let standard = LayoutConfiguration(showMinimap: true)
  }

  let language: LanguageConfiguration
  let layout  : LayoutConfiguration

  @Binding private var text:     String

  /// Creates a fully configured code editor.
  ///
  /// - Parameters:
  ///   - text: Binding to the edited text.
  ///   - language: Language configuration for highlighting and similar.
  ///   - layout: Layout configuration determining the visible elements of the editor view.
  ///
  public init(text:     Binding<String>,
              language: LanguageConfiguration = .none,
              layout:   LayoutConfiguration = .standard)
  {
    self._text     = text
    self.language  = language
    self.layout    = layout
  }

  public class _Coordinator {
    @Binding var text: String

    init(_ text: Binding<String>) {
      self._text = text
    }
  }
}


// MARK: -
// MARK: AppKit version

extension CodeEditor: NSViewRepresentable {
  public func makeNSView(context: Context) -> NSScrollView {

    // Set up scroll view
    let scrollView = NSScrollView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
    scrollView.borderType          = .noBorder
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalRuler  = false
    scrollView.autoresizingMask    = [.width, .height]

    // Set up text view with gutter
    let codeView = CodeView(frame: CGRect(x: 0, y: 0, width: 100, height: 40),
                            with: language,
                            viewLayout: layout,
                            theme: context.environment[CodeEditorTheme])
    codeView.isVerticallyResizable   = true
    codeView.isHorizontallyResizable = false
    codeView.autoresizingMask        = .width

    // Embedd text view in scroll view
    scrollView.documentView = codeView

    codeView.string = text
    if let delegate = codeView.delegate as? CodeViewDelegate {
      delegate.textDidChange      = context.coordinator.textDidChange
      delegate.selectionDidChange = selectionDidChange
    }
    codeView.setSelectedRange(NSRange(location: 0, length: 0))

    // The minimap needs to be vertically positioned in dependence on the scroll position of the main code view.
    context.coordinator.liveScrollNotificationObserver
      = NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification,
                                               object: scrollView.contentView,
                                               queue: .main){ _ in codeView.adjustScrollPositionOfMinimap() }

    return scrollView
  }

  public func updateNSView(_ nsView: NSScrollView, context: Context) {
    guard let codeView = nsView.documentView as? CodeView else { return }

    let theme = context.environment[CodeEditorTheme]
    if text != codeView.string { codeView.string = text }  // Hoping for the string comparison fast path...
    if theme.id != codeView.theme.id { codeView.theme = theme }
    if layout != codeView.viewLayout { codeView.viewLayout = layout }
  }

  public func makeCoordinator() -> Coordinator {
    return Coordinator($text)
  }

  public final class Coordinator: _Coordinator {
    var liveScrollNotificationObserver: NSObjectProtocol?

    deinit {
      if let observer = liveScrollNotificationObserver { NotificationCenter.default.removeObserver(observer) }
    }

    func textDidChange(_ textView: NSTextView) {
      self.text = textView.string
    }
  }
}


// MARK: -
// MARK: Shared code

/// Environment key for the current code editor theme.
///
public struct CodeEditorTheme: EnvironmentKey {
  public static var defaultValue: Theme = Theme.defaultLight
}

extension EnvironmentValues {
  /// The current code editor theme.
  ///
  public var codeEditorTheme: Theme {
    get { self[CodeEditorTheme.self] }
    set { self[CodeEditorTheme.self] = newValue }
  }
}

