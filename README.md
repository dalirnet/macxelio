# Macxelio

> Native Xray Interface

A native macOS client for managing Xray proxy configurations.

## Requirements

- macOS 13.0 or later

## Features

- Native SwiftUI interface
- Manage Xray proxy configurations
- Server connection management
- Clean and intuitive design

## Quick Start

### Build

```bash
make build
```

### Run

```bash
make run
```

### Release Build

```bash
make release
```

## Project Structure

```
Macxelio/
├── Sources/
│   ├── MacxelioApp.swift    # App entry point
│   ├── Models/              # Data models
│   ├── Views/               # SwiftUI views
│   └── Utils/               # Utilities
├── Resources/
│   ├── Info.plist           # App configuration
│   └── AppIcon.icns         # App icon
├── Package.swift            # Swift package manifest
├── Makefile                 # Build commands
└── build.sh                 # Build script
```

## License

MIT License - see [LICENSE](LICENSE) for details.
