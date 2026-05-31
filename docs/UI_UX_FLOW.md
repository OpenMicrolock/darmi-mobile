# UI/UX Flow — Smart Device Controller (Lock + Lamp)

Berdasarkan **tambahan.md** — UX/UI Recommendation v2

---

## UX Principles

1. **One Primary Action Per Screen** — hanya tampilkan satu tombol aksi utama (yang mengubah state)
2. **Minimize Number of Taps** — akses aksi utama secepat mungkin
3. **Device Switching Without Navigation** — ganti device langsung dari Home via dropdown
4. **Hide Technical Details** (IP Address) — tampilkan nama device saja, IP disembunyikan
5. **Show Connection Status Clearly** — 🟢 🟡 🔴 ❌
6. **Consistent Material 3 Design**
7. **Mobile First Layout**
8. **Fast Access To Main Actions**

---

## Navigation Structure

```text
Startup
 │
 ├─ No Device
 │    └─ Setup Wizard
 │
 └─ Device Available
      └─ Home

Bottom Navigation
 ├─ Home
 ├─ Devices
 └─ Settings
```

### Bottom Navigation

```dart
NavigationBar(
  destinations: [
    NavigationDestination(icon: Icons.home_outlined,    label: 'Home'),
    NavigationDestination(icon: Icons.devices_outlined, label: 'Devices'),
    NavigationDestination(icon: Icons.settings_outlined, label: 'Settings'),
  ],
)
```

---

## Home Screen

Home selalu menampilkan **device aktif**.  
User dapat mengganti device melalui **dropdown** tanpa harus masuk ke halaman Devices.

### Device Switcher

````
┌─────────────────────────────┐
│ Front Door          ▼       │
└─────────────────────────────┘

Dropdown:
────────────────
🔒 Front Door          ← active
💡 Living Room
🔒 Garage
💡 Bedroom Lamp
────────────────
  ＋ Add new device
````

Dropdown berisi semua device tersimpan, dengan icon type di depan nama.  
Item terakhir "＋ Add new device" shortcut ke setup wizard.

---

### Home — Lock Device

#### State: Locked

````
┌─────────────────────────────────────────┐
│ Front Door                     ▼        │
├─────────────────────────────────────────┤
│                                         │
│           ┌─────────────────┐           │
│           │    🔒 LOCKED    │           │
│           │    Front Door   │           │
│           │    🟢 Active    │           │
│           │ Last update 14:32           │
│           └─────────────────┘           │
│                                         │
│           ┌─────────────────┐           │
│           │   🔓 UNLOCK     │← primary  │
│           └─────────────────┘           │
│                                         │
│           🔄 Refresh                    │
└─────────────────────────────────────────┘
````

#### State: Unlocked

````
┌─────────────────────────────────────────┐
│ Front Door                     ▼        │
├─────────────────────────────────────────┤
│                                         │
│           ┌─────────────────┐           │
│           │   🔓 UNLOCKED   │           │
│           │    Front Door   │           │
│           │    🟢 Active    │           │
│           │ Last update 14:32           │
│           └─────────────────┘           │
│                                         │
│           ┌─────────────────┐           │
│           │   🔒 LOCK       │← primary  │
│           └─────────────────┘           │
│                                         │
│           🔄 Refresh                    │
└─────────────────────────────────────────┘
````

> **One Primary Action**: Hanya satu tombol aksi utama — tombol yang **mengubah** state.  
> Tidak perlu dua tombol (Lock + Unlock) bersamaan.

---

### Home — Lamp Device

#### State: ON

````
┌─────────────────────────────────────────┐
│ Living Room                    ▼        │
├─────────────────────────────────────────┤
│                                         │
│           ┌─────────────────┐           │
│           │    💡 ON        │           │
│           │   Living Room   │           │
│           │   🟢 Active     │           │
│           │ Last update 14:32           │
│           └─────────────────┘           │
│                                         │
│           ┌─────────────────┐           │
│           │     OFF         │← primary  │
│           └─────────────────┘           │
│                                         │
│           🔄 Refresh                    │
└─────────────────────────────────────────┘
````

#### State: OFF

````
┌─────────────────────────────────────────┐
│ Living Room                    ▼        │
├─────────────────────────────────────────┤
│                                         │
│           ┌─────────────────┐           │
│           │    ⚫ OFF       │           │
│           │   Living Room   │           │
│           │   🟢 Active     │           │
│           │ Last update 14:32           │
│           └─────────────────┘           │
│                                         │
│           ┌─────────────────┐           │
│           │     ON          │← primary  │
│           └─────────────────┘           │
│                                         │
│           🔄 Refresh                    │
└─────────────────────────────────────────┘
````

---

## Connection States

Setiap device memiliki indikator status koneksi di status card:

| State | Indicator | Deskripsi |
|-------|-----------|-----------|
| **Active** | 🟢 Active | Device reachable, data valid |
| **Connecting** | 🟡 Connecting... | Request in progress |
| **Non Active** | 🔴 Non Active | Device not reachable / timeout |
| **Error** | ❌ *message* | Auth error / unexpected error |

---

## Setup Wizard

Setup dipisah menjadi beberapa step — lebih mudah dipahami non-teknis.

### Step 1: Select Device Type

