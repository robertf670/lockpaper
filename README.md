# Lockpaper - Private Notes App

A minimalist, **offline-first** notes application built with Flutter. It keeps all data on-device, protects it with biometrics/PIN, and aims for a single one-time purchase model with **no ads or trackers**.

## ✨ Guiding Principles

1.  **Privacy-by-design:** No network access required for core features.
2.  **Keep it small:** Fast install (<15 MB APK) and low memory usage.
3.  **Material 3 polish:** Respect platform design guidelines; smooth 120 Hz animations.
4.  **Accessibility first:** Support for large text scaling, screen-reader labels, and high-contrast modes.
5.  **Sustainable indie:** One-time purchase model, no vendor lock-in.

## 🚀 Features (v1.0)

*   Create, edit, delete, and list notes.
*   Secure access with Local Authentication (biometric + PIN fallback).
*   Encrypted on-device storage using Drift + SQLCipher.
*   Light/dark themes with dynamic color seeding (Material You).
*   Smooth animated page transitions and FAB hero animation.

## 🔒 Privacy & Security

*   All note data is stored **only** on your device.
*   Data is encrypted at rest using SQLCipher (AES-256).
*   The app requires no network permissions for core functionality.
*   No trackers, ads, or third-party analytics are included.
*   Please review the [Privacy Policy](https://robertf670.github.io/lockpaper/privacy_policy.md) for full details.

## 🛠️ Tech Stack

*   **UI Framework:** Flutter 3.29+
*   **State Management:** Riverpod 2.x
*   **Routing:** GoRouter 14
*   **Database:** Drift 2.x + sqlcipher_flutter_libs
*   **Security:** `local_auth` + `flutter_secure_storage` + `crypt`
*   **Theming:** FlexColorScheme 7+
*   **Code Generation:** `build_runner` / `drift_dev`
*   **CI/CD:** GitHub Actions

## 🏗️ Architecture

This project follows a **Clean Architecture Lite** approach:

```text
/lib
 ├─ main.dart            # App entry point, theme, router setup
 ├─ core/                # Shared modules (theme, router, security, utils)
 │   ├─ app_theme.dart
 │   ├─ app_router.dart
 │   └─ ...
 └─ features/            # Feature-specific modules (e.g., notes, settings)
     └─ notes/
         ├─ data/        # Data sources (Drift database, DAOs)
         ├─ application/ # Business logic (Riverpod providers/notifiers)
         └─ presentation/# UI (Widgets, Screens)
     └─ settings/
         └─ ...
```

*   Features are organized vertically within `features/`.
*   Shared code resides horizontally in `core/`.

## ⚙️ Building from Source

This repository contains the source code for Lockpaper. While the code is visible, it is provided under the terms specified in the License section below.

### Environment Setup

1.  **Install Flutter:** Ensure you have Flutter SDK `3.29` or later.
    ```bash
    flutter upgrade
    ```
2.  **Install SQLCipher:** (Required for running/testing database encryption locally)
    ```bash
    # macOS
    brew install sqlcipher

    # Linux (Debian/Ubuntu)
    sudo apt-get update && sudo apt-get install -y sqlcipher libsqlite3-dev 

    # Windows: Download precompiled binary or build from source (refer to SQLCipher docs)
    ```
3.  **Get Dependencies:**
    ```bash
    flutter pub get
    ```

### Running

1.  **Code Generation:** (Required if modifying database or Riverpod providers)
    ```bash
    dart run build_runner watch --delete-conflicting-outputs
    ```
2.  **Run the App:**
    ```bash
    flutter run
    ```

## 🤝 Contributions

Contributions are not being accepted for this project at this time.

## 📧 Contact & Support

For questions or support inquiries, please contact: ixrqq@tuta.io

Please note that support response times may vary.

## 📄 License

Copyright © 2025 Robert Fitzsimons

All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software") for viewing and
evaluation purposes only. No permission is granted to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software, or to
permit persons to whom the Software is furnished to do so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
