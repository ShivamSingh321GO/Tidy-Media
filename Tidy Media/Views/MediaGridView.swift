//
//  MediaGridView.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/5/26.
//

import SwiftUI
import Photos

struct MediaGridView: View {
    let mediaTab: MediaTab
    @ObservedObject var photoService: PhotoLibraryService
    @ObservedObject var viewModel: MainViewModel
    @StateObject private var scannerService = MediaScannerService.shared
    
    // Grid & Filter State
    @State private var fetchResult: PHFetchResult<PHAsset>? = nil
    @State private var selectedFilter: PhotoFilterOption = .all
    @State private var selectedVideoFilter: VideoFilterOption = .all
    @State private var isSelectMode: Bool = false
    @State private var selectedAssetIds: Set<String> = []
    
    // Fullscreen Viewer State
    @State private var viewerFetchResult: PHFetchResult<PHAsset>? = nil
    @State private var viewerIndex: Int? = nil
    @State private var viewerSessionId: UUID = UUID()
    @State private var showDeleteAlert: Bool = false
    @State private var selectedGroupDetail: GroupDetailItem? = nil
    
    // 3-Column Square Grid matching Apple Photos
    private let columns = [
        GridItem(.flexible(), spacing: 5),
        GridItem(.flexible(), spacing: 5),
        GridItem(.flexible(), spacing: 5)
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Top Header (Title + Count + Filter + Select + Options)
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(headerTitle)
                            .font(.system(size: 34, weight: .bold, design: .serif))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        Text(headerSubtitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Filter Menu Button (For Photos & Videos Tabs)
                    if mediaTab == .photos {
                        Menu {
                            ForEach(PhotoFilterOption.allCases) { option in
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedFilter = option
                                        viewModel.activePhotoFilter = option
                                        if option == .all {
                                            selectedAssetIds.removeAll()
                                            isSelectMode = false
                                        }
                                    }
                                    handleFilterTrigger(option)
                                } label: {
                                    Label(option.rawValue, systemImage: option.iconName)
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selectedFilter == .all ? .primary : Color.appAccent)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(selectedFilter == .all ? Color(uiColor: .secondarySystemBackground) : Color.appAccent.opacity(0.18))
                                )
                        }
                        .buttonStyle(.plain)
                    } else if mediaTab == .videos {
                        Menu {
                            ForEach(VideoFilterOption.allCases) { option in
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedVideoFilter = option
                                        viewModel.activeVideoFilter = option
                                        if option == .all {
                                            selectedAssetIds.removeAll()
                                            isSelectMode = false
                                        }
                                    }
                                    handleVideoFilterTrigger(option)
                                } label: {
                                    Label(option.rawValue, systemImage: option.iconName)
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selectedVideoFilter == .all ? .primary : Color.appAccent)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(selectedVideoFilter == .all ? Color(uiColor: .secondarySystemBackground) : Color.appAccent.opacity(0.18))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Pill Select / Done Button
                    if canShowSelectButton {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSelectMode.toggle()
                                if !isSelectMode {
                                    selectedAssetIds.removeAll()
                                }
                            }
                        } label: {
                            Text(isSelectMode ? "Done" : "Select")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(Color(uiColor: .secondarySystemBackground))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // MARK: - Main Content: Standard Grid vs Filter Results
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        if mediaTab == .photos && selectedFilter == .duplicates {
                            duplicateContentView
                        } else if mediaTab == .photos && selectedFilter == .similar {
                            similarContentView
                        } else if mediaTab == .videos && selectedVideoFilter == .large {
                            largeVideosContentView
                        } else if mediaTab == .videos && selectedVideoFilter == .duplicates {
                            duplicateVideosContentView
                        } else {
                            standardGridView
                        }
                    }
                    .padding(.bottom, 120) // Extra padding for the floating bottom bar
                }
                .scrollDismissesKeyboard(.interactively)
                .refreshable {
                    loadAssets()
                    if mediaTab == .photos {
                        if selectedFilter == .duplicates {
                            Task { await scannerService.scanDuplicatePhotos(from: allCurrentAssets) }
                        } else if selectedFilter == .similar {
                            Task { await scannerService.scanSimilarPhotos(from: allCurrentAssets) }
                        }
                    } else {
                        if selectedVideoFilter == .duplicates {
                            Task { await scannerService.scanDuplicateVideos(from: allCurrentAssets) }
                        } else if selectedVideoFilter == .large {
                            Task { await scannerService.scanLargeVideos(from: allCurrentAssets) }
                        }
                    }
                }
            }
            
            // MARK: - Batch Action Bar (When in Select Mode or Photos Selected)
            if isSelectMode || !selectedAssetIds.isEmpty {
                HStack {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if selectedAssetIds.count == selectableCount {
                            selectedAssetIds.removeAll()
                        } else {
                            selectAllCurrentAssets()
                        }
                    } label: {
                        Text(selectedAssetIds.count == selectableCount && selectableCount > 0 ? "Deselect All" : "Select All")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color.appAccent)
                    }
                    
                    Spacer()
                    
                    Text("\(selectedAssetIds.count) Selected")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button {
                        guard !selectedAssetIds.isEmpty else { return }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(selectedAssetIds.isEmpty ? .gray : .red)
                    }
                    .disabled(selectedAssetIds.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 90)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // MARK: - Fullscreen Photo/Video Viewer Overlay
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
                        loadAssets()
                        handleFilterTrigger(selectedFilter)
                    },
                    photoService: photoService
                )
                .id(viewerSessionId)
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .confirmationDialog(
            "Delete \(selectedAssetIds.count) Items?",
            isPresented: $showDeleteAlert,
            titleVisibility: .visible
        ) {
            Button("Delete from Library", role: .destructive) {
                deleteSelected()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("These items will be permanently removed from your Photos library.")
        }
        .navigationDestination(item: $selectedGroupDetail) { item in
            GroupMediaDetailView(
                groupItem: item,
                photoService: photoService,
                onUpdate: {
                    loadAssets()
                    handleFilterTrigger(selectedFilter)
                }
            )
            .navigationBarBackButtonHidden(true)
        }
        .onChange(of: viewerIndex) { _, newIndex in
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.isFullScreenViewerOpen = newIndex != nil
            }
        }
        .task(id: mediaTab) {
            loadAssets()
            if mediaTab == .photos {
                if viewModel.activePhotoFilter != selectedFilter {
                    selectedFilter = viewModel.activePhotoFilter
                }
                if selectedFilter != .all {
                    handleFilterTrigger(selectedFilter)
                }
            } else if mediaTab == .videos {
                if viewModel.activeVideoFilter != selectedVideoFilter {
                    selectedVideoFilter = viewModel.activeVideoFilter
                }
                if selectedVideoFilter != .all {
                    handleVideoFilterTrigger(selectedVideoFilter)
                }
            }
        }
        .onChange(of: viewModel.activePhotoFilter) { _, newFilter in
            if mediaTab == .photos && selectedFilter != newFilter {
                selectedFilter = newFilter
                handleFilterTrigger(newFilter)
            }
        }
        .onChange(of: viewModel.activeVideoFilter) { _, newFilter in
            if mediaTab == .videos && selectedVideoFilter != newFilter {
                selectedVideoFilter = newFilter
                handleVideoFilterTrigger(newFilter)
            }
        }
        .onReceive(photoService.$totalPhotosCount) { _ in
            if mediaTab == .photos {
                loadAssets()
                if selectedFilter != .all {
                    handleFilterTrigger(selectedFilter)
                }
            }
        }
        .onReceive(photoService.$totalVideosCount) { _ in
            if mediaTab == .videos {
                loadAssets()
                if selectedVideoFilter != .all {
                    handleVideoFilterTrigger(selectedVideoFilter)
                }
            }
        }
    }
    
    // MARK: - 1. Standard 3-Column Square Grid
    @ViewBuilder
    private var standardGridView: some View {
        if let results = fetchResult, results.count > 0 {
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(0..<results.count, id: \.self) { index in
                    let asset = results.object(at: index)
                    let isSelected = selectedAssetIds.contains(asset.localIdentifier)
                    
                    MediaGridThumbnailCell(
                        asset: asset,
                        isSelectMode: isSelectMode,
                        isSelected: isSelected,
                        photoService: photoService
                    )
                    .id(asset.localIdentifier)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleAssetTap(asset: asset, index: index, in: results)
                    }
                }
            }
            .padding(.horizontal, 16)
        } else {
            emptyStateView
        }
    }
    
    // MARK: - 2. Duplicate Photos Clustered View
    @ViewBuilder
    private var duplicateContentView: some View {
        if scannerService.isScanningDuplicates && scannerService.duplicateGroups.isEmpty {
            ProgressView()
                .tint(.white)
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
        } else if scannerService.duplicateGroups.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.green)
                    .padding(.top, 50)
                
                Text("No Duplicate Photos Found")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Every photo in your library is a unique copy.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(scannerService.duplicateGroups) { group in
                    let hasMoreThanThree = group.assets.count > 3
                    let displayedAssets = hasMoreThanThree ? Array(group.assets.prefix(3)) : group.assets
                    let groupColumns = Array(
                        repeating: GridItem(.flexible(), spacing: 6),
                        count: min(displayedAssets.count, 3)
                    )
                    
                    VStack(alignment: .leading, spacing: 10) {
                        // Compact Header: Date & Count Badge (with navigation chevron if > 3)
                        HStack(alignment: .center) {
                            if let date = group.assets.first?.creationDate {
                                HStack(spacing: 5) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Text(date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Duplicates")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                if hasMoreThanThree {
                                    openDuplicateGroupDetail(group)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text("\(group.assets.count) Copies")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Color.white.opacity(0.85))
                                    
                                    if hasMoreThanThree {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(hasMoreThanThree ? 0.16 : 0.12))
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!hasMoreThanThree)
                        }
                        .padding(.horizontal, 2)
                        
                        LazyVGrid(columns: groupColumns, spacing: 6) {
                            ForEach(0..<displayedAssets.count, id: \.self) { assetIndex in
                                let asset = displayedAssets[assetIndex]
                                let isKeepOriginal = asset.localIdentifier == group.keepAssetId
                                let isSelected = selectedAssetIds.contains(asset.localIdentifier)
                                let isLastPreview = hasMoreThanThree && assetIndex == 2
                                
                                ZStack(alignment: .bottomTrailing) {
                                    MediaGridThumbnailCell(
                                        asset: asset,
                                        isSelectMode: isSelectMode || !selectedAssetIds.isEmpty,
                                        isSelected: isSelected,
                                        photoService: photoService
                                    )
                                    .id(asset.localIdentifier)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .onTapGesture {
                                        if hasMoreThanThree {
                                            if isSelectMode || !selectedAssetIds.isEmpty {
                                                handleDuplicateAssetTap(asset: asset, group: group)
                                            } else {
                                                openDuplicateGroupDetail(group)
                                            }
                                        } else {
                                            handleDuplicateAssetTap(asset: asset, group: group)
                                        }
                                    }
                                    
                                    // Original "Keep" Tag (Bottom Right)
                                    if isKeepOriginal && !isLastPreview {
                                        Text("KEEP")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(
                                                Capsule().fill(Color.green.opacity(0.85))
                                            )
                                            .padding(6)
                                            .allowsHitTesting(false)
                                    }
                                    
                                    // "+N More" Overlay on 3rd Image when > 3
                                    if isLastPreview {
                                        ZStack {
                                            Color.black.opacity(0.55)
                                            VStack(spacing: 2) {
                                                Text("+\(group.assets.count - 2)")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.white)
                                                Text("More")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.85))
                                            }
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .allowsHitTesting(false)
                                    }
                                }
                            }
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 0.8)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if hasMoreThanThree && !isSelectMode && selectedAssetIds.isEmpty {
                            openDuplicateGroupDetail(group)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
    
    // MARK: - 3. Similar Photos Clustered View
    @ViewBuilder
    private var similarContentView: some View {
        if scannerService.isScanningSimilar && scannerService.similarGroups.isEmpty {
            ProgressView()
                .tint(.white)
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
        } else if scannerService.similarGroups.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 52))
                    .foregroundColor(.yellow)
                    .padding(.top, 50)
                
                Text("No Similar Photos Found")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("No burst shots or near-identical angles detected.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(scannerService.similarGroups) { group in
                    let hasMoreThanThree = group.assets.count > 3
                    let displayedAssets = hasMoreThanThree ? Array(group.assets.prefix(3)) : group.assets
                    let groupColumns = Array(
                        repeating: GridItem(.flexible(), spacing: 6),
                        count: min(displayedAssets.count, 3)
                    )
                    
                    VStack(alignment: .leading, spacing: 10) {
                        // Compact Header: Date & Count Badge (with navigation chevron if > 3)
                        HStack(alignment: .center) {
                            if let date = group.assets.first?.creationDate {
                                HStack(spacing: 5) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Text(date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Similar Shots")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                if hasMoreThanThree {
                                    openSimilarGroupDetail(group)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text("\(group.assets.count) Shots")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Color.white.opacity(0.85))
                                    
                                    if hasMoreThanThree {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(hasMoreThanThree ? 0.16 : 0.12))
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!hasMoreThanThree)
                        }
                        .padding(.horizontal, 2)
                        
                        LazyVGrid(columns: groupColumns, spacing: 6) {
                            ForEach(0..<displayedAssets.count, id: \.self) { assetIndex in
                                let asset = displayedAssets[assetIndex]
                                let isBestShot = asset.localIdentifier == group.bestAssetId
                                let isSelected = selectedAssetIds.contains(asset.localIdentifier)
                                let isLastPreview = hasMoreThanThree && assetIndex == 2
                                
                                ZStack(alignment: .bottomTrailing) {
                                    MediaGridThumbnailCell(
                                        asset: asset,
                                        isSelectMode: isSelectMode || !selectedAssetIds.isEmpty,
                                        isSelected: isSelected,
                                        photoService: photoService
                                    )
                                    .id(asset.localIdentifier)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .onTapGesture {
                                        if hasMoreThanThree {
                                            if isSelectMode || !selectedAssetIds.isEmpty {
                                                handleSimilarAssetTap(asset: asset, group: group)
                                            } else {
                                                openSimilarGroupDetail(group)
                                            }
                                        } else {
                                            handleSimilarAssetTap(asset: asset, group: group)
                                        }
                                    }
                                    
                                    // Best Shot Tag (Bottom Right, Clean Text)
                                    if isBestShot && !isLastPreview {
                                        Text("BEST")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(
                                                Capsule().fill(Color.appAccent.opacity(0.85))
                                            )
                                            .padding(6)
                                            .allowsHitTesting(false)
                                    }
                                    
                                    // "+N More" Overlay on 3rd Image when > 3
                                    if isLastPreview {
                                        ZStack {
                                            Color.black.opacity(0.55)
                                            VStack(spacing: 2) {
                                                Text("+\(group.assets.count - 2)")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.white)
                                                Text("More")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.85))
                                            }
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .allowsHitTesting(false)
                                    }
                                }
                            }
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 0.8)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if hasMoreThanThree && !isSelectMode && selectedAssetIds.isEmpty {
                            openSimilarGroupDetail(group)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
    
    // MARK: - 3. Large Videos Grid View
    @ViewBuilder
    private var largeVideosContentView: some View {
        if scannerService.isScanningLargeVideos {
            VStack(spacing: 16) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                    .padding(.top, 60)
                
                Text("Analyzing video file sizes...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        } else if scannerService.largeVideos.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "externaldrive.badge.checkmark")
                    .font(.system(size: 52))
                    .foregroundColor(.green)
                    .padding(.top, 50)
                
                Text("No Videos Found")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("There are no videos in your library.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        } else {
            // 3-Column Large Videos Grid with File Size Badges
            LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(scannerService.largeVideos) { item in
                        let isSelected = selectedAssetIds.contains(item.id)
                        
                        ZStack(alignment: .topTrailing) {
                            MediaGridThumbnailCell(
                                asset: item.asset,
                                isSelectMode: isSelectMode || !selectedAssetIds.isEmpty,
                                isSelected: isSelected,
                                photoService: photoService
                            )
                            .id(item.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                handleLargeVideoTap(item: item)
                            }
                            
                            // Top Right: Size Pill Badge
                            if !isSelectMode && selectedAssetIds.isEmpty {
                                Text(item.formattedSize)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.72))
                                            .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.5))
                                    )
                                    .padding(5)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
        }
    }
    
    // MARK: - 4. Duplicate Videos Clustered View
    @ViewBuilder
    private var duplicateVideosContentView: some View {
        if scannerService.isScanningDuplicateVideos && scannerService.duplicateVideoGroups.isEmpty {
            ProgressView()
                .tint(.white)
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
        } else if scannerService.duplicateVideoGroups.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.green)
                    .padding(.top, 50)
                
                Text("No Duplicate Videos Found")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Every video in your library is a unique clip.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(scannerService.duplicateVideoGroups) { group in
                    let hasMoreThanThree = group.assets.count > 3
                    let displayedAssets = hasMoreThanThree ? Array(group.assets.prefix(3)) : group.assets
                    let groupColumns = Array(
                        repeating: GridItem(.flexible(), spacing: 6),
                        count: min(displayedAssets.count, 3)
                    )
                    
                    VStack(alignment: .leading, spacing: 10) {
                        // Compact Header: Date & Count Badge (with navigation chevron if > 3)
                        HStack(alignment: .center) {
                            if let date = group.assets.first?.creationDate {
                                HStack(spacing: 5) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Text(date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Duplicates")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                if hasMoreThanThree {
                                    openDuplicateVideoGroupDetail(group)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text("\(group.assets.count) Copies")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Color.white.opacity(0.85))
                                    
                                    if hasMoreThanThree {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(hasMoreThanThree ? 0.16 : 0.12))
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!hasMoreThanThree)
                        }
                        .padding(.horizontal, 2)
                        
                        LazyVGrid(columns: groupColumns, spacing: 6) {
                            ForEach(0..<displayedAssets.count, id: \.self) { assetIndex in
                                let asset = displayedAssets[assetIndex]
                                let isKeepOriginal = asset.localIdentifier == group.keepAssetId
                                let isSelected = selectedAssetIds.contains(asset.localIdentifier)
                                let isLastPreview = hasMoreThanThree && assetIndex == 2
                                
                                ZStack(alignment: .bottomTrailing) {
                                    MediaGridThumbnailCell(
                                        asset: asset,
                                        isSelectMode: isSelectMode || !selectedAssetIds.isEmpty,
                                        isSelected: isSelected,
                                        photoService: photoService
                                    )
                                    .id(asset.localIdentifier)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .onTapGesture {
                                        if hasMoreThanThree {
                                            if isSelectMode || !selectedAssetIds.isEmpty {
                                                handleDuplicateVideoAssetTap(asset: asset, group: group)
                                            } else {
                                                openDuplicateVideoGroupDetail(group)
                                            }
                                        } else {
                                            handleDuplicateVideoAssetTap(asset: asset, group: group)
                                        }
                                    }
                                    
                                    // Original "Keep" Tag (Bottom Right)
                                    if isKeepOriginal && !isLastPreview {
                                        Text("KEEP")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(
                                                Capsule().fill(Color.green.opacity(0.85))
                                            )
                                            .padding(6)
                                            .allowsHitTesting(false)
                                    }
                                    
                                    // "+N More" Overlay on 3rd Video when > 3
                                    if isLastPreview {
                                        ZStack {
                                            Color.black.opacity(0.55)
                                            VStack(spacing: 2) {
                                                Text("+\(group.assets.count - 2)")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.white)
                                                Text("More")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.85))
                                            }
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .allowsHitTesting(false)
                                    }
                                }
                            }
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 0.8)
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: mediaTab == .photos ? "photo.on.rectangle.angled" : "video.badge.plus")
                .font(.system(size: 46, weight: .light))
                .foregroundColor(.gray.opacity(0.45))
            
            Text(mediaTab == .photos ? "No Photos in Library" : "No Videos in Library")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(mediaTab == .photos ? "Photos you take or save will appear here." : "Videos you record or save will appear here.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
    
    // MARK: - Tap Handlers
    private func handleAssetTap(asset: PHAsset, index: Int, in fetchResults: PHFetchResult<PHAsset>) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if isSelectMode {
            if selectedAssetIds.contains(asset.localIdentifier) {
                selectedAssetIds.remove(asset.localIdentifier)
            } else {
                selectedAssetIds.insert(asset.localIdentifier)
            }
        } else {
            var finalIndex = index
            if finalIndex < fetchResults.count && fetchResults.object(at: finalIndex).localIdentifier == asset.localIdentifier {
                // Exact index confirmed
            } else {
                let trueIndex = fetchResults.index(of: asset)
                if trueIndex != NSNotFound && trueIndex < fetchResults.count {
                    finalIndex = trueIndex
                } else {
                    for i in 0..<fetchResults.count {
                        if fetchResults.object(at: i).localIdentifier == asset.localIdentifier {
                            finalIndex = i
                            break
                        }
                    }
                }
            }
            self.viewerFetchResult = fetchResults
            self.viewerSessionId = UUID()
            withAnimation(.easeInOut(duration: 0.22)) {
                self.viewerIndex = finalIndex
            }
        }
    }
    
    private func handleDuplicateAssetTap(asset: PHAsset, group: DuplicatePhotoGroup) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if isSelectMode || !selectedAssetIds.isEmpty {
            if selectedAssetIds.contains(asset.localIdentifier) {
                selectedAssetIds.remove(asset.localIdentifier)
            } else {
                selectedAssetIds.insert(asset.localIdentifier)
            }
        } else {
            // Open group in viewer
            let ids = group.assets.map(\.localIdentifier)
            let groupFetch = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
            var finalIndex = 0
            for i in 0..<groupFetch.count {
                if groupFetch.object(at: i).localIdentifier == asset.localIdentifier {
                    finalIndex = i
                    break
                }
            }
            self.viewerFetchResult = groupFetch
            self.viewerSessionId = UUID()
            withAnimation(.easeInOut(duration: 0.22)) {
                self.viewerIndex = finalIndex
            }
        }
    }
    
    private func handleSimilarAssetTap(asset: PHAsset, group: SimilarPhotoGroup) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if isSelectMode || !selectedAssetIds.isEmpty {
            if selectedAssetIds.contains(asset.localIdentifier) {
                selectedAssetIds.remove(asset.localIdentifier)
            } else {
                selectedAssetIds.insert(asset.localIdentifier)
            }
        } else {
            let ids = group.assets.map(\.localIdentifier)
            let groupFetch = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
            var finalIndex = 0
            for i in 0..<groupFetch.count {
                if groupFetch.object(at: i).localIdentifier == asset.localIdentifier {
                    finalIndex = i
                    break
                }
            }
            self.viewerFetchResult = groupFetch
            self.viewerSessionId = UUID()
            withAnimation(.easeInOut(duration: 0.22)) {
                self.viewerIndex = finalIndex
            }
        }
    }
    
    private func openDuplicateGroupDetail(_ group: DuplicatePhotoGroup) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        self.selectedGroupDetail = GroupDetailItem(
            id: group.id,
            title: "Exact Duplicates",
            subtitle: "\(group.assets.count) Identical Copies",
            filterType: .duplicates,
            initialAssets: group.assets,
            keepOrBestAssetId: group.keepAssetId,
            creationDate: group.assets.first?.creationDate
        )
    }
    
    private func openSimilarGroupDetail(_ group: SimilarPhotoGroup) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        self.selectedGroupDetail = GroupDetailItem(
            id: group.id,
            title: "Similar Shots",
            subtitle: "\(group.assets.count) Similar Photos",
            filterType: .similar,
            initialAssets: group.assets,
            keepOrBestAssetId: group.bestAssetId,
            creationDate: group.assets.first?.creationDate
        )
    }
    
    private func openDuplicateVideoGroupDetail(_ group: DuplicateVideoGroup) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        self.selectedGroupDetail = GroupDetailItem(
            id: group.id,
            title: "Exact Duplicates",
            subtitle: "\(group.assets.count) Identical Videos",
            filterType: .duplicates,
            initialAssets: group.assets,
            keepOrBestAssetId: group.keepAssetId,
            creationDate: group.assets.first?.creationDate
        )
    }
    
    private func handleLargeVideoTap(item: LargeVideoItem) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if isSelectMode || !selectedAssetIds.isEmpty {
            if selectedAssetIds.contains(item.id) {
                selectedAssetIds.remove(item.id)
            } else {
                selectedAssetIds.insert(item.id)
            }
        } else {
            let ids = scannerService.largeVideos.map(\.id)
            let groupFetch = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
            var finalIndex = 0
            for i in 0..<groupFetch.count {
                if groupFetch.object(at: i).localIdentifier == item.id {
                    finalIndex = i
                    break
                }
            }
            self.viewerFetchResult = groupFetch
            self.viewerSessionId = UUID()
            withAnimation(.easeInOut(duration: 0.22)) {
                self.viewerIndex = finalIndex
            }
        }
    }
    
    private func handleDuplicateVideoAssetTap(asset: PHAsset, group: DuplicateVideoGroup) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if isSelectMode || !selectedAssetIds.isEmpty {
            if selectedAssetIds.contains(asset.localIdentifier) {
                selectedAssetIds.remove(asset.localIdentifier)
            } else {
                selectedAssetIds.insert(asset.localIdentifier)
            }
        } else {
            let ids = group.assets.map(\.localIdentifier)
            let groupFetch = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
            var finalIndex = 0
            for i in 0..<groupFetch.count {
                if groupFetch.object(at: i).localIdentifier == asset.localIdentifier {
                    finalIndex = i
                    break
                }
            }
            self.viewerFetchResult = groupFetch
            self.viewerSessionId = UUID()
            withAnimation(.easeInOut(duration: 0.22)) {
                self.viewerIndex = finalIndex
            }
        }
    }
    
    // MARK: - Filter Triggers
    private func handleFilterTrigger(_ option: PhotoFilterOption) {
        guard mediaTab == .photos else { return }
        
        let freshFetch = photoService.fetchAllPhotos()
        self.fetchResult = freshFetch
        
        var freshList: [PHAsset] = []
        for i in 0..<freshFetch.count {
            freshList.append(freshFetch.object(at: i))
        }
        
        switch option {
        case .all:
            break
        case .duplicates:
            Task {
                await scannerService.scanDuplicatePhotos(from: freshList)
            }
        case .similar:
            Task {
                await scannerService.scanSimilarPhotos(from: freshList)
            }
        }
    }
    
    private func handleVideoFilterTrigger(_ option: VideoFilterOption) {
        guard mediaTab == .videos else { return }
        
        let freshFetch = photoService.fetchAllVideos()
        self.fetchResult = freshFetch
        
        var freshList: [PHAsset] = []
        for i in 0..<freshFetch.count {
            freshList.append(freshFetch.object(at: i))
        }
        
        switch option {
        case .all:
            break
        case .large:
            Task {
                await scannerService.scanLargeVideos(from: freshList)
            }
        case .duplicates:
            Task {
                await scannerService.scanDuplicateVideos(from: freshList)
            }
        }
    }
    
    private func selectAllDuplicateCopies() {
        var copyIds = Set<String>()
        for group in scannerService.duplicateGroups {
            for duplicate in group.duplicateAssets {
                copyIds.insert(duplicate.localIdentifier)
            }
        }
        self.selectedAssetIds = copyIds
        self.isSelectMode = !copyIds.isEmpty
    }
    
    private func selectAllCurrentAssets() {
        if mediaTab == .photos {
            if selectedFilter == .duplicates {
                var ids = Set<String>()
                for group in scannerService.duplicateGroups {
                    for asset in group.assets {
                        ids.insert(asset.localIdentifier)
                    }
                }
                selectedAssetIds = ids
            } else if selectedFilter == .similar {
                var ids = Set<String>()
                for group in scannerService.similarGroups {
                    for asset in group.assets {
                        ids.insert(asset.localIdentifier)
                    }
                }
                selectedAssetIds = ids
            } else if let results = fetchResult {
                var ids = Set<String>()
                for i in 0..<results.count {
                    ids.insert(results.object(at: i).localIdentifier)
                }
                selectedAssetIds = ids
            }
        } else {
            if selectedVideoFilter == .duplicates {
                var ids = Set<String>()
                for group in scannerService.duplicateVideoGroups {
                    for asset in group.assets {
                        ids.insert(asset.localIdentifier)
                    }
                }
                selectedAssetIds = ids
            } else if selectedVideoFilter == .large {
                selectedAssetIds = Set(scannerService.largeVideos.map(\.id))
            } else if let results = fetchResult {
                var ids = Set<String>()
                for i in 0..<results.count {
                    ids.insert(results.object(at: i).localIdentifier)
                }
                selectedAssetIds = ids
            }
        }
    }
    
    private var selectableCount: Int {
        if mediaTab == .photos {
            if selectedFilter == .duplicates {
                return scannerService.duplicateGroups.reduce(0) { $0 + $1.assets.count }
            } else if selectedFilter == .similar {
                return scannerService.similarGroups.reduce(0) { $0 + $1.assets.count }
            } else {
                return fetchResult?.count ?? 0
            }
        } else {
            if selectedVideoFilter == .duplicates {
                return scannerService.duplicateVideoGroups.reduce(0) { $0 + $1.assets.count }
            } else if selectedVideoFilter == .large {
                return scannerService.largeVideos.count
            } else {
                return fetchResult?.count ?? 0
            }
        }
    }
    
    private var canShowSelectButton: Bool {
        if mediaTab == .photos {
            if selectedFilter == .all {
                return assetCount > 0
            } else if selectedFilter == .duplicates {
                return !scannerService.duplicateGroups.isEmpty
            } else if selectedFilter == .similar {
                return !scannerService.similarGroups.isEmpty
            }
        } else {
            if selectedVideoFilter == .all {
                return assetCount > 0
            } else if selectedVideoFilter == .large {
                return !scannerService.largeVideos.isEmpty
            } else if selectedVideoFilter == .duplicates {
                return !scannerService.duplicateVideoGroups.isEmpty
            }
        }
        return false
    }
    
    // MARK: - Computed Helpers
    private var allCurrentAssets: [PHAsset] {
        guard let results = fetchResult else { return [] }
        var list: [PHAsset] = []
        for i in 0..<results.count {
            list.append(results.object(at: i))
        }
        return list
    }
    
    private var assetCount: Int {
        fetchResult?.count ?? 0
    }
    
    private var headerTitle: String {
        if mediaTab == .photos {
            switch selectedFilter {
            case .all: return "Photos"
            case .duplicates: return "Duplicates"
            case .similar: return "Similar"
            }
        } else {
            switch selectedVideoFilter {
            case .all: return "Videos"
            case .large: return "Large Videos"
            case .duplicates: return "Duplicate Videos"
            }
        }
    }
    
    private var headerSubtitle: String {
        if mediaTab == .photos {
            switch selectedFilter {
            case .all:
                return "\(assetCount) Photos"
            case .duplicates:
                return "\(scannerService.duplicateGroups.count) Duplicate Sets"
            case .similar:
                return "\(scannerService.similarGroups.count) Similar Sets"
            }
        } else {
            switch selectedVideoFilter {
            case .all:
                return "\(assetCount) Videos"
            case .large:
                let totalBytes = scannerService.largeVideos.reduce(Int64(0)) { $0 + $1.fileSize }
                let formattedTotal = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
                return "\(scannerService.largeVideos.count) Videos • \(formattedTotal)"
            case .duplicates:
                return "\(scannerService.duplicateVideoGroups.count) Duplicate Sets"
            }
        }
    }
    
    private func loadAssets() {
        if mediaTab == .photos {
            self.fetchResult = photoService.fetchAllPhotos()
        } else {
            self.fetchResult = photoService.fetchAllVideos()
        }
        
        // Pre-warm initial visible thumbnails in PhotoKit cache
        if let results = fetchResult, results.count > 0 {
            let countToPreheat = min(results.count, 45)
            var initialAssets: [PHAsset] = []
            for i in 0..<countToPreheat {
                initialAssets.append(results.object(at: i))
            }
            photoService.preheatThumbnails(for: initialAssets, targetSize: CGSize(width: 400, height: 400))
        }
    }
    
    private func deleteSelected() {
        guard !selectedAssetIds.isEmpty else { return }
        
        let allCurrent = allCurrentAssets
        let assetsToDelete = allCurrent.filter { selectedAssetIds.contains($0.localIdentifier) }
        
        Task {
            do {
                try await photoService.deleteAssets(assetsToDelete)
                selectedAssetIds.removeAll()
                isSelectMode = false
                loadAssets()
                photoService.loadLibraryStats()
                
                // Refresh active filter
                if mediaTab == .photos {
                    if selectedFilter == .duplicates {
                        await scannerService.scanDuplicatePhotos(from: allCurrentAssets)
                    } else if selectedFilter == .similar {
                        await scannerService.scanSimilarPhotos(from: allCurrentAssets)
                    }
                } else {
                    if selectedVideoFilter == .duplicates {
                        await scannerService.scanDuplicateVideos(from: allCurrentAssets)
                    } else if selectedVideoFilter == .large {
                        await scannerService.scanLargeVideos(from: allCurrentAssets)
                    }
                }
            } catch {
                print("Failed to delete assets: \(error.localizedDescription)")
            }
        }
    }
}
