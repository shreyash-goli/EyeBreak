//
//  VisualEffectView.swift
//  EyeBreak
//
//  Created by Shreyash Goli on 11/26/25.
//

import SwiftUI
import AppKit

/// SwiftUI wrapper for NSVisualEffectView to create glassmorphism effects
struct VisualEffectView: NSViewRepresentable {
    
    /// The material type for the blur effect
    var material: NSVisualEffectView.Material
    
    /// The blending mode
    var blendingMode: NSVisualEffectView.BlendingMode
    
    /// Whether the view is emphasized
    var isEmphasized: Bool
    
    init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        isEmphasized: Bool = false
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.isEmphasized = isEmphasized
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        
        // Configure the visual effect
        view.material = material
        view.blendingMode = blendingMode
        view.isEmphasized = isEmphasized
        view.state = .active
        
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.isEmphasized = isEmphasized
    }
}

#Preview {
    ZStack {
        // Simulated background
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Visual effect overlay
        VisualEffectView(material: .hudWindow)
            .overlay {
                Text("Frosted Glass Effect")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
            }
    }
    .frame(width: 400, height: 300)
}
