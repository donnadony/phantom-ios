# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Phantom is a cross-platform debug toolkit for mobile apps. Currently only the iOS Swift Package is implemented (`phantom-ios/`). Flutter and Android packages are planned but not yet started.

## Build & Test Commands

```bash
# Build the iOS package
swift build

# Build via xcodebuild (for iOS Simulator)
xcodebuild -scheme Phantom -destination 'generic/platform=iOS Simulator' build

# Run all tests
swift test

# Run a single test class
swift test --filter PhantomLoggerTests

# Run a single test method
swift test --filter PhantomLoggerTests/testLogInfo
```

## Architecture

This is a Swift Package (iOS 15+, Swift 5.9+) with a single `Phantom` library target.

### Public API Surface

`Phantom` (enum) is the sole public entry point — all features are accessed via static methods on this enum. It delegates to four singleton core managers:

- **PhantomLogger** — App-level logging with levels (info/warning/error) and tags. Stores `PhantomLogItem` entries in-memory, newest first.
- **PhantomNetworkLogger** — Captures HTTP request/response pairs. Uses a pending-request tracking system (keyed by request signature and URL) to correlate `logRequest` and `logResponse` calls. Thread-safe via a serial `DispatchQueue`.
- **PhantomMockInterceptor** — URL pattern matching to intercept requests and return mock responses. Rules persist via `UserDefaults`. Matches by HTTP method + URL path substring.
- **PhantomConfig** — Generic key-value override system. Host app registers config entries with defaults; overrides persist in `UserDefaults` with `phantom_config_` prefix.
- **PhantomLocalizer** — Bilingual string management (English/Spanish) with group filtering. Host app registers localization entries; current language persists in `UserDefaults`.

All five core managers are `ObservableObject`s with `@Published` properties, enabling direct SwiftUI binding.

UI-only features (no core manager, self-contained in their view/viewmodel):

- **cURL Export** — Builds a curl command from a `PhantomNetworkItem` (method, URL, headers, body). Lives in `PhantomNetworkDetailViewModel.buildCurlCommand()`.
- **Device Info** — Reads app bundle info, device model (marketing name mapping), screen metrics, disk storage via `FileManager`, and memory via `task_vm_info`. Lives in `UI/DeviceInfo/`.
- **UserDefaults Viewer** — Reads `UserDefaults.standard.dictionaryRepresentation()`, filters out system keys (Apple/NS/AK prefixes + volatile domains), detects types via `CFBooleanGetTypeID()`. Supports inline Bool toggle, tap-to-edit sheet for String/Int/Double, add/delete/clear. Lives in `UI/UserDefaults/`.

### UI Layer

SwiftUI views under `UI/` provide the debug panel:
- `PhantomView` — Root navigation view (Logs, Network, Mock Services, Configuration, Device Info, UserDefaults, Localization)
- Feature-specific views: `PhantomLogsView`, `PhantomNetworkView` (with `PhantomNetworkDetailView` and `PhantomJsonTreeView`), `PhantomMockListView`/`PhantomMockEditView`, `PhantomConfigView`, `PhantomDeviceInfoView`, `PhantomUserDefaultsView`/`PhantomUserDefaultsEditView`, `PhantomLocalizationView`

### Key Patterns

- **Request correlation**: Network logger matches responses to pending requests using a composite key (`method|url|bodyHash`) with fallback to URL-only matching.
- **External entries**: `logExternalEntry(_:)` accepts raw JSON strings for logging network activity from non-native layers (e.g., WebViews, Flutter bridges).
- **Thread safety**: Network logger mutations happen on a serial queue, then snapshot to main thread for UI updates.
