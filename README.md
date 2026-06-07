# Darmi Mobile

**A Flutter-based mobile client for controlling ESP32 smart devices — part of the [Open Microlock](https://github.com/OpenMicrolock) ecosystem.**

Darmi Mobile lets you control **Smart Locks** and **Smart Lamps** powered by ESP32 over HTTP REST APIs with token-based authentication. It features a modern Material 3 dark theme, an intuitive setup wizard, real-time device control with slide-to-unlock gestures, and Wi-Fi provisioning for ESP32 devices.

---

## ✨ Features

- **Multi-Device Support** — Control both Smart Locks (lock/unlock with auto-lock timer) and Smart Lamps (on/off/toggle)
- **Setup Wizard** — 5-step guided flow to add devices: type selection → info → auth → test → save
- **Real-Time Control** — One-tap actions with live connection status badges
- **Slide-to-Unlock** — Touchscreen-friendly slide gesture for unlocking doors
- **Auto-Lock Timer** — Configurable auto-lock countdown (default 5s)
- **Device Management** — List, edit, delete, and reorder devices with swipe gestures
- **Wi-Fi Provisioning** — Configure ESP32 network settings (STA/AP modes) directly from the app
- **Dark Theme** — Modern Material 3 dark mode with green brand palette (amber accent for lamps)
- **Secure Storage** — Device credentials stored using `flutter_secure_storage` with encrypted SharedPreferences
- **Device Simulators** — Node.js-based ESP32 simulators for development without hardware

---

## 📱 Screens

| Screen | Description |
|---|---|
| **Splash** | Animated logo with auto-routing to onboarding or home |
| **Onboarding** | First-run feature cards for Smart Lock and Smart Lamp |
| **Setup Wizard** | 5-step device configuration (type → info → auth → test → save) |
| **Home / Control** | Device switcher, hero status card, primary action, slide-to-unlock, auto-lock timer |
| **Devices** | Device list with live status, context menu, swipe-to-delete |
| **Device Edit** | Edit device name, host, port, token, and type |
| **Settings** | Dark mode toggle, haptic feedback, active device quick config, about section |
| **Provisioning** | ESP32 Wi-Fi/AP network configuration |

---

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart) with Material 3 |
| **State / Persistence** | `flutter_secure_storage` (encrypted key-value) |
| **HTTP Client** | `http` package v1.2.2 |
| **Design System** | Custom Material 3 dark theme, centralized palette & spacing |
| **Platforms** | Android, iOS, Linux Desktop |
| **Simulators** | Node.js + Express v4.18.2 (ES modules) |
| **Linting** | `flutter_lints` v5.0.0 |
| **Testing** | `flutter_test`, `MockClient` |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** (stable channel, Dart SDK ^3.8.0)
- **Node.js 18+** (for device simulators)

### Installation

```bash
# Clone the repository
git clone https://github.com/OpenMicrolock/darmi-mobile.git
cd darmi-mobile

# Install Flutter dependencies
flutter pub get

# Run the app
flutter run
```

### Running Device Simulators

For development without physical ESP32 hardware, start the simulators:

```bash
# Terminal 1 — Smart Lock Simulator
cd simulator-lock
npm install
MICROLOCK_TOKEN=demo-token node server.js

# Terminal 2 — Smart Lamp Simulator
cd simulator-lamp
npm install
MICROLOCK_TOKEN=demo-token node server.js
```

Both simulators listen on `http://127.0.0.1:1212` by default (configurable via `PORT` env var).

---

## 🧪 Usage Guide

### First Run

1. Launch the app — the Splash screen appears with an animated logo
2. On first run, you're guided to the **Onboarding** screen
3. Tap **"Add First Device"** to enter the Setup Wizard

### Adding a Smart Lock

1. Select **Smart Lock** as device type
2. Enter a name (e.g. "Front Door") and IP address (e.g. `127.0.0.1`)
3. Port defaults to `1212`
4. Enter auth token: `demo-token`
5. Tap **Test Connection** — green badge confirms success
6. Review summary and **Save**

### Adding a Smart Lamp

