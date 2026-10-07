# Tidy Media

> **Bring order to your media.**

Tidy Media is a native iOS gallery cleaner and media organizer designed to help users find and manage unwanted or redundant photos and videos.
---

## ✨ Features

- 📊 **Storage Dashboard & Recoverable Calculator** — Live breakdown of library storage (Videos, Photos, Screenshots) with an actionable *"⚡ Free up ~X GB"* badge.
- 📸 **Screenshots** — Find all screenshots in one dedicated place.
- 🎥 **Videos** — Browse all videos in the Photos library.
- 🔄 **Duplicate Photos** — Find exact duplicate photos and group them for cleanup.
- 🖼️ **Similar Photos** — Identify visually similar photos (e.g. multiple shots of the same scene).
- 🎬 **Duplicate Videos** — Find exact duplicate video assets and group them for review.
- 📦 **Large Videos** — Sort videos by file size to find storage-heavy files quickly.
---

## 🎯 Goal

Tidy Media is not a replacement for Apple's Photos app. It works with the user's existing Photos library and provides a focused interface for finding media that may be duplicated, unnecessary, or taking significant storage space.

```text
Apple Photos Library → PhotoKit → Tidy Media
    ↓
┌─────────────────┐
│ Screenshots     │
│ Videos          │
│ Duplicate Photos│
│ Similar Photos  │
│ Duplicate Videos│
│ Large Videos    │
└─────────────────┘
    ↓
Review / Manage
```
---

## 🛠️ Tech Stack

| Technology | Purpose |
| :--- | :--- |
| **Swift** | Core programming language |
| **SwiftUI** | User interface |
| **PhotoKit (Photos)** | Access and manage the Photos library |
| **Vision** | Visual analysis for similar photo detection |
| **AVFoundation** | Video processing and previews |
| **Swift Concurrency** | Background processing and responsive UI |
| **PHCachingImageManager** | Efficient thumbnail loading and caching |

Built entirely with Apple's native frameworks. No backend or cloud server required.
---

## 🏗️ Architecture

MVVM-oriented structure with dedicated services for Photos-library operations and media processing.

```text
┌────────────────────────────────────────┐
│            SwiftUI Views               │
│     Home / Category / Media Screens    │
└───────────────────▲────────────────────┘
                    │ State / Bindings
┌───────────────────┴────────────────────┐
│             ViewModels                 │
│      UI State & Business Logic         │
└───────────────────▲────────────────────┘
                    │
┌───────────────────┴────────────────────┐
│              Services                  │
│  Photo Library / Media Analysis / Video│
└───────────────────▲────────────────────┘
                    │
┌───────────────────┴────────────────────┐
│        Apple System Frameworks         │
│   PhotoKit / Vision / AVFoundation     │
└────────────────────────────────────────┘
```

**Performance**: Background processing, lazy grid loading, thumbnail-based rendering, `PHCachingImageManager` caching, Swift Concurrency for non-blocking work, and incremental processing.
---

## 🔐 Photos Permission & Privacy

- Requests Photos access to read, analyze, and manage media.
- Handles both full and limited Photos access.
- All processing happens on-device. No cloud uploads.
- No backend required for gallery analysis.
- Deletion is performed through PhotoKit after explicit user action.
---

## 🧠 Duplicate vs Similar Photos

**Duplicate Photos** — Exact copies detected via hash/checksum comparison:
```text
Photo A → Hash A    Photo B → Hash A    →  A = B (Duplicate)
Photo C → Hash B                        →  A ≠ C (Not Duplicate)
```

**Similar Photos** — Visually similar but not identical, detected via Vision framework feature analysis. Catches multiple shots of the same scene, burst-style photos, and different framings of the same subject.
---

## 📂 Project Structure

```text
Tidy-Media/
├── Tidy Media/
│   ├── Tidy_MediaApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   │   └── AlbumItem.swift
│   ├── ViewModels/
│   │   └── MainViewModel.swift
│   ├── Services/
│   │   ├── PhotoLibraryService.swift
│   │   ├── MediaScannerService.swift
│   │   ├── StorageCalculatorService.swift
│   │   └── RecentlyDeletedService.swift
│   ├── Theme/
│   │   └── AppTheme.swift
│   ├── Views/
│   │   ├── LaunchScreenView.swift
│   │   ├── OnboardingView.swift
│   │   ├── AlbumsGridView.swift
│   │   ├── AlbumDetailView.swift
│   │   ├── MediaGridView.swift
│   │   ├── GroupMediaDetailView.swift
│   │   ├── RecentlyDeletedView.swift
│   │   ├── StorageDetailsView.swift
│   │   └── Components/
│   └── Assets.xcassets/
├── assets/
│   └── app_icon.png
├── Tidy Media.xcodeproj
└── README.md
```
---

## 🚀 Getting Started

**Requirements:** macOS, Xcode 15.0+, iOS 17.0+. Physical iPhone recommended for Photos library testing.

```bash
git clone https://github.com/ShivamSingh321GO/Tidy-Media.git
cd Tidy-Media
open "Tidy Media.xcodeproj"
```

Select the **Tidy Media** scheme and run on an iOS Simulator or connected iPhone. On first launch, allow Photos access when prompted. Use **Full Access** for complete testing.
---

## 🧪 Testing

Test with: small and large photo libraries, many screenshots, multiple duplicate/similar photo groups, large video files, duplicate videos, limited and full Photos access, and deletion/cancellation flows. Monitor performance to ensure scanning does not freeze the UI.
---

## 🎨 Design

Native iOS visual approach using SwiftUI: simple navigation, category-based organization, native components, smooth scrolling, clear selection states, lightweight onboarding, Light and Dark Mode support, and consistent brand accent color.

**Brand Color — Primary Accent:** `#2879E7`
---

## 📋 Assignment Scope

Developed as an iOS Gallery Cleaner task covering: Screenshots, Videos, Duplicate Photos, Similar Photos, Duplicate Videos, and Large Videos. Primary focus is efficient media loading, responsive UI, accurate categorization, and safe media management.
