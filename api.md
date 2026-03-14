# AgriSentinel — Demo API Design

> **Scope:** Demo/prototype endpoints for submission. All responses use hardcoded or seeded placeholder data. No authentication complexity — a single static token is sufficient for headers.

---

## Base URL

```
https://api.agrisentinel.demo/v1
```

---

## Authentication

All requests include a static demo bearer token. No real auth flow is required for the prototype.

```
Authorization: Bearer DEMO_TOKEN_2024
```

---

## Overview of Flows

The API is structured around the 4-step prototype journey:

| Step | Screen | Purpose |
|------|--------|---------|
| 1 | Scout Dashboard | Load farmer profile and active hotspot alerts |
| 2 | GPS Truth Walk | Fetch hotspot target coordinates for navigation |
| 3 | AI Camera Interface | Submit captured image and receive damage assessment |
| 4 | Claim Dossier | Generate and download the verified claim PDF |

---

## 1. Farmer Profile

Used by the **Scout Dashboard** header to display the farmer's name, region, and farm summary.

### `GET /farmer/profile`

Returns the demo farmer's profile and regional summary statistics.

**Response**
```json
{
  "farmer_id": "DEMO-F-001",
  "name": "James Mwangi",
  "region": "Laikipia County, Kenya",
  "farm_plots": 3,
  "total_hectares": 12.4,
  "active_alerts": 2,
  "pending_claims": 1,
  "avatar_url": "https://api.agrisentinel.demo/assets/avatars/demo_farmer.jpg"
}
```

---

## 2. Hotspot Alerts (Scout Dashboard)

Used by the **Scout Dashboard** map widget and alert list. Returns satellite-detected NDVI anomaly zones near the farmer's location.

### `GET /hotspots`

Returns a list of all active damage hotspots for the demo farmer.

**Query Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `farmer_id` | string | Yes | Demo farmer ID |
| `status` | string | No | Filter by `pending`, `verified`, `all` (default: `pending`) |

**Response**
```json
{
  "hotspots": [
    {
      "id": "HS-001",
      "status": "pending",
      "crop_type": "Maize",
      "ndvi_score": 0.18,
      "ndvi_delta": -0.42,
      "severity": "high",
      "estimated_area_ha": 3.2,
      "damage_cause": "Wildlife conflict",
      "detected_at": "2024-03-10T08:30:00Z",
      "coordinates": {
        "latitude": -0.3925,
        "longitude": 36.7862
      },
      "satellite_image_url": "https://api.agrisentinel.demo/assets/satellite/hs_001_before.jpg",
      "distance_km": 1.4
    },
    {
      "id": "HS-002",
      "status": "pending",
      "crop_type": "Wheat",
      "ndvi_score": 0.22,
      "ndvi_delta": -0.31,
      "severity": "medium",
      "estimated_area_ha": 1.8,
      "damage_cause": "Flood damage",
      "detected_at": "2024-03-11T14:15:00Z",
      "coordinates": {
        "latitude": -0.3901,
        "longitude": 36.7910
      },
      "satellite_image_url": "https://api.agrisentinel.demo/assets/satellite/hs_002_before.jpg",
      "distance_km": 2.1
    }
  ],
  "total": 2
}
```

**Severity Thresholds (for UI colour coding)**

| NDVI Delta | Severity | UI Colour |
|------------|----------|-----------|
| > -0.20 | low | Yellow |
| -0.20 to -0.35 | medium | Orange |
| < -0.35 | high | Red |

---

### `GET /hotspots/{hotspot_id}`

Returns full detail for a single hotspot. Called when a farmer taps an alert card on the dashboard or begins navigation.

**Path Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `hotspot_id` | string | Hotspot identifier (e.g. `HS-001`) |

**Response**
```json
{
  "id": "HS-001",
  "status": "pending",
  "crop_type": "Maize",
  "ndvi_score": 0.18,
  "ndvi_delta": -0.42,
  "severity": "high",
  "estimated_area_ha": 3.2,
  "damage_cause": "Wildlife conflict",
  "detected_at": "2024-03-10T08:30:00Z",
  "coordinates": {
    "latitude": -0.3925,
    "longitude": 36.7862
  },
  "boundary_polygon": [
    { "latitude": -0.3920, "longitude": 36.7855 },
    { "latitude": -0.3920, "longitude": 36.7870 },
    { "latitude": -0.3930, "longitude": 36.7870 },
    { "latitude": -0.3930, "longitude": 36.7855 }
  ],
  "satellite_image_url": "https://api.agrisentinel.demo/assets/satellite/hs_001_before.jpg",
  "ndvi_heatmap_url": "https://api.agrisentinel.demo/assets/satellite/hs_001_ndvi.jpg",
  "land_parcel": {
    "parcel_id": "LND-KE-044-2201",
    "owner_name": "James Mwangi",
    "registered_area_ha": 4.0,
    "crop_season": "Long Rains 2024"
  }
}
```

