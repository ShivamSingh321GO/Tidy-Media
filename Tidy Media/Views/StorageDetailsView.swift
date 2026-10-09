//
//  StorageDetailsView.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/7/26.
//

import SwiftUI
import Photos

// MARK: - Sunburst Sector Slice Data
private struct SunburstSlice: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let bytes: Int64
    let ratio: Double
    let startAngle: Double
    let endAngle: Double
    let color: Color
    let parentCategory: String
    let isOuter: Bool
    
    var midAngle: Double {
        (startAngle + endAngle) / 2.0
    }
}

// MARK: - Sunburst Multi-Layer Spherical Donut Pie Chart (Image Reference 3)
struct SunburstStoragePieView: View {
    let breakdown: StorageCategoryBreakdown
    @Binding var selectedSliceName: String?
    var chartSize: CGFloat = 240
    
    @State private var animatedProgress: CGFloat = 0.0
    
    private var totalBytes: Double {
        Double(max(1, breakdown.totalMediaBytes))
    }
    
    // Percentage of total device hardware storage occupied by media
    private var mediaPercentOfDevice: Int {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory())
        var devBytes: Int64 = 128_000_000_000
        if let values = try? fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey]),
           let cap = values.volumeTotalCapacity {
            devBytes = Int64(cap)
        } else if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
                  let sz = attrs[.systemSize] as? Int64 {
            devBytes = sz
        }
        let percent = Int(round((Double(breakdown.totalMediaBytes) / Double(max(1, devBytes))) * 100))
        return max(1, min(100, percent))
    }
    
    // Inner Ring: 4 Main Categories (Photos, Videos, Duplicates, Screenshots)
    private var innerSlices: [SunburstSlice] {
        let categories: [(name: String, bytes: Int64, color: Color)] = [
            ("Photos", breakdown.photosBytes, Color(red: 0.10, green: 0.72, blue: 0.48)),
            ("Videos", breakdown.videosBytes, Color(red: 0.14, green: 0.44, blue: 0.96)),
            ("Duplicates", max(1, breakdown.recoverableBytes), Color(red: 0.95, green: 0.28, blue: 0.42)),
            ("Screenshots", breakdown.screenshotsBytes, Color(red: 0.98, green: 0.60, blue: 0.15))
        ]
        
        var slices: [SunburstSlice] = []
        var currentAngle: Double = -90.0
        let gap: Double = 2.0
        
        for item in categories {
            let r = max(0.04, Double(item.bytes) / totalBytes)
            let span = r * 360.0
            let start = currentAngle
            let end = start + max(1.0, span - gap)
            
            slices.append(SunburstSlice(
                name: item.name,
                bytes: item.bytes,
                ratio: r,
                startAngle: start,
                endAngle: end,
                color: item.color,
                parentCategory: item.name,
                isOuter: false
            ))
            currentAngle += span
        }
        return slices
    }
    
    // Outer Ring: Subcategory Detailed Slices (Matching Image 3)
    private var outerSlices: [SunburstSlice] {
        var slices: [SunburstSlice] = []
        let gap: Double = 1.8
        
        for inner in innerSlices {
            let parentSpan = (inner.endAngle - inner.startAngle) + 2.0
            
            switch inner.name {
            case "Photos":
                let favEstBytes = Int64(breakdown.photosCount > 0 ? (breakdown.photosBytes / Int64(breakdown.photosCount)) * 12 : 0)
                let camBytes = max(1, breakdown.photosBytes - favEstBytes)
                
                let subItems: [(name: String, bytes: Int64, color: Color)] = [
                    ("Camera Photos", camBytes, Color(red: 0.05, green: 0.80, blue: 0.54)),
                    ("Favorites", max(1, favEstBytes), Color(red: 0.35, green: 0.88, blue: 0.68))
                ]
                var subStart = inner.startAngle
                for sub in subItems {
                    let subRatio = Double(sub.bytes) / Double(max(1, breakdown.photosBytes))
                    let span = subRatio * parentSpan
                    slices.append(SunburstSlice(
                        name: sub.name,
                        bytes: sub.bytes,
                        ratio: subRatio,
                        startAngle: subStart,
                        endAngle: subStart + max(1.0, span - gap),
                        color: sub.color,
                        parentCategory: "Photos",
                        isOuter: true
                    ))
                    subStart += span
                }
                
            case "Videos":
                let largeBytes = Int64(Double(breakdown.videosBytes) * 0.45)
                let standardBytes = max(1, breakdown.videosBytes - largeBytes)
                
                let subItems: [(name: String, bytes: Int64, color: Color)] = [
                    ("Large 4K Videos", largeBytes, Color(red: 0.10, green: 0.35, blue: 0.90)),
                    ("Standard Clips", standardBytes, Color(red: 0.35, green: 0.60, blue: 1.0))
                ]
                var subStart = inner.startAngle
                for sub in subItems {
                    let subRatio = Double(sub.bytes) / Double(max(1, breakdown.videosBytes))
                    let span = subRatio * parentSpan
                    slices.append(SunburstSlice(
                        name: sub.name,
                        bytes: sub.bytes,
                        ratio: subRatio,
                        startAngle: subStart,
                        endAngle: subStart + max(1.0, span - gap),
                        color: sub.color,
                        parentCategory: "Videos",
                        isOuter: true
                    ))
                    subStart += span
                }
                
            case "Duplicates":
                let dupPhotoBytes = max(1, breakdown.duplicatePhotosBytes)
                let dupVideoBytes = max(1, breakdown.duplicateVideosBytes)
                let totalDup = max(1, dupPhotoBytes + dupVideoBytes)
                
                let subItems: [(name: String, bytes: Int64, color: Color)] = [
                    ("Duplicate Photos", dupPhotoBytes, Color(red: 0.90, green: 0.20, blue: 0.38)),
                    ("Duplicate Videos", dupVideoBytes, Color(red: 1.0, green: 0.48, blue: 0.60))
                ]
                var subStart = inner.startAngle
                for sub in subItems {
                    let subRatio = Double(sub.bytes) / Double(totalDup)
                    let span = subRatio * parentSpan
                    slices.append(SunburstSlice(
                        name: sub.name,
                        bytes: sub.bytes,
                        ratio: subRatio,
                        startAngle: subStart,
                        endAngle: subStart + max(1.0, span - gap),
                        color: sub.color,
                        parentCategory: "Duplicates",
                        isOuter: true
                    ))
                    subStart += span
                }
                
            case "Screenshots":
                slices.append(SunburstSlice(
                    name: "Screenshots",
                    bytes: breakdown.screenshotsBytes,
                    ratio: 1.0,
                    startAngle: inner.startAngle,
                    endAngle: inner.endAngle,
                    color: Color(red: 1.0, green: 0.72, blue: 0.28),
                    parentCategory: "Screenshots",
                    isOuter: true
                ))
                
            default:
                break
            }
        }
        return slices
    }
    
    // Currently active selected slice for dynamic center display
    private var activeSlice: SunburstSlice? {
        guard let name = selectedSliceName else { return nil }
        return (outerSlices + innerSlices).first(where: { $0.name == name })
    }
    
    var body: some View {
        ZStack {
            // MARK: - 1. Outer Ring (Subcategory Slices)
            ForEach(outerSlices) { slice in
                sliceView(slice: slice, innerR: chartSize * 0.36, outerR: chartSize * 0.49)
            }
            
            // MARK: - 2. Inner Ring (Main Categories Slices)
            ForEach(innerSlices) { slice in
                sliceView(slice: slice, innerR: chartSize * 0.23, outerR: chartSize * 0.35)
            }
            
            // MARK: - 3. Center Hole: Dynamic Interactive Content
            ZStack {
                Circle()
                    .fill(Color(uiColor: .systemBackground))
                    .frame(width: chartSize * 0.42, height: chartSize * 0.42)
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)
                    .onTapGesture {
                        if selectedSliceName != nil {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedSliceName = nil
                            }
                        }
                    }
                
                if let slice = activeSlice {
                    // Selected Slice Dynamic View
                    VStack(spacing: 2) {
                        Circle()
                            .fill(slice.color)
                            .frame(width: 8, height: 8)
                        
                        Text(slice.name)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 4)
                        
                        Text(StorageCategoryBreakdown.formatBytes(slice.bytes))
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(slice.color)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        let pct = Int(round((Double(slice.bytes) / totalBytes) * 100))
                        Text("\(pct)% OF MEDIA")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(0.4)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    // Default Overview Center View
                    VStack(spacing: 1) {
                        Text("\(mediaPercentOfDevice)%")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("OF DEVICE")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(0.6)
                        
                        Text(breakdown.formattedTotalSize)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.appAccent)
                            .padding(.top, 1)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(width: chartSize, height: chartSize)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    handleTouch(at: gesture.location)
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.85, dampingFraction: 0.75)) {
                animatedProgress = 1.0
            }
        }
    }
    
    // MARK: - Individual Arc Slice View with Pop-Out & Dimming
    @ViewBuilder
    private func sliceView(slice: SunburstSlice, innerR: CGFloat, outerR: CGFloat) -> some View {
        let isSelected = selectedSliceName == slice.name ||
                         (selectedSliceName == slice.parentCategory && !slice.isOuter)
        let isAnySelected = selectedSliceName != nil
        let opacity = isAnySelected ? (isSelected ? 1.0 : 0.4) : 1.0
        
        // Pop-out radial offset along angle
        let rad = slice.midAngle * .pi / 180.0
        let offsetDist: CGFloat = isSelected ? 5.0 : 0.0
        let offsetX = cos(rad) * offsetDist
        let offsetY = sin(rad) * offsetDist
        
        SunburstArcShape(
            startAngle: .degrees(slice.startAngle),
            endAngle: .degrees(slice.startAngle + (slice.endAngle - slice.startAngle) * animatedProgress),
            innerRadius: innerR,
            outerRadius: outerR
        )
        .fill(slice.color)
        .offset(x: offsetX, y: offsetY)
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .opacity(opacity)
        .shadow(
            color: slice.color.opacity(isSelected ? 0.7 : 0.2),
            radius: isSelected ? 8 : 2,
            x: 0,
            y: isSelected ? 3 : 1
        )
        .animation(.spring(response: 0.32, dampingFraction: 0.72), value: isSelected)
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                if selectedSliceName == slice.name {
                    selectedSliceName = nil
                } else {
                    selectedSliceName = slice.name
                }
            }
        }
    }
    
    // MARK: - Continuous Touch & Drag Resolver
    private func handleTouch(at location: CGPoint) {
        let center = CGPoint(x: chartSize / 2, y: chartSize / 2)
        let dx = location.x - center.x
        let dy = location.y - center.y
        let radius = sqrt(dx*dx + dy*dy)
        
        // Center hole tapped -> reset selection
        if radius < chartSize * 0.22 {
            if selectedSliceName != nil {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                    selectedSliceName = nil
                }
            }
            return
        }
        
        // Outside chart bounds
        guard radius <= chartSize * 0.52 else { return }
        
        // Compute continuous angle starting at top (-90 degrees) to +270 degrees
        var deg = atan2(dy, dx) * 180.0 / .pi
        if deg < -90.0 {
            deg += 360.0
        }
        
        let isOuterRing = radius >= (chartSize * 0.355)
        
        if isOuterRing {
            if let matched = outerSlices.first(where: { deg >= $0.startAngle && deg <= $0.endAngle }) {
                if selectedSliceName != matched.name {
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                        selectedSliceName = matched.name
                    }
                }
            }
        } else {
            if let matched = innerSlices.first(where: { deg >= $0.startAngle && deg <= $0.endAngle }) {
                if selectedSliceName != matched.name {
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                        selectedSliceName = matched.name
                    }
                }
            }
        }
    }
}

