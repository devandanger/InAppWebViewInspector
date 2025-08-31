//
//  EmbeddedWebViewScreen.swift
//  InAppWebViewInspector
//
//  Created on 8/31/25.
//

import SwiftUI

struct EmbeddedWebViewScreen: View {
    let urlString: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            if let url = URL(string: urlString) {
                WebView(url: url)
                    .ignoresSafeArea(edges: .bottom)
                    .navigationTitle("Embedded WebView")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") {
                                dismiss()
                            }
                        }
                    }
            } else {
                Text("Invalid URL")
                    .font(.headline)
            }
        }
    }
}