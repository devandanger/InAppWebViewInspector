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

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var consoleLogs: [ConsoleMessage]
    
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