# ReelIQ

ReelIQ is an AI-powered Instagram Reel optimization platform designed to maximize viewer engagement, rating hook effectiveness, predicting retention profiles, and detailing specific structural recommendations. Built with **Flutter**, **Dart**, and **Material 3**.

## Features Overview

1. **Authentication Gate**: Simple Email Login, Email Sign-up, and native Google Login integration.
2. **Dynamic Dashboard Tracker**: Monitor total processed reels, average engagement score trends, and a scrollable log of prior AI scans.
3. **Interactive Upload Sandbox**: Select video clips directly from the local gallery, play back selections in an integrated viewer, and start the AI metric calculations.
4. **Detailed AI Feedback reports**: View the calculated viral score out of 100 on an interactive visual gauge, read linguistic grade outputs, and list customized pacing suggestions.
5. **Hook A/B Testing Lab**: Type in three custom Hook variations, run linguistic analysis simulations, compare score breakdowns side-by-side, and identify the winning hook.
6. **Creator Profile**: View personal user telemetry, toggle the offline fallback database, and exit the session.

---

## Tech Stack & Libraries

- **Frontend**: Flutter & Dart (Material 3 Dark Theme)
- **State Management & DI**: `provider` (MVVM architecture binding)
- **Routing**: `go_router` (declares nested path and parameter routes)
- **Media**: `image_picker` (video galleries selection), `video_player` (integrated video playback)
- **Design Typography**: `google_fonts` (Outfit typography family)
- **Backend Integrations**:
  - `firebase_core` (Core initialization)
  - `firebase_auth` (Sign-in and accounts storage)
  - `cloud_firestore` (Data persistence for analytics logs)
  - `firebase_storage` (Video hosting and asset endpoints)
  - `google_sign_in` (Google provider authentication)

---

## Architecture Layout (Clean MVVM)

The project utilizes a feature-first clean folder structure separating concerns between data layers, business logic controllers, and views:

```
lib/
├── core/
│   ├── navigation/        # GoRouter routes and redirect structures (app_router.dart)
│   ├── services/          # Global configs and mock toggle rules (mock_config.dart)
│   ├── theme/             # Palette gradients, shapes, and theme configuration (app_theme.dart)
│   └── widgets/           # Global reusable UI parts (glass_card.dart)
│
└── features/
    ├── auth/              # Account signups, google log-ins, and session caching
    ├── dashboard/         # Metrics counters and list logs
    ├── reel_upload/       # Picker triggers, upload progress, and previews
    ├── analysis/          # Dynamic scoring gauges and improvement items
    └── hook_testing/      # Multi-concept A/B testing forms and winner cards
        ├── data/
        │   ├── models/        # Plain data structures (models)
        │   └── repositories/  # Backend fetching rules (live vs mock)
        └── presentation/
            ├── viewmodels/    # Notifiers binding view events to datasets
            └── views/         # Beautiful responsive dark layouts (screens)
```

---

## Dynamic Backend Configurations (Offline Mock Mode)

ReelIQ features a robust **Mock Mode** enabled by default. If platform-specific configuration files (`google-services.json` on Android or `GoogleService-Info.plist` on iOS) are not present at runtime, the application will catch the initialization exception, notify the debugging terminal, and seamlessly spin up local in-memory mock databases and AI engine simulators.

### To Connect Your Live Firebase Backend:

1. **Create a project** in the Firebase console.
2. **Register apps** for Android and iOS.
3. **Download and drop configuration files**:
   - For Android: Place `google-services.json` inside the `android/app/` folder.
   - For iOS: Place `GoogleService-Info.plist` inside the `ios/Runner/` folder using Xcode.
4. **Enable Auth methods**: Email/Password and Google Sign-in.
5. **Set up Firestore collections**: Create a `reels` collection.
6. **Set up Storage buckets**: Allow reading/writing to `reels/`.

---

## Run and Compile Guidelines

To run locally on a connected emulator, simulator, or desktop target:

1. Fetch and configure all dependency packages:
   ```bash
   flutter pub get
   ```
2. Check for linting, type errors, or warnings:
   ```bash
   flutter analyze
   ```
3. Run target build:
   ```bash
   flutter run
   ```
