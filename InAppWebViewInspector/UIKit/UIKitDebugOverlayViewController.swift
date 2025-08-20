//
//  UIKitDebugOverlayViewController.swift
//  InAppWebViewInspector
//
//  Created by Claude on 8/19/25.
//

import UIKit

protocol UIKitDebugOverlayDelegate: AnyObject {
    func debugOverlayDidRequestScriptExecution(_ script: String)
    func debugOverlayDidRequestDOMInspection(completion: @escaping (String) -> Void)
    func debugOverlayDidRequestClearLogs()
    func debugOverlayDidRequestClearNetworkRequests()
}

// Custom view class that properly handles touch events
class DebugOverlayView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        print("🎯 DebugOverlayView hitTest called at point: \(point)")
        print("🎯 View bounds: \(bounds)")
        
        // Let the normal hit testing occur
        let result = super.hitTest(point, with: event)
        print("🎯 DebugOverlayView hitTest result: \(String(describing: result))")
        
        return result
    }
}

class UIKitDebugOverlayViewController: UIViewController {
    weak var delegate: UIKitDebugOverlayDelegate?
    
    private var consoleLogs: [ConsoleLog] = []
    private var networkRequests: [NetworkRequest] = []
    private var currentURL: String = ""
    private var isLoading: Bool = false
    
    private var selectedTab: DebugTab = .console
    private var isExpanded: Bool = false
    private var domStructure: String = ""
    
    // UI Components
    private let containerView = UIView()
    private let toggleBarView = UIView()
    private let titleLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let toggleButton = UIButton(type: .system)
    private let expandedView = UIView()
    private let tabSegmentedControl = UISegmentedControl(items: DebugTab.allCases.map { $0.title })
    private let contentScrollView = UIScrollView()
    private let contentView = UIView()
    
    // Tab Content Views
    private let consoleView = UIView()
    private let domView = UIView()
    private let networkView = UIView()
    private let controlsView = UIView()
    
    // Console components
    private let consoleTableView = UITableView()
    private let consoleTitleLabel = UILabel()
    private let consoleClearButton = UIButton(type: .system)
    
    // DOM components
    private let domTitleLabel = UILabel()
    private let domInspectButton = UIButton(type: .system)
    private let domTextView = UITextView()
    
    // Network components
    private let networkTableView = UITableView()
    private let networkTitleLabel = UILabel()
    private let networkClearButton = UIButton(type: .system)
    private let networkEmptyLabel = UILabel()
    
    // Controls components
    private let controlsTitleLabel = UILabel()
    private let scriptTextView = UITextView()
    private let executeButton = UIButton(type: .system)
    private let clearScriptButton = UIButton(type: .system)
    private let quickActionsStackView = UIStackView()
    private let currentURLLabel = UILabel()
    