````
┌─ Set Up Device ───────────────────────────┐
│                                           │
│  Pilih tipe device:                        │
│                                           │
│  ┌──────────────────────────────────┐     │
│  │          🔒 Smart Lock           │     │
│  └──────────────────────────────────┘     │
│                                           │
│  ┌──────────────────────────────────┐     │
│  │          💡 Smart Lamp           │     │
│  └──────────────────────────────────┘     │
│                                           │
│              [ Next → ]                   │
└───────────────────────────────────────────┘
````

### Step 2: Device Information

````
┌─ Device Information ──────────────────────┐
│                                           │
│  Device Name                               │
│  ┌────────────────────────────────────┐   │
│  │ Front Door                        │   │
│  └────────────────────────────────────┘   │
│                                           │
│  IP Address                                │
│  ┌────────────────────────────────────┐   │
│  │ 192.168.4.1                       │   │
│  └────────────────────────────────────┘   │
│                                           │
│         [ ← Back ]    [ Next → ]          │
└───────────────────────────────────────────┘
````

### Step 3: Authentication

````
┌─ Authentication ──────────────────────────┐
│                                           │
│  Token                                     │
│  ┌────────────────────────────────┬───┐   │
│  │ ****************              │ 👁 │   │
│  └────────────────────────────────┴───┘   │
│                                           │
│         [ ← Back ]    [ Next → ]          │
└───────────────────────────────────────────┘
````

### Step 4: Test Connection

````
┌─ Test Connection ─────────────────────────┐
│                                           │
│  ┌──────────────────────────────────┐     │
│  │       🔍 Test Connection         │     │
│  └──────────────────────────────────┘     │
│                                           │
│  Result:                                   │
│  🟢 Device Connected                      │
│  atau                                      │
│  🔴 Connection Failed                     │
│                                           │
│         [ ← Back ]    [ Next → ]          │
└───────────────────────────────────────────┘
````

### Step 5: Save Device

````
┌─ Save Device ─────────────────────────────┐
│                                           │
│  Ringkasan:                                │
│  🔒 Smart Lock                            │
│  Front Door · 192.168.4.1                 │
│                                           │
│  ┌──────────────────────────────────┐     │
│  │         ✅ Save Device           │     │
│  └──────────────────────────────────┘     │
└───────────────────────────────────────────┘
````

---

## Devices Screen

Manajemen seluruh device. Menampilkan status terakhir setiap device.

````
┌─ Devices ─────────────────────────────────┐
│                                           │
│  ┌──────────────────────────────────┐     │
│  │       ＋ Add Device              │     │
│  └──────────────────────────────────┘     │
│                                           │
│  ┌─────────────────────────────────────┐  │
│  │ 🔒 Front Door              🟢      │  │
│  │    Active • Locked          ⋮      │  │
│  └─────────────────────────────────────┘  │
│                                           │
│  ┌─────────────────────────────────────┐  │
│  │ 💡 Living Room              🟢     │  │
│  │    Active • ON               ⋮      │  │
│  └─────────────────────────────────────┘  │
│                                           │
│  ┌─────────────────────────────────────┐  │
│  │ 🔒 Garage                   🔴     │  │
│  │    Non Active                ⋮      │  │
│  └─────────────────────────────────────┘  │
└───────────────────────────────────────────┘
````

### Device Context Menu

````
Tap ⋮ :
┌─────────────┐
│ Edit        │
│ Delete      │
└─────────────┘
````

---

## Settings Screen

Settings hanya untuk aplikasi, **bukan** untuk edit device.

````
┌─ Settings ────────────────────────────────┐
│                                           │
│  Theme                                     │
│  ┌─────────────────────────────────────┐  │
│  │ 🌙 Dark mode               [Switch] │  │
│  └─────────────────────────────────────┘  │
│                                           │
│  ┌─────────────────────────────────────┐  │
│  │ ℹ️  About                           │  │
│  │    Version 1.0.0                   │  │
│  └─────────────────────────────────────┘  │
└───────────────────────────────────────────┘
````

> Edit device dilakukan dari **Devices screen** → tap ⋮ → Edit.  
> Atau dari **Home screen dropdown** → pilih device → otomatis aktif.

---

## Recommended Material 3 Components

```dart
NavigationBar      // Bottom navigation
FilledButton       // Primary action (UNLOCK, LOCK, ON, OFF)
OutlinedButton     // Secondary action (Refresh)
Card               // Status card
ListTile           // Device list items
DropdownMenu       // Device switcher di Home
SegmentedButton    // Device type selector di wizard
Switch             // Dark mode toggle
SnackBar           // Feedback notifications
Stepper / custom   // Setup wizard multi-step
```

---

## Perubahan Files

| File | Change |
|------|--------|
| `lib/api/lock_api.dart` | ✅ `DeviceType`, `DeviceLampState`, `turnOn/Off/toggle/lampStatus` |
| `lib/settings/settings_store.dart` | ✅ `deviceType` field |
| `lib/main.dart` | 🔧 Bootstrap → wizard flow instead of single form |
| `lib/screens/home_screen.dart` | 🔧 Add device switcher dropdown, one primary action button, connection status |
| `lib/screens/devices_screen.dart` | 🔧 (new?) Extract from home_screen, show live status per device |
| `lib/screens/settings_screen.dart` | 🔧 App settings (theme, about) — remove device edit |
| `lib/screens/setup_wizard.dart` | 🔧 (new) Multi-step wizard (type → info → auth → test → save) |
| `lib/widgets/connection_status.dart` | 🔧 (new) Reusable status indicator widget |
| `lib/widgets/device_switcher.dart` | 🔧 (new) Dropdown for switching active device |
