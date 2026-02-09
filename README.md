# RemoteForPC

A powerful cross-platform remote mouse and keyboard control application built with Flutter.

## Features

- 🖱️ **Mouse Control** - Smooth cursor movement, clicks, and scrolling
- ⌨️ **Keyboard Input** - Full keyboard support with modifiers and special keys
- 🎨 **Trackpad Gestures** - Multi-touch gestures (pinch, swipe, rotate)
- 📋 **Clipboard Sync** - Share clipboard content between devices
- 🎵 **Media Controls** - Play, pause, volume, and media key support

## Connection Modes

### 1. LAN Mode (Wi-Fi)
- Fastest, lowest latency (~5-15ms)
- Auto-discovery via mDNS/Bonjour
- Direct WebSocket connection
- Best for home/office use

### 2. Remote Mode (Internet)
- Control from anywhere via cloud relay
- End-to-end encrypted communication
- Requires user login and device pairing
- Works through NAT/firewalls

### 3. Bluetooth Mode
- Works without Wi-Fi
- Fallback for offline scenarios
- Uses BLE GATT protocol
- Higher latency (~20-50ms)

## Platform Support

- **Server**: macOS, Windows (Desktop apps)
- **Client**: iOS, Android (Mobile apps)

## Architecture

```
┌────────────────────┐         ┌─────────────────────┐
│  Mobile Client     │         │  Desktop Server     │
│  (iOS/Android)     │◄───────►│  (macOS/Windows)    │
│                    │         │                     │
│  • Touch Input     │  Modes: │  • Input Injection  │
│  • Gestures        │  - LAN  │  • Native APIs      │
│  • UI              │  - BLE  │  • System Tray      │
│                    │  - Relay│                     │
└────────────────────┘         └─────────────────────┘
         │                              │
         └──────────────────────────────┘
              Secure WebSocket
           End-to-End Encrypted
```

## Project Structure

```
remoteforpc/
├── apps/
│   ├── server_desktop/      # macOS/Windows server
│   └── client_mobile/       # iOS/Android client
├── packages/
│   └── remote_protocol/     # Shared protocol & crypto
├── backend/                 # Cloud auth + relay backend config
└── melos.yaml              # Monorepo config
```

## Getting Started

### Prerequisites

- Flutter SDK 3.10.0+
- Dart SDK 3.0.0+
- Xcode (for macOS/iOS development)
- Visual Studio 2022 (for Windows development)
- Melos CLI: `dart pub global activate melos`

### Setup

1. **Clone and bootstrap**
   ```bash
   git clone <your-repo-url>
   cd remoteforpc
   melos bootstrap
   ```

2. **Run server app**
   ```bash
   cd apps/server_desktop
   flutter run -d macos  # or windows
   ```

3. **Run client app**
   ```bash
   cd apps/client_mobile
   flutter run -d <your-device>
   ```

### Platform-Specific Setup

#### macOS Server
- Grant Accessibility permissions: System Preferences → Security & Privacy → Accessibility
- Allow network connections in Firewall settings

#### Windows Server
- May require running as Administrator for input injection
- Allow app through Windows Firewall

#### iOS Client
- Configure provisioning profile for device testing
- Grant Local Network and Bluetooth permissions when prompted

#### Android Client
- Enable developer mode on device
- Grant Location permission (required for BLE scanning on Android)

## Development

### Available Scripts

```bash
# Get all dependencies
melos get

# Run analysis
melos analyze

# Format code
melos format

# Run tests
melos test

# Clean all packages
melos clean

# Build server
melos build:server

# Build client
melos build:client
```

### Development Phases

- ✅ **Phase 0**: Project scaffolding
- 🚧 **Phase 1**: LAN Wi-Fi control MVP
- 📅 **Phase 2**: Pairing + encryption
- 📅 **Phase 3**: Cloud relay + remote mode
- 📅 **Phase 4**: Bluetooth fallback
- 📅 **Phase 5**: Full feature set

## Security

- **End-to-End Encryption**: AES-256-GCM for all messages
- **Key Exchange**: ECDH P-256 during pairing
- **Authentication**: PIN-based pairing + JWT for cloud access
- **Zero Trust**: Relay server cannot decrypt messages

## License

MIT License - see LICENSE file for details

## Contributing

Contributions welcome! Please read CONTRIBUTING.md first.
