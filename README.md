# Phantom

Cross-platform debug toolkit for mobile apps.

[![iOS](https://img.shields.io/badge/iOS-15%2B-blue)](phantom-ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)](phantom-ios/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## Screenshots

| Home | Logs | Network Inspector |
|:---:|:---:|:---:|
| <img src="Screenshots/home.jpeg" width="200" /> | <img src="Screenshots/logs.jpeg" width="200" /> | <img src="Screenshots/network.jpeg" width="200" /> |
| Main debug panel with access to all features | Filter logs by level (Info, Warn, Error) and search by message or tag | Inspect HTTP requests/responses with JSON tree viewer, filter by errors or slow requests |

| Mock Services | New Mock Rule | Edit Mock Rule |
|:---:|:---:|:---:|
| <img src="Screenshots/mock_list.jpeg" width="200" /> | <img src="Screenshots/mock_new.jpeg" width="200" /> | <img src="Screenshots/mock_edit.jpeg" width="200" /> |
| List of mock rules with enable/disable toggles per rule | Create new mock rules with URL pattern, HTTP method, and JSON response | Edit existing rules, change status code, response body, or delete the rule |

## Features

- **Logs** - App-level logging with levels (info, warning, error) and tag filtering
- **Network Inspector** - Capture and inspect HTTP requests/responses with JSON tree viewer
- **Mock Services** - Intercept network requests and return mock responses at runtime, with JSON import/export
- **Configuration** - Generic key-value override system with group support for organized config sections
- **Localization** - Bilingual string management (English/Spanish) with group filtering and language switching

## Platforms

| Platform | Status | Package |
|----------|--------|---------|
| iOS (Swift) | Available | `phantom-ios/` |
| Flutter | Planned | `phantom-flutter/` |
| Android (Kotlin) | Planned | `phantom-android/` |

## iOS - Quick Start

### Installation

Add `phantom-ios/` as a local Swift Package or via SPM:

```swift
.package(url: "https://github.com/donnadony/phantom.git", from: "0.0.1")
```

### Usage

```swift
import Phantom

// App logging
Phantom.log(.info, "User logged in", tag: "Auth")
Phantom.log(.error, "Failed to fetch data", tag: "API")

// Network logging - hook into your network layer
Phantom.logRequest(urlRequest)
Phantom.logResponse(for: urlRequest, body: responseData)

// Mock interceptor - check before making real request
if let (data, response) = Phantom.mockResponse(for: urlRequest) {
    // Return mock data instead of hitting the network
}

// Config overrides (with optional groups)
Phantom.registerConfig("API Base URL", key: "api_base_url", defaultValue: "https://prod.api.com")
Phantom.registerConfig("Cache TTL", key: "cache_ttl", defaultValue: "300", group: "Performance")
let url = Phantom.config("api_base_url") ?? defaultUrl

// Localization
Phantom.registerLocalization(key: "welcome", english: "Welcome", spanish: "Bienvenido")
Phantom.registerLocalization(key: "login", english: "Log In", spanish: "Iniciar Sesión", group: "Auth")
let text = Phantom.localized("welcome")
Phantom.setLanguage(.spanish)

// Show debug panel
Phantom.view()
```

### Mock Import / Export

Load mock rules from JSON files bundled in your app or imported at runtime. Export your current mocks to share with your team.

```swift
// Load mocks from a JSON file in the app bundle
Phantom.loadMocks(from: "auth_mocks") // looks for auth_mocks.json

// Load mocks from a URL
Phantom.loadMocks(from: fileURL)

// Export current mocks as JSON
if let data = Phantom.exportMocks(name: "My Mocks") {
    // Share via AirDrop, save to file, etc.
}
```

The JSON format supports both a collection wrapper and a raw array:

```json
{
  "name": "Auth Mocks",
  "description": "Mock rules for authentication endpoints",
  "rules": [
    {
      "urlPattern": "/v1/auth/login",
      "httpMethod": "POST",
      "ruleDescription": "Login success",
      "responses": [
        { "name": "Response 1", "statusCode": 200, "responseBody": "{\"token\": \"abc\"}" }
      ]
    }
  ]
}
```

The Mock Services UI also includes an import/export menu for loading and sharing mock files directly from the debug panel.

### Configuration Groups

Config entries can be organized into groups. When multiple groups exist, a filter appears automatically.

```swift
// Default group ("General") - no group parameter needed
Phantom.registerConfig("API Base URL", key: "api_url", defaultValue: "https://api.example.com")

// Custom groups
Phantom.registerConfig("Cache TTL", key: "cache_ttl", defaultValue: "300", group: "Performance")
Phantom.registerConfig("Log Level", key: "log_level", defaultValue: "info", type: .picker, options: ["debug", "info", "warning", "error"], group: "Debug")
```

### Localization

Manage bilingual strings (English/Spanish) organized by groups, with a language switcher in the UI.

```swift
// Default group
Phantom.registerLocalization(key: "welcome", english: "Welcome", spanish: "Bienvenido")

// Custom groups
Phantom.registerLocalization(key: "login", english: "Log In", spanish: "Iniciar Sesión", group: "Auth")
Phantom.registerLocalization(key: "home", english: "Home", spanish: "Inicio", group: "Navigation")

// Get localized string (uses current language)
let text = Phantom.localized("welcome") // "Welcome" or "Bienvenido"

// Switch language
Phantom.setLanguage(.spanish)
```

### Theme Configuration

Phantom ships with a dark theme (Kodivex) by default. You can customize every color by providing a `PhantomTheme` before presenting the debug panel:

```swift
// Use the default Kodivex dark theme (no setup needed)
Phantom.view()

// Customize specific colors
let customTheme = PhantomTheme(
    background: Color(hex: "#1a1a2e"),
    surface: Color(hex: "#16213e"),
    primary: Color(hex: "#e94560"),
    tint: Color(hex: "#e94560"),
    inputBackground: Color(hex: "#0f3460")
)
Phantom.setTheme(customTheme)
```

All `PhantomTheme` properties have default values, so you only need to override the colors you want to change.

| Property | Description |
|----------|-------------|
| `background` | Main screen background |
| `surface` | Card and container backgrounds |
| `surfaceVariant` | Elevated surface backgrounds |
| `onBackground` | Primary text on background |
| `onBackgroundVariant` | Secondary/muted text |
| `onPrimary` | Text on primary-colored elements |
| `primary` | Accent color for buttons, links, selections |
| `primaryContainer` | Accent variant for filled containers |
| `tint` | Tint for interactive controls (toggles, pickers) |
| `inputBackground` | Background for text editors and input fields |
| `info` | Info-level log color |
| `warning` | Warning-level log / modified badge color |
| `error` | Error-level log / destructive action color |
| `success` | Success status color |
| `outline` | Border/divider color |
| `outlineVariant` | Subtle border color |
| `httpGet/Post/Put/Delete` | HTTP method badge colors |
| `jsonString/Number/Boolean/Null` | JSON tree viewer syntax colors |

## Architecture

```
Phantom/
├── phantom-ios/           Swift Package (iOS 15+, Swift 5.9+)
│   ├── Sources/Phantom/
│   │   ├── Core/          Platform-agnostic logic
│   │   ├── UI/            SwiftUI views
│   │   └── Extensions/    Internal helpers
│   └── Tests/
├── phantom-flutter/       Flutter package (planned)
└── phantom-android/       Kotlin module (planned)
```

## License

MIT
