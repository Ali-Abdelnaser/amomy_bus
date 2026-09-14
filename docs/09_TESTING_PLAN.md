# 09 — Testing & Quality Assurance Plan

## 1. Testing Pyramid

```
                       / \
                      /   \
                     / E2E \       (Field Tests, Real Bus Verification)
                    /-------\
                   /  Widget \     (Screen States, Seat Map, Skeletons)
                  /-----------\
                 /  Integration\   (Booking Lifecycle, Ledger, Realtime)
                /---------------\
               /      Unit       \ (BLoCs, UseCases, Repos, Error Handler)
              /-------------------\
```

---

## 2. Unit Testing Strategy
- **BLoCs**: Test state progression for every event using `bloc_test`. Verify initial, loading, loaded, and error transitions.
- **Use Cases**: Mock repository contracts with `mocktail` to test business logic isolation.
- **Error Handler**: Test mapping of various exceptions (Dio timeout, 401 Unauthorized, Supabase RLS error) into the correct domain `Failure`.
- **Entities & Models**: Test JSON deserialization and equality comparisons (`props`).

---

## 3. Widget & UI Testing Strategy
- **Core Widgets**: Test `AppButton`, `AppErrorView`, `AppEmptyView`, and `AppSkeleton` under varied inputs.
- **Localization**: Verify that widgets render in both English (LTR) and Arabic (RTL) without text clipping or overflow errors.
- **Responsive Layouts**: Test UI components across multiple screen aspect ratios (compact phones, large displays, tablets).
- **Seat Map Visual States**: Verify that seats display correct colors (Blue, Orange, Green, Gray) and gender icons.

---

## 4. Integration & Regression Test Coverage

The project maintains comprehensive test coverage across all core features:
- **Tracking & Google Maps**: `test/features/tracking/` (89 passed tests) covering Google Maps migration, custom marker anchors, road polyline split, stop ETA engine, dwell time calculation, ETrack telemetry ingestion, and reconnection states.
- **Booking Flow & Seat Map**: `test/features/booking/` covering 28-seat layout geometry, atomic holds, dynamic stop fare calculation, review screen, and QR pass generation.
- **Wallet & Top-Up**: `test/features/wallet/` & `test/features/topup/` covering double-entry point transaction display, pending points banner, receipt upload, and request resubmission.
- **Trips & Forensic Actions**: `test/features/trips/` covering 30-minute cutoff, exact batch point refund, seat swapping, and ticket modal rendering.
- **Auth & Onboarding**: `test/features/auth/` & `test/features/onboarding/` covering validation, session persistence, and profile completeness checks.

---
**Last Updated**: 2026-09-14

