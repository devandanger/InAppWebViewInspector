//
//  ContentView.swift
//  InAppWebViewInspector
//
//  Created by Evan Anger on 8/19/25.
//

import SwiftUI
import SwiftData
import WebKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var currentURL: String = "https://example.com"
    @State private var domInspectionResult: String = ""
    @State private var selectedURL: String? = nil
    @State private var selectedItem: Item? = nil
    @State private var useUIKitImplementation: Bool = false
    
    private var webViewURL: URL? {
        guard let selectedURL = selectedURL else { return nil }
        return URL(string: selectedURL)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            VStack {
                Text("WebView Inspector")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Implementation:")
                        .font(.headline)
                    
                    Toggle("Use UIKit Implementation", isOn: $useUIKitImplementation)
                        .toggleStyle(SwitchToggleStyle())
                    
                    Divider()
                    
                    Text("Quick Tests:")
                        .font(.headline)
                    
                    Button("Load Example.com") {
                        let url = "https://www.progressive.com"
                        currentURL = url
                        selectedURL = url
                        selectedItem = nil
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Load Debug Page") {
                        let url = "debug://test-page"
                        currentURL = url
                        selectedURL = url
                        selectedItem = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(.white)
                    .tint(.purple)
                    
                    Button("Load Apple.com") {
                        let url = "https://apple.com"
                        currentURL = url
                        selectedURL = url
                        selectedItem = nil
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Load HTML with Console Logs") {
                        let url = "data:text/html,<html><head><title>Test Page</title></head><body><h1>Test Page</h1><script>console.log('Page loaded!'); setTimeout(() => console.log('Delayed log'), 1000); console.error('Test error'); console.warn('Test warning');</script><button onclick='console.log(\"Button clicked!\")'>Click me</button></body></html>"
                        currentURL = url
                        selectedURL = url
                        selectedItem = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(.white)
                    .tint(.orange)
                    
                    if let selectedURL = selectedURL {
                        Text("Selected: \(selectedURL.hasPrefix("data:") ? "HTML Test Page" : selectedURL)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
                .padding()
                
                Spacer()
                
                Text("Items History")
                    .font(.headline)
                    .padding(.horizontal)
                
                List(selection: $selectedItem) {
                    ForEach(items.suffix(5)) { item in
                        NavigationLink(value: item) {
                            VStack(alignment: .leading) {
                                Text("Session: \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                                    .font(.caption)
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: addItem) {
                            Label("Add Session", systemImage: "plus")
                        }
                    }
                }
                .navigationDestination(for: Item.self) { item in
                    VStack {
                        Text("Session Details")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding()
                        
                        Text("Created: \(item.timestamp, format: Date.FormatStyle(date: .complete, time: .standard))")
                            .font(.headline)
                            .padding()
                        
                        Spacer()
                        
                        VStack(spacing: 16) {
                            Text("Load a test page to start debugging")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Load Debug Page") {
                                let url = "debug://test-page"
                                currentURL = url
                                selectedURL = url
                                selectedItem = nil
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                        }
                        .padding()
                    }
                    .navigationTitle("Session")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        } detail: {
            if webViewURL != nil {
                if useUIKitImplementation {
                    UIKitWebViewInspectorView(url: webViewURL, domInspectionResult: $domInspectionResult)
                } else {
                    WebViewInspectorDetail(url: webViewURL, domInspectionResult: $domInspectionResult)
                }
            } else if let selectedItem = selectedItem {
                VStack {
                    Text("Session Details")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                    
                    Text("Created: \(selectedItem.timestamp, format: Date.FormatStyle(date: .complete, time: .standard))")
                        .font(.headline)
                        .padding()
                    
                    Spacer()
                    
                    Text("Load a test page to start debugging")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .navigationTitle("Session")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                VStack {
                    Image(systemName: "safari")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("WebView Inspector")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text("Select a test option or session from the sidebar to get started.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                }
                .navigationTitle("Inspector")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
