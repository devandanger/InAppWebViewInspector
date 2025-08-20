//
//  DebugURLSchemeHandler.swift
//  InAppWebViewInspector
//
//  Created by Claude on 8/19/25.
//

import Foundation
import WebKit

struct NetworkRequest {
    let id = UUID()
    let url: String
    let method: String
    let timestamp: Date
    let headers: [String: String]?
}

class DebugURLSchemeHandler: NSObject, WKURLSchemeHandler {
    @Published var interceptedRequests: [NetworkRequest] = []
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(NSError(domain: "InvalidURL", code: -1))
            return
        }
        
        let request = NetworkRequest(
            url: url.absoluteString,
            method: urlSchemeTask.request.httpMethod ?? "GET",
            timestamp: Date(),
            headers: urlSchemeTask.request.allHTTPHeaderFields
        )
        
        DispatchQueue.main.async {
            self.interceptedRequests.append(request)
        }
        
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Debug Test Page</title>
            <style>
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif; 
                    padding: 20px; 
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    min-height: 100vh;
                    margin: 0;
                }
                .container { 
                    max-width: 600px; 
                    margin: 0 auto; 
                    background: rgba(255,255,255,0.1);
                    padding: 30px;
                    border-radius: 20px;
                    backdrop-filter: blur(10px);
                }
                h1 { 
                    color: #fff; 
                    text-align: center;
                    margin-bottom: 30px;
                }
                .test-section {
                    background: rgba(255,255,255,0.1);
                    padding: 20px;
                    margin: 15px 0;
                    border-radius: 10px;
                }
                button { 
                    background: #007AFF; 
                    color: white; 
                    border: none; 
                    padding: 12px 24px; 
                    border-radius: 8px; 
                    margin: 5px;
                    cursor: pointer;
                    font-size: 16px;
                }
                button:hover { 
                    background: #0056b3; 
                }
                #output {
                    background: rgba(0,0,0,0.3);
                    padding: 15px;
                    border-radius: 8px;
                    margin-top: 15px;
                    font-family: 'Courier New', monospace;
                    white-space: pre-wrap;
                    min-height: 100px;
                }
                .log-entry {
                    margin: 5px 0;
                    padding: 5px;
                    border-left: 3px solid #007AFF;
                    background: rgba(255,255,255,0.05);
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🛠️ WebView Debug Test Page</h1>
                
                <div class="test-section">
                    <h3>Console Testing</h3>
                    <button onclick="testConsoleLog()">Test console.log</button>
                    <button onclick="testConsoleError()">Test console.error</button>
                    <button onclick="testConsoleWarn()">Test console.warn</button>
                    <button onclick="testMultipleLogs()">Multiple Logs</button>
                </div>
                
                <div class="test-section">
                    <h3>DOM Testing</h3>
                    <button onclick="addElement()">Add Element</button>
                    <button onclick="removeElement()">Remove Element</button>
                    <button onclick="modifyElement()">Modify Element</button>
                    <div id="dynamic-content"></div>
                </div>
                
                <div class="test-section">
                    <h3>JavaScript Execution Test</h3>
                    <button onclick="calculateResult()">Run Calculation</button>
                    <button onclick="getCurrentTime()">Get Current Time</button>
                    <button onclick="testAsyncOperation()">Test Async</button>
                    <div id="output">Output will appear here...</div>
                </div>
                
                <div class="test-section">
                    <h3>Network Testing</h3>
                    <button onclick="makeNetworkRequest()">Make Network Request</button>
                    <button onclick="loadImage()">Load Image</button>
                </div>
                
                <div id="test-elements"></div>
            </div>
            
            <script>
                let elementCounter = 0;
                
                function testConsoleLog() {
                    console.log('This is a test console.log message!');
                    console.log('Current timestamp:', new Date().toISOString());
                }
                
                function testConsoleError() {
                    console.error('This is a test error message!');
                }
                
                function testConsoleWarn() {
                    console.warn('This is a test warning message!');
                }
                
                function testMultipleLogs() {
                    console.log('Starting multiple log test...');
                    console.log('Log 1: First message');
                    console.warn('Log 2: Warning message');
                    console.error('Log 3: Error message');
                    console.log('Log 4: Final message');
                }
                
                function addElement() {
                    elementCounter++;
                    const container = document.getElementById('dynamic-content');
                    const newElement = document.createElement('div');
                    newElement.id = 'element-' + elementCounter;
                    newElement.className = 'log-entry';
                    newElement.textContent = 'Dynamic element #' + elementCounter;
                    container.appendChild(newElement);
                    console.log('Added element:', newElement.id);
                }
                
                function removeElement() {
                    const container = document.getElementById('dynamic-content');
                    const lastElement = container.lastElementChild;
                    if (lastElement) {
                        console.log('Removing element:', lastElement.id);
                        container.removeChild(lastElement);
                        elementCounter = Math.max(0, elementCounter - 1);
                    } else {
                        console.warn('No elements to remove');
                    }
                }
                
                function modifyElement() {
                    const container = document.getElementById('dynamic-content');
                    const elements = container.children;
                    if (elements.length > 0) {
                        const randomElement = elements[Math.floor(Math.random() * elements.length)];
                        randomElement.style.background = '#' + Math.floor(Math.random()*16777215).toString(16);
                        randomElement.textContent += ' (modified)';
                        console.log('Modified element:', randomElement.id);
                    } else {
                        console.warn('No elements to modify');
                    }
                }
                
                function calculateResult() {
                    const result = Math.random() * 100;
                    const output = document.getElementById('output');
                    output.textContent += '\\nCalculation result: ' + result.toFixed(2);
                    console.log('Calculation completed:', result);
                }
                
                function getCurrentTime() {
                    const now = new Date();
                    const output = document.getElementById('output');
                    output.textContent += '\\nCurrent time: ' + now.toLocaleString();
                    console.log('Time requested:', now.toISOString());
                }
                
                function testAsyncOperation() {
                    console.log('Starting async operation...');
                    const output = document.getElementById('output');
                    output.textContent += '\\nAsync operation started...';
                    
                    setTimeout(() => {
                        output.textContent += '\\nAsync operation completed!';
                        console.log('Async operation completed after 2 seconds');
                    }, 2000);
                }
                
                function makeNetworkRequest() {
                    console.log('Attempting network request...');
                    // This will be intercepted by our URL scheme handler
                    fetch('debug://api/test-endpoint')
                        .then(response => {
                            console.log('Network response received');
                            return response.text();
                        })
                        .then(data => {
                            console.log('Network data:', data);
                        })
                        .catch(error => {
                            console.error('Network error:', error);
                        });
                }
                
                function loadImage() {
                    const img = new Image();
                    img.onload = () => console.log('Image loaded successfully');
                    img.onerror = () => console.error('Failed to load image');
                    img.src = 'debug://images/test-image.png';
                    console.log('Image load initiated');
                }
                
                // Auto-run some initial logs
                console.log('Debug test page loaded successfully!');
                console.log('Page URL:', window.location.href);
                console.log('User agent:', navigator.userAgent);
                
                // Test periodic logging
                let logCounter = 0;
                setInterval(() => {
                    logCounter++;
                    if (logCounter <= 5) {
                        console.log('Periodic log #' + logCounter + ' - Page has been active for ' + logCounter * 5 + ' seconds');
                    }
                }, 5000);
            </script>
        </body>
        </html>
        """
        
        let data = htmlContent.data(using: .utf8)!
        let response = URLResponse(
            url: url,
            mimeType: "text/html",
            expectedContentLength: data.count,
            textEncodingName: "utf-8"
        )
        
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // Handle cancellation if needed
    }
    
    func clearRequests() {
        interceptedRequests.removeAll()
    }
}