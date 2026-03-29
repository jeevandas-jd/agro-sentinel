# Git Workflow & Contribution Guide

This document explains how to contribute to the Agro Sentinel repository using our defined Git workflow.

---

## 🌿 Branch Strategy

We follow a **3-branch system**:

### 🔹 `main`

* Production-ready code only
* Always stable
* No direct commits

### 🔹 `dev`

* Integration branch
* All features are merged here first
* Should remain runnable at all times

### 🔹 Feature Branches

Each developer works on separate branches:

#### ML Work

* `ml/training`

#### Flutter Work

* `flutter/radar-ui`
* `flutter/camera-screen`
* etc.

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/agro-sentinel.git
cd agro-sentinel
```

---

### 2. Checkout Development Branch

```bash
git checkout dev
git pull origin dev
```

---

### 3. Create Your Feature Branch

```bash
git checkout -b <feature-name>
```

Examples:

```bash
git checkout -b flutter/radar-ui
git checkout -b ml/improve-accuracy
```

---

## 💻 Development Workflow

### Step 1 — Work on your feature

Make changes in your respective folder:

* ML → `ml/`
* Flutter → `flutter_app/`
* Backend → `backend/`

---

### Step 2 — Stage and Commit

```bash
git add .
git commit -m "type(scope): short description"
```

---

## 📝 Commit Convention

Use this format:

```text
type(scope): short description
```

### Types:

* `feat` → new feature
* `fix` → bug fix
* `train` → model training update
* `docs` → documentation
* `chore` → setup / config
* `refactor` → code cleanup

### Examples:

```bash
feat(ml): add LightCDC model
train(ml): achieve 90.4% validation accuracy
feat(flutter): implement camera capture screen
fix(flutter): correct image preprocessing
docs(readme): update project description
```

---

## 🔼 Push Your Work

```bash
git push origin <your-branch>
```

---

## 🔀 Merge Workflow

### Step 1 — Open Pull Request (PR)

* From your branch → `dev`
* Add clear title and description

---

### Step 2 — Review

* Another team member reviews
* Fix comments if needed

---

### Step 3 — Merge

* Merge into `dev`
* Delete feature branch after merge

---

## 🚫 Rules (IMPORTANT)

### ❌ Do NOT commit:

* Model weights (`.pth`, `.onnx`)
* Dataset files (`ml/data/`)
* API keys / credentials
* `.env` files

---

### ✅ Allowed:

* `.tflite` model (final only)
* notebooks
* scripts
* UI code

---

## 🔄 Updating Your Branch

Before pushing:

```bash
git checkout dev
git pull origin dev

git checkout <your-branch>
git merge dev
```

---

## 🧠 Best Practices

* Keep commits small and meaningful
* Push frequently
* Do NOT break `dev`
* Always test before pushing
* Write clear commit messages

---

## 🧩 Project Structure

```
agro-sentinel/
├── ml/
├── flutter_app/
├── backend/
├── docs/
```

---

## 🎯 Goal

Maintain:

* Clean history
* Stable integration
* Fast collaboration

---

## 🚀 Final Note

If you're unsure:

* Ask before merging
* Do NOT push directly to `main`

---

Let’s build clean, scalable, and production-ready code 🚀

