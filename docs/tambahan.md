# Smart Device Controller App

## UX/UI Recommendation v2

---

# Overview

Aplikasi digunakan untuk mengontrol beberapa device IoT:

* 🔒 Smart Lock
* 💡 Smart Lamp

Tujuan UX:

* Akses aksi utama secepat mungkin
* Mengurangi jumlah tap
* Mudah dipahami pengguna non-teknis
* Mengikuti pola Smart Home modern (Google Home, Tuya, SmartThings)

---

# Navigation Structure

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

---

# Home Screen

Home selalu menampilkan device aktif.

User dapat mengganti device melalui dropdown tanpa harus masuk ke halaman Devices.

## Layout

```text
┌─────────────────────────────┐
│ Front Door ▼                │
└─────────────────────────────┘

┌─────────────────────────────┐
│ 🔒 LOCKED                   │
│                             │
│ Front Door                  │
│ 🟢 Active                   │
│ Last update 14:32           │
└─────────────────────────────┘

┌─────────────────────────────┐
│        🔓 UNLOCK            │
└─────────────────────────────┘
```

---

# Lock Device State

## Locked

```text
┌─────────────────────────────┐
│ 🔒 LOCKED                   │
│ Front Door                  │
│ 🟢 Active                   │
└─────────────────────────────┘

┌─────────────────────────────┐
│        🔓 UNLOCK            │
└─────────────────────────────┘
```

## Unlocked

```text
┌─────────────────────────────┐
│ 🔓 UNLOCKED                 │
│ Front Door                  │
│ 🟢 Active                   │
└─────────────────────────────┘

┌─────────────────────────────┐
│         🔒 LOCK             │
└─────────────────────────────┘
```

---

# Lamp Device State

## Lamp ON

```text
┌─────────────────────────────┐
│ 💡 ON                       │
│ Living Room                 │
│ 🟢 Active                   │
└─────────────────────────────┘

┌─────────────────────────────┐
│           OFF               │
└─────────────────────────────┘
```

## Lamp OFF

```text
┌─────────────────────────────┐
│ ⚫ OFF                       │
│ Living Room                 │
│ 🟢 Active                   │
└─────────────────────────────┘

┌─────────────────────────────┐
│            ON               │
└─────────────────────────────┘
```

---

# Device Switcher

Mengganti device langsung dari Home.

```text
┌─────────────────────────────┐
│ Front Door ▼                │
└─────────────────────────────┘

Dropdown:

Front Door
Living Room
Garage Lock
Bedroom Lamp
```

---

# Connection States

## Active

```text
🟢 Active
```

## Connecting

```text
🟡 Connecting...
```

## Non Active

```text
🔴 Non Active
```

## Error

```text
❌ Device Not Reachable
```

---

# Devices Screen

Berfungsi sebagai manajemen seluruh device.

```text
┌─────────────────────────────┐
│ + Add Device                │
└─────────────────────────────┘

┌─────────────────────────────┐
│ 🔒 Front Door              │
│ Active • Locked            │
│                       ⋮     │
└─────────────────────────────┘

┌─────────────────────────────┐
│ 💡 Living Room             │
│ Active • ON                │
│                       ⋮     │
└─────────────────────────────┘

┌─────────────────────────────┐
│ 🔒 Garage                  │
│ Non Active                    │
│                       ⋮     │
└─────────────────────────────┘
```

---

# Device Context Menu

```text
┌─────────────┐
│ Edit        │
│ Delete      │
└─────────────┘
```

---

# Setup Wizard

## Step 1

Select Device Type

```text
🔒 Smart Lock

💡 Smart Lamp
```

---

## Step 2

Device Information

```text
Device Name
[_____________]

IP Address
[_____________]
```

---

## Step 3

Authentication

```text
Token
[*************]
```

---

## Step 4

Test Connection

```text
┌───────────────────────┐
│ Test Connection       │
└───────────────────────┘
```

Result:

```text
🟢 Device Connected
```

atau

```text
🔴 Connection Failed
```

---

## Step 5

Save Device

```text
┌───────────────────────┐
│ Save Device           │
└───────────────────────┘
```

---

# Settings Screen

Settings hanya untuk aplikasi.

```text
Settings

• Theme
• Notifications
• About
• Version
```

Tidak digunakan untuk edit device.

---

# Recommended Material 3 Components

```dart
NavigationBar
FilledButton
OutlinedButton
FilledCard
ListTile
DropdownMenu
Switch
SnackBar
```

---

# UX Principles

1. One Primary Action Per Screen
2. Minimize Number of Taps
3. Device Switching Without Navigation
4. Hide Technical Details (IP Address)
5. Show Connection Status Clearly
6. Consistent Material 3 Design
7. Mobile First Layout
8. Fast Access To Main Actions

```
```
