# 02 — Folder Structure & Modular Organization

## 1. Project Root Directory
```
amomy_bus/
├── android/                   # Native Android configuration
├── ios/                       # Native iOS configuration
├── docs/                      # Architectural & specification documentation
├── lib/                       # Application source code
├── test/                      # Unit, widget, and integration tests
├── l10n.yaml                  # Flutter localization tool configuration
├── pubspec.yaml               # Project dependencies and metadata
└── analysis_options.yaml      # Static analysis & lint rules
```

---

## 2. Source Code (`lib/`) Breakdown

```
lib/
├── app/
│   ├── app.dart                   # MaterialApp.router configuration
│   ├── bootstrap.dart             # Zone initialization, DI, and startup hooks
│   ├── router/
│   │   ├── app_router.dart        # GoRouter definition with route guards
│   │   ├── route_names.dart       # Route identifier constants
│   │   └── route_paths.dart       # URL-like path definitions
│   └── di/
│       ├── injection.dart         # GetIt initialization entrypoint
│       ├── register_module.dart   # Third-party module registrations
│       └── injection.config.dart  # Generated dependency graph
│
├── core/
│   ├── config/
│   │   ├── app_config.dart        # Dynamic environment configuration
│   │   └── environment.dart       # Environment enum (dev, staging, prod)
│   ├── constants/
│   │   ├── api_constants.dart     # Endpoints, headers, and API paths
│   │   ├── app_constants.dart     # System durations and general constants
│   │   └── storage_keys.dart      # Preferences and secure storage keys
│   ├── error/
│   │   ├── error_handler.dart     # Centralized exception-to-failure mapper
│   │   ├── exceptions.dart        # Data-layer typed exceptions
│   │   └── failures.dart          # Domain-level failure definitions
│   ├── extensions/
│   │   └── context_extensions.dart# BuildContext helper extensions
│   ├── localization/
│   │   └── localization_helpers.dart# RTL/LTR and locale helper accessors
│   ├── network/
│   │   ├── dio_client.dart        # Configured Dio instance with logging
│   │   ├── network_info.dart      # Connectivity contract and checker
│   │   └── interceptors/
│   │       └── auth_interceptor.dart # JWT token injection interceptor
│   ├── services/
│   │   ├── connectivity_service.dart # Network connectivity monitor
│   │   ├── secure_storage_service.dart # Keychain / Keystore storage wrapper
│   │   └── storage_service.dart   # Key-value preferences wrapper
│   ├── theme/
│   │   ├── app_colors.dart        # Theme colors and bus seat status tokens
│   │   ├── app_radius.dart        # Border radius tokens
│   │   ├── app_spacing.dart       # Spacing and margin tokens
│   │   ├── app_text_styles.dart   # Typography scale
│   │   └── app_theme.dart         # Material 3 light/dark ThemeData
│   ├── typedefs/
│   │   └── typedefs.dart          # Result monad and common type definitions
│   ├── utils/
│   │   └── app_bloc_observer.dart # Global state logger for BLoC
│   └── widgets/
│       ├── app_button.dart        # Reusable button with states and variants
│       ├── app_empty_view.dart    # Standard empty state visual placeholder
│       ├── app_error_view.dart    # Standard error view with retry action
│       ├── app_loading.dart       # Adaptive loading spinner
│       └── app_skeleton.dart      # Standard Skeletonizer shimmer wrapper
│
├── features/
│   └── splash/                    # Scaffolded initial feature
│       ├── data/
│       │   ├── datasources/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/
│           ├── bloc/
│           └── pages/
│
├── l10n/
│   ├── app_ar.arb                 # Arabic translations
│   ├── app_en.arb                 # English translations
│   └── app_localizations*.dart    # Generated localization classes
│
└── main.dart                      # Lean application entrypoint
```

---

## 3. Planned Modular Features
Future features follow the identical Clean Architecture structure (`data/`, `domain/`, `presentation/`):

- `features/auth/` — Authentication, registration, OTP, role loading, session persistence.
- `features/profile/` — Passenger profile, settings, locale toggle, theme toggle.
- `features/trips/` — Daily trip catalog, schedule browsing, route information.
- `features/seats/` — Interactive 2D bus seat layout, atomic seat locking/holds.
- `features/booking/` — Booking confirmation, reservation lifecycle, QR code pass.
- `features/wallet/` — Cash & Subscription points balances, top-up requests, receipt uploads.
- `features/subscriptions/` — Monthly subscription packages, renewal, NFC card eligibility.
- `features/tracking/` — Live bus GPS tracking during active booking window.
- `features/notifications/` — FCM push notification handling and inbox history.
- `features/admin/` — Protected dashboard: topup screenshot verification, manual point grants, fleet audits.
