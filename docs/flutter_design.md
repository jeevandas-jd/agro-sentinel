# Agro Sentinel — Flutter App Design Document
**Team:** Gradient Descent  
**Version:** 1.0  
**Date:** March 2026  
**Purpose:** Complete reference document for Flutter developers. Read this fully before writing a single line of code.

---

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Tech Stack](#2-tech-stack)
3. [Firebase Setup](#3-firebase-setup)
4. [Codebase Structure](#4-codebase-structure)
5. [Git Flow](#5-git-flow)
6. [Authentication](#6-authentication)
7. [Data Models](#7-data-models)
8. [Map Integration](#8-map-integration)
9. [Screen-by-Screen UI Guide](#9-screen-by-screen-ui-guide)
10. [AI Integration](#10-ai-integration)
11. [Security Rules](#11-security-rules)
12. [Environment & Secrets](#12-environment--secrets)
13. [pubspec.yaml Dependencies](#13-pubspecyaml-dependencies)
14. [Demo Mode](#14-demo-mode)
15. [Scalable Features](#15-scalable-features)

---

## 1. Project Overview

Agro Sentinel is a Flutter mobile application for Android that helps Kerala farmers document crop damage and file insurance claims automatically. 

### What the app does — in plain English

1. Farmer logs in with their credentials
2. They see their land plotted on a map
3. When a disaster happens, they raise a "Disaster Event"
4. They mark hotspot areas on the map (worst damage zones) — either by tapping the map or visiting the location physically with GPS
5. They capture photos at each hotspot — photos are automatically tagged with GPS coordinates
6. They describe what happened in their own words (text, scalable to voice)
7. The on-device AI model analyses each photo and returns a damage classification
8. The app builds a detailed damage dossier
9. The dossier is submitted — farmer gets a reference number

### Who uses it
Farmers in Kerala. Assume low digital literacy. Assume poor connectivity in the field. The app must work fully offline after initial data load.

---

## 2. Tech Stack

| Concern | Choice | Reason |
|---------|--------|--------|
| Framework | Flutter (Android first) | Cross-platform, single codebase |
| State management | Provider | Simple, well-documented, appropriate for team level |
| Authentication | Firebase Auth (Email+Password) | Simple, secure, free tier sufficient |
| Database | Cloud Firestore | Real-time, offline-first, works with Firebase Auth |
| File storage | Firebase Storage | For dossier photos and reports |
| Maps | Google Maps Flutter (`google_maps_flutter`) | Best Flutter map support |
| AI inference | `tflite_flutter` | On-device, offline inference |
| Local storage | Hive | Offline queue, fast key-value |
| PDF generation | `pdf` + `printing` packages | For dossier report |
| HTTP | `http` or `dio` | For watsonx/Gemini API call |
| Navigation | `go_router` | Clean URL-based routing |

---

## 3. Firebase Setup

### Step 1 — Firebase project
- Go to console.firebase.google.com
- Use the existing Google account (one account for both developers)
- Project name: `agro-sentinel`
- Enable Google Analytics: NO (not needed)

### Step 2 — Enable services
In Firebase console enable these services:
- Authentication → Sign-in method → Email/Password → Enable
- Firestore Database → Create database → Start in **test mode** (we apply security rules later)
- Storage → Get started → Start in test mode

### Step 3 — Add Android app
- Android package name: `com.gradientdescent.agrosentinel`
- App nickname: Agro Sentinel
- Download `google-services.json`
- Place it in `flutter_app/android/app/google-services.json`
- **NEVER commit this file to git** — it is in .gitignore already

### Step 4 — FlutterFire CLI setup
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=agro-sentinel
```
This generates `lib/firebase_options.dart` — also add this to .gitignore.

---

## 4. Codebase Structure

This is the exact folder structure. Create all folders before writing any code.

```
flutter_app/
├── android/
│   └── app/
│       └── google-services.json          # DO NOT COMMIT
├── assets/
│   ├── models/
│   │   └── lightcdc.tflite               # ML model — committed to git
│   ├── images/
│   │   └── logo.png
│   └── demo/
│       └── demo_farm.json                # Demo land data for hackathon
├── lib/
│   ├── main.dart                         # Entry point
│   ├── firebase_options.dart             # DO NOT COMMIT
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart           # All colors in one place
│   │   │   ├── app_strings.dart          # All UI text strings
│   │   │   └── canopy_constants.dart     # Crop canopy area values
│   │   ├── theme/
│   │   │   └── app_theme.dart            # MaterialTheme definition
│   │   ├── router/
│   │   │   └── app_router.dart           # All routes defined here
│   │   └── utils/
│   │       ├── location_utils.dart       # GPS helpers
│   │       ├── image_utils.dart          # Image processing helpers
│   │       └── loss_calculator.dart      # Tree count formula
│   │
│   ├── models/
│   │   ├── farmer_model.dart
│   │   ├── farm_model.dart
│   │   ├── hotspot_model.dart
│   │   ├── disaster_event_model.dart
│   │   └── dossier_model.dart
│   │
│   ├── services/
│   │   ├── auth_service.dart             # Firebase Auth wrapper
│   │   ├── firestore_service.dart        # Firestore CRUD operations
│   │   ├── storage_service.dart          # Firebase Storage uploads
│   │   ├── inference_service.dart        # TFLite model wrapper
│   │   ├── ai_narrative_service.dart     # watsonx/Gemini API call
│   │   └── offline_queue_service.dart    # Hive offline queue
│   │
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── farm_provider.dart
│   │   ├── disaster_provider.dart
│   │   └── dossier_provider.dart
│   │
│   └── features/
│       ├── splash/
│       │   └── splash_screen.dart
│       ├── auth/
│       │   ├── login_screen.dart
│       │   └── widgets/
│       │       └── login_form.dart
│       ├── home/
│       │   ├── home_screen.dart
│       │   └── widgets/
│       │       ├── farm_summary_card.dart
│       │       └── active_disasters_list.dart
│       ├── map/
│       │   ├── farm_map_screen.dart
│       │   ├── hotspot_map_screen.dart
│       │   └── widgets/
│       │       ├── hotspot_marker.dart
│       │       └── map_action_bar.dart
│       ├── disaster/
│       │   ├── new_disaster_screen.dart
│       │   ├── disaster_detail_screen.dart
│       │   └── widgets/
│       │       ├── disaster_type_picker.dart
│       │       └── description_input.dart
│       ├── capture/
│       │   ├── camera_capture_screen.dart
│       │   ├── ai_result_screen.dart
│       │   └── widgets/
│       │       ├── capture_overlay.dart
│       │       └── damage_result_card.dart
│       ├── dossier/
│       │   ├── dossier_review_screen.dart
│       │   ├── dossier_submit_screen.dart
│       │   └── widgets/
│       │       └── dossier_section_card.dart
│       └── radar/
│           ├── radar_screen.dart         # Compass navigation to hotspot
│           └── radar_painter.dart        # CustomPainter for radar UI
│
├── test/
│   └── widget_test.dart
├── pubspec.yaml
└── .env.example                          # Template — actual .env not committed
```

---

## 5. Git Flow

### Branches
```
main          ← stable, demo-ready code only
dev           ← integration branch
flutter/auth  ← authentication screens
flutter/map   ← map and hotspot features  
flutter/ai    ← camera + TFLite inference
flutter/dossier ← report generation
```

### Daily workflow
```bash
# Start of day — always pull dev first
git checkout dev
git pull origin dev

# Create feature branch from dev
git checkout -b flutter/auth

# Work, commit often
git add .
git commit -m "feat(auth): implement login screen UI"
git commit -m "feat(auth): connect Firebase Auth service"
git commit -m "fix(auth): handle wrong password error state"

# When feature is complete
git push origin flutter/auth
# Create Pull Request on GitHub: flutter/auth → dev
# Other developer reviews (even a quick look)
# Merge into dev

# When dev is stable and demo-ready
# Create PR: dev → main
```

### Commit message format
```
feat(scope): what you added
fix(scope): what you fixed
refactor(scope): what you restructured
style(scope): UI/styling changes
docs(scope): documentation

Scopes: auth, map, ai, dossier, radar, home, core
```

### Rules
- Never commit directly to main
- Never commit `google-services.json` or `firebase_options.dart` or `.env`
- Commit after every logical unit of work — not once at the end of the day
- If something breaks, commit anyway with `fix(scope): WIP — broken, investigating`

---

## 6. Authentication

### Flow
```
App opens
    ↓
SplashScreen (2 seconds)
    ↓
Firebase.authStateChanges() check
    ↓
[Not logged in] → LoginScreen
[Logged in]     → HomeScreen
```

### LoginScreen
- Email field
- Password field  
- "Login" button
- NO registration screen in the app — accounts are created manually in Firebase console for the demo
- Show loading spinner while Firebase is working
- Show friendly error messages — not Firebase error codes

### Error messages (friendly versions)
| Firebase error | Show to user |
|---------------|--------------|
| wrong-password | Incorrect password. Please try again. |
| user-not-found | No account found. Please contact support. |
| network-request-failed | No internet connection. Please check your network. |
| too-many-requests | Too many attempts. Please wait a few minutes. |

### After login
When a farmer logs in, immediately fetch their farmer profile from Firestore using their `uid`. The farmer profile contains their farm data and land boundaries. Store this in `FarmProvider` so all screens can access it.

### AuthService — what it must do
```dart
// lib/services/auth_service.dart

class AuthService {
  // Sign in — returns FirebaseUser or throws friendly error
  Future<UserCredential> signIn(String email, String password)
  
  // Sign out
  Future<void> signOut()
  
  // Stream of auth state changes — used in router
  Stream<User?> get authStateChanges
  
  // Current user — null if not logged in
  User? get currentUser
}
```

---

## 7. Data Models

### Firestore Collection Structure
```
/farmers/{uid}
    name: string
    phone: string
    email: string
    aadhaar_last4: string
    created_at: timestamp

/farms/{farmId}
    farmer_uid: string          ← links to /farmers/{uid}
    name: string                ← "North Coconut Plot"
    survey_number: string       ← from land tax receipt
    crop_type: string           ← "Coconut" | "Rubber" | "Plantain"
    area_hectares: double
    boundaries: List<GeoPoint>  ← polygon coordinates of the land
    center: GeoPoint            ← center point for map
    created_at: timestamp

/disaster_events/{eventId}
    farmer_uid: string
    farm_id: string
    disaster_type: string       ← "Wildlife" | "Flood" | "Storm" | "Other"
    farmer_description: string  ← what the farmer typed
    occurred_at: timestamp      ← when disaster happened
    reported_at: timestamp      ← when farmer reported in app
    status: string              ← "draft" | "submitted" | "verified"
    hotspots: List<Map>         ← list of hotspot objects (see below)
    ai_narrative: string        ← generated by watsonx/Gemini
    total_trees_lost: int
    estimated_loss_inr: double

/dossiers/{dossierId}
    event_id: string
    farmer_uid: string
    farm_id: string
    pdf_url: string             ← Firebase Storage URL
    submitted_at: timestamp
    reference_number: string    ← e.g. "AGS-2026-001"
```

### Hotspot object (inside disaster_events)
```dart
// This is a Map inside the disaster_events document
// Not a separate collection — keeps things simple

{
  "id": "hs_001",
  "latitude": 10.5231,
  "longitude": 76.2144,
  "photo_url": "https://...",       // Firebase Storage URL
  "ai_result": "damaged",          // "damaged" | "non_damaged"
  "ai_confidence": 0.94,           // 0.0 to 1.0
  "gradcam_url": "https://...",    // Firebase Storage URL for heatmap
  "trees_lost": 12,
  "captured_at": timestamp
}
```

### Dart model classes

**FarmerModel**
```dart
class FarmerModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String aadhaarLast4;
  
  // fromFirestore and toFirestore factory methods
}
```

**FarmModel**
```dart
class FarmModel {
  final String id;
  final String farmerUid;
  final String name;
  final String surveyNumber;
  final String cropType;
  final double areaHectares;
  final List<LatLng> boundaries;  // GeoPoint → LatLng conversion
  final LatLng center;
}
```

**DisasterEventModel**
```dart
class DisasterEventModel {
  final String id;
  final String farmerUid;
  final String farmId;
  final String disasterType;
  final String farmerDescription;
  final DateTime occurredAt;
  final String status;
  final List<HotspotModel> hotspots;
  final String? aiNarrative;
  final int totalTreesLost;
  final double estimatedLossInr;
}
```

**HotspotModel**
```dart
class HotspotModel {
  final String id;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final String? aiResult;       // "damaged" or "non_damaged"
  final double? aiConfidence;
  final String? gradcamUrl;
  final int treesLost;
  final DateTime capturedAt;
}
```

---

## 8. Map Integration

### Setup
1. Get Google Maps API key from Google Cloud Console
2. Enable: Maps SDK for Android
3. Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}"/>
```
4. Add to `android/local.properties`:
```
MAPS_API_KEY=your_actual_key_here
```
5. In `android/app/build.gradle`:
```gradle
manifestPlaceholders = [MAPS_API_KEY: localProperties['MAPS_API_KEY']]
```
**Never hardcode the API key in Dart code.**

### FarmMapScreen — what it shows
- Farmer's land boundary drawn as a green polygon
- Farm center marked with a custom marker (leaf icon)
- Existing hotspots shown as red markers
- Bottom sheet showing farm summary (crop type, area, active disasters)

### HotspotMapScreen — marking damage zones
Two ways to add a hotspot:

**Method 1 — Tap on map**
- Long press on map → shows confirmation dialog
- "Mark this as damaged area?" → Yes/No
- On Yes → creates hotspot at tapped coordinates
- Navigate to CameraCaptureScreen for that hotspot

**Method 2 — GPS (farmer visits the location)**  
- "Use my current location" button
- Gets device GPS coordinates
- Creates hotspot at current position
- Navigate to CameraCaptureScreen

### Map permissions — AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### Map constants
```dart
// lib/core/constants/app_colors.dart
static const farmBoundaryColor = Color(0xFF2D6A4F);    // dark green
static const hotspotMarkerColor = Color(0xFFE24B4A);   // red
static const visitedHotspotColor = Color(0xFF52B788);  // light green
```

---

## 9. Screen-by-Screen UI Guide

### Design language
- **Background:** `#0D1F0F` (dark forest green) for primary screens
- **Surface:** `#1A3A1E` (mid green) for cards and containers
- **Accent:** `#52B788` (lime green) for interactive elements
- **Gold:** `#D4A017` for warnings and highlights
- **Text:** `#F4EFE1` (cream white) on dark backgrounds
- **Font:** Use `Trebuchet MS` for headings, `Calibri` equivalent (Roboto Slab or similar) for body
- **Corner radius:** 12px for cards, 8px for buttons, 20px for pills/badges
- **No gradients** — flat solid colors only
- **Icons:** Use `flutter_svg` or Material icons — keep them simple

### Screen 1 — SplashScreen
- Dark green background `#0D1F0F`
- Centered logo (leaf icon + "AGRO SENTINEL" text)
- Tagline: "From Space to Soil"
- NDVI rainbow color strip at the top (7 colored bands)
- Auto-navigate after 2 seconds based on auth state
- No loading spinner — just the logo

### Screen 2 — LoginScreen
- Dark green background
- Logo at top (smaller version)
- Card in center with:
  - Email field
  - Password field with show/hide toggle
  - "Login" button (lime green, full width)
- Bottom text: "Agro Sentinel v1.0 — Gradient Descent"
- NO "Forgot password", NO "Register" — demo only
- Show `CircularProgressIndicator` inside button while loading
- Show `SnackBar` for errors — friendly messages only

### Screen 3 — HomeScreen
- AppBar: "Agro Sentinel" title, logout icon top right
- Farmer name and farm name shown prominently
- Two main action cards:
  - **"View My Farm"** → navigates to FarmMapScreen
  - **"Report Disaster"** → navigates to NewDisasterScreen
- List of active/past disaster events below
- Each disaster card shows: type, date, status badge (Draft/Submitted/Verified)
- Floating action button: "+" to start new disaster report

### Screen 4 — FarmMapScreen
- Full screen Google Map
- Farm boundary shown as green polygon
- Farm name shown in top overlay card
- Existing hotspots shown as markers colored by status
- Bottom sheet (draggable) showing:
  - Farm details (crop type, area)
  - "Start New Disaster Report" button
- AppBar with back button

### Screen 5 — NewDisasterScreen
- Title: "Report Damage"
- Disaster type picker — horizontal scrollable chips:
  - Wildlife Attack
  - Flood
  - Storm/Wind
  - Drought
  - Other
- Date/time picker — "When did it happen?"
- Text field (multiline, minimum 3 lines): "Describe what happened"
  - Placeholder: "e.g. Wild elephants destroyed the northern section last night"
  - Character count shown
- "Continue to Map" button at bottom
- Validates: type selected + description not empty

### Screen 6 — HotspotMapScreen
- Title: "Mark Damaged Areas"
- Full screen map showing the farm
- Instruction banner at top: "Tap on the map or visit the location to mark damage"
- Bottom sheet with two buttons:
  - "Tap Location on Map" (toggles tap mode)
  - "Use My GPS Location" (uses device location)
- Each hotspot appears as a numbered red marker
- Hotspot list at bottom showing each one with status
  - Red circle = photo not taken yet
  - Green circle = photo taken and AI analysed
- "Done — Generate Report" button (enabled when at least 1 hotspot has photo)

### Screen 7 — CameraCaptureScreen
- Title: "Capture Damage Photo"
- Full screen camera preview
- GPS coordinates shown as overlay at bottom: "10.5231°N, 76.2144°E"
- Capture button (large circle) at bottom center
- Instruction text at top: "Point camera at the damaged area"
- After capture:
  - Photo preview shown
  - "Use this photo" button
  - "Retake" button
- Photo is automatically saved with GPS EXIF data

### Screen 8 — AIResultScreen
- Shows the captured photo
- Loading state: "Analysing damage..." with spinner
- Result card appears below photo:
  - Large label: "DAMAGED" (red) or "HEALTHY" (green)
  - Confidence percentage: "94% confidence"
  - GradCAM heatmap overlay on photo (shows what AI looked at)
  - Estimated trees affected (if damaged)
- "Confirm and Continue" button
- "Retake Photo" button

### Screen 9 — DossierReviewScreen
- Title: "Damage Report Preview"
- Scrollable page showing:
  - Farm details section
  - Disaster details section
  - Hotspot summary (photo thumbnails + AI results for each)
  - Total damage summary:
    - Total hotspots marked: X
    - Damaged areas: X
    - Estimated trees lost: X
    - Estimated loss: ₹X
  - AI-generated narrative paragraph (from watsonx/Gemini)
  - Farmer description (what they typed earlier)
- Edit button for farmer description
- "Generate PDF Report" button

### Screen 10 — DossierSubmitScreen
- Shows: "Report submitted successfully"
- Reference number prominently displayed: "AGS-2026-001"
- PDF download button
- "Back to Home" button
- Green checkmark animation

### RadarScreen (bonus — if time allows)
- Compass-based navigation screen
- Guides farmer to nearest unvisited hotspot
- Bearing and distance shown
- Hotspot list at bottom

---

## 10. AI Integration

### TFLite inference — InferenceService

```dart
// lib/services/inference_service.dart

class InferenceService {
  // Load model from assets once at app start
  Future<void> loadModel()
  
  // Run inference on a captured image
  // Returns: {"label": "damaged", "confidence": 0.94}
  Future<Map<String, dynamic>> classify(File imageFile)
  
  // Dispose when app closes
  void dispose()
}
```

**Input:** Image resized to 256×256, normalized with ImageNet mean/std  
**Output:** Two logits → softmax → [damaged_prob, non_damaged_prob]  
**Label:** index 0 = damaged, index 1 = non_damaged  

### AI Narrative — AINarrativeService

```dart
// lib/services/ai_narrative_service.dart

class AINarrativeService {
  // Calls watsonx.ai or Gemini with structured damage data
  // Returns a paragraph of professional insurance language
  Future<String> generateNarrative(DisasterEventModel event)
}
```

**Prompt template to send:**
```
You are an agricultural damage assessment officer. Based on the following 
field data, write a professional 2-3 sentence damage assessment paragraph 
suitable for an insurance claim report.

Farm: {crop_type} plantation, Survey No. {survey_number}, {area} hectares
Disaster type: {disaster_type}
Date of incident: {date}
Farmer's account: {farmer_description}
AI damage assessment: {damaged_count} of {total_count} locations showed 
significant damage
Estimated trees lost: {trees_lost}

Write in formal English. Be factual and precise. Do not add information 
not provided above.
```

**Fallback:** If API call fails, use a pre-written template string. Never show the error to the farmer — just use the template.

### Loss calculation — LossCalculator

```dart
// lib/core/utils/loss_calculator.dart

class LossCalculator {
  // Canopy constants from the paper
  static const Map<String, double> canopyConstants = {
    'Coconut': 38.5,
    'Rubber': 25.0,
    'Plantain': 12.0,
  };

  // Market rates per tree (INR) — approximate 2026 values
  static const Map<String, double> treeValueInr = {
    'Coconut': 7000.0,
    'Rubber': 5000.0,
    'Plantain': 2000.0,
  };

  static int estimateTreesLost(
    double damagedAreaSqM, 
    String cropType
  ) {
    final constant = canopyConstants[cropType] ?? 38.5;
    return (damagedAreaSqM / constant).round();
  }

  static double estimateLossInr(int treesLost, String cropType) {
    final rate = treeValueInr[cropType] ?? 7000.0;
    return treesLost * rate;
  }
}
```

---

## 11. Security Rules

### Firestore Rules
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Farmers can only read/write their own profile
    match /farmers/{uid} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == uid;
    }
    
    // Farmers can only read/write their own farms
    match /farms/{farmId} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == resource.data.farmer_uid;
      allow create: if request.auth != null
                    && request.auth.uid == request.resource.data.farmer_uid;
    }
    
    // Farmers can only read/write their own disaster events
    match /disaster_events/{eventId} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == resource.data.farmer_uid;
      allow create: if request.auth != null
                    && request.auth.uid == request.resource.data.farmer_uid;
    }
    
    // Farmers can only read their own dossiers
    match /dossiers/{dossierId} {
      allow read: if request.auth != null 
                  && request.auth.uid == resource.data.farmer_uid;
      allow create: if request.auth != null
                    && request.auth.uid == request.resource.data.farmer_uid;
    }
  }
}
```

### Storage Rules
```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Farmers can only access their own folder
    match /farmers/{uid}/{allPaths=**} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == uid;
    }
  }
}
```

### Storage folder structure
```
/farmers/{uid}/
    /hotspot_photos/{disasterId}/{hotspotId}.jpg
    /gradcam/{disasterId}/{hotspotId}_heatmap.jpg
    /dossiers/{dossierId}/report.pdf
```

---

## 12. Environment & Secrets

### Never hardcode these in Dart files:
- Google Maps API key
- watsonx API key
- Gemini API key
- Firebase config (use generated firebase_options.dart)

### How to handle secrets
Create a file `lib/core/constants/api_keys.dart`:
```dart
// This file is in .gitignore — NEVER commit it
// Create this file manually on each developer's machine

class ApiKeys {
  static const String geminiApiKey = 'your_actual_key_here';
  static const String watsonxApiKey = 'your_actual_key_here';
  static const String watsonxProjectId = 'your_project_id_here';
}
```

Create `lib/core/constants/api_keys.dart.example`:
```dart
// Copy this file to api_keys.dart and fill in the real values
// api_keys.dart.example IS committed to git

class ApiKeys {
  static const String geminiApiKey = 'FILL_IN_YOUR_KEY';
  static const String watsonxApiKey = 'FILL_IN_YOUR_KEY';
  static const String watsonxProjectId = 'FILL_IN_YOUR_PROJECT_ID';
}
```

Add to `.gitignore`:
```
lib/core/constants/api_keys.dart
lib/firebase_options.dart
android/app/google-services.json
android/local.properties
```

---

## 13. pubspec.yaml Dependencies

```yaml
name: agro_sentinel
description: AI-powered crop damage assessment for Kerala farmers
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  firebase_storage: ^12.0.0

  # Maps
  google_maps_flutter: ^2.9.0

  # State management
  provider: ^6.1.0

  # Navigation
  go_router: ^14.0.0

  # ML inference
  tflite_flutter: ^0.10.4

  # Local storage
  hive_flutter: ^1.1.0

  # Camera and location
  camera: ^0.11.0
  geolocator: ^13.0.0
  image_picker: ^1.1.0
  exif: ^4.0.0

  # PDF generation
  pdf: ^3.11.0
  printing: ^5.13.0

  # HTTP for AI API calls
  dio: ^5.7.0

  # Image processing
  image: ^4.2.0
  flutter_image_compress: ^2.3.0

  # UI helpers
  cached_network_image: ^3.4.0
  shimmer: ^3.0.0
  lottie: ^3.1.0

  # Utilities
  uuid: ^4.5.0
  intl: ^0.19.0
  path_provider: ^2.1.0
  permission_handler: ^11.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/models/
    - assets/images/
    - assets/demo/
```

---

## 14. Demo Mode

For the hackathon demo, use pre-loaded demo data so the app works without needing real Firestore data during the presentation.

### Demo farm data — assets/demo/demo_farm.json
```json
{
  "farmer": {
    "uid": "demo_farmer_001",
    "name": "Rajan Krishnan",
    "phone": "+91 9876543210",
    "survey_number": "KL-TRS-2041"
  },
  "farm": {
    "id": "demo_farm_001",
    "name": "North Coconut Plot",
    "crop_type": "Coconut",
    "area_hectares": 1.2,
    "center": { "lat": 10.5231, "lng": 76.2144 },
    "boundaries": [
      { "lat": 10.5238, "lng": 76.2138 },
      { "lat": 10.5238, "lng": 76.2152 },
      { "lat": 10.5224, "lng": 76.2152 },
      { "lat": 10.5224, "lng": 76.2138 }
    ]
  },
  "demo_hotspots": [
    { "lat": 10.5233, "lng": 76.2143, "label": "Hotspot 1 — NW corner" },
    { "lat": 10.5229, "lng": 76.2148, "label": "Hotspot 2 — Centre" },
    { "lat": 10.5226, "lng": 76.2141, "label": "Hotspot 3 — SW corner" }
  ]
}
```

### Demo Firebase account
Create ONE Firebase Auth account manually in the console:
- Email: `demo@agrosentinel.in`
- Password: `AgroDemo2026`
- Create the corresponding Firestore documents for this farmer

Both developers use this same demo account for testing and for the finale demo.

---

## 15. Scalable Features

These are NOT required for the hackathon. Implement only if everything else is complete and time remains.

### Voice input (Malayalam to English)
- Use Google Speech-to-Text API
- Farmer speaks in Malayalam
- Text is transcribed and translated to English
- Populates the disaster description field
- Package: `speech_to_text` Flutter package

### Radar navigation screen
- Compass-based navigation to nearest hotspot
- Uses `flutter_compass` package
- Already designed — code is in the repository under `lib/features/radar/`

### Offline-first sync
- All Firestore writes go to Hive first
- Background sync when connectivity restored
- Package: `connectivity_plus` to detect network state

---

## Quick Start for Developer

```bash
# 1. Clone the repo
git clone https://github.com/jeevandas-jd/agro-sentinel.git
cd agro-sentinel/flutter_app

# 2. Checkout the flutter dev branch
git checkout dev
git checkout -b flutter/your-feature-name

# 3. Get dependencies
flutter pub get

# 4. Create api_keys.dart from example
cp lib/core/constants/api_keys.dart.example lib/core/constants/api_keys.dart
# Fill in the actual keys — ask Jeevandas for the values

# 5. Get google-services.json from Jeevandas
# Place it at: android/app/google-services.json

# 6. Run the app
flutter run

# 7. Commit often
git add .
git commit -m "feat(auth): implement login screen"
git push origin flutter/your-feature-name
```

--- 

**Sync daily at 9 AM** — even a 10-minute call is enough.  
**Finale date:** April 4, 2026 — Report by 7:00 AM at JAIN University, Bengaluru.

---

*Document version 1.0 — March 2026 — Team Gradient Descent*
