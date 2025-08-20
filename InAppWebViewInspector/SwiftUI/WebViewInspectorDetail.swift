//
//  WebViewInspectorDetail.swift
//  InAppWebViewInspector
//
//  Created by Claude on 8/19/25.
//

import SwiftUI
import WebKit

struct WebViewInspectorDetail: View {
    let url: URL?
    @Binding var domInspectionResult: String
    
    @StateObject    private var coordinator = WebViewCoordinator()
    @State private var domStructure: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let url = url {
                    DebugWebViewContainer(url: url, coordinator: coordinator)
                        .overlay(alignment: .bottom) {
                            DebugOverlay(
                                consoleLogs: coordinator.consoleLogs,
                                networkRequests: coordinator.networkInterceptor.interceptedRequests,
                                currentURL: coordinator.currentURL,
                                isLoading: coordinator.isLoading,
                                onExecuteScript: { script in
                                    coordinator.executeJavaScript(script) { result, error in
                                        if let error = error {
                                            print("JavaScript execution error: \(error)")
                                        } else if let result = result {
                                            print("JavaScript result: \(result)")
                                        }
                                    }
                                },
                                onInspectDOM: { completion in
                                    coordinator.getDOMStructure { result in
                                        if let result = result {
                                            DispatchQueue.main.async {
                                                domStructure = result
                                                domInspectionResult = result
                                                completion(result)
                                            }
                                        }
                                    }
                                },
                                onClearLogs: {
                                    coordinator.consoleLogs.removeAll()
                                },
                                onClearNetworkRequests: {
                                    coordinator.networkInterceptor.clearRequests()
                                }
                            )
                            .padding(.horizontal)
                            .padding(.bottom, geometry.safeAreaInsets.bottom)
                        }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "safari")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("WebView Inspector")
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Text("Select a test option from the sidebar to load a webpage and start debugging.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Features:")
                                .font(.headline)
                            
                            Label("Console log capture", systemImage: "terminal")
                            Label("DOM inspection", systemImage: "doc.text")
                            Label("Network request monitoring", systemImage: "network")
                            Label("JavaScript execution", systemImage: "play.circle")
                            Label("Safari Web Inspector integration", systemImage: "safari")
                        }
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("WebView Inspector")
        .navigationBarTitleDisplayMode(.inline)
    }
}
