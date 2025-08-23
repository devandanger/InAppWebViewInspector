//
//  ContentView.swift
//  InAppWebViewInspector
//
//  Created by Evan Anger on 8/19/25.
//

import SwiftUI
import SwiftData

enum WebViewType: String, CaseIterable {
    case safariInternal = "Safari Internal"
    case externalSafari = "External Safari"
    case embeddedWebView = "Embedded WebView"
    
    var title: String {
        return self.rawValue
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var urlText: String = "https://example.com"
    @State private var selectedWebViewType: WebViewType = .embeddedWebView
    
    var body: some View {
        VStack(spacing: 30) {
            Text("WebView Inspector")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 50)
            
            VStack(spacing: 20) {
                TextField("Enter URL", text: $urlText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal)
                
                Picker("WebView Type", selection: $selectedWebViewType) {
                    ForEach(WebViewType.allCases, id: \.self) { type in
                        Text(type.title).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                Button("Launch") {
                    launchWebView()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .navigationTitle("Inspector")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func launchWebView() {
        // TODO: Implement launch functionality based on selectedWebViewType
        print("Launching \(selectedWebViewType.title) with URL: \(urlText)")
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