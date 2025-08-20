//
//  DebugWebViewContainer.swift
//  InAppWebViewInspector
//
//  Created by Evan Anger on 8/19/25.
//

import SwiftUI
import WebKit

struct DebugWebViewContainer: UIViewRepresentable {
    let url: URL?
    let coordinator: WebViewCoordinator
    
    func makeUIView(context: Context) -> WKWebView {
        let scriptSource = """
        (function() {
            var originalLog = console.log;
            console.log = function(message) {
                window.webkit.messageHandlers.logHandler.postMessage(message);
                originalLog.apply(console, arguments);
            };
            
            var originalError = console.error;
            console.error = function(message) {
                window.webkit.messageHandlers.logHandler.postMessage('ERROR: ' + message);
                originalError.apply(console, arguments);
            };
            
            var originalWarn = console.warn;
            console.warn = function(message) {
                window.webkit.messageHandlers.logHandler.postMessage('WARN: ' + message);
                originalWarn.apply(console, arguments);
            };
        })();
        """
        
        let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        let contentController = WKUserContentController()
        contentController.addUserScript(script)
        contentController.add(coordinator, name: "logHandler")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.setURLSchemeHandler(coordinator.networkInterceptor, forURLScheme: "debug")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = coordinator
        coordinator.webView = webView
        
        #if DEBUG
        webView.isInspectable = true
        #endif
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
}
