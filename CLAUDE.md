# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

InAppWebViewInspector is an iOS app built with SwiftUI that aims to provide in-app debugging capabilities for WKWebView without relying on Safari Web Inspector. The project is designed to implement custom debugging tools directly within the iOS application for enhanced WKWebView development and testing.

## Development Commands

### Building and Running
- **Build**: Use Xcode to build the project by opening `InAppWebViewInspector.xcodeproj`
- **Run**: Use Xcode's run button or Cmd+R to build and run on simulator/device
- **Clean**: Product → Clean Build Folder in Xcode

### Testing
- **Unit Tests**: The project uses Swift Testing framework for unit tests located in `InAppWebViewInspectorTests/`
- **UI Tests**: XCTest-based UI tests are in `InAppWebViewInspectorUITests/`
- **Run Tests**: Use Xcode's test navigator or Cmd+U to run all tests

## Architecture

### Core Components
- **InAppWebViewInspectorApp.swift**: Main app entry point with SwiftData model container setup
- **ContentView.swift**: Primary SwiftUI view with navigation split view layout and SwiftData integration
- **Item.swift**: SwiftData model representing timestamped items

### Data Layer
- Uses SwiftData for persistence with `ModelContainer` configured in the main app
- `Item` model stores timestamp data with SwiftData `@Model` macro

### Project Structure
```
InAppWebViewInspector/
├── InAppWebViewInspector/          # Main app source
│   ├── InAppWebViewInspectorApp.swift
│   ├── ContentView.swift
│   ├── Item.swift
│   └── Assets.xcassets/
├── InAppWebViewInspectorTests/     # Unit tests (Swift Testing)
└── InAppWebViewInspectorUITests/   # UI tests (XCTest)
```

### Key Technical Details
- **Target iOS Version**: 18.5+
- **Swift Version**: 5.0
- **UI Framework**: SwiftUI with SwiftData integration
- **Bundle ID**: com.mightystrong.InAppWebViewInspector
- **Development Team**: Q7BEAG244J

### WKWebView Integration Goals
Based on the project plan, this app is intended to implement:
- JavaScript execution and console log capture via `WKScriptMessageHandler`
- DOM inspection and manipulation through `evaluateJavaScript`
- Network request interception using `WKURLSchemeHandler`
- Custom debug overlays and controls for WKWebView debugging
- Programmatic inspector controls using `isInspectable` property

Currently the project is a basic SwiftUI app template - the WKWebView debugging features are yet to be implemented.
- When we make changes to the SwiftUI/ Debugging capabilities we should consider changes to the UIKit implementations as well and vice-versa.