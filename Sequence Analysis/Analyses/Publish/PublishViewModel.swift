//
//  Publish+MVVM.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 10/28/21.
//

import SwiftUI

// V I E W M O D E L  ==============================================================
class PublishViewModel {
  
  
  init() {}

func showPublishLegend() {
  
  let window: NSWindow =  NSWindow(
    contentRect: CGRect(x: 0, y: 0, width: 0, height: 0),
    styleMask: [.titled, .closable],
    backing: .buffered,
    defer: false
  )
  window.center()
  window.title = "Publish Layout Tokens"
  let contents = InfoWindowContent(window: window)
  let windowController = WindowController(window: window, contents: AnyView(contents))
  windowController.showWindow(self)
}

struct InfoWindowContent: View {
 
  var window: NSWindow
  
  var legend: String = """
      #) number line          :                10        20
      .) dot scale line       :                 .         .
      s) sequence             :        GAATTCACGATCGATCGTAG
      S) sequence, numbered   :     1  GAATTCACGATCGATCGTAG  20
      r) reverse complement   :        CTTAAGTGCTAGCTAGCATC
      R) revcomp, numbered    :     1  CTTAAGTGCTAGCTAGCATC  20
      -) scale line           :        ---------+---------+
      +) scale line, numbered :     1  ---------+---------+  20
      _) blank line           :
      
      a) 3 letter forward 1   :        GluPheThrIleAspArg
      b) 3 letter forward 2   :         AsnSerArgSerIleVal
      c) 3 letter forward 3   :          IleHisAspArgSer***
      d) 3 letter reverse 1   :          AsnValIleSerArgLeu
      e) 3 letter reverse 2   :         Ile***SerArgAspTyr
      f) 3 letter reverse 3   :        PheGluArgAspIleThr
      NB: ABCDEF are numbered translations
      
      1) 1 letter forward 1   :        E  F  T  I  D  R
      2) 1 letter forward 2   :         N  S  R  S  I  V
      3) 1 letter forward 3   :          I  H  D  R  S  *
      4) 1 letter reverse 1   :          N  V  I  S  R  L
      5) 1 letter reverse 2   :         I  *  S  R  D  Y
      6) 1 letter reverse 3   :        F  E  R  D  I  T
      """

  var body: some View {
    VStack {
      HStack{
        Text(legend)
          .font( .system(size: 14, weight: .regular, design: .monospaced) )
      }

      Spacer()
      
      // Button panel ===============================
      Section {
        HStack {
          Spacer()

          // O K  =--------------------------------
          Button(action: {
            window.close()
          }) {
            Text("Done")
          }
          .keyboardShortcut(.defaultAction)
        }
      }
      // Button panel ===============================

    }
    .padding(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
    .frame(width: 550, height: 450)
  }
}

}
