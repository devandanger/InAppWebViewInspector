//
//  UIKitWebViewInspectorViewController.swift
//  InAppWebViewInspector
//
//  Created by Claude on 8/19/25.
//

import UIKit
import WebKit

class UIKitWebViewInspectorViewController: UIViewController {
    private let url: URL?
    private let coordinator = WebViewCoordinator()
    private var debugOverlayViewController: UIKitDebugOverlayViewController!
    private var webView: WKWebView!
    
    init(url: URL?) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupDebugOverlay()
        setupConstraints()
        loadURL()
        
        title = "WebView Inspector"
        navigationItem.largeTitleDisplayMode = .never
    }
    
    private func setupWebView() {
        // Configure JavaScript injection for console log capture
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
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = coordinator
        coordinator.webView = webView
        
        #if DEBUG
        webView.isInspectable = true
        #endif
        
        webView.backgroundColor = .systemBackground
        view.addSubview(webView)
    }
    
    private func setupDebugOverlay() {
        debugOverlayViewController = UIKitDebugOverlayViewController()
        debugOverlayViewController.delegate = self
        
        addChild(debugOverlayViewController)
        view.addSubview(debugOverlayViewController.view)
        debugOverlayViewController.didMove(toParent: self)
        
        // Ensure overlay is on top of WebView
        view.bringSubviewToFront(debugOverlayViewController.view)
        
        // Start observing coordinator changes
        startObservingCoordinator()
    }
    
    private func setupConstraints() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        debugOverlayViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // WebView fills most of view, leaving space for overlay at bottom
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100), // Leave space for overlay
            
            // Debug overlay on top, anchored to bottom
            debugOverlayViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            debugOverlayViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            debugOverlayViewController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func loadURL() {
        guard let url = url else {
            showEmptyState()
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func showEmptyState() {
        let emptyStateView = createEmptyStateView()
        view.addSubview(emptyStateView)
        
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func createEmptyStateView() -> UIView {
        let containerView = UIView()
        
        let iconImageView = UIImageView(image: UIImage(systemName: "safari"))
        iconImageView.tintColor = .systemGray
        iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 60)
        
        let titleLabel = UILabel()
        titleLabel.text = "WebView Inspector"
        titleLabel.font = .preferredFont(forTextStyle: .title1)
        titleLabel.textAlignment = .center
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = "Select a test option from the sidebar to load a webpage and start debugging."
        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        
        let featuresLabel = UILabel()
        featuresLabel.text = "Features:"
        featuresLabel.font = .preferredFont(forTextStyle: .headline)
        featuresLabel.textAlignment = .center
        
        let featuresStackView = UIStackView()
        featuresStackView.axis = .vertical
        featuresStackView.spacing = 8
        featuresStackView.distribution = .equalSpacing
        
        let features = [
            ("terminal", "Console log capture"),
            ("doc.text", "DOM inspection"),
            ("network", "Network request monitoring"),
            ("play.circle", "JavaScript execution"),
            ("safari", "Safari Web Inspector integration")
        ]
        
        for (icon, text) in features {
            let featureView = UIStackView()
            featureView.axis = .horizontal
            featureView.spacing = 8
            featureView.alignment = .center
            
            let iconView = UIImageView(image: UIImage(systemName: icon))
            iconView.tintColor = .secondaryLabel
            iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 16)
            
            let textLabel = UILabel()
            textLabel.text = text
            textLabel.font = .preferredFont(forTextStyle: .subheadline)
            textLabel.textColor = .secondaryLabel
            
            featureView.addArrangedSubview(iconView)
            featureView.addArrangedSubview(textLabel)
            featuresStackView.addArrangedSubview(featureView)
        }
        
        let mainStackView = UIStackView(arrangedSubviews: [
            iconImageView,
            titleLabel,
            descriptionLabel,
            featuresLabel,
            featuresStackView
        ])
        mainStackView.axis = .vertical
        mainStackView.spacing = 20
        mainStackView.alignment = .center
        
        [iconImageView, titleLabel, descriptionLabel, featuresLabel, featuresStackView, mainStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        containerView.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            featuresStackView.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor),
            featuresStackView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor)
        ])
        
        return containerView
    }
    
    private func startObservingCoordinator() {
        // Use a timer to periodically update the debug overlay with coordinator data
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.debugOverlayViewController.updateData(
                consoleLogs: self.coordinator.consoleLogs,
                networkRequests: self.coordinator.networkInterceptor.interceptedRequests,
                currentURL: self.coordinator.currentURL,
                isLoading: self.coordinator.isLoading
            )
        }
    }
}

// MARK: - UIKitDebugOverlayDelegate
extension UIKitWebViewInspectorViewController: UIKitDebugOverlayDelegate {
    func debugOverlayDidRequestScriptExecution(_ script: String) {
        coordinator.executeJavaScript(script) { result, error in
            if let error = error {
                print("JavaScript execution error: \(error)")
            } else if let result = result {
                print("JavaScript result: \(result)")
            }
        }
    }
    
    func debugOverlayDidRequestDOMInspection(completion: @escaping (String) -> Void) {
        coordinator.getDOMStructure { result in
            completion(result ?? "Failed to inspect DOM")
        }
    }
    
    func debugOverlayDidRequestClearLogs() {
        coordinator.consoleLogs.removeAll()
    }
    
    func debugOverlayDidRequestClearNetworkRequests() {
        coordinator.networkInterceptor.clearRequests()
    }
}