# AgriSentinel Frontend Prototype Plan

This document outlines the development requirements and architecture for the Flutter-based agricultural damage verification prototype.

---

## 1. Prototype Core Flow
The prototype will follow a 4-step user journey:
1.  **Dashboard**: View active satellite-detected damage alerts.
2.  **Navigation (Satellite Scout)**: GPS-guided movement to a specific hotspot.
3.  **Verification (Truth Walk)**: Real-time AI camera scan of crop damage.
4.  **Dossier**: Review and generate a "Verified Claim" PDF.

---

## 2. UI/UX Architecture

### Screen 1: Scout Dashboard
* **Header**: Farmer profile and region stats.
* **Map Widget**: `Maps_flutter` in `MapType.satellite`.
* **Hotspot Layers**: Hardcoded `Polygon` or `Circle` overlays representing NDVI anomalies.
* **Alert List**: Vertical list of "Pending Verifications" with distance indicators.

### Screen 2: GPS Guidance (The Truth Walk)
* **Live Tracking**: Implementation of `geolocator` to show user's current position vs. target hotspot.
* **Directional UI**: A custom `CustomPainter` compass needle pointing toward the target coordinates.
* **Proximity Lock**: A "Capture Evidence" button that remains disabled until the user is within 10 meters of the target.

### Screen 3: AI Camera Interface
* **Camera Preview**: Integration of the `camera` plugin.
* **ML Overlay**: 
    * Stack a `CustomPaint` widget over the camera feed.
    * Display a bounding box or semantic mask (mocked or via `tflite_flutter`).
* **Telemetry Data**: On-screen display of current GPS, Timestamp, and "Damage %" calculation.

### Screen 4: Claim Summary & Export
* **Data Visualization**: Before (Satellite) vs. After (Ground Photo) comparison cards.
* **OCR Mockup**: Form fields for Land ID and Owner Name (pre-filled).
* **Export Action**: Use the `pdf` package to compile images and data into a standard AIMS compliant dossier.

---

## 3. Technical Requirements

### Required Flutter Plugins
| Function | Package |
| :--- | :--- |
| **Maps** | `Maps_flutter` |
| **Location** | `geolocator` |
| **On-Device AI** | `tflite_flutter` (for U-Net model) |
| **Sensors** | `flutter_compass` |
| **Storage** | `path_provider` & `shared_preferences` |
| **Document Gen** | `pdf` & `printing` |

### Asset Requirements
* **TFLite Model**: A quantized `.tflite` file for crop segmentation (U-Net).
* **Map Styles**: JSON styling for Google Maps to emphasize vegetation.
* **Mock Data**: A `hotspots.json` file containing:
    * `id`, `latitude`, `longitude`, `ndvi_score`, `crop_type`.

---

## 4. Prototype Implementation Strategy

### Step 1: Mocking the "Top-Down" Data
Since the satellite backend isn't integrated yet, the app will read from a local JSON file.
* Define "Damage Zones" near the developer's current location to test the GPS proximity logic in real-time.

### Step 2: Computer Vision Integration
* Implement the `Isolate` pattern for TFLite inference to ensure the camera UI maintains 60 FPS.
* If the U-Net model is too heavy for the prototype, use a **Color Filtering Algorithm** (detecting brown/yellow vs green pixels) as a functional placeholder for "Damage Detection."

### Step 3: Local Evidence Loop
* Photos captured in-app will be stored in the temporary directory.
* Metadata (GPS/Timestamp) will be burned into the image or stored in a local `Sembast` or `SQLite` database for the final report generation.

---

## 5. Success Criteria for Prototype
- [ ] User can see a red "hotspot" on a satellite map.
- [ ] User can navigate to the coordinate using a live GPS pointer.
- [ ] The camera recognizes "damaged" areas vs "healthy" areas.
- [ ] A PDF is generated containing the location, photo, and AI damage score.