1. In the wizard, select **Smart Lamp**
2. Follow the same steps as above

### Controlling Devices

- Use the **device switcher dropdown** in the AppBar to switch between devices
- **Smart Lock**: Tap the lock icon to trigger slide-to-unlock; tap again to lock
- **Smart Lamp**: Tap to toggle on/off
- Pull-to-refresh updates the device status

### Device Management

- Navigate to the **Devices** tab to see all saved devices
- Tap the **⋮** menu to edit, delete, or access Wi-Fi provisioning
- Swipe left on a device to delete

---

## 📁 Project Structure

```
lib/
├── main.dart                      # App entry point
├── branding.dart                  # App name & logo constants
├── api/
│   └── lock_api.dart              # REST API client (Lock, Lamp, Provisioning)
├── screens/
│   ├── splash_screen.dart         # Animated splash + route logic
│   ├── onboarding_screen.dart     # First-run onboarding
│   ├── setup_wizard.dart          # 5-step device configuration
│   ├── home_shell.dart            # Bottom nav scaffold
│   ├── control_screen.dart        # Device control interface
│   ├── devices_screen.dart        # Device list management
│   ├── device_edit_screen.dart    # Edit device parameters
│   ├── settings_screen.dart       # App preferences
│   └── provisioning_screen.dart   # ESP32 Wi-Fi provisioning
├── settings/
│   ├── settings_store.dart        # LockSettings model + persistence
│   └── lock_settings_sync_strategy.dart
├── theme/
│   ├── app_colors.dart            # Color palette
│   ├── app_spacing.dart           # Spacing & radius constants
│   └── app_theme.dart             # Material 3 ThemeData
└── widgets/
    ├── confirm_sheet.dart         # Bottom sheet confirmation
    ├── device_avatar.dart         # Device type avatar
    ├── empty_state.dart           # Empty state placeholder
    ├── hero_status_card.dart      # Status card with pulse animation
    ├── microlock_logo.dart        # Logo widget
    ├── slide_to_action.dart       # Slide gesture action
    ├── status_badge.dart          # Connection status badge
    └── step_indicator.dart        # Wizard step indicator

simulator-lock/                    # ESP32 Lock simulator (Node.js)
simulator-lamp/                    # ESP32 Lamp simulator (Node.js)
test/                              # Unit & widget tests
docs/                              # UI/UX design documentation
```

---

## 📡 API Reference

The ESP32 devices expose the following REST endpoints (token-authenticated via `X-Auth-Token` header):

### Smart Lock

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/` | Ping / health check |
| `POST` | `/lock` | Lock the device |
| `POST` | `/unlock` | Unlock the device |
| `POST` | `/status` | Get current lock state |
| `GET` | `/config` | Get Wi-Fi provisioning config |
| `POST` | `/config` | Update Wi-Fi provisioning config |

### Smart Lamp

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/` | Ping / health check |
| `POST` | `/on` | Turn lamp on |
| `POST` | `/off` | Turn lamp off |
| `POST` | `/toggle` | Toggle lamp state |
| `POST` | `/status` | Get current lamp state |
| `POST` | `/config/status` | Get provisioning config |
| `POST` | `/config` | Update provisioning config |

Default timeout: **5 seconds** per request.

---

## 🤝 Contributing

We welcome contributions from the community! Here's how to get started:

1. **Fork** the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. **Commit** your changes following [Conventional Commits](https://www.conventionalcommits.org/)
4. **Run tests**: `flutter test`
5. **Push** and open a **Pull Request**

### Code Style

- This project uses `flutter_lints` with the recommended rule set
- Run `dart analyze` before submitting PRs
- Follow existing patterns for widgets, screens, and API calls

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

- **Discussions**: [GitHub Discussions](https://github.com/OpenMicrolock/darmi-mobile/discussions)
## 🌐 Community

- **GitHub Organization**: [Open Microlock](https://github.com/OpenMicrolock)
- **Report Issues**: [GitHub Issues](https://github.com/OpenMicrolock/darmi-mobile/issues)

---

*Built with ❤️ by the Open Microlock Community*
