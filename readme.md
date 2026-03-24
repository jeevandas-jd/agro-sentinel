# Agro Sentinel

> AI-powered crop damage assessment and insurance verification 
> for Kerala's smallholder farmers.

**Team:** Gradient Descent  
**Track:** AI Based Crop Health & Pest Management  
**Event:** National Hackathon: Tech for Agriculture 2026 (IBM)

---

## The Problem

Kerala's farmers face a verification bottleneck. When wildlife 
raids or natural disasters strike, manual damage inspection for 
the AIMS insurance portal is slow, subjective, and disputed. 
Farmers wait weeks for compensation they may never fully receive.

## Our Solution

Agro Sentinel combines satellite imagery analysis, on-device AI, 
and automated report generation to produce fraud-proof damage 
dossiers in hours — not weeks.

## Architecture
```
Satellite Layer (GEE + Planet TFO)
        ↓
   Hotspot Detection
        ↓
Mobile Edge Layer (Flutter + TFLite)
        ↓
  Ground Verification
        ↓
Cloud Backend (Firebase + watsonx.ai)
        ↓
   Insurance Dossier
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter, TFLite, Provider |
| ML Model | PyTorch, ShuffleNetV2, GradCAM |
| Backend | Firebase, Cloud Functions |
| AI Narrative | watsonx.ai / Gemini API |
| Satellite | Google Earth Engine, Sentinel-2 |

## Project Structure
```
agro-sentinel/
├── ml/                    # ML training and model export
│   ├── notebooks/         # Kaggle training notebooks
│   ├── models/            # Exported .tflite models
│   └── scripts/           # Utility scripts
├── flutter_app/           # Mobile application
├── backend/               # Firebase functions and config
└── docs/                  # Architecture and API docs
```

## ML Model

- Architecture: LightCDC (ShuffleNetV2 based)
- Dataset: CDC Dataset (23,000 images)
- Accuracy: 89.44% (target)
- Model size: ~4.5MB (TFLite int8)
- Inference time: ~13ms on device

## Setup

### ML
```bash
cd ml
pip install -r requirements.txt
```

### Flutter
```bash
cd flutter_app
flutter pub get
flutter run
```

## Results

*Training in progress — results will be updated here*

## Team



| Jeevandas M S 
| AMAL MEHBIN 
| NANDAKISHOR

## License

MIT
