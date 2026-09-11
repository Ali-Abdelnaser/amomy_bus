# 00 — Project Overview

## 1. System Vision & Architecture
Amomy Bus is a modern, high-reliability bus transportation platform designed for scheduled passenger transit. The ecosystem consists of two separate applications sharing a unified backend infrastructure:

1. **Passenger App (This Project)**
   - Target Platforms: **Android & iOS**
   - Target Audience: Daily commuters, students, workers, and monthly subscribers.
   - Core Features: Schedule browsing, atomic seat selection and booking, Points wallet & recharge requests, QR boarding pass, live bus tracking during trips, push notifications, and a protected internal **Admin / Super Admin** dashboard.

2. **Staff App (Separate Project)**
   - Target Platforms: **Android only**
   - Target Audience: Onboarding staff, conductors, and station operators.
   - Core Features: Rapid QR code scanning, physical NFC card touch reading, ticket validation, and mandatory manual attendance confirmation.

---

## 2. Core Operational Ecosystem

```mermaid
flowchart TD
    subgraph Clients["Frontend Clients"]
        PA["Passenger App (Android / iOS)"]
        SA["Staff App (Android)"]
        AD["Admin / Super Admin Portal (Inside Passenger App)"]
    end

    subgraph Backend["Unified Backend Platform"]
        SB["Supabase PostgreSQL (RLS, Migrations)"]
        SBA["Supabase Auth"]
        SBR["Supabase Realtime (Seat locks, Tracking)"]
        FCM["Firebase Cloud Messaging (Push Notifications)"]
        GPS["External GPS Provider Ingestion Service"]
    end

    PA -->|Auth, Booking, Wallet| SB
    PA -->|Listen to Seat Holds & Live Map| SBR
    PA -->|Push Notifications| FCM
    SA -->|Scan QR / Tap NFC & Confirm Attendance| SB
    AD -->|Approve Topups, Manage Trips, Audit| SB
    GPS -->|Ingest Vehicle Telemetry| SB
```

---

## 3. Technology Stack

| Layer | Technology | Rationale |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.x (Dart 3) | Single codebase for Android and iOS with native performance |
| **State Management** | BLoC / Cubit | Predictable, reactive, testable state separation |
| **Architecture** | Clean Architecture (Feature-First) | Decoupled presentation, domain, and data layers |
| **Dependency Injection**| GetIt + Injectable | Automated compile-time code generation for IoC container |
| **Routing** | GoRouter | Declarative routing with path parameters and guard hooks |
| **Networking** | Dio + PrettyDioLogger | Resilient HTTP requests with interceptors and structured logging |
| **Backend & Database** | Supabase (PostgreSQL, Storage, Realtime) | Row-Level Security, migrations, atomic PostgreSQL functions |
| **Push Notifications**| Firebase Cloud Messaging (FCM) | Reliable cross-platform messaging and updates |
| **Local Storage** | SharedPreferences & FlutterSecureStorage | Encrypted credential storage & local preferences |
| **Loading UX** | Skeletonizer | Premium shimmer skeleton layouts over standard spinners |
| **Localization** | flutter_localizations + intl (ARB) | Native Arabic (RTL) & English (LTR) support from Day 1 |
