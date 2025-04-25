# Private Notes App (Development)

A minimalist, **offline-first** notes application built with Flutter. It keeps all data on-device, protects it with biometrics/PIN, and aims for a single one-time purchase model with **no ads or trackers**.

> **Note:** This is the development repository. For the full development plan, see [`plan.md`](plan.md).

## ✨ Guiding Principles

1.  **Privacy-by-design:** No network access required for core features.
2.  **Keep it small:** Fast install (<15 MB APK) and low memory usage.
3.  **Material 3 polish:** Respect platform design guidelines; smooth 120 Hz animations.
4.  **Accessibility first:** Support for large text scaling, screen-reader labels, and high-contrast modes.
5.  **Sustainable indie:** One-time purchase model, no vendor lock-in.

## 🚀 Features (MVP v1.0)

*   Create, edit, delete, and list notes.
*   Secure access with Local Authentication (biometric + PIN fallback).
*   Encrypted on-device storage using Drift + SQLCipher.
*   Light/dark themes with dynamic color seeding (Material You).
*   In-app purchase for unlocking full features (non-consumable).
*   Smooth animated page transitions and FAB hero animation.

_(See [`plan.md`](plan.md) for post-launch and long-term feature goals)._

## 🛠️ Tech Stack

*   **UI Framework:** Flutter 3.29+ / Material 3
*   **State Management:** Riverpod 2.x
*   **Routing:** GoRouter 12
*   **Database:** Drift 2.x + sqflite_sqlcipher (for encrypted storage)
*   **Security:** `local_auth` + `flutter_secure_storage`
*   **Theming:** FlexColorScheme 9
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
 └─ features/            # Feature-specific modules (e.g., notes)
     └─ notes/
         ├─ data/        # Data sources (Drift database, DAOs)
         ├─ domain/      # Interfaces (Repositories) & Entities
         ├─ application/ # Business logic (Riverpod providers/controllers)
         └─ presentation/# UI (Widgets, Screens)
```

*   Features are organized vertically within `features/`.
*   Shared code resides horizontally in `core/`.

## ⚙️ Environment Setup

1.  **Install Flutter:** Ensure you have Flutter SDK `3.29` or later.
    ```bash
    flutter upgrade
    ```
2.  **Enable Impeller:** (Recommended for performance)
    ```bash
    flutter config --enable-impeller
    # flutter config --enable-ios # If targeting iOS
    ```
3.  **Install SQLCipher:** (Required for running/testing database encryption locally, especially on macOS)
    ```bash
    # macOS
    brew install sqlcipher

    # Other platforms: Refer to SQLCipher documentation
    ```
4.  **Get Dependencies:**
    ```bash
    dart pub get
    ```

## ▶️ Development Workflow

1.  **Run Build Runner:** Watch for code generation changes (needed for Drift, Riverpod generators, etc.).
    ```bash
    dart run build_runner watch --delete-conflicting-outputs
    ```
2.  **Run the App:** Use standard Flutter run commands. Hot reload should work.
    ```bash
    flutter run
    ```
3.  **Run Tests:**
    *   Widget Tests: `flutter test test/widget/`
    *   Unit Tests: `flutter test test/unit/` (or wherever they are placed)
    *   Integration Tests: `flutter test integration_test/`
    *   All tests: `flutter test`
4.  **Check Code Quality:**
    ```bash
    dart analyze
    ```

## 🧪 Testing

*   **Unit Tests:** Located in `test/` (target Repositories, Services).
*   **Widget Tests:** Located in `test/widget/` (target UI states, using golden files potentially).
*   **Integration/E2E Tests:** Located in `integration_test/` (target full user flows like install, unlock, CRUD operations). Run using `flutter test integration_test`.

## 🌳 Git Flow

```text
main        # Corresponds to production store builds
  ↑ (Merge)
develop     # Main development branch, features merged here
  ↑ (PR)
feature/*   # Individual feature branches
```

Commit messages should follow conventional commit standards if possible.

## 📄 License

_(Specify your license here, e.g., MIT, Apache 2.0, or proprietary)_
