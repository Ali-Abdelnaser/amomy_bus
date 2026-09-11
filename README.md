# Amomy Bus — Passenger & Admin Application

Production-ready Flutter application for the **Amomy Bus** scheduled transportation system. This repository contains the cross-platform (Android & iOS) application used by passengers to book and manage scheduled bus trips using internal points, and includes a protected internal administrative portal for fleet and financial operators.

---

## 1. Project Stack

- **Framework**: Flutter 3.x / Dart 3
- **Platforms**: Android & iOS
- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc) + [bloc](https://pub.dev/packages/bloc) + [equatable](https://pub.dev/packages/equatable)
- **Dependency Injection**: [get_it](https://pub.dev/packages/get_it) + [injectable](https://pub.dev/packages/injectable)
- **Navigation & Routing**: [go_router](https://pub.dev/packages/go_router)
- **Networking**: [dio](https://pub.dev/packages/dio) + [pretty_dio_logger](https://pub.dev/packages/pretty_dio_logger)
- **Backend Infrastructure**: [supabase_flutter](https://pub.dev/packages/supabase_flutter) (PostgreSQL, Auth, Storage, Realtime)
- **Push Notifications**: [firebase_core](https://pub.dev/packages/firebase_core) + [firebase_messaging](https://pub.dev/packages/firebase_messaging)
- **Local Storage**: [shared_preferences](https://pub.dev/packages/shared_preferences) & [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
- **Loading UX**: [skeletonizer](https://pub.dev/packages/skeletonizer)
- **Icons**: [phosphor_icons](https://pub.dev/packages/phosphor_icons) (Duotone)
- **Animations**: [flutter_animate](https://pub.dev/packages/flutter_animate)
- **Localization**: Native Flutter L10n (`intl`, ARB files) for Arabic (RTL) and English (LTR)

---

## 2. Architecture

The application is structured using **Clean Architecture** combined with a **Feature-First** modular organization:

```
lib/
├── app/          # App setup, bootstrap, DI, and GoRouter routing
├── core/         # Cross-cutting concerns: config, theme, network, errors, widgets
├── features/     # Feature modules (splash, auth, trips, seats, booking, wallet, admin)
├── l10n/         # Localization ARB files and generated translation classes
└── main.dart     # Lean application entry point
```

For in-depth architectural details, refer to:
- [01 — System Architecture](docs/01_ARCHITECTURE.md)
- [02 — Folder Structure](docs/02_FOLDER_STRUCTURE.md)
- [03 — Coding Standards](docs/03_CODING_STANDARDS.md)
- [04 — Business Rules](docs/04_BUSINESS_RULES.md)

---

## 3. Getting Started & Setup

### Prerequisites
- Flutter SDK `^3.12.x` or later
- Android Studio / Xcode configured for Android & iOS builds
- Java 17+ / CocoaPods

### Installation
1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd amomy_bus
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate dependency injection and serialization files:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Generate localization files:
   ```bash
   flutter gen-l10n
   ```

5. Run static analysis & tests:
   ```bash
   flutter analyze
   flutter test
   ```

6. Run the application:
   ```bash
   flutter run
   ```

---

## 4. Code Generation & Localization

### Code Generation (`build_runner`)
Run code generation whenever Injectable dependencies, Freezed entities, or JsonSerializable models are modified:
```bash
# One-shot build
dart run build_runner build --delete-conflicting-outputs

# Continuous watch during active development
dart run build_runner watch --delete-conflicting-outputs
```

### Localization (`l10n`)
Translations are located in `lib/l10n/`:
- `lib/l10n/app_en.arb` (English — default template)
- `lib/l10n/app_ar.arb` (Arabic — RTL support)

Whenever ARB files are updated, run:
```bash
flutter gen-l10n
```
Access translations in widgets via the context extension:
```dart
Text(context.l10n.appName)
```

---

## 5. Environment Configuration

The application supports multiple deployment environments (`dev`, `staging`, `prod`) configured in `AppConfig`:

```bash
# Example running with environment flags
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

If credentials are not supplied, the app gracefully falls back to offline/mock mode for design and UI development without throwing startup exceptions.

---

## 6. Project Documentation Index

Comprehensive documentation is available in the [`docs/`](docs/) directory:

- [00 — Project Overview](docs/00_PROJECT_OVERVIEW.md)
- [01 — System Architecture](docs/01_ARCHITECTURE.md)
- [02 — Folder Structure](docs/02_FOLDER_STRUCTURE.md)
- [03 — Coding Standards](docs/03_CODING_STANDARDS.md)
- [04 — Business Rules](docs/04_BUSINESS_RULES.md)
- [05 — Database Entity Plan](docs/05_DATABASE_PLAN.md)
- [06 — Seven-Day Delivery Roadmap](docs/06_SEVEN_DAY_TIMELINE.md)
- [07 — Backend Architecture Plan](docs/07_BACKEND_PLAN.md)
- [08 — Security & Privacy Plan](docs/08_SECURITY_PLAN.md)
- [09 — Testing & QA Plan](docs/09_TESTING_PLAN.md)
- [10 — Architecture Decision Records](docs/10_DECISIONS.md)
- [11 — Points Ledger & Expiration Engine](docs/11_POINTS_ENGINE.md)
- [12 — Row Level Security Matrix](docs/12_RLS_MATRIX.md)
- [13 — Design System Specification](docs/13_DESIGN_SYSTEM.md)
- [14 — Authentication Setup & Platform Configuration](docs/14_AUTH_SETUP.md)

---

## 7. Current Phase Status

- **Phase**: **Day 2B — Authentication, Session Persistence, Auth Guards, Google Sign-In & Recovery**
- **Status**: **COMPLETE & VERIFIED**
- **Next Phase**: Day 3A — Wallet & Points Engine Integration (Recharge, Top-up Requests, Ledger).

