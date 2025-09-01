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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .onChange(of: logs.count) { _ in
                if let lastLog = logs.last {
                    withAnimation {
                        proxy.scrollTo(lastLog.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color.white)
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
        .background(Color.white)
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
    @State private var searchText = ""
    @State private var showingSearch = false
    
    enum DOMViewMode {
        case tree
        case raw
    }
    
    var highlightedRawText: AttributedString {
        let rawText = domTree?.toRawText() ?? ""
        var attributed = AttributedString(rawText)
        
        if searchText.count >= 2 {
            let searchLower = searchText.lowercased()
            var currentIndex = attributed.startIndex
            
            while currentIndex < attributed.endIndex {
                let remainingRange = currentIndex..<attributed.endIndex
                if let range = attributed[remainingRange].range(of: searchLower, options: .caseInsensitive) {
                    attributed[range].backgroundColor = .yellow
                    attributed[range].foregroundColor = .black
                    currentIndex = range.upperBound
                } else {
                    break
                }
            }
        }
        
        return attributed
    }
    
    var body: some View {
        ZStack {
            // Main content background
            Color.white
                .ignoresSafeArea()
            
            // Content
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading DOM...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            } else if let domTree = domTree {
                if viewMode == .tree {
                    ScrollView {
                        VStack(alignment: .leading) {
                            DOMNodeView(node: domTree, searchText: searchText)
                                .padding()
                                .padding(.bottom, 80) // Space for FABs
                        }
                    }
                    .background(Color.white)
                } else {
                    ScrollView {
                        VStack(alignment: .leading) {
                            if searchText.count >= 2 {
                                Text(highlightedRawText)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .padding()
                                    .padding(.bottom, 80) // Space for FABs
                            } else {
                                Text(domTree.toRawText())
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .textSelection(.enabled)
                                    .padding()
                                    .padding(.bottom, 80) // Space for FABs
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.white)
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
                .background(Color.white)
            }
            
            // Search Bar
            if showingSearch && domTree != nil {
                VStack {
                    HStack {
                        TextField("Search (2+ chars)", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .submitLabel(.search)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingSearch = false
                                searchText = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .shadow(radius: 2)
                    
                    Spacer()
                }
            }
            
            // Floating Action Buttons
            if domTree != nil {
                VStack {
                    // Search FAB (top right)
                    if !showingSearch {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingSearch = true
                                }
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            .padding(.trailing, 20)
                            .padding(.top, 20)
                        }
                    }
                    
                    Spacer()
                    
                    // View Mode FABs (bottom right)
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
    let searchText: String
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
    
    var truncatedText: String? {
        guard let text = node.innerText, !text.isEmpty else { return nil }
        let maxLength = 50
        if text.count > maxLength {
            return String(text.prefix(maxLength)) + "..."
        }
        return text
    }
    
    var matchesSearch: Bool {
        if searchText.count < 2 {
            return true
        }
        return nodeContainsSearch(node)
    }
    
    func nodeContainsSearch(_ node: DOMNode) -> Bool {
        let searchLower = searchText.lowercased()
        
        // Check current node
        if node.tag.lowercased().contains(searchLower) ||
           node.idAttr.lowercased().contains(searchLower) ||
           node.className.lowercased().contains(searchLower) ||
           (node.innerText?.lowercased().contains(searchLower) ?? false) {
            return true
        }
        
        // Check children
        for child in node.children {
            if nodeContainsSearch(child) {
                return true
            }
        }
        
        return false
    }
    
    var highlightedNodeLabel: AttributedString {
        var attributed = AttributedString(nodeLabel)
        
        if searchText.count >= 2 {
            let searchLower = searchText.lowercased()
            if let range = attributed.range(of: searchLower, options: .caseInsensitive) {
                attributed[range].backgroundColor = .yellow
                attributed[range].foregroundColor = .black
            }
        }
        
        return attributed
    }
    
    var body: some View {
        if matchesSearch {
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
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if searchText.count >= 2 {
                            Text(highlightedNodeLabel)
                                .font(.system(.caption, design: .monospaced))
                        } else {
                            Text(nodeLabel)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                        
                        // Show inner text if available
                        if let text = truncatedText {
                            Text(text)
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                                .italic()
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    if !node.children.isEmpty {
                        let visibleChildren = node.children.filter { nodeContainsSearch($0) }
                        if searchText.count >= 2 && visibleChildren.count != node.children.count {
                            Text("(\(visibleChildren.count)/\(node.children.count))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("(\(node.children.count))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if isExpanded && !node.children.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(node.children) { child in
                            DOMNodeView(node: child, searchText: searchText)
                                .padding(.leading, 16)
                        }
                    }
                }
            }
        }
    }
}


