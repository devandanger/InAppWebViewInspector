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
    @StateObject private var webViewModel = WebViewModel()
    
    var body: some View {
        NavigationView {
            if let url = URL(string: urlString) {
                WebView(url: url, consoleLogs: $consoleLogs, viewModel: webViewModel)
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
                        DebugPanel(url: url, consoleLogs: $consoleLogs, webViewModel: webViewModel)
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
    let webViewModel: WebViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var domTree: DOMNode?
    @State private var isLoadingDOM = false
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Console Tab
                ConsoleView(logs: consoleLogs)
                    .tabItem {
                        Label("Console", systemImage: "terminal")
                    }
                    .tag(0)
                
                // DOM Tab
                DOMInspectorView(domTree: domTree, isLoading: isLoadingDOM, onRefresh: fetchDOM)
                    .tabItem {
                        Label("DOM", systemImage: "doc.text.magnifyingglass")
                    }
                    .tag(1)
                
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
                .tag(2)
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
                } else if selectedTab == 1 {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Refresh") {
                            fetchDOM()
                        }
                    }
                }
            }
        }
        .onAppear {
            if selectedTab == 1 && domTree == nil {
                fetchDOM()
            }
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == 1 && domTree == nil {
                fetchDOM()
            }
        }
    }
    
    private func fetchDOM() {
        isLoadingDOM = true
        Task {
            domTree = await webViewModel.fetchDOMTree()
            isLoadingDOM = false
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

struct DOMInspectorView: View {
    let domTree: DOMNode?
    let isLoading: Bool
    let onRefresh: () -> Void
    @State private var viewMode: DOMViewMode = .tree
    
    enum DOMViewMode {
        case tree
        case raw
    }
    
    var body: some View {
        ZStack {
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading DOM...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let domTree = domTree {
                if viewMode == .tree {
                    ScrollView {
                        VStack(alignment: .leading) {
                            DOMNodeView(node: domTree)
                                .padding()
                                .padding(.bottom, 80) // Space for FABs
                        }
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading) {
                            Text(domTree.toRawText())
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                                .padding()
                                .padding(.bottom, 80) // Space for FABs
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No DOM loaded")
                        .foregroundColor(.secondary)
                    Button("Load DOM", action: onRefresh)
                        .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Floating Action Buttons
            if domTree != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            // Tree View Button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewMode = .tree
                                }
                            }) {
                                Image(systemName: "list.bullet.indent")
                                    .font(.system(size: 20))
                                    .foregroundColor(viewMode == .tree ? .white : .blue)
                                    .frame(width: 56, height: 56)
                                    .background(viewMode == .tree ? Color.blue : Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.blue, lineWidth: viewMode == .tree ? 0 : 1)
                                    )
                            }
                            
                            // Raw Text Button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewMode = .raw
                                }
                            }) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 20))
                                    .foregroundColor(viewMode == .raw ? .white : .blue)
                                    .frame(width: 56, height: 56)
                                    .background(viewMode == .raw ? Color.blue : Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.blue, lineWidth: viewMode == .raw ? 0 : 1)
                                    )
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }
}

struct DOMNodeView: View {
    let node: DOMNode
    @State private var isExpanded = true
    
    var nodeLabel: String {
        var label = node.tag.lowercased()
        if !node.idAttr.isEmpty {
            label += "#\(node.idAttr)"
        }
        if !node.className.isEmpty {
            let classes = node.className.split(separator: " ").joined(separator: ".")
            label += ".\(classes)"
        }
        return label
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                if !node.children.isEmpty {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 12)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                            }
                        }
                } else {
                    Spacer()
                        .frame(width: 12)
                }
                
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.caption2)
                    .foregroundColor(.blue)
                
                Text(nodeLabel)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
                
                if !node.children.isEmpty {
                    Text("(\(node.children.count))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded && !node.children.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(node.children) { child in
                        DOMNodeView(node: child)
                            .padding(.leading, 16)
                    }
                }
            }
        }
    }
}