// MARK: - Custom Arc Shape for Sunburst Slices
private struct SunburstArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var innerRadius: CGFloat
    var outerRadius: CGFloat
    
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set {
            startAngle = .degrees(newValue.first)
            endAngle = .degrees(newValue.second)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Storage Details Full View (Dedicated Destination)
struct StorageDetailsView: View {
    @ObservedObject var viewModel: MainViewModel
    @ObservedObject private var storageService = StorageCalculatorService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSliceName: String? = nil
    @State private var selectedDestinationAlbum: AlbumItem? = nil
    @State private var showDuplicatesView: Bool = false
    
    // Direct album destinations for instant 1-tap browsing
    private var photosAlbum: AlbumItem {
        AlbumItem(
            id: "camera",
            title: "Photos",
            count: viewModel.photoService.totalPhotosCount,
            keyAsset: viewModel.photoService.cameraKeyAsset,
            systemIcon: "photo.fill",
            gradient: AlbumCategoryType.camera.placeholderGradient,
            isPinned: true,
            belongsToTabs: [.all, .photos],
            categoryType: .camera
        )
    }
    
    private var videosAlbum: AlbumItem {
        AlbumItem(
            id: "videos",
            title: "Videos",
            count: viewModel.photoService.totalVideosCount,
            keyAsset: viewModel.photoService.videosKeyAsset,
            systemIcon: "play.rectangle.fill",
            gradient: AlbumCategoryType.videos.placeholderGradient,
            isPinned: true,
            belongsToTabs: [.all, .videos],
            categoryType: .videos
        )
    }
    
    private var screenshotsAlbum: AlbumItem {
        AlbumItem(
            id: "screenshots",
            title: "Screenshots",
            count: viewModel.photoService.screenshotsCount,
            keyAsset: viewModel.photoService.screenshotsKeyAsset,
            systemIcon: "iphone.gen3",
            gradient: AlbumCategoryType.screenshots.placeholderGradient,
            isPinned: true,
            belongsToTabs: [.all, .photos],
            categoryType: .screenshots
        )
    }
    
    var body: some View {
        let breakdown = storageService.breakdown
        
        ScrollViewReader { scrollProxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: - 1. Top Custom Navigation Bar
                    HStack(alignment: .center) {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            dismiss()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Albums")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(Color.appAccent)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text("Storage Details")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Balance space
                        Color.clear.frame(width: 70, height: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    
                    // MARK: - 2. Spherical Sunburst Donut Pie Chart Card (Image 3)
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("LIBRARY BREAKDOWN")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .tracking(0.6)
                                
                                Text("Capacity Distribution")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            // Device capacity badge
                            Text(StorageCalculatorService.deviceTotalCapacityFormatted)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(Color(uiColor: .tertiarySystemBackground))
                                )
                        }
                        
                        // Touch Instruction or Active Selection Pill
                        if let selected = selectedSliceName {
                            HStack(spacing: 6) {
                                Text("Inspecting: \(selected)")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        selectedSliceName = nil
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(Color(uiColor: .tertiarySystemBackground))
                            )
                            .transition(.scale.combined(with: .opacity))
                        } else {
                            Text("Touch or drag slices to inspect")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary.opacity(0.8))
                                .transition(.opacity)
                        }
                        
                        // Interactive Sunburst Multi-Layer Pie Chart
                        SunburstStoragePieView(
                            breakdown: breakdown,
                            selectedSliceName: $selectedSliceName,
                            chartSize: 230
                        )
                        .padding(.vertical, 6)
                        
                        // Radial Callout Badges (Exact Callouts from Image 3, Tappable & Scrolls to Category)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            calloutBadge(
                                title: "Photos",
                                ratioText: ratioString(bytes: breakdown.photosBytes),
                                color: Color(red: 0.10, green: 0.72, blue: 0.48),
                                isSelected: selectedSliceName == "Photos" || selectedSliceName?.contains("Photo") == true,
                                onTap: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        selectedSliceName = "Photos"
                                        scrollProxy.scrollTo("card_photos", anchor: .top)
                                    }
                                }
                            )
                            calloutBadge(
                                title: "Videos",
                                ratioText: ratioString(bytes: breakdown.videosBytes),
                                color: Color(red: 0.14, green: 0.44, blue: 0.96),
                                isSelected: selectedSliceName == "Videos" || selectedSliceName?.contains("Video") == true,
                                onTap: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        selectedSliceName = "Videos"
                                        scrollProxy.scrollTo("card_videos", anchor: .top)
                                    }
                                }
                            )
                            calloutBadge(
                                title: "Duplicates",
                                ratioText: ratioString(bytes: breakdown.recoverableBytes),
                                color: Color(red: 0.95, green: 0.28, blue: 0.42),
                                isSelected: selectedSliceName == "Duplicates" || selectedSliceName?.contains("Duplicate") == true,
                                onTap: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        selectedSliceName = "Duplicates"
                                        scrollProxy.scrollTo("card_duplicates", anchor: .top)
                                    }
                                }
                            )
                            calloutBadge(
                                title: "Screenshots",
                                ratioText: ratioString(bytes: breakdown.screenshotsBytes),
                                color: Color(red: 0.98, green: 0.60, blue: 0.15),
                                isSelected: selectedSliceName == "Screenshots",
                                onTap: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        selectedSliceName = "Screenshots"
                                        scrollProxy.scrollTo("card_screenshots", anchor: .top)
                                    }
                                }
                            )
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 0.8)
                    )
                    .padding(.horizontal, 16)
                    
                    // MARK: - 3. Detailed Category Cards
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Category Details")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                        
                        // A. Photos Detailed Card
                        detailedCategoryCard(
                            icon: "photo.fill",
                            iconColor: Color(red: 0.10, green: 0.72, blue: 0.48),
                            title: "Photos & Images",
                            totalSize: breakdown.formattedPhotosSize,
                            totalCount: "\(breakdown.photosCount) items",
                            subItems: [
                                ("Camera Roll Photos", "\(max(0, breakdown.photosCount - breakdown.screenshotsCount)) items"),
                                ("Favorite Photos", "\(viewModel.photoService.favoritesCount) items")
                            ],
                            actionTitle: "Browse Photos",
                            action: {
                                selectedDestinationAlbum = photosAlbum
                            }
                        )
                        .id("card_photos")
                        
                        // B. Videos Detailed Card
                        detailedCategoryCard(
                            icon: "play.rectangle.fill",
                            iconColor: Color(red: 0.14, green: 0.44, blue: 0.96),
                            title: "Videos & Recordings",
                            totalSize: breakdown.formattedVideosSize,
                            totalCount: "\(breakdown.videosCount) clips",
                            subItems: [
                                ("Total Video Library", "\(breakdown.videosCount) video assets"),
                                ("Space Occupied", breakdown.formattedVideosSize)
                            ],
                            actionTitle: "Browse Videos",
                            action: {
                                selectedDestinationAlbum = videosAlbum
                            }
                        )
                        .id("card_videos")
                        
                        // C. Duplicates / Recoverable Space Detailed Card
                        detailedCategoryCard(
                            icon: "doc.on.doc.fill",
                            iconColor: Color(red: 0.95, green: 0.28, blue: 0.42),
                            title: "Duplicates & Redundant Media",
                            totalSize: breakdown.formattedRecoverableSize,
                            totalCount: "\(breakdown.recoverableCount) redundant copies",
                            subItems: [
                                ("Duplicate Photos", "\(breakdown.duplicatePhotosCount) copies (\(StorageCategoryBreakdown.formatBytes(breakdown.duplicatePhotosBytes)))"),
                                ("Duplicate Videos", "\(breakdown.duplicateVideosCount) copies (\(StorageCategoryBreakdown.formatBytes(breakdown.duplicateVideosBytes)))")
                            ],
                            actionTitle: breakdown.recoverableBytes > 0 ? "Review & Clean Duplicates" : "View Duplicates",
                            isHighlight: breakdown.recoverableBytes > 0,
                            action: {
                                showDuplicatesView = true
                            }
                        )
                        .id("card_duplicates")
                        
                        // D. Screenshots Detailed Card
                        detailedCategoryCard(
                            icon: "iphone.gen3",
                            iconColor: Color(red: 0.98, green: 0.60, blue: 0.15),
                            title: "Screenshots",
                            totalSize: breakdown.formattedScreenshotsSize,
                            totalCount: "\(breakdown.screenshotsCount) screenshots",
                            subItems: [
                                ("Captured Screens", "\(breakdown.screenshotsCount) items"),
                                ("Storage Consumed", breakdown.formattedScreenshotsSize)
                            ],
                            actionTitle: "Open Screenshots",
                            action: {
                                selectedDestinationAlbum = screenshotsAlbum
                            }
                        )
                        .id("card_screenshots")
                    }
                    
                    Spacer(minLength: 60)
                }
                .padding(.bottom, 24)
            }
            .navigationDestination(item: $selectedDestinationAlbum) { album in
                AlbumDetailView(album: album, photoService: viewModel.photoService)
                    .navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $showDuplicatesView) {
                StorageDuplicatesDetailView(viewModel: viewModel)
                    .navigationBarBackButtonHidden(true)
            }
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }
    
    // MARK: - Helpers & Subviews
    private func ratioString(bytes: Int64) -> String {
        let total = max(1, storageService.breakdown.totalMediaBytes)
        let percent = Int(round((Double(bytes) / Double(total)) * 100))
        return "\(percent)%"
    }
    
    @ViewBuilder
    private func calloutBadge(
        title: String,
        ratioText: String,
        color: Color,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(ratioText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func detailedCategoryCard(
        icon: String,
        iconColor: Color,
        title: String,
        totalSize: String,
        totalCount: String,
        subItems: [(String, String)],
        actionTitle: String,
        isHighlight: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Row
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.16))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("\(totalCount) • \(totalSize)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(totalSize)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(isHighlight ? iconColor : .primary)
            }
            
            Divider()
                .opacity(0.5)
            
            // Sub-breakdown rows
            VStack(spacing: 6) {
                ForEach(0..<subItems.count, id: \.self) { i in
                    let item = subItems[i]
                    HStack {
                        Text(item.0)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(item.1)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // Action Button
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                action()
            } label: {
                HStack {
                    Text(actionTitle)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(isHighlight ? .white : Color.appAccent)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isHighlight ? iconColor : Color.appAccent.opacity(0.12))
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isHighlight ? iconColor.opacity(0.35) : Color.primary.opacity(0.06), lineWidth: isHighlight ? 1.0 : 0.8)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Storage Duplicates Detail View
struct StorageDuplicatesDetailView: View {
    @ObservedObject var viewModel: MainViewModel
    @ObservedObject private var scannerService = MediaScannerService.shared
    @ObservedObject private var photoService = PhotoLibraryService.shared
    @ObservedObject private var storageService = StorageCalculatorService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMediaKind: DuplicateMediaKind = .photos
    @State private var viewerIndex: Int? = nil
    @State private var viewerFetchResult: PHFetchResult<PHAsset>? = nil
    @State private var showConfirmDeleteAll: Bool = false
    @State private var isDeleting: Bool = false
    
    enum DuplicateMediaKind: String, CaseIterable, Identifiable {
        case photos = "Photos"
        case videos = "Videos"
        var id: String { rawValue }
    }
    
    private var photoDuplicateCount: Int {
        scannerService.duplicateGroups.reduce(0) { $0 + $1.duplicateAssets.count }
    }
    
    private var videoDuplicateCount: Int {
        scannerService.duplicateVideoGroups.reduce(0) { $0 + $1.duplicateAssets.count }
    }
    
    private var currentTotalDuplicates: Int {
        selectedMediaKind == .photos ? photoDuplicateCount : videoDuplicateCount
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Custom Navigation Bar
                HStack(spacing: 12) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Storage")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(Color.appAccent)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text("Duplicate Media")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        triggerRescan()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.appAccent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Summary Banner Card
                        summaryBannerCard
                        
                        // Segmented Picker (Photos vs Videos)
                        Picker("Category", selection: $selectedMediaKind) {
                            Text("Photos (\(photoDuplicateCount))").tag(DuplicateMediaKind.photos)
                            Text("Videos (\(videoDuplicateCount))").tag(DuplicateMediaKind.videos)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        
                        // Content based on selection
                        if selectedMediaKind == .photos {
                            photoDuplicatesSection
                        } else {
                            videoDuplicatesSection
                        }
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.top, 4)
                }
            }
            
            // Bottom Sticky Clean All Button (if duplicates exist)
            if currentTotalDuplicates > 0 {
                bottomActionBar
            }
            
            // Fullscreen viewer overlay
            if let index = viewerIndex, let results = viewerFetchResult, results.count > 0 {
                FullScreenMediaView(
                    fetchResult: results,
                    initialIndex: index,
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewerIndex = nil
                            viewerFetchResult = nil
                        }
                    },
                    onDelete: {
                        triggerRescan()
                    },
                    photoService: photoService
                )
                .id("dup_viewer_\(index)_\(results.count)")
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .task {
            triggerInitialScanIfNeeded()
        }
    }
    
    // MARK: - Summary Banner Card
    private var summaryBannerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("RECOVERABLE STORAGE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(0.5)
                    
                    Text(storageService.breakdown.formattedRecoverableSize)
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Text("Keep the original best shot and safely remove redundant copies to reclaim device storage.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(2)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.98, green: 0.45, blue: 0.58)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Photo Duplicates Section
    @ViewBuilder
    private var photoDuplicatesSection: some View {
        if scannerService.isScanningDuplicates && scannerService.duplicateGroups.isEmpty {
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.top, 40)
                Text("Analyzing photo library for duplicates...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        } else if scannerService.duplicateGroups.isEmpty {
            emptyStateView(message: "No Duplicate Photos Found", subtitle: "Every photo in your camera roll is unique!")
        } else {
            VStack(spacing: 16) {
                ForEach(scannerService.duplicateGroups) { group in
                    duplicatePhotoGroupCard(group: group)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Video Duplicates Section
    @ViewBuilder
    private var videoDuplicatesSection: some View {
        if scannerService.isScanningDuplicateVideos && scannerService.duplicateVideoGroups.isEmpty {
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.top, 40)
                Text("Scanning video clips for redundant copies...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        } else if scannerService.duplicateVideoGroups.isEmpty {
            emptyStateView(message: "No Duplicate Videos Found", subtitle: "All videos in your gallery are unique copies.")
        } else {
            VStack(spacing: 16) {
                ForEach(scannerService.duplicateVideoGroups) { group in
                    duplicateVideoGroupCard(group: group)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Duplicate Photo Group Card
    @ViewBuilder
    private func duplicatePhotoGroupCard(group: DuplicatePhotoGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if let date = group.assets.first?.creationDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(group.assets.count) Copies")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.95, green: 0.28, blue: 0.42))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(Color(red: 0.95, green: 0.28, blue: 0.42).opacity(0.12))
                    )
            }
            
            // Thumbnails Grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: min(group.assets.count, 4))
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<group.assets.count, id: \.self) { idx in
                    let asset = group.assets[idx]
                    let isKeep = asset.localIdentifier == group.keepAssetId
                    
                    ZStack(alignment: .bottomTrailing) {
                        MediaGridThumbnailCell(
                            asset: asset,
                            isSelectMode: false,
                            isSelected: false,
                            photoService: photoService
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        
                        // Badge: KEEP or DUPLICATE
                        HStack(spacing: 2) {
                            Image(systemName: isKeep ? "star.fill" : "trash.fill")
                                .font(.system(size: 7, weight: .bold))
                            Text(isKeep ? "KEEP" : "DELETE")
                                .font(.system(size: 8, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2.5)
                        .background(
                            Capsule().fill(isKeep ? Color.green : Color.red.opacity(0.9))
                        )
                        .padding(4)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        openGroupInViewer(assets: group.assets, selectedIndex: idx)
                    }
                }
            }
            
            // Delete Group Redundant Copies Action
            if !group.duplicateAssets.isEmpty {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    deletePhotoGroupDuplicates(group)
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Delete \(group.duplicateAssets.count) Duplicate \(group.duplicateAssets.count == 1 ? "Copy" : "Copies")")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(Color(red: 0.95, green: 0.28, blue: 0.42))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(red: 0.95, green: 0.28, blue: 0.42).opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
    
    // MARK: - Duplicate Video Group Card
    @ViewBuilder
    private func duplicateVideoGroupCard(group: DuplicateVideoGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Video Duplicates")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(group.assets.count) Clips")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.14, green: 0.44, blue: 0.96))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(Color(red: 0.14, green: 0.44, blue: 0.96).opacity(0.12))
                    )
            }
            
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: min(group.assets.count, 4))
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<group.assets.count, id: \.self) { idx in
                    let asset = group.assets[idx]
                    let isKeep = asset.localIdentifier == group.keepAssetId
                    
                    ZStack(alignment: .bottomTrailing) {
                        MediaGridThumbnailCell(
                            asset: asset,
                            isSelectMode: false,
                            isSelected: false,
                            photoService: photoService
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        
                        HStack(spacing: 2) {
                            Text(isKeep ? "KEEP" : "DELETE")
                                .font(.system(size: 8, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2.5)
                        .background(
                            Capsule().fill(isKeep ? Color.green : Color.red.opacity(0.9))
                        )
                        .padding(4)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        openGroupInViewer(assets: group.assets, selectedIndex: idx)
                    }
                }
            }
            
            if !group.duplicateAssets.isEmpty {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    deleteVideoGroupDuplicates(group)
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Delete \(group.duplicateAssets.count) Duplicate Video")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(Color(red: 0.95, green: 0.28, blue: 0.42))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(red: 0.95, green: 0.28, blue: 0.42).opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
    
    // MARK: - Empty State View
    private func emptyStateView(message: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
                .padding(.top, 40)
            
            Text(message)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Bottom Floating Clean All Action Bar
    private var bottomActionBar: some View {
        VStack {
            Button {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                deleteAllDuplicatesInCurrentTab()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text("Delete All \(currentTotalDuplicates) Duplicates")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(red: 0.95, green: 0.25, blue: 0.42))
                )
                .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            LinearGradient(
                colors: [Color(uiColor: .systemBackground).opacity(0.0), Color(uiColor: .systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Actions & Logic
    private func openGroupInViewer(assets: [PHAsset], selectedIndex: Int) {
        let fetch = PHAsset.fetchAssets(withLocalIdentifiers: assets.map(\.localIdentifier), options: nil)
        self.viewerFetchResult = fetch
        self.viewerIndex = selectedIndex
    }
    
    private func deletePhotoGroupDuplicates(_ group: DuplicatePhotoGroup) {
        let targets = group.duplicateAssets
        guard !targets.isEmpty else { return }
        Task {
            do {
                try await photoService.deleteAssets(targets)
                await reloadStatsAndScans()
            } catch {
                print("Failed to delete duplicates: \(error)")
            }
        }
    }
    
    private func deleteVideoGroupDuplicates(_ group: DuplicateVideoGroup) {
        let targets = group.duplicateAssets
        guard !targets.isEmpty else { return }
        Task {
            do {
                try await photoService.deleteAssets(targets)
                await reloadStatsAndScans()
            } catch {
                print("Failed to delete duplicate videos: \(error)")
            }
        }
    }
    
    private func deleteAllDuplicatesInCurrentTab() {
        let targets: [PHAsset]
        if selectedMediaKind == .photos {
            targets = scannerService.duplicateGroups.flatMap { $0.duplicateAssets }
        } else {
            targets = scannerService.duplicateVideoGroups.flatMap { $0.duplicateAssets }
        }
        guard !targets.isEmpty else { return }
        Task {
            do {
                try await photoService.deleteAssets(targets)
                await reloadStatsAndScans()
            } catch {
                print("Failed to delete all duplicates: \(error)")
            }
        }
    }
    
    private func reloadStatsAndScans() async {
        photoService.loadLibraryStats()
        storageService.recalculate(force: true)
        
        let photoFetch = photoService.fetchAllPhotos()
        var pList: [PHAsset] = []
        for i in 0..<photoFetch.count { pList.append(photoFetch.object(at: i)) }
        await scannerService.scanDuplicatePhotos(from: pList)
        
        let videoFetch = photoService.fetchAllVideos()
        var vList: [PHAsset] = []
        for i in 0..<videoFetch.count { vList.append(videoFetch.object(at: i)) }
        await scannerService.scanDuplicateVideos(from: vList)
    }
    
    private func triggerRescan() {
        Task {
            await reloadStatsAndScans()
        }
    }
    
    private func triggerInitialScanIfNeeded() {
        Task {
            if scannerService.duplicateGroups.isEmpty && !scannerService.isScanningDuplicates {
                let fetch = photoService.fetchAllPhotos()
                var list: [PHAsset] = []
                for i in 0..<fetch.count { list.append(fetch.object(at: i)) }
                await scannerService.scanDuplicatePhotos(from: list)
            }
            if scannerService.duplicateVideoGroups.isEmpty && !scannerService.isScanningDuplicateVideos {
                let fetch = photoService.fetchAllVideos()
                var list: [PHAsset] = []
                for i in 0..<fetch.count { list.append(fetch.object(at: i)) }
                await scannerService.scanDuplicateVideos(from: list)
            }
        }
    }
}