---

## 3. GPS Navigation (Truth Walk)

Used by the **GPS Guidance screen** to supply the target coordinates and proximity threshold for the Truth Walk.

### `GET /hotspots/{hotspot_id}/navigation`

Returns lightweight navigation data — only coordinates and proximity requirements. Designed to be polled or called once before navigation begins.

**Response**
```json
{
  "hotspot_id": "HS-001",
  "target": {
    "latitude": -0.3925,
    "longitude": 36.7862
  },
  "proximity_threshold_meters": 10,
  "instructions": "Walk toward the flagged zone. The Capture Evidence button activates within 10 metres of the target.",
  "bearing_hint": "Head south-east from your current position"
}
```

> **Frontend note:** GPS tracking itself is handled on-device via `geolocator`. This endpoint only supplies the target and unlock threshold. The compass bearing is computed locally using the device heading and target coordinates.

---

## 4. Evidence Submission (AI Camera Interface)

Called after the farmer captures a photo within the proximity zone. The demo backend accepts the image upload and returns a mocked AI damage assessment result.

### `POST /evidence/submit`

Submits a captured ground photo along with GPS and hotspot metadata. Returns a demo damage score.

**Request** — `multipart/form-data`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `hotspot_id` | string | Yes | Associated hotspot |
| `farmer_id` | string | Yes | Demo farmer ID |
| `image` | file | Yes | Captured JPEG/PNG photo |
| `latitude` | float | Yes | Capture location latitude |
| `longitude` | float | Yes | Capture location longitude |
| `timestamp` | string | Yes | ISO 8601 capture timestamp |
| `device_heading_deg` | float | No | Compass heading at capture time |

**Response**
```json
{
  "evidence_id": "EVD-001-A",
  "hotspot_id": "HS-001",
  "status": "analysed",
  "image_url": "https://api.agrisentinel.demo/assets/evidence/evd_001_a.jpg",
  "ai_analysis": {
    "damage_percentage": 67.4,
    "healthy_pixel_ratio": 0.326,
    "damaged_pixel_ratio": 0.674,
    "confidence_score": 0.89,
    "damage_class": "Crop destruction — Wildlife conflict",
    "segmentation_overlay_url": "https://api.agrisentinel.demo/assets/evidence/evd_001_a_mask.jpg"
  },
  "geotag": {
    "latitude": -0.3925,
    "longitude": 36.7862,
    "timestamp": "2024-03-12T11:42:00Z"
  }
}
```

> **Demo note:** The backend does not need to run a real ML model. Return a hardcoded `damage_percentage` between 60–80% and a static `segmentation_overlay_url` for all submissions. The frontend renders the overlay on top of the captured image.

---

## 5. Claim Dossier (Claim Summary & Export)

Used by the **Claim Summary screen** to display the consolidated report and trigger PDF generation.

### `GET /claims/{hotspot_id}/summary`

Returns the full claim summary combining satellite data, ground evidence, and land parcel information. Displayed as the before/after comparison and data cards on the Claim Summary screen.

**Response**
```json
{
  "claim_id": "CLM-2024-001",
  "hotspot_id": "HS-001",
  "farmer": {
    "farmer_id": "DEMO-F-001",
    "name": "James Mwangi",
    "national_id": "DEMO-ID-123456"
  },
  "land_parcel": {
    "parcel_id": "LND-KE-044-2201",
    "owner_name": "James Mwangi",
    "registered_area_ha": 4.0,
    "crop_type": "Maize",
    "crop_season": "Long Rains 2024"
  },
  "satellite_data": {
    "detection_date": "2024-03-10",
    "ndvi_before": 0.60,
    "ndvi_after": 0.18,
    "ndvi_delta": -0.42,
    "estimated_damage_ha": 3.2,
    "satellite_image_before_url": "https://api.agrisentinel.demo/assets/satellite/hs_001_before.jpg",
    "satellite_image_after_url": "https://api.agrisentinel.demo/assets/satellite/hs_001_after.jpg"
  },
  "ground_evidence": {
    "evidence_id": "EVD-001-A",
    "capture_date": "2024-03-12",
    "damage_percentage": 67.4,
    "damage_class": "Crop destruction — Wildlife conflict",
    "confidence_score": 0.89,
    "ground_photo_url": "https://api.agrisentinel.demo/assets/evidence/evd_001_a.jpg",
    "segmentation_overlay_url": "https://api.agrisentinel.demo/assets/evidence/evd_001_a_mask.jpg",
    "geotag": {
      "latitude": -0.3925,
      "longitude": 36.7862
    }
  },
  "claim_status": "ready_for_export",
  "created_at": "2024-03-12T12:00:00Z"
}
```

