//
//  aspoApp.swift
//  aspo
//
//  Created by kurt on 10.12.24.
//

import SwiftUI

class TransparentWindowView: NSView {
    override func viewDidMoveToWindow() {
        window?.backgroundColor = .clear
        super.viewDidMoveToWindow()
        window?.isMovableByWindowBackground = true
      
    }
}

struct TransparentWindow: NSViewRepresentable {
   func makeNSView(context: Self.Context) -> NSView { return TransparentWindowView() }
   func updateNSView(_ nsView: NSView, context: Context) { }
}

@main
struct aspoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 300, height: 300)
                .background(TransparentWindow())
                .navigationTitle("Undecorated")
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification), perform: { _ in
                    NSApp.mainWindow?.standardWindowButton(.zoomButton)?.isHidden = true
                    NSApp.mainWindow?.standardWindowButton(.closeButton)?.isHidden = true
                    NSApp.mainWindow?.standardWindowButton(.miniaturizeButton)?.isHidden = true
                })
             
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
    }
}

