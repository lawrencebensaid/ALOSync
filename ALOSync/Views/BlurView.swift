//
//  BlurView.swift
//  BlurView
//
//  Created by Lawrence Bensaid on 19/09/2021.
//

import SwiftUI

struct BlurView: NSViewRepresentable {
    
    private let mode: NSVisualEffectView.BlendingMode
    
    init(_ mode: NSVisualEffectView.BlendingMode = .behindWindow)  {
        self.mode = mode
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = mode
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        
    }
    
}
