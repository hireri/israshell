# 🐚 israshell

**israshell** is a high-performance, modular Wayland shell designed for users who demand both aesthetic perfection and extreme utility. Built with [Quickshell](https://github.com/outfoxxed/quickshell) and meticulously optimized for **Hyprland** on **Arch-based Linux distributions**, it bridges the gap between a minimal compositor and a full desktop environment.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Wayland-orange.svg)
![Distro](https://img.shields.io/badge/optimized_for-Arch_Linux-1793d1.svg?logo=arch-linux)
![Compositor](https://img.shields.io/badge/compositor-Hyprland-brightgreen.svg)

---

## ✨ Showcase
https://github.com/user-attachments/assets/a8801fbd-5926-4c2e-8c5f-b0d1f30682bb

---

## 🌟 Beyond the Basics: Features

### 🚀 The Intelligence Launcher
While most shells provide a simple application runner, **israshell** includes a "Swiss-Army" toolkit that eliminates the need for external tools:

- **🎨 Color Intelligence**: Instant HEX/RGB/HSL conversion and visualization. Input any color format, see a live preview, and copy the normalized result.
- **🕒 Temporal Logic**: 
  - **Unix Converter**: Paste a timestamp to see human-readable dates, ISO strings, and relative time (e.g., "3 hours ago").
  - **Countdown Engine**: Natural language queries like `days until christmas` or `time since 2023-01-01` provide instant delta calculations.
- **🌐 Global Utility**: 
  - **Dictionary & Whois**: Instant word definitions and domain/IP intelligence.
  - **Translation with TTS**: Multi-language support with high-quality text-to-speech.
- **📋 Persistent Clipboard**: A unified manager using `clipvault` that tracks text and image history.

### ⚡ Power Management & System Control
- **Quick Settings**: A ChromeOS-inspired panel for Wi-Fi, Bluetooth, and Audio.
- **Eye Care & Sleep**: Integrated toggles for `hyprsunset` (Night Light) and `hypridle` (Caffeine mode) with state persistence.
- **Media Hub**: Unified media controls that track active players and provide visual feedback.

### 🔔 Modular Notification Server
A robust implementation of the Desktop Notification Specification:
- **Smart Grouping**: Notifications are automatically organized by application.
- **Persistence**: A centralized history view ensures you never miss a critical alert.
- **Material Design**: Modern, cohesive styling that follows the Material 3 specification.

### 🎨 Architected for Customization
- **MD3 Color System**: A full implementation of Material Design 3 in QML, ensuring perfect visual harmony.
- **Hot-Reloading JSON**: No need to recompile or restart. Edit `config.json` and watch your shell transform instantly.
- **Arch Optimized**: Lightweight and designed to leverage the Arch Linux ecosystem (Pipewire, NetworkManager, Bluez).

---

## 🛠️ Installation & Setup

### 1. Requirements
Ensure you are on an Arch-based system with the following installed:
```bash
sudo pacman -S quickshell hyprland pipewire bluez networkmanager hypridle
# full feature set
sudo pacman -S whois kakasi mpv espeak-ng xdg-utils rdap
```

### 2. Configuration
Initialize your settings:
```bash
cp config.json.example config.json
```

### 3. Execution
Launch the shell:
```bash
qs -n
```

---

## 📦 Detailed Dependency Matrix

| Component | Package | Role |
| :--- | :--- | :--- |
| **Shell Core** | `quickshell`, `hyprland` | Runtime & WM |
| **Audio/Comm** | `pipewire`, `bluez`, `networkmanager` | Connectivity |
| **Productivity**| `clipvault`, `whois`, `kakasi` `rdap` | Widgets |
| **Multimedia**  | `gtts-cli`, `mpv`, `espeak-ng` | TTS Engine |
| **System**      | `hyprsunset`, `hypridle`, `systemd` | Control |