    // Constraint properties
    private var containerHeightConstraint: NSLayoutConstraint!
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    override func loadView() {
        // Use our custom view that handles touch events properly
        view = DebugOverlayView()
        view.backgroundColor = .clear
        print("🚀 Debug Overlay: Custom DebugOverlayView created")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🚀 Debug Overlay: viewDidLoad called")
        setupUI()
        setupConstraints()
        setupActions()
        updateTabContent()
        
        // Debug: Print view hierarchy
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🔍 Debug Overlay view frame: \(self.view.frame)")
            print("🔍 Container view frame: \(self.containerView.frame)")
            print("🔍 Toggle bar frame: \(self.toggleBarView.frame)")
        }
    }
    
    func updateData(consoleLogs: [ConsoleLog], networkRequests: [NetworkRequest], currentURL: String, isLoading: Bool) {
        self.consoleLogs = consoleLogs
        self.networkRequests = networkRequests
        self.currentURL = currentURL
        self.isLoading = isLoading
        
        DispatchQueue.main.async {
            self.updateLoadingIndicator()
            self.updateCurrentURLLabel()
            self.consoleTableView.reloadData()
            self.networkTableView.reloadData()
            self.updateNetworkEmptyState()
            self.updateConsoleTitleLabel()
            self.updateNetworkTitleLabel()
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        
        // Ensure hit testing works properly
        view.clipsToBounds = false
        
        // Container setup - make it more visible and touchable
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        containerView.isUserInteractionEnabled = true
        
        // Add border to make it more visible
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        
        // Toggle bar setup
        toggleBarView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toggleBarView.isUserInteractionEnabled = true
        
        titleLabel.text = "Debug Tools"
        titleLabel.textColor = .white
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        
        toggleButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        toggleButton.tintColor = .white
        
        // Expanded view setup
        expandedView.backgroundColor = .clear
        expandedView.isHidden = true
        expandedView.isUserInteractionEnabled = true
        
        // Tab setup
        tabSegmentedControl.selectedSegmentIndex = 0
        tabSegmentedControl.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        tabSegmentedControl.selectedSegmentTintColor = .systemBlue
        tabSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        tabSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        tabSegmentedControl.isUserInteractionEnabled = true
        
        // Content scroll view
        contentScrollView.showsVerticalScrollIndicator = false
        contentScrollView.backgroundColor = .clear
        contentScrollView.isUserInteractionEnabled = true
        
        // Ensure content view is interactive
        contentView.backgroundColor = .clear
        contentView.isUserInteractionEnabled = true
        
        // Ensure tab views are interactive
        [consoleView, domView, networkView, controlsView].forEach {
            $0.backgroundColor = .clear
            $0.isUserInteractionEnabled = true
        }
        
        setupConsoleView()
        setupDOMView()
        setupNetworkView()
        setupControlsView()
    }
    
    private func setupConsoleView() {
        consoleTitleLabel.text = "Console Logs (0)"
        consoleTitleLabel.textColor = .white
        consoleTitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        
        consoleClearButton.setTitle("Clear", for: .normal)
        consoleClearButton.setTitleColor(.systemRed, for: .normal)
        consoleClearButton.titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        
        consoleTableView.backgroundColor = .clear
        consoleTableView.separatorStyle = .none
        consoleTableView.register(ConsoleLogCell.self, forCellReuseIdentifier: "ConsoleLogCell")
        consoleTableView.dataSource = self
        consoleTableView.delegate = self
    }
    
    private func setupDOMView() {
        domTitleLabel.text = "DOM Inspector"
        domTitleLabel.textColor = .white
        domTitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        
        domInspectButton.setTitle("Inspect", for: .normal)
        domInspectButton.setTitleColor(.systemBlue, for: .normal)
        domInspectButton.titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        
        domTextView.backgroundColor = .clear
        domTextView.textColor = .white
        domTextView.font = .preferredFont(forTextStyle: .caption1)
        domTextView.text = "Tap 'Inspect' to view DOM structure"
        domTextView.isEditable = false
        domTextView.isUserInteractionEnabled = true
        domTextView.isScrollEnabled = true
    }
    
    private func setupNetworkView() {
        networkTitleLabel.text = "Network Requests (0)"
        networkTitleLabel.textColor = .white
        networkTitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        
        networkClearButton.setTitle("Clear", for: .normal)
        networkClearButton.setTitleColor(.systemRed, for: .normal)
        networkClearButton.titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        
        networkTableView.backgroundColor = .clear
        networkTableView.separatorStyle = .none
        networkTableView.register(NetworkRequestCell.self, forCellReuseIdentifier: "NetworkRequestCell")
        networkTableView.dataSource = self
        networkTableView.delegate = self
        
        networkEmptyLabel.text = "No network requests intercepted yet.\nTry loading a debug:// URL"
        networkEmptyLabel.textColor = .gray
        networkEmptyLabel.font = .preferredFont(forTextStyle: .caption1)
        networkEmptyLabel.textAlignment = .center
        networkEmptyLabel.numberOfLines = 0
    }
    
    private func setupControlsView() {
        controlsTitleLabel.text = "JavaScript Console"
        controlsTitleLabel.textColor = .white
        controlsTitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        
        scriptTextView.backgroundColor = UIColor.systemGray6
        scriptTextView.textColor = .label
        scriptTextView.font = .preferredFont(forTextStyle: .body)
        scriptTextView.layer.cornerRadius = 8
        scriptTextView.text = ""
        scriptTextView.isEditable = true
        scriptTextView.isUserInteractionEnabled = true
        
        executeButton.setTitle("Execute", for: .normal)
        executeButton.setTitleColor(.systemBlue, for: .normal)
        executeButton.setTitleColor(.systemGray, for: .disabled)
        executeButton.isEnabled = false
        
        clearScriptButton.setTitle("Clear", for: .normal)
        clearScriptButton.setTitleColor(.systemBlue, for: .normal)
        
        // Quick actions
        quickActionsStackView.axis = .vertical
        quickActionsStackView.spacing = 8
        quickActionsStackView.distribution = .fillEqually
        
        let quickButtons = [
            ("Log Hello World", "console.log('Hello from JavaScript!')"),
            ("Get Page Title", "console.log('Page title:', document.title)"),
            ("Count Elements", "console.log('Total elements:', document.querySelectorAll('*').length)"),
            ("Get URL", "console.log('Current URL:', window.location.href)"),
            ("Test Error", "console.error('Test error message')"),
            ("Test Warning", "console.warn('Test warning message')")
        ]
        
        for (title, _) in quickButtons {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .preferredFont(forTextStyle: .caption1)
            button.addTarget(self, action: #selector(quickButtonTapped(_:)), for: .touchUpInside)
            button.tag = quickButtons.firstIndex(where: { $0.0 == title }) ?? 0
            quickActionsStackView.addArrangedSubview(button)
        }
        
        currentURLLabel.text = "Current URL: No URL loaded"
        currentURLLabel.textColor = .systemBlue
        currentURLLabel.font = .preferredFont(forTextStyle: .caption1)
        currentURLLabel.numberOfLines = 0
    }
    
    private func setupConstraints() {
        [containerView, toggleBarView, titleLabel, loadingIndicator, toggleButton, expandedView,
         tabSegmentedControl, contentScrollView, contentView, consoleView, domView, networkView, controlsView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        view.addSubview(containerView)
        containerView.addSubview(toggleBarView)
        containerView.addSubview(expandedView)
        
        toggleBarView.addSubview(titleLabel)
        toggleBarView.addSubview(loadingIndicator)
        toggleBarView.addSubview(toggleButton)
        
        expandedView.addSubview(tabSegmentedControl)
        expandedView.addSubview(contentScrollView)
        contentScrollView.addSubview(contentView)
        
        contentView.addSubview(consoleView)
        contentView.addSubview(domView)
        contentView.addSubview(networkView)
        contentView.addSubview(controlsView)
        
        NSLayoutConstraint.activate([
            // Container
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Toggle bar
            toggleBarView.topAnchor.constraint(equalTo: containerView.topAnchor),
            toggleBarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            toggleBarView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            toggleBarView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.leadingAnchor.constraint(equalTo: toggleBarView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: toggleBarView.centerYAnchor),
            
            toggleButton.trailingAnchor.constraint(equalTo: toggleBarView.trailingAnchor, constant: -16),
            toggleButton.centerYAnchor.constraint(equalTo: toggleBarView.centerYAnchor),
            toggleButton.widthAnchor.constraint(equalToConstant: 44),
            toggleButton.heightAnchor.constraint(equalToConstant: 44),
            
            loadingIndicator.trailingAnchor.constraint(equalTo: toggleButton.leadingAnchor, constant: -8),
            loadingIndicator.centerYAnchor.constraint(equalTo: toggleBarView.centerYAnchor),
            
            // Expanded view
            expandedView.topAnchor.constraint(equalTo: toggleBarView.bottomAnchor),
            expandedView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            expandedView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            expandedView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Tab control
            tabSegmentedControl.topAnchor.constraint(equalTo: expandedView.topAnchor),
            tabSegmentedControl.leadingAnchor.constraint(equalTo: expandedView.leadingAnchor),
            tabSegmentedControl.trailingAnchor.constraint(equalTo: expandedView.trailingAnchor),
            tabSegmentedControl.heightAnchor.constraint(equalToConstant: 44),
            
            // Content scroll view
            contentScrollView.topAnchor.constraint(equalTo: tabSegmentedControl.bottomAnchor),
            contentScrollView.leadingAnchor.constraint(equalTo: expandedView.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: expandedView.trailingAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: expandedView.bottomAnchor),
            contentScrollView.heightAnchor.constraint(equalToConstant: 300),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: contentScrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: contentScrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentScrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentScrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: contentScrollView.widthAnchor),
        ])
        
        setupTabConstraints()
        
        // Container height constraint - initially collapsed
        containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 60)
        containerHeightConstraint.isActive = true
    }
    
    private func setupTabConstraints() {
        // All tab views fill content view
        [consoleView, domView, networkView, controlsView].forEach { tabView in
            NSLayoutConstraint.activate([
                tabView.topAnchor.constraint(equalTo: contentView.topAnchor),
                tabView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                tabView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                tabView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                tabView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300)
            ])
        }
        
        setupConsoleConstraints()
        setupDOMConstraints()
        setupNetworkConstraints()
        setupControlsConstraints()
    }
    
    private func setupConsoleConstraints() {
        [consoleTitleLabel, consoleClearButton, consoleTableView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            consoleView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            consoleTitleLabel.topAnchor.constraint(equalTo: consoleView.topAnchor, constant: 16),
            consoleTitleLabel.leadingAnchor.constraint(equalTo: consoleView.leadingAnchor, constant: 16),
            
            consoleClearButton.topAnchor.constraint(equalTo: consoleView.topAnchor, constant: 16),
            consoleClearButton.trailingAnchor.constraint(equalTo: consoleView.trailingAnchor, constant: -16),
            
            consoleTableView.topAnchor.constraint(equalTo: consoleTitleLabel.bottomAnchor, constant: 8),
            consoleTableView.leadingAnchor.constraint(equalTo: consoleView.leadingAnchor),
            consoleTableView.trailingAnchor.constraint(equalTo: consoleView.trailingAnchor),
            consoleTableView.bottomAnchor.constraint(equalTo: consoleView.bottomAnchor)
        ])
    }
    
    private func setupDOMConstraints() {
        [domTitleLabel, domInspectButton, domTextView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            domView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            domTitleLabel.topAnchor.constraint(equalTo: domView.topAnchor, constant: 16),
            domTitleLabel.leadingAnchor.constraint(equalTo: domView.leadingAnchor, constant: 16),
            
            domInspectButton.topAnchor.constraint(equalTo: domView.topAnchor, constant: 16),
            domInspectButton.trailingAnchor.constraint(equalTo: domView.trailingAnchor, constant: -16),
            
            domTextView.topAnchor.constraint(equalTo: domTitleLabel.bottomAnchor, constant: 8),
            domTextView.leadingAnchor.constraint(equalTo: domView.leadingAnchor, constant: 16),
            domTextView.trailingAnchor.constraint(equalTo: domView.trailingAnchor, constant: -16),
            domTextView.bottomAnchor.constraint(equalTo: domView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupNetworkConstraints() {
        [networkTitleLabel, networkClearButton, networkTableView, networkEmptyLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            networkView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            networkTitleLabel.topAnchor.constraint(equalTo: networkView.topAnchor, constant: 16),
            networkTitleLabel.leadingAnchor.constraint(equalTo: networkView.leadingAnchor, constant: 16),
            
            networkClearButton.topAnchor.constraint(equalTo: networkView.topAnchor, constant: 16),
            networkClearButton.trailingAnchor.constraint(equalTo: networkView.trailingAnchor, constant: -16),
            
            networkTableView.topAnchor.constraint(equalTo: networkTitleLabel.bottomAnchor, constant: 8),
            networkTableView.leadingAnchor.constraint(equalTo: networkView.leadingAnchor),
            networkTableView.trailingAnchor.constraint(equalTo: networkView.trailingAnchor),
            networkTableView.bottomAnchor.constraint(equalTo: networkView.bottomAnchor),
            
            networkEmptyLabel.centerXAnchor.constraint(equalTo: networkView.centerXAnchor),
            networkEmptyLabel.centerYAnchor.constraint(equalTo: networkView.centerYAnchor),
            networkEmptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: networkView.leadingAnchor, constant: 16),
            networkEmptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: networkView.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupControlsConstraints() {
        [controlsTitleLabel, scriptTextView, executeButton, clearScriptButton, quickActionsStackView, currentURLLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            controlsView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            controlsTitleLabel.topAnchor.constraint(equalTo: controlsView.topAnchor, constant: 16),
            controlsTitleLabel.leadingAnchor.constraint(equalTo: controlsView.leadingAnchor, constant: 16),
            controlsTitleLabel.trailingAnchor.constraint(equalTo: controlsView.trailingAnchor, constant: -16),
            
            scriptTextView.topAnchor.constraint(equalTo: controlsTitleLabel.bottomAnchor, constant: 8),
            scriptTextView.leadingAnchor.constraint(equalTo: controlsView.leadingAnchor, constant: 16),
            scriptTextView.trailingAnchor.constraint(equalTo: controlsView.trailingAnchor, constant: -16),
            scriptTextView.heightAnchor.constraint(equalToConstant: 80),
            
            executeButton.topAnchor.constraint(equalTo: scriptTextView.bottomAnchor, constant: 8),
            executeButton.leadingAnchor.constraint(equalTo: controlsView.leadingAnchor, constant: 16),
            
            clearScriptButton.topAnchor.constraint(equalTo: scriptTextView.bottomAnchor, constant: 8),
            clearScriptButton.trailingAnchor.constraint(equalTo: controlsView.trailingAnchor, constant: -16),
            
            quickActionsStackView.topAnchor.constraint(equalTo: executeButton.bottomAnchor, constant: 16),
            quickActionsStackView.leadingAnchor.constraint(equalTo: controlsView.leadingAnchor, constant: 16),
            quickActionsStackView.trailingAnchor.constraint(equalTo: controlsView.trailingAnchor, constant: -16),
            
            currentURLLabel.topAnchor.constraint(equalTo: quickActionsStackView.bottomAnchor, constant: 16),
            currentURLLabel.leadingAnchor.constraint(equalTo: controlsView.leadingAnchor, constant: 16),
            currentURLLabel.trailingAnchor.constraint(equalTo: controlsView.trailingAnchor, constant: -16),
            currentURLLabel.bottomAnchor.constraint(lessThanOrEqualTo: controlsView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupActions() {
        toggleButton.addTarget(self, action: #selector(toggleButtonTapped), for: .touchUpInside)
        tabSegmentedControl.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
        consoleClearButton.addTarget(self, action: #selector(clearConsoleTapped), for: .touchUpInside)
        domInspectButton.addTarget(self, action: #selector(inspectDOMTapped), for: .touchUpInside)
        networkClearButton.addTarget(self, action: #selector(clearNetworkTapped), for: .touchUpInside)
        executeButton.addTarget(self, action: #selector(executeScriptTapped), for: .touchUpInside)
        clearScriptButton.addTarget(self, action: #selector(clearScriptTapped), for: .touchUpInside)
        
        scriptTextView.delegate = self
    }
    
    @objc private func toggleButtonTapped() {
        print("🔄 Debug Overlay: Toggle button tapped!")
        isExpanded.toggle()
        updateExpandedState()
    }
    
    @objc private func tabChanged() {
        selectedTab = DebugTab.allCases[tabSegmentedControl.selectedSegmentIndex]
        updateTabContent()
    }
    
    @objc private func clearConsoleTapped() {
        delegate?.debugOverlayDidRequestClearLogs()
    }
    
    @objc private func inspectDOMTapped() {
        delegate?.debugOverlayDidRequestDOMInspection { [weak self] result in
            DispatchQueue.main.async {
                self?.domStructure = result
                self?.domTextView.text = result.isEmpty ? "Tap 'Inspect' to view DOM structure" : result
            }
        }
    }
    
    @objc private func clearNetworkTapped() {
        delegate?.debugOverlayDidRequestClearNetworkRequests()
    }
    
    @objc private func executeScriptTapped() {
        let script = scriptTextView.text ?? ""
        if !script.isEmpty {
            delegate?.debugOverlayDidRequestScriptExecution(script)
        }
    }
    
    @objc private func clearScriptTapped() {
        scriptTextView.text = ""
        updateExecuteButtonState()
    }
    
    @objc private func quickButtonTapped(_ sender: UIButton) {
        let scripts = [
            "console.log('Hello from JavaScript!')",
            "console.log('Page title:', document.title)",
            "console.log('Total elements:', document.querySelectorAll('*').length)",
            "console.log('Current URL:', window.location.href)",
            "console.error('Test error message')",
            "console.warn('Test warning message')"
        ]
        
        if sender.tag < scripts.count {
            delegate?.debugOverlayDidRequestScriptExecution(scripts[sender.tag])
        }
    }
    
    private func updateExpandedState() {
        expandedView.isHidden = !isExpanded
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.toggleButton.imageView?.transform = self.isExpanded ? .identity : CGAffineTransform(rotationAngle: .pi)
            self.containerView.layer.cornerRadius = self.isExpanded ? 0 : 20
            
            // Update height constraint using the property
            self.containerHeightConstraint.constant = self.isExpanded ? 404 : 60 // 60 + 44 + 300
            
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateTabContent() {
        [consoleView, domView, networkView, controlsView].forEach { $0.isHidden = true }
        
        switch selectedTab {
        case .console:
            consoleView.isHidden = false
        case .dom:
            domView.isHidden = false
        case .network:
            networkView.isHidden = false
        case .controls:
            controlsView.isHidden = false
        }
    }
    
    private func updateLoadingIndicator() {
        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }
    
    private func updateCurrentURLLabel() {
        currentURLLabel.text = "Current URL: \(currentURL.isEmpty ? "No URL loaded" : currentURL)"
    }
    
    private func updateConsoleTitleLabel() {
        consoleTitleLabel.text = "Console Logs (\(consoleLogs.count))"
    }
    
    private func updateNetworkTitleLabel() {
        networkTitleLabel.text = "Network Requests (\(networkRequests.count))"
    }
    
    private func updateNetworkEmptyState() {
        networkEmptyLabel.isHidden = !networkRequests.isEmpty
        networkTableView.isHidden = networkRequests.isEmpty
    }
    
    private func updateExecuteButtonState() {
        executeButton.isEnabled = !(scriptTextView.text?.isEmpty ?? true)
    }
    
    private func logColor(for message: String) -> UIColor {
        if message.hasPrefix("ERROR:") {
            return .systemRed
        } else if message.hasPrefix("WARN:") {
            return .systemOrange
        } else {
            return .white
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension UIKitDebugOverlayViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == consoleTableView {
            return min(consoleLogs.count, 50)
        } else if tableView == networkTableView {
            return min(networkRequests.count, 20)
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == consoleTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ConsoleLogCell", for: indexPath) as! ConsoleLogCell
            let logIndex = max(0, consoleLogs.count - 50) + indexPath.row
            if logIndex < consoleLogs.count {
                let log = consoleLogs[logIndex]
                cell.configure(with: log, timeFormatter: timeFormatter, logColor: logColor(for: log.message))
            }
            return cell
        } else if tableView == networkTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NetworkRequestCell", for: indexPath) as! NetworkRequestCell
            let requestIndex = max(0, networkRequests.count - 20) + indexPath.row
            if requestIndex < networkRequests.count {
                let request = networkRequests[requestIndex]
                cell.configure(with: request, timeFormatter: timeFormatter)
            }
            return cell
        }
        return UITableViewCell()
    }
}

// MARK: - UITextViewDelegate
extension UIKitDebugOverlayViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView == scriptTextView {
            updateExecuteButtonState()
        }
    }
}

// MARK: - Custom Cell Classes
class ConsoleLogCell: UITableViewCell {
    private let timestampLabel = UILabel()
    private let messageLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        timestampLabel.font = .preferredFont(forTextStyle: .caption2)
        timestampLabel.textColor = .systemGray
        timestampLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        messageLabel.font = .preferredFont(forTextStyle: .caption1)
        messageLabel.numberOfLines = 0
        
        [timestampLabel, messageLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            timestampLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            timestampLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timestampLabel.widthAnchor.constraint(equalToConstant: 60),
            
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: timestampLabel.trailingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }
    
    func configure(with log: ConsoleLog, timeFormatter: DateFormatter, logColor: UIColor) {
        timestampLabel.text = timeFormatter.string(from: log.timestamp)
        messageLabel.text = log.message
        messageLabel.textColor = logColor
    }
}

class NetworkRequestCell: UITableViewCell {
    private let timestampLabel = UILabel()
    private let methodLabel = UILabel()
    private let urlLabel = UILabel()
    private let containerView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        containerView.backgroundColor = UIColor.systemGray.withAlphaComponent(0.1)
        containerView.layer.cornerRadius = 4
        
        timestampLabel.font = .preferredFont(forTextStyle: .caption2)
        timestampLabel.textColor = .systemGray
        
        methodLabel.font = .preferredFont(forTextStyle: .caption1)
        methodLabel.textColor = .systemBlue
        methodLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        methodLabel.layer.cornerRadius = 4
        methodLabel.textAlignment = .center
        methodLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        urlLabel.font = .preferredFont(forTextStyle: .caption1)
        urlLabel.textColor = .white
        urlLabel.numberOfLines = 2
        
        [containerView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        [timestampLabel, methodLabel, urlLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            timestampLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            timestampLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            
            methodLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            methodLabel.leadingAnchor.constraint(equalTo: timestampLabel.trailingAnchor, constant: 8),
            methodLabel.widthAnchor.constraint(equalToConstant: 50),
            
            urlLabel.topAnchor.constraint(equalTo: timestampLabel.bottomAnchor, constant: 4),
            urlLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            urlLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            urlLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with request: NetworkRequest, timeFormatter: DateFormatter) {
        timestampLabel.text = timeFormatter.string(from: request.timestamp)
        methodLabel.text = request.method
        urlLabel.text = request.url
    }
}