//
//  MainViewModel.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/5/26.
//

import SwiftUI
import Photos
import Combine

@MainActor
final class MainViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedTab: MediaTab = .all
    @Published var isSearchPresented: Bool = false
    @Published var searchText: String = ""
    @Published var selectedAlbum: AlbumItem? = nil
    @Published var isFullScreenViewerOpen: Bool = false
    @Published var activePhotoFilter: PhotoFilterOption = .all
    @Published var activeVideoFilter: VideoFilterOption = .all
    
    // Services
    let photoService = PhotoLibraryService.shared
    let storageService = StorageCalculatorService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        photoService.objectWillChange
            .receive(on: RunLoop.main)
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.storageService.recalculate()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 4 Pinned Categories (Top 2x2 Grid)
    var pinnedAlbums: [AlbumItem] {
        let topFour: [AlbumItem] = [
            AlbumItem(
                id: "camera",
                title: "Photo",
                count: photoService.totalPhotosCount,
                keyAsset: photoService.cameraKeyAsset,
                systemIcon: "photo.fill",
                gradient: AlbumCategoryType.camera.placeholderGradient,
                isPinned: true,
                belongsToTabs: [.all, .photos],
                categoryType: .camera
            ),
            AlbumItem(
                id: "favorites",
                title: "Favourite",
                count: photoService.favoritesCount,
                keyAsset: photoService.favoritesKeyAsset,
                systemIcon: "heart.fill",
                gradient: AlbumCategoryType.favorites.placeholderGradient,
                isPinned: true,
                belongsToTabs: [.all, .photos],
                categoryType: .favorites
            ),
            AlbumItem(
                id: "videos",
                title: "Video",
                count: photoService.totalVideosCount,
                keyAsset: photoService.videosKeyAsset,
                systemIcon: "play.rectangle.fill",
                gradient: AlbumCategoryType.videos.placeholderGradient,
                isPinned: true,
                belongsToTabs: [.all, .videos],
                categoryType: .videos
            ),
            AlbumItem(
                id: "screenshots",
                title: "Screenshots",
                count: photoService.screenshotsCount,
                keyAsset: photoService.screenshotsKeyAsset,
                systemIcon: "iphone.gen3",
                gradient: AlbumCategoryType.screenshots.placeholderGradient,
                isPinned: true,
                belongsToTabs: [.all, .photos],
                categoryType: .screenshots
            )
        ]
        
        let filteredByTab: [AlbumItem]
        switch selectedTab {
        case .all:
            filteredByTab = topFour
        case .photos:
            filteredByTab = topFour.filter { $0.belongsToTabs.contains(.photos) }
        case .videos:
            filteredByTab = topFour.filter { $0.belongsToTabs.contains(.videos) }
        }
        
        // Only show pinned categories that actually have media in them (count > 0)
        let nonEmptyPinned = filteredByTab.filter { $0.count > 0 }
        
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if isSearchPresented && !query.isEmpty {
            return nonEmptyPinned.filter { $0.title.lowercased().contains(query) }
        }
        return nonEmptyPinned
    }
    
    // MARK: - Other Categories (Smaller 3-Column Grid)
    // 100% Real: Dynamically queries all albums created by apps (WhatsApp, Telegram, Downloads, etc.) or user on this device.
    var otherAlbums: [AlbumItem] {
        let realAlbums = photoService.userAlbums.map { userAlbum in
            AlbumItem(
                id: userAlbum.id,
                title: userAlbum.title,
                count: userAlbum.count,
                keyAsset: userAlbum.keyAsset,
                systemIcon: userAlbum.iconName,
                gradient: userAlbum.gradient,
                isPinned: false,
                belongsToTabs: [.all, .photos, .videos],
                categoryType: nil
            )
        }
        
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if isSearchPresented && !query.isEmpty {
            return realAlbums.filter { $0.title.lowercased().contains(query) }
        }
        return realAlbums
    }
    
    // MARK: - User Actions
    func selectTab(_ tab: MediaTab) {
        guard selectedTab != tab else { return }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
            selectedTab = tab
        }
    }
    
    func onSearchTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isSearchPresented.toggle()
            if !isSearchPresented {
                searchText = ""
            }
        }
    }
    
    func requestPermission() {
        Task {
            _ = await photoService.requestPermission()
        }
    }
    
    func navigateToDuplicates() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        activePhotoFilter = .duplicates
        selectTab(.photos)
    }
    
    func openScreenshotsAlbum() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let screenshotsItem = AlbumItem(
            id: "screenshots",
            title: "Screenshots",
            count: photoService.screenshotsCount,
            keyAsset: photoService.screenshotsKeyAsset,
            systemIcon: "iphone.gen3",
            gradient: AlbumCategoryType.screenshots.placeholderGradient,
            isPinned: true,
            belongsToTabs: [.all, .photos],
            categoryType: .screenshots
        )
        self.selectedAlbum = screenshotsItem
    }
    
    func refresh() {
        photoService.loadLibraryStats()
        storageService.recalculate(force: true)
    }
}
