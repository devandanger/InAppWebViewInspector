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
    @State private var consoleLogs: [ConsoleMessage] = []
    
    var body: some View {
        NavigationView {
            if let url = URL(string: urlString) {
                WebView(url: url, consoleLogs: $consoleLogs)
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
                        DebugPanel(url: url, consoleLogs: $consoleLogs)
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
    @Binding var consoleLogs: [ConsoleMessage]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Console Tab
                ConsoleView(logs: consoleLogs)
                    .tabItem {
                        Label("Console", systemImage: "terminal")
                    }
                    .tag(0)
                
                // Info Tab
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
                    
                    Spacer()
                }
                .padding()
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
                .tag(1)
            }
            .navigationTitle("Debug Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if selectedTab == 0 {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Clear") {
                            consoleLogs.removeAll()
                        }
                    }
                }
            }
        }
    }
}

struct ConsoleView: View {
    let logs: [ConsoleMessage]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if logs.isEmpty {
                        Text("No console logs yet")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(logs) { log in
                            ConsoleLogRow(log: log)
                                .id(log.id)
                        }
                    }
                }
            }
            .onChange(of: logs.count) { _ in
                if let lastLog = logs.last {
                    withAnimation {
                        proxy.scrollTo(lastLog.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

struct ConsoleLogRow: View {
    let log: ConsoleMessage
    
    var logColor: Color {
        switch log.method {
        case "error":
            return .red
        case "warn":
            return .orange
        case "info":
            return .blue
        case "debug":
            return .purple
        default:
            return .primary
        }
    }
    
    var logIcon: String {
        switch log.method {
        case "error":
            return "xmark.circle.fill"
        case "warn":
            return "exclamationmark.triangle.fill"
        case "info":
            return "info.circle.fill"
        case "debug":
            return "ant.fill"
        default:
            return "chevron.right.circle.fill"
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: logIcon)
                .foregroundColor(logColor)
                .font(.caption)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(log.args)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(logColor)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(log.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground).opacity(0.3))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
}