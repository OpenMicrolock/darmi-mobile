# Microlock

A Flutter mobile application for remotely controlling the Microlock ESP32 smart lock via Wi-Fi. Lock and unlock your door with a single tap from your phone.

<p align="center">
  <img src="assets/logo_trim.png" alt="Microlock Logo" width="140" />
</p>

---

## Features

- **Remote Lock/Unlock** - Control your smart lock from anywhere on the same network
- **Real-time Status** - View current lock state with automatic refresh
- **Token Authentication** - Secure API access with pre-shared token
- **Persistent Settings** - Device connection saved locally
- **Dark Mode** - Automatic light/dark theme based on system preference
- **Accessibility** - Large touch targets and semantic labels

---

## Requirements

| Requirement | Version |
|------------|---------|
| Flutter SDK | >= 3.8.0 |
| Dart SDK | ^3.8.0 |
| Android | API 21+ (minSdk) |
| iOS | 12.0+ (target) |

---

## Project Structure

```
poc-mobileapp/
├── lib/
│   ├── main.dart              # App entry point & routing
│   ├── branding.dart          # App name & logo asset constants
│   ├── api/
│   │   └── lock_api.dart     # HTTP client for lock API
│   ├── screens/
│   │   ├── home_screen.dart   # Main lock/unlock UI
│   │   └── settings_screen.dart # Device configuration form
│   ├── settings/
│   │   └── settings_store.dart # Persistent settings storage
│   └── widgets/
│       └── microlock_logo.dart # Logo component
├── simulator/
│   ├── server.js            # Mock lock API server (Node.js)
│   └── package.json
├── assets/
│   ├── logo.png
│   ├── logo_trim.png
│   └── ...
└── android/ & ios/          # Platform configs
```

---

## Getting Started

### 1. Clone & Install Dependencies

```bash
git clone <repository-url>
cd poc-mobileapp
flutter pub get
```

### 2. Configure Device Connection

The app requires your lock device's:

- **Host** - IP address (default: `192.168.4.1` in AP mode)
- **Port** - API port (default: `1212`)
- **Token** - Authentication token (printed on device sticker or serial output)

### 3. Run the App

```bash
# Development
flutter run

# Release build
flutter build apk --release
flutter build ios --release
```

---

## Simulator (Mock API)

For testing without physical hardware, use the included simulator:

```bash
cd simulator
npm install
npm start
```

**Default credentials:**
- URL: `http://localhost:1212`
- Token: `demo-token`

---

## API Reference

The mobile app communicates with the lock device over HTTP REST API.

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Health check / ping |
| POST | `/lock` | Lock the door |
| POST | `/unlock` | Unlock the door |
| POST | `/status` | Get current state |

### Request Format

```json
{
  "token": "your-auth-token"
}
```

### Response Format

```json
{
  "state": "locked" | "unlocked"
}
```

### Error Responses

| Status | Meaning |
|--------|---------|
| 401 | Invalid token |
| 200-299 | Success |
| 3xx-5xx | API error (timeout, network, etc.) |

---

## Architecture

### State Management

Simple StatefulWidget with asynchronous operations. No external state library required.

### Settings Persistence

`SharedPreferences` stores:
- `lock_host` - Device IP/hostname
- `lock_port` - Device port
- `lock_token` - Auth token

### Error Handling

- `UnauthorizedException` - Invalid token (401)
- `LockApiException` - Connection/API errors with user-friendly messages

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | UI framework |
| `http` | ^1.2.2 | HTTP client |
| `shared_preferences` | ^2.3.4 | Local storage |

---

## Building for Release

### Android

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS

```bash
flutter build ios --release
# Output: build/ios/iphone/Release/Runner.app
```

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

---

## License

This project is open source under the **MIT License**.

---

## Acknowledgments

Built with [Flutter](https://flutter.dev) - the cross-platform UI toolkit.