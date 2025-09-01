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
    @State private var showingDebugPanel = false
    
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
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Debug") {
                                showingDebugPanel = true
                            }
                        }
                    }
                    .sheet(isPresented: $showingDebugPanel) {
                        DebugPanel(url: url)
                    }
            } else {
                Text("Invalid URL")
                    .font(.headline)
            }
        }
    }
}

struct DebugPanel: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current URL")
                        .font(.headline)
                    Text(url.absoluteString)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Debug Options")
                        .font(.headline)
                    
                    Button(action: {
                        // TODO: Implement JavaScript console
                    }) {
                        Label("JavaScript Console", systemImage: "terminal")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        // TODO: Implement DOM inspector
                    }) {
                        Label("DOM Inspector", systemImage: "doc.text.magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        // TODO: Implement network monitor
                    }) {
                        Label("Network Monitor", systemImage: "network")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Debug Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}