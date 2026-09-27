# Mouse Clicker for macOS

[简体中文](README.md) | [English](README.en.md)

A lightweight native auto clicker built with SwiftUI and AppKit. Requires macOS 13 or later and has no third-party dependencies. The app interface is currently in Simplified Chinese.

## Download and install

Download `MouseClicker-1.0.0-universal.dmg` from [Releases](https://github.com/Ryan-H-S-Z/mouse-clicker/releases/latest). Open the disk image and drag **鼠标连点器.app** to **Applications**. The Universal app supports both Apple Silicon and Intel Macs. No source code, Xcode, or other developer tools are required.

This release is **ad-hoc signed and has not been signed with an Apple Developer ID or notarized**. macOS may block the first launch after downloading. If you trust this project, follow the **Open Anyway** instructions in **System Settings → Privacy & Security** after attempting to open the app. Packaging an app as a DMG does not remove macOS security checks or the need for Accessibility permission.

Each release includes `SHA256SUMS.txt`. To verify the download, run this in the directory containing both files:

```sh
shasum -a 256 -c SHA256SUMS.txt
```

## Use

1. Launch **鼠标连点器** from Applications.
2. Click **前往授权** (Grant permission) and enable the app under **System Settings → Privacy & Security → Accessibility**. If it is missing from the list, add the installed `.app` using the plus button. The permission status refreshes automatically; restart the app if macOS requests it.
3. Choose the left or right mouse button, an interval from **20 to 3,600,000 milliseconds**, and either a fixed click count or **无限** (Unlimited).
4. Click **开始连点** (Start). Move the pointer to your target during the three-second countdown. Each click follows the pointer's current position, including across multiple displays.
5. Press **Control + Option + Space** to start or stop globally, or **Esc** to stop. The menu bar also provides a stop command.

The app refuses to start if its global shortcut cannot be registered. Closing the window, quitting, system sleep, or revoking Accessibility permission stops clicking. After closing the window, you can reopen it from the menu bar or start another session with the global shortcut.

The counter reports mouse down/up pairs sent, not clicks confirmed by the target app. Timing depends on system load and the target application's behavior. Each event pair uses a click-state value of 1.

## Build from source

Install Apple's Command Line Tools, then double-click `build.command` or run:

```sh
./build.command
```

The default output is `~/Applications/鼠标连点器.app`. To choose another output, pass a full `.app` path as the first argument. The script compiles arm64 and x86_64 binaries, combines them into a Universal binary, and applies and verifies an ad-hoc signature.

Avoid building the app inside a cloud-synced directory: file-provider metadata can interfere with signature verification. After rebuilding or moving the app, you may need to remove its old Accessibility entry and add it again. Grant permission at the final installation location.

## Package a DMG

```sh
./package-dmg.command
```

This builds the Universal app in a temporary directory, verifies its signature, creates and verifies a compressed disk image with an Applications shortcut and installation instructions, and writes the DMG and SHA-256 checksum file to `dist/`. The version comes from `Info.plist`.
