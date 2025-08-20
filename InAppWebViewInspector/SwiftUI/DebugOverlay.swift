//
//  DebugOverlay.swift
//  InAppWebViewInspector
//
//  Created by Claude on 8/19/25.
//

import SwiftUI

enum DebugTab: CaseIterable {
    case console
    case dom
    case network
    case controls
    
    var title: String {
        switch self {
        case .console: return "Console"
        case .dom: return "DOM"
        case .network: return "Network"
        case .controls: return "Controls"
        }
    }
    
    var icon: String {
        switch self {
        case .console: return "terminal"
        case .dom: return "doc.text"
        case .network: return "network"
        case .controls: return "slider.horizontal.3"
        }
    }
}

struct DebugOverlay: View {
    let consoleLogs: [ConsoleLog]
    let networkRequests: [NetworkRequest]
    let currentURL: String
    let isLoading: Bool
    let onExecuteScript: (String) -> Void
    let onInspectDOM: (@escaping (String) -> Void) -> Void
    let onClearLogs: () -> Void
    let onClearNetworkRequests: () -> Void
    
    @State private var selectedTab: DebugTab = .console
    @State private var isExpanded: Bool = false
    @State private var scriptToExecute: String = ""
    @State private var domStructure: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            toggleBar
        }
        .background(Color.black.opacity(0.9))
        .cornerRadius(isExpanded ? 0 : 20)
        .animation(.spring(response: 0.3), value: isExpanded)
    }
    
    private var toggleBar: some View {
        HStack {
            Text("Debug Tools")
                .foregroundColor(.white)
                .font(.headline)
            
            Spacer()
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
            
            Button(action: { isExpanded.toggle() }) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isExpanded ? 0 : 180))
                    .animation(.spring(response: 0.3), value: isExpanded)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
    
    private var expandedView: some View {
        VStack(spacing: 0) {
            tabPicker
            
            ScrollView {
                switch selectedTab {
                case .console:
                    consoleView
                case .dom:
                    domView
                case .network:
                    networkView
                case .controls:
                    controlsView
                }
            }
            .frame(height: 300)
        }
    }
    
    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(DebugTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                        Text(tab.title)
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == tab ? .blue : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color.black.opacity(0.6))
    }
    
    private var consoleView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Console Logs (\(consoleLogs.count))")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Clear", action: onClearLogs)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .padding(.horizontal)
            .padding(.top)
            
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(consoleLogs.suffix(50), id: \.id) { log in
                    HStack(alignment: .top, spacing: 8) {
                        Text(timeFormatter.string(from: log.timestamp))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(width: 60, alignment: .leading)
                        
                        Text(log.message)
                            .font(.caption)
                            .foregroundColor(logColor(for: log.message))
                            .textSelection(.enabled)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    private var domView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("DOM Inspector")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Inspect") {
                    onInspectDOM { result in
                        domStructure = result
                    }
                }
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.top)
            
            ScrollView {
                Text(domStructure.isEmpty ? "Tap 'Inspect' to view DOM structure" : domStructure)
                    .font(.caption)
                    .foregroundColor(.white)
                    .textSelection(.enabled)
                    .padding()
            }
        }
    }
    
    private var networkView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Network Requests (\(networkRequests.count))")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Clear", action: onClearNetworkRequests)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .padding(.horizontal)
            .padding(.top)
            
            if networkRequests.isEmpty {
                Text("No network requests intercepted yet.\nTry loading a debug:// URL")
                    .foregroundColor(.gray)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(networkRequests.suffix(20), id: \.id) { request in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(timeFormatter.string(from: request.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text(request.method)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                                
                                Spacer()
                            }
                            
                            Text(request.url)
                                .font(.caption)
                                .foregroundColor(.white)
                                .textSelection(.enabled)
                                .lineLimit(2)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private var controlsView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("JavaScript Console")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            VStack(spacing: 8) {
                TextField("Enter JavaScript code", text: $scriptToExecute, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                HStack {
                    Button("Execute") {
                        if !scriptToExecute.isEmpty {
                            onExecuteScript(scriptToExecute)
                        }
                    }
                    .disabled(scriptToExecute.isEmpty)
                    
                    Spacer()
                    
                    Button("Clear") {
                        scriptToExecute = ""
                    }
                }
                .padding(.horizontal)
                
                VStack(spacing: 8) {
                    HStack {
                        Button("Log Hello World") {
                            onExecuteScript("console.log('Hello from JavaScript!')")
                        }
                        .font(.caption)
                        
                        Button("Get Page Title") {
                            onExecuteScript("console.log('Page title:', document.title)")
                        }
                        .font(.caption)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Button("Count Elements") {
                            onExecuteScript("console.log('Total elements:', document.querySelectorAll('*').length)")
                        }
                        .font(.caption)
                        
                        Button("Get URL") {
                            onExecuteScript("console.log('Current URL:', window.location.href)")
                        }
                        .font(.caption)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Button("Test Error") {
                            onExecuteScript("console.error('Test error message')")
                        }
                        .font(.caption)
                        
                        Button("Test Warning") {
                            onExecuteScript("console.warn('Test warning message')")
                        }
                        .font(.caption)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Current URL:")
                        .foregroundColor(.white)
                        .font(.caption)
                    
                    Spacer()
                }
                
                Text(currentURL.isEmpty ? "No URL loaded" : currentURL)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .textSelection(.enabled)
            }
            .padding(.horizontal)
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
    
    private func logColor(for message: String) -> Color {
        if message.hasPrefix("ERROR:") {
            return .red
        } else if message.hasPrefix("WARN:") {
            return .orange
        } else {
            return .white
        }
    }
}