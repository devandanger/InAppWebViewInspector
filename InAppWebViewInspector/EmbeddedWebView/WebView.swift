//
//  WebView.swift
//  InAppWebViewInspector
//
//  Created on 8/31/25.
//

import SwiftUI
import WebKit
import Combine

class ConsoleMessageHandler: NSObject, WKScriptMessageHandler {
    let onMessage: (ConsoleMessage) -> Void
    
    init(onMessage: @escaping (ConsoleMessage) -> Void) {
        self.onMessage = onMessage
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any],
              let method = dict["method"] as? String,
              let args = dict["args"] as? [Any] else { return }
        
        let consoleMessage = ConsoleMessage(
            method: method,
            args: args.map { String(describing: $0) }.joined(separator: " "),
            timestamp: Date()
        )
        onMessage(consoleMessage)
    }
}

struct ConsoleMessage: Identifiable {
    let id = UUID()
    let method: String
    let args: String
    let timestamp: Date
}

struct DOMNode: Identifiable, Decodable {
    let id = UUID()
    let tag: String
    let idAttr: String
    let className: String
    let children: [DOMNode]
    
    enum CodingKeys: String, CodingKey {
        case tag, idAttr = "id", className, children
    }
    
    func toRawText(indent: Int = 0) -> String {
        let indentString = String(repeating: "  ", count: indent)
        var result = indentString + "<\(tag.lowercased())"
        
        if !idAttr.isEmpty {
            result += " id=\"\(idAttr)\""
        }
        
        if !className.isEmpty {
            result += " class=\"\(className)\""
        }
        
        if children.isEmpty {
            result += " />"
        } else {
            result += ">"
            for child in children {
                result += "\n" + child.toRawText(indent: indent + 1)
            }
            result += "\n" + indentString + "</\(tag.lowercased())>"
        }
        
        return result
    }
}

class WebViewModel: ObservableObject {
    var webView: WKWebView?
    
    func fetchDOMTree() async -> DOMNode? {
        guard let webView = webView else { return nil }
        
        let script = """
        (function() {
            function getDomTree(element) {
                const obj = {
                    tag: element.tagName || "",
                    id: element.id || "",
                    className: (typeof element.className === 'string' ? element.className : element.className?.baseVal || "") || "",
                    children: []
                };
                for (let child of element.children) {
                    obj.children.push(getDomTree(child));
                }
                return obj;
            }
            return JSON.stringify(getDomTree(document.body));
        })()
        """
        
        do {
            let result = try await webView.evaluateJavaScript(script)
            if let jsonString = result as? String,
               let jsonData = jsonString.data(using: .utf8) {
                let decoder = JSONDecoder()
                return try decoder.decode(DOMNode.self, from: jsonData)
            }
        } catch {
            print("Error fetching DOM: \(error)")
        }
        return nil
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var consoleLogs: [ConsoleMessage]
    let viewModel: WebViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Inject console override script
        let consoleScript = """
        (function() {
            const methods = ['log', 'warn', 'error', 'info', 'debug'];
            methods.forEach((method) => {
                const original = console[method];
                console[method] = function(...args) {
                    window.webkit.messageHandlers.console.postMessage({
                        method: method,
                        args: args
                    });
                    original.apply(console, args);
                };
            });
        })();
        """
        
        let script = WKUserScript(source: consoleScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(script)
        
        // Add message handler
        let handler = ConsoleMessageHandler { message in
            DispatchQueue.main.async {
                self.consoleLogs.append(message)
            }
        }
        configuration.userContentController.add(handler, name: "console")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isInspectable = true
        viewModel.webView = webView
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
    }
    
    class Coordinator: NSObject {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
    }
}