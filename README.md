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
- **Guided Provisioning** - One-step onboarding for Wi-Fi setup and AP fallback
- **Persistent Settings** - Device connection and provisioning settings saved locally
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
│   │   └── lock_api.dart      # HTTP client for lock + provisioning API
│   ├── screens/
│   │   ├── home_screen.dart   # Main lock/unlock UI
│   │   ├── provisioning_screen.dart # Guided Wi-Fi/AP setup
│   │   └── settings_screen.dart # Host/token settings
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

The app can now guide provisioning directly from the device AP.

- Use **Set Up New Device** for Wi-Fi onboarding.
- Use **Change host or token** only if you already know the device IP and token.
- Enter the device host shown by the app, device, or simulator.
- API port: `1212`

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

Simulator provisioning values are configurable through environment variables:

```bash
MICROLOCK_AP_SSID=Device-1234 \
MICROLOCK_AP_PASSWORD=<your-choice> \
MICROLOCK_WIFI_SSID="" \
npm start
```

---

## API Reference

The mobile app communicates with the lock device over HTTP REST API.

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Health check / ping |
| GET | `/config` | Read current provisioning config |
| POST | `/lock` | Lock the door |
| POST | `/unlock` | Unlock the door |
| POST | `/status` | Get current state |
| POST | `/config` | Save Wi-Fi / AP provisioning settings |

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
- `lock_wifi_ssid` - Saved target Wi-Fi SSID
- `lock_wifi_password` - Saved target Wi-Fi password
- `lock_ap_ssid` - Saved fallback AP SSID
- `lock_ap_password` - Saved fallback AP password
- `lock_ap_broadcast_ssid` - Whether the AP SSID is visible

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
