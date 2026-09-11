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

## 4. Integration & Atomic Concurrency Testing
- **5-Minute Hold Concurrency**: Simulate two passengers attempting to hold the same seat simultaneously; verify that exactly one succeeds and the other receives a `SEAT_UNAVAILABLE` failure.
- **Hold Expiration**: Verify that if a booking is not confirmed within 5 minutes, the seat returns to `available` and the point hold is released.
- **Spending Priority**: Verify that subscription points are debited prior to cash points.

---

## 5. Field Testing on Physical Buses (Day 7)
- **Real-World Scenarios**: Test QR scanning and NFC tap confirmation in physical bus lighting and motion conditions.
- **Offline / Low Connectivity**: Validate that temporary cellular drops during transit do not crash the Staff App or lose boarding confirmation queues.
- **GPS Telemetry Latency**: Benchmark live location tracking delay from IoT bus tracker to passenger map screen.