---

### `POST /claims/{hotspot_id}/generate-pdf`

Triggers generation of the AIMS-compliant PDF dossier. Returns a download URL for the generated document.

**Request Body** — `application/json`

```json
{
  "farmer_id": "DEMO-F-001",
  "claim_id": "CLM-2024-001",
  "include_satellite_images": true,
  "include_ground_evidence": true,
  "include_ai_analysis": true
}
```

**Response**
```json
{
  "claim_id": "CLM-2024-001",
  "pdf_status": "generated",
  "pdf_url": "https://api.agrisentinel.demo/assets/reports/CLM-2024-001_dossier.pdf",
  "generated_at": "2024-03-12T12:05:00Z",
  "expires_at": "2024-03-19T12:05:00Z",
  "file_size_kb": 842
}
```

> **Demo note:** The PDF URL can point to a pre-generated static file stored on the demo server. The frontend uses the `pdf` Flutter package to generate the dossier on-device as a fallback if this endpoint is unavailable.

---

## 6. Error Responses

All endpoints return a consistent error envelope.

```json
{
  "error": true,
  "code": "HOTSPOT_NOT_FOUND",
  "message": "The requested hotspot does not exist.",
  "status": 404
}
```

**Common Error Codes**

| HTTP Status | Code | Trigger |
|-------------|------|---------|
| 400 | `INVALID_REQUEST` | Missing required fields |
| 401 | `UNAUTHORIZED` | Missing or invalid token |
| 404 | `NOT_FOUND` | Resource ID does not exist |
| 413 | `IMAGE_TOO_LARGE` | Uploaded image exceeds 10 MB |
| 500 | `SERVER_ERROR` | Demo server internal error |

---

## 7. Full Endpoint Reference

| Method | Endpoint | Screen | Purpose |
|--------|----------|--------|---------|
| `GET` | `/farmer/profile` | Scout Dashboard | Load farmer profile header |
| `GET` | `/hotspots?farmer_id=&status=` | Scout Dashboard | Load alert list and map overlays |
| `GET` | `/hotspots/{hotspot_id}` | Dashboard / Navigation | Load hotspot detail and boundary polygon |
| `GET` | `/hotspots/{hotspot_id}/navigation` | GPS Truth Walk | Get target coordinates and proximity threshold |
| `POST` | `/evidence/submit` | AI Camera Interface | Upload ground photo and receive AI damage score |
| `GET` | `/claims/{hotspot_id}/summary` | Claim Summary | Load before/after comparison and claim data |
| `POST` | `/claims/{hotspot_id}/generate-pdf` | Claim Summary | Generate and retrieve AIMS-compliant PDF dossier |

---

## 8. Demo Data Seed Reference

The backend engineer should seed the following static records to support the full prototype flow end-to-end.

### Farmer
- `farmer_id`: `DEMO-F-001`
- `name`: James Mwangi
- `region`: Laikipia County, Kenya

### Hotspots
- `HS-001` — High severity, Maize, Wildlife conflict, coordinates near developer's test location
- `HS-002` — Medium severity, Wheat, Flood damage

### Evidence
- `EVD-001-A` — Linked to `HS-001`, 67.4% damage, pre-generated segmentation mask image

### Claim
- `CLM-2024-001` — Linked to `HS-001` and `EVD-001-A`, PDF pre-generated as a static file

> All image assets (satellite before/after, segmentation masks, demo PDF) can be static files hosted on any public URL or mock server (e.g. Firebase Storage, S3, or a simple Express static file server).

---

## 9. Recommended Mock Server Options

For rapid demo setup, the backend engineer can use any of the following:

| Option | Notes |
|--------|-------|
| **Firebase Hosting + Firestore** | Aligns with the production tech stack described in the README |
| **Express.js static server** | Fastest to spin up; serve JSON fixtures and static assets |
| **Mockoon / Postman Mock Server** | Zero-code option; import the endpoint list above as a collection |
| **json-server** | Single `db.json` file serves all GET endpoints automatically |

