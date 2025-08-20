//
//  DebugWebView.swift
//  InAppWebViewInspector
//
//  Created by Claude on 8/19/25.
//

import WebKit

struct ConsoleLog {
    let message: String
    let timestamp: Date
    let id = UUID()
}

class WebViewCoordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, ObservableObject {
    @Published var consoleLogs: [ConsoleLog] = []
    @Published var currentURL: String = ""
    @Published var isLoading: Bool = false
    
    var webView: WKWebView?
    let networkInterceptor = DebugURLSchemeHandler()
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "logHandler" {
            let logMessage = ConsoleLog(message: "\(message.body)", timestamp: Date())
            DispatchQueue.main.async {
                self.consoleLogs.append(logMessage)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = true
            self.currentURL = webView.url?.absoluteString ?? ""
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.currentURL = webView.url?.absoluteString ?? ""
        }
    }
    
    func executeJavaScript(_ script: String, completion: @escaping (Any?, Error?) -> Void) {
        webView?.evaluateJavaScript(script, completionHandler: completion)
    }
    
    func inspectElement(at point: CGPoint, completion: @escaping (String?) -> Void) {
        let script = """
        (function() {
            var element = document.elementFromPoint(\(point.x), \(point.y));
            if (element) {
                return {
                    tagName: element.tagName,
                    id: element.id,
                    className: element.className,
                    outerHTML: element.outerHTML,
                    textContent: element.textContent?.substring(0, 100)
                };
            }
            return null;
        })();
        """
        
        executeJavaScript(script) { result, error in
            if let result = result {
                completion("\(result)")
            } else {
                completion(nil)
            }
        }
    }
    
    func getDOMStructure(completion: @escaping (String?) -> Void) {
        let script = """
        (function() {
            function getElementInfo(element, depth = 0) {
                if (depth > 3) return null; // Limit depth to avoid too much data
                
                var info = {
                    tagName: element.tagName,
                    id: element.id,
                    className: element.className,
                    children: []
                };
                
                for (var i = 0; i < Math.min(element.children.length, 10); i++) {
                    var child = getElementInfo(element.children[i], depth + 1);
                    if (child) info.children.push(child);
                }
                
                return info;
            }
            
            return JSON.stringify(getElementInfo(document.body));
        })();
        """
        
        executeJavaScript(script) { result, error in
            if let result = result as? String {
                completion(result)
            } else {
                completion(nil)
            }
        }
    }
}

