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
│   ├── auth/                      # Authentication, registration, OTP, Google sign-in
│   ├── booking/                   # Seat selection, 28-seat layout, atomic holds, review, QR ticket
│   ├── home/                      # Passenger Home Hub, announcements, today hub, mini-map
│   ├── onboarding/                # Onboarding carousel & introduction screens
│   ├── profile/                   # Passenger profile, settings, locale & theme toggles
│   ├── shell/                     # Persistent floating bottom navigation bar
│   ├── splash/                    # Two-tier launch splash
│   ├── topup/                     # Points recharge flow, payment methods, receipt upload, resubmission
│   ├── tracking/                  # Live Google Maps bus tracking, road polylines, ETA engine
│   ├── trips/                     # My Trips, booking history, seat change, cancellation
│   └── wallet/                    # Points wallet, balance cards, double-entry ledger history
│
├── l10n/
│   ├── app_ar.arb                 # Arabic translations (RTL)
│   ├── app_en.arb                 # English translations (LTR)
│   └── app_localizations*.dart    # Generated localization classes
│
└── main.dart                      # Lean application entrypoint
```

---

## 3. Implemented Feature Modules
All features follow the identical Clean Architecture structure (`data/`, `domain/`, `presentation/`):

- `features/auth/` — Authentication, registration, OTP, Google Sign-in, Complete Profile Guard, Password Reset.
- `features/booking/` — Interactive 28-seat physical layout, direction and stop selectors, dynamic fare zone calculation, 5-minute atomic holds, review card, and QR ticket generation.
- `features/home/` — Passenger home hub, active trip banner, announcements carousel, today's schedule, and live mini-map.
- `features/profile/` — Profile details, language switch (AR/EN), theme toggle, privacy, and terms.
- `features/topup/` — Multi-step manual point top-up (Vodafone Cash, InstaPay), receipt image upload, status tracking, and request resubmission.
- `features/tracking/` — Live Google Maps Platform tracking, road-following polylines, ETrack IoT GPS telemetry ingestion, stop ETAs, and arrival event detection.
- `features/trips/` — Active and historical trips, QR boarding ticket modal, 30-minute cutoff cancellation with refund, and seat swap.
- `features/wallet/` — Dual point balances, pending top-up points, and immutable transaction history.

---
**Last Updated**: 2026-09-14

