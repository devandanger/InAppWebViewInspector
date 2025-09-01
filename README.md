# InAppWebViewInspector

An iOS app that provides in-app debugging capabilities for WKWebView without relying on Safari Web Inspector. Built with SwiftUI and UIKit for iOS 18.5+.

## Features

### Implementation Options

The app supports both SwiftUI and UIKit implementations:

1. **SwiftUI Implementation** - Modern declarative UI with comprehensive debugging features
2. **UIKit Implementation** - Traditional UIKit-based debugging interface

### Quick Test Options

Pre-configured test scenarios:
- **Example.com** - Standard website testing
- **Debug Page** - Custom debug URL scheme for testing
- **Apple.com** - Real-world website testing  
- **HTML with Console Logs** - Data URL with JavaScript for console testing

### Debug Overlay

Both implementations include comprehensive debugging capabilities:

#### Console Monitoring
Real-time JavaScript console logging with:
- **Captured Methods**: All console output methods
- **Visual Indicators**: Color-coded messages and timestamps
- **Features**: Auto-scroll, clear functionality, selectable text

#### DOM Inspection
Interactive DOM structure analysis:
- **Element Selection**: Tap-to-inspect functionality
- **DOM Structure**: Complete DOM tree visualization
- **Element Details**: Tag names, IDs, classes, and content

#### Network Monitoring
Real-time network request interception:
- **Request Tracking**: All HTTP/HTTPS requests
- **Custom Schemes**: Support for debug:// URL scheme
- **Request Details**: Method, URL, headers, and response data

#### JavaScript Execution
Direct JavaScript execution capabilities:
- **Script Input**: Execute custom JavaScript code
- **Result Display**: View execution results and errors
- **DOM Manipulation**: Real-time DOM modifications

### Safari Web Inspector Integration
- **isInspectable**: WebViews configured for Safari debugging
- **Native Integration**: Seamless Safari Web Inspector access

## Architecture

### Project Structure
```
InAppWebViewInspector/
├── ContentView.swift                    # Main navigation and test options
├── DebugWebView.swift                   # Core debugging coordinator
├── DebugURLSchemeHandler.swift          # Network interception
├── SwiftUI/
│   ├── DebugOverlay.swift              # SwiftUI debug interface
│   ├── DebugWebViewContainer.swift     # SwiftUI WebView wrapper
│   └── WebViewInspectorDetail.swift    # SwiftUI main view
├── UIKit/
│   ├── UIKitDebugOverlayViewController.swift    # UIKit debug interface
│   ├── UIKitWebViewInspectorViewController.swift # UIKit WebView container
│   └── UIKitWebViewInspectorWrapper.swift       # UIKit SwiftUI bridge
├── Item.swift                          # SwiftData session model
└── InAppWebViewInspectorApp.swift      # App entry point
```

### Key Components

#### DebugWebView.swift
- `WebViewCoordinator`: Central debugging coordinator with console capture
- `ConsoleLog`: Console message data structure
- **Features**: JavaScript message handling, navigation tracking, DOM inspection

#### Debug Overlay Components
- **Console Panel**: Real-time log display with filtering
- **DOM Inspector**: Interactive element inspection
- **Network Monitor**: Request/response tracking
- **JavaScript Console**: Live script execution

#### Network Debugging
- `DebugURLSchemeHandler`: Custom URL scheme handler for debug:// URLs
- **Request Interception**: Captures all network activity
- **Response Analysis**: Headers, status codes, and content inspection

## Requirements

- iOS 18.5+
- Xcode 15.0+
- Swift 5.0+

## Building

1. Open `InAppWebViewInspector.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run (Cmd+R)

## Usage

1. Launch the app
2. Choose between SwiftUI or UIKit implementation
3. Select a quick test option or enter a custom URL
4. Interact with the debug overlay for real-time debugging

### Debugging Features

#### Console Monitoring
- View all JavaScript console output in real-time
- Filter by log level using color coding
- Copy specific log messages for further analysis

#### DOM Inspection
- Tap any element to inspect its properties
- View complete DOM structure
- Explore element attributes and content

#### Network Analysis
- Monitor all network requests in real-time
- Inspect request/response details
- Test custom URL schemes

#### JavaScript Development
- Execute custom JavaScript in the WebView context
- Test DOM manipulations live
- Debug script execution with immediate feedback

## Implementation Details

### SwiftUI Implementation
- Modern declarative UI architecture
- State-driven debugging interface
- Seamless integration with SwiftData for session management

### UIKit Implementation
- Traditional view controller architecture
- UIKit-native debugging controls
- Bridge to SwiftUI for main app integration

### Dual Architecture Benefits
- Compare implementation approaches
- Framework-specific debugging capabilities
- Educational value for iOS developers

## Future Enhancements

Potential areas for expansion:
- Performance metrics monitoring
- Memory usage analysis
- CSS style inspection
- Cookie and storage management
- Advanced network filtering
- Export debugging data

## License

This project is for educational and development purposes.