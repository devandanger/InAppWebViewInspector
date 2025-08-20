//
//  UIKitWebViewInspectorWrapper.swift
//  InAppWebViewInspector
//
//  Created by Claude on 8/19/25.
//

import SwiftUI
import UIKit

struct UIKitWebViewInspectorWrapper: UIViewControllerRepresentable {
    let url: URL?
    
    func makeUIViewController(context: Context) -> UIKitWebViewInspectorViewController {
        return UIKitWebViewInspectorViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: UIKitWebViewInspectorViewController, context: Context) {
        // Handle URL updates if needed
        // Note: For simplicity, we're creating a new instance when URL changes
        // In a production app, you might want to update the existing WebView
    }
}

struct UIKitWebViewInspectorView: View {
    let url: URL?
    @Binding var domInspectionResult: String
    
    var body: some View {
        UIKitWebViewInspectorWrapper(url: url)
            .navigationTitle("UIKit WebView Inspector")
            .navigationBarTitleDisplayMode(.inline)
    }
}