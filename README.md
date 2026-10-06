# Tidy Media

> **Bring order to your media.**

![Tidy Media App Icon](assets/app_icon.png)

Tidy Media is a native iOS gallery cleaner and media organizer designed to help users find and manage unwanted or redundant photos and videos.

---

## ✨ Features

Tidy Media focuses on six core media-management categories:

### 📸 Screenshots
Find screenshots stored in the user's Photos library in one dedicated place.

### 🎥 Videos
Browse the videos available in the Photos library.

### 🔄 Duplicate Photos
Find exact duplicate photos and group them together for easier review and cleanup.

### 🖼️ Similar Photos
Identify photos that are visually similar, such as multiple shots of the same scene or subject.

### 🎬 Duplicate Videos
Find exact duplicate video assets and group them together for review.

### 📦 Large Videos
Sort videos by file size so users can quickly identify videos consuming the most storage.

---

## 🎯 Goal

Tidy Media is not a replacement for Apple's Photos app.

It works with the user's existing Photos library and provides a focused interface for finding media that may be duplicated, unnecessary, or taking significant storage space.

```text
Apple Photos Library
        ↓
     PhotoKit
        ↓
    Tidy Media
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
| **PhotoKit (Photos)** | Access and manage the user's Photos library |
| **Vision** | Visual analysis for identifying similar photos |
| **AVFoundation** | Video-related processing and previews |
| **Swift Concurrency** | Background processing and responsive UI |
| **PHCachingImageManager** | Efficient thumbnail loading and caching |

Tidy Media is built using Apple's native frameworks and does not require a backend or cloud server for its core functionality.

---

## 🏗️ Architecture

Tidy Media follows an MVVM-oriented structure with dedicated services for Photos-library operations and media processing.

```text
┌──────────────────────────────────────────┐
│                SwiftUI Views             │
│       Home / Category / Media Screens    │
└─────────────────────▲────────────────────┘
                      │
                 State / Bindings
                      │
┌─────────────────────┴────────────────────┐
│               ViewModels                 │
│        UI State & Business Logic         │
└─────────────────────▲────────────────────┘
                      │
┌─────────────────────┴────────────────────┐
│                Services                  │
│ Photo Library / Media Analysis / Video   │
└─────────────────────▲────────────────────┘
                      │
┌─────────────────────┴────────────────────┐
│           Apple System Frameworks        │
│     PhotoKit / Vision / AVFoundation     │
└──────────────────────────────────────────┘
```

### Performance
The app is designed to remain responsive while working with large photo libraries.

Key considerations include:
- Background processing for expensive operations.
- Lazy loading of media grids.
- Thumbnail-based rendering instead of loading full-resolution images unnecessarily.
- `PHCachingImageManager` for efficient image caching.
- Swift Concurrency for non-blocking work.
- Incremental processing instead of loading thousands of full-resolution assets into memory at once.

---

## 🔐 Photos Permission

Tidy Media uses Apple's PhotoKit framework to access the user's existing Photos library.

The app requests Photos access so it can:
- Read photos and videos.
- Analyze media.
- Identify duplicates and similar photos.
- Sort videos by size.
- Delete selected assets when the user explicitly chooses to remove them.

The app handles both full and limited Photos access appropriately. If the user grants limited access, Tidy Media only works with the assets made available by the user.

---

## 🔒 Privacy

Privacy is a core part of the app design:
- Photos and videos are processed on the device.
- No media needs to be uploaded to a cloud server.
- No backend is required for gallery analysis.
- The app uses Apple's native Photos permission system.
- Deletion is performed through PhotoKit after explicit user action.

Tidy Media does not copy the user's entire Photos library into a separate cloud database.

---

## 🧠 Duplicate vs Similar Photos

Tidy Media treats duplicate and similar photos differently.

### Duplicate Photos
Duplicate detection looks for exact copies.

```text
Photo A → Hash A
Photo B → Hash A
Photo C → Hash B

A = B → Duplicate
A ≠ C → Not Duplicate
```

### Similar Photos
Similar-photo detection focuses on visual similarity rather than identical file data.

Examples include:
- Multiple shots of the same scene.
- Similar photos taken moments apart.
- Different images of the same subject.
- Visually similar versions of an image.

Vision-based image feature analysis is used to compare the visual characteristics of photos.

---

## 📱 User Flow

```text
Launch App
    ↓
Onboarding
    ↓
Photos Permission
    ↓
Tidy Media Home
    ↓
Select Category
    ↓
Scan / Load Media
    ↓
Review Results
    ↓
Select Media
    ↓
Confirm Action
    ↓
Manage / Delete Selected Assets
```

---

## 📂 Project Structure

```text
Tidy-Media/
│
├── Tidy Media/
│   ├── Tidy_MediaApp.swift
│   ├── ContentView.swift
│   │
│   ├── Models/
│   │   └── AlbumItem.swift
│   │
│   ├── ViewModels/
│   │   └── MainViewModel.swift
│   │
│   ├── Services/
│   │   ├── PhotoLibraryService.swift
│   │   ├── MediaScannerService.swift
│   │   └── RecentlyDeletedService.swift
│   │
│   ├── Theme/
│   │   └── AppTheme.swift
│   │
│   ├── Views/
│   │   ├── LaunchScreenView.swift
│   │   ├── OnboardingView.swift
│   │   ├── AlbumsGridView.swift
│   │   ├── AlbumDetailView.swift
│   │   ├── MediaGridView.swift
│   │   ├── GroupMediaDetailView.swift
│   │   ├── RecentlyDeletedView.swift
│   │   └── Components/
│   │
│   └── Assets.xcassets/
│
├── assets/
│   └── app_icon.png
├── Tidy Media.xcodeproj
├── LICENSE
└── README.md
```

---

## 🚀 Getting Started

### Requirements
- macOS
- Xcode 15.0+
- iOS 17.0+
- A physical iPhone is recommended for testing the Photos library and deletion flow.

### Installation
```bash
git clone https://github.com/ShivamSingh321GO/Tidy-Media.git
cd Tidy-Media
```

Open the Xcode project:
```bash
open "Tidy Media.xcodeproj"
```

Select the **Tidy Media** scheme and run it on an iOS Simulator or connected iPhone.

### Photos Permission
On first launch, allow Photos access when prompted. For complete gallery testing, use **Full Access**.

---

## 🧪 Testing

The app should be tested with:
- Small photo libraries.
- Large photo libraries containing thousands of assets.
- Many screenshots.
- Multiple duplicate photo groups.
- Multiple similar-photo groups.
- Large video files.
- Duplicate videos.
- Limited Photos access.
- Full Photos access.
- Deletion and cancellation flows.

Performance should be monitored to ensure scanning and media loading do not freeze the UI.

---

## 🎨 Design

Tidy Media follows a native iOS visual approach using SwiftUI.

The design focuses on:
- Simple navigation.
- Clear category-based organization.
- Native iOS components.
- Smooth scrolling.
- Clear selection states.
- Lightweight onboarding.
- Light and Dark Mode support.
- Consistent brand accent color.

### Brand Color
- **Primary Accent**: `#2879E7`

---

## 📋 Assignment Scope

The application was developed as an iOS Gallery Cleaner task with the following required categories:
- Screenshots
- Videos
- Duplicate Photos
- Similar Photos
- Duplicate Videos
- Large Videos

The primary focus is efficient media loading, responsive UI, accurate categorization, and safe media management.
