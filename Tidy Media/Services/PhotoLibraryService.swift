//
//  PhotoLibraryService.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/5/26.
//

import SwiftUI
import Photos
import Combine
import AVFoundation

struct UserAlbumInfo: Identifiable, Sendable {
    let id: String
    let title: String
    let count: Int
    let keyAsset: PHAsset?
    
    var iconName: String {
        let lower = title.lowercased()
        if lower.contains("whatsapp") { return "message.fill" }
        if lower.contains("telegram") { return "paperplane.fill" }
        if lower.contains("instagram") { return "camera.viewfinder" }
        if lower.contains("download") { return "arrow.down.circle.fill" }
        if lower.contains("chatgpt") { return "sparkles" }
        if lower.contains("twitter") || lower == "x" { return "bubble.left.and.bubble.right.fill" }
        if lower.contains("selfie") { return "person.crop.square" }
        if lower.contains("portrait") || lower.contains("depth") { return "cube.fill" }
        if lower.contains("live") { return "livephoto" }
        if lower.contains("burst") { return "square.stack.3d.down.right.fill" }
        if lower.contains("pano") { return "pano.fill" }
        if lower.contains("document") || lower.contains("scanner") { return "doc.viewfinder.fill" }
        return "folder.fill"
    }
    
    var gradient: [Color] {
        let hash = abs(title.hashValue)
        let hue = Double(hash % 360) / 360.0
        return [
            Color(hue: hue, saturation: 0.55, brightness: 0.35),
            Color(hue: hue, saturation: 0.65, brightness: 0.14)
        ]
    }
}

struct LibraryStatsResult: Sendable {
    let photosCount: Int
    let videosCount: Int
    let screenshotsCount: Int
    let favoritesCount: Int
    let cameraKeyAsset: PHAsset?
    let favoritesKeyAsset: PHAsset?
    let videosKeyAsset: PHAsset?
    let screenshotsKeyAsset: PHAsset?
    let userAlbums: [UserAlbumInfo]
}

@MainActor
final class PhotoLibraryService: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    static let shared = PhotoLibraryService()
    
    // MARK: - Published States
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var isScanning: Bool = false
    
    // Live counts for Pinned Categories
    @Published var totalPhotosCount: Int = 0
    @Published var totalVideosCount: Int = 0
    @Published var screenshotsCount: Int = 0
    @Published var favoritesCount: Int = 0
    
    // Key Assets for Pinned Thumbnails
    @Published var cameraKeyAsset: PHAsset?
    @Published var favoritesKeyAsset: PHAsset?
    @Published var videosKeyAsset: PHAsset?
    @Published var screenshotsKeyAsset: PHAsset?
    
    // Real App & User Albums dynamically queried from device
    @Published var userAlbums: [UserAlbumInfo] = []
    
    // Image Caching Manager
    let imageManager = PHCachingImageManager()
    
    // High-performance in-memory cache for decoded crisp thumbnails (prevents reload flicker & blur)
    private let thumbnailCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 600
        cache.totalCostLimit = 150 * 1024 * 1024 // 150 MB max RAM
        return cache
    }()
    
    func cachedThumbnail(for assetId: String) -> UIImage? {
        if let cached = thumbnailCache.object(forKey: "\(assetId)_360" as NSString) {
            return cached
        }
        if let cached = thumbnailCache.object(forKey: "\(assetId)_400" as NSString) {
            return cached
        }
        if let cached = thumbnailCache.object(forKey: "\(assetId)_600" as NSString) {
            return cached
        }
        return thumbnailCache.object(forKey: assetId as NSString)
    }
    
    func cacheThumbnail(_ image: UIImage, for assetId: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        thumbnailCache.setObject(image, forKey: assetId as NSString, cost: cost)
    }
    
    func preheatThumbnails(for assets: [PHAsset], targetSize: CGSize = CGSize(width: 400, height: 400)) {
        guard !assets.isEmpty else { return }
        let uncached = assets.filter { cachedThumbnail(for: $0.localIdentifier) == nil }
        guard !uncached.isEmpty else { return }
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        
        imageManager.startCachingImages(for: uncached, targetSize: targetSize, contentMode: .aspectFill, options: options)
    }
    
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
        checkCurrentPermission()
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // MARK: - Real-Time Observer (Updates when photos/albums are added or clicked)
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            self.loadLibraryStats()
        }
    }
    
    // MARK: - Permissions
    func checkCurrentPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        self.authorizationStatus = status
        if status == .authorized || status == .limited {
            Task { @MainActor in
                self.performFastInitialKeyAssetFetch()
                self.loadLibraryStats()
            }
        } else if status == .notDetermined {
            Task {
                _ = await requestPermission()
            }
        }
    }
    
    func requestPermission() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        self.authorizationStatus = status
        if status == .authorized || status == .limited {
            performFastInitialKeyAssetFetch()
            await loadLibraryStatsAsync()
            return true
        }
        return false
    }
    
    private func performFastInitialKeyAssetFetch() {
        // Fast 1-asset fetch to guarantee thumbnails have a valid key asset immediately on launch
        let photosOptions = PHFetchOptions()
        photosOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        photosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        photosOptions.fetchLimit = 1
        let photosFetch = PHAsset.fetchAssets(with: photosOptions)
        if self.cameraKeyAsset == nil {
            self.cameraKeyAsset = photosFetch.firstObject
        }
        if self.totalPhotosCount == 0 && photosFetch.count > 0 {
            self.totalPhotosCount = photosFetch.count
        }
        
        let favOptions = PHFetchOptions()
        favOptions.predicate = NSPredicate(format: "isFavorite = true")
        favOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        favOptions.fetchLimit = 1
        let favFetch = PHAsset.fetchAssets(with: favOptions)
        if self.favoritesKeyAsset == nil {
            self.favoritesKeyAsset = favFetch.firstObject
        }
        if self.favoritesCount == 0 && favFetch.count > 0 {
            self.favoritesCount = favFetch.count
        }
        
        let videosOptions = PHFetchOptions()
        videosOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        videosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        videosOptions.fetchLimit = 1
        let videosFetch = PHAsset.fetchAssets(with: videosOptions)
        if self.videosKeyAsset == nil {
            self.videosKeyAsset = videosFetch.firstObject
        }
        if self.totalVideosCount == 0 && videosFetch.count > 0 {
            self.totalVideosCount = videosFetch.count
        }
        
        let screenOptions = PHFetchOptions()
        screenOptions.predicate = NSPredicate(
            format: "mediaType = %d AND (mediaSubtypes & %d) != 0",
            PHAssetMediaType.image.rawValue,
            PHAssetMediaSubtype.photoScreenshot.rawValue
        )
        screenOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        screenOptions.fetchLimit = 1
        let screenFetch = PHAsset.fetchAssets(with: screenOptions)
        if self.screenshotsKeyAsset == nil {
            self.screenshotsKeyAsset = screenFetch.firstObject
        }
        if self.screenshotsCount == 0 && screenFetch.count > 0 {
            self.screenshotsCount = screenFetch.count
        }
        
        // Immediate background pre-warming of initial key assets
        let initialAssets = [self.cameraKeyAsset, self.favoritesKeyAsset, self.videosKeyAsset, self.screenshotsKeyAsset].compactMap { $0 }
        if !initialAssets.isEmpty {
            self.preheatThumbnails(for: initialAssets, targetSize: CGSize(width: 600, height: 600))
            for asset in initialAssets {
                Task.detached(priority: .userInitiated) { [weak self] in
                    _ = await self?.loadThumbnail(for: asset, targetSize: CGSize(width: 600, height: 600))
                }
            }
        }
    }
    
    // MARK: - Fetch Asset Data
    func loadLibraryStats() {
        Task {
            await loadLibraryStatsAsync()
        }
    }
    
    func loadLibraryStatsAsync() async {
        guard authorizationStatus == .authorized || authorizationStatus == .limited else { return }
        
        isScanning = true
        defer { isScanning = false }
        
        // Run PhotoKit queries in a detached background task to guarantee zero main-thread hitching
        let result = await Task.detached(priority: .userInitiated) { () -> LibraryStatsResult in
            // 1. All Photos (Camera / Recents)
            let photosOptions = PHFetchOptions()
            photosOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            photosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let photosFetch = PHAsset.fetchAssets(with: photosOptions)
            let pCount = photosFetch.count
            let cAsset = photosFetch.firstObject
            
            // 2. Videos
            let videosOptions = PHFetchOptions()
            videosOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            videosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let videosFetch = PHAsset.fetchAssets(with: videosOptions)
            let vCount = videosFetch.count
            let vAsset = videosFetch.firstObject
            
            // 3. Screenshots
            let screenshotsOptions = PHFetchOptions()
            screenshotsOptions.predicate = NSPredicate(
                format: "mediaType = %d AND (mediaSubtypes & %d) != 0",
                PHAssetMediaType.image.rawValue,
                PHAssetMediaSubtype.photoScreenshot.rawValue
            )
            screenshotsOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let screenshotsFetch = PHAsset.fetchAssets(with: screenshotsOptions)
            let sCount = screenshotsFetch.count
            let sAsset = screenshotsFetch.firstObject
            
            // 4. Favorites
            let favOptions = PHFetchOptions()
            favOptions.predicate = NSPredicate(format: "isFavorite = true")
            favOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let favFetch = PHAsset.fetchAssets(with: favOptions)
            let fCount = favFetch.count
            let fAsset = favFetch.firstObject
            
            // 5. Real Device & App-Created Albums (WhatsApp, Telegram, Instagram, Downloads, etc.)
            var albumsList: [UserAlbumInfo] = []
            var seenIdentifiers = Set<String>()
            
            // Exclude the 4 pinned collections from this secondary list
            let excludedSubtypes: [PHAssetCollectionSubtype] = [
                .smartAlbumUserLibrary,
                .smartAlbumFavorites,
                .smartAlbumVideos,
                .smartAlbumScreenshots,
                .smartAlbumAllHidden
            ]
            
            let processCollection: (PHAssetCollection) -> Void = { collection in
                guard !seenIdentifiers.contains(collection.localIdentifier) else { return }
                guard !excludedSubtypes.contains(collection.assetCollectionSubtype) else { return }
                
                let title = collection.localizedTitle ?? ""
                let lower = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
                // Do not duplicate the 4 pinned categories
                if lower == "recents" || lower == "camera" || lower == "favorites" || lower == "favourite" || lower == "videos" || lower == "video" || lower == "screenshots" || lower == "hidden" {
                    return
                }
                
                let assets = PHAsset.fetchAssets(in: collection, options: nil)
                guard assets.count > 0 else { return }
                
                seenIdentifiers.insert(collection.localIdentifier)
                albumsList.append(
                    UserAlbumInfo(
                        id: collection.localIdentifier,
                        title: title.isEmpty ? "Album" : title,
                        count: assets.count,
                        keyAsset: assets.lastObject
                    )
                )
            }
            
            // A. Top-Level User Collections (contains third-party app folders: WhatsApp, Telegram, Twitter, etc.)
            let topLevel = PHCollectionList.fetchTopLevelUserCollections(with: nil)
            topLevel.enumerateObjects { item, _, _ in
                if let collection = item as? PHAssetCollection {
                    processCollection(collection)
                }
            }
            
            // B. Regular & App Albums
            let regular = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            regular.enumerateObjects { collection, _, _ in
                processCollection(collection)
            }
            
            // C. Smart Media Albums (e.g. Selfies, Panoramas, Live Photos, Portrait, Bursts)
            let smart = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
            smart.enumerateObjects { collection, _, _ in
                processCollection(collection)
            }
            
            // Sort by count descending
            albumsList.sort { $0.count > $1.count }
            
            return LibraryStatsResult(
                photosCount: pCount,
                videosCount: vCount,
                screenshotsCount: sCount,
                favoritesCount: fCount,
                cameraKeyAsset: cAsset,
                favoritesKeyAsset: fAsset,
                videosKeyAsset: vAsset,
                screenshotsKeyAsset: sAsset,
                userAlbums: albumsList
            )
        }.value
        
        self.totalPhotosCount = result.photosCount
        self.totalVideosCount = result.videosCount
        self.screenshotsCount = result.screenshotsCount
        self.favoritesCount = result.favoritesCount
        
        self.cameraKeyAsset = result.cameraKeyAsset
        self.favoritesKeyAsset = result.favoritesKeyAsset
        self.videosKeyAsset = result.videosKeyAsset
        self.screenshotsKeyAsset = result.screenshotsKeyAsset
        self.userAlbums = result.userAlbums
        
        // Background pre-warming of all key album assets in memory cache
        let albumKeyAssets = [
            result.cameraKeyAsset,
            result.favoritesKeyAsset,
            result.videosKeyAsset,
            result.screenshotsKeyAsset
        ].compactMap { $0 } + result.userAlbums.compactMap { $0.keyAsset }
        
        if !albumKeyAssets.isEmpty {
            self.preheatThumbnails(for: albumKeyAssets, targetSize: CGSize(width: 600, height: 600))
            for asset in albumKeyAssets {
                Task.detached(priority: .userInitiated) { [weak self] in
                    _ = await self?.loadThumbnail(for: asset, targetSize: CGSize(width: 600, height: 600))
                }
            }
        }
    }
    
    // MARK: - Crisp High-Quality Thumbnail Fetching (Never returns blurry low-res proxy)
    @discardableResult
    func loadHighQualityThumbnail(
        for asset: PHAsset?,
        targetSize: CGSize = CGSize(width: 600, height: 600),
        onImage: @escaping @MainActor (UIImage) -> Void
    ) -> PHImageRequestID? {
        guard let asset = asset else { return nil }
        
        // Fast in-memory cache check: 0ms return if already loaded
        let cacheKey = "\(asset.localIdentifier)_\(Int(targetSize.width))"
        if let cached = thumbnailCache.object(forKey: cacheKey as NSString) ?? thumbnailCache.object(forKey: asset.localIdentifier as NSString) {
            Task { @MainActor in
                onImage(cached)
            }
            return nil
        }
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isSynchronous = false
        
        return imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, info in
            guard let image = image else { return }
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            // Strict check: NEVER deliver degraded blurry images to the UI!
            guard !isDegraded else { return }
            
            let cost = Int(image.size.width * image.size.height * 4)
            self?.thumbnailCache.setObject(image, forKey: cacheKey as NSString, cost: cost)
            self?.thumbnailCache.setObject(image, forKey: asset.localIdentifier as NSString, cost: cost)
            
            Task { @MainActor in
                onImage(image)
            }
        }
    }
    
    // Legacy alias to ensure backwards compatibility
    @discardableResult
    func loadProgressiveThumbnail(
        for asset: PHAsset?,
        targetSize: CGSize = CGSize(width: 600, height: 600),
        onImage: @escaping @MainActor (UIImage) -> Void
    ) -> PHImageRequestID? {
        return loadHighQualityThumbnail(for: asset, targetSize: targetSize, onImage: onImage)
    }
    
    // MARK: - Direct Non-Blocking Thumbnail Request with Cancellation
    @discardableResult
    func requestThumbnail(
        for asset: PHAsset,
        targetSize: CGSize = CGSize(width: 360, height: 360),
        onImage: @escaping @MainActor (UIImage?) -> Void
    ) -> PHImageRequestID? {
        let cacheKey = "\(asset.localIdentifier)_\(Int(targetSize.width))"
        if let cached = thumbnailCache.object(forKey: cacheKey as NSString) ?? thumbnailCache.object(forKey: asset.localIdentifier as NSString) {
            onImage(cached)
            return nil
        }
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isSynchronous = false
        
        return imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, info in
            guard let image = image else {
                Task { @MainActor in onImage(nil) }
                return
            }
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            guard !isDegraded else { return }
            
            let cost = Int(image.size.width * image.size.height * 4)
            self?.thumbnailCache.setObject(image, forKey: cacheKey as NSString, cost: cost)
            self?.thumbnailCache.setObject(image, forKey: asset.localIdentifier as NSString, cost: cost)
            
            Task { @MainActor in
                onImage(image)
            }
        }
    }
    
    func cancelImageRequest(_ requestID: PHImageRequestID) {
        imageManager.cancelImageRequest(requestID)
    }
    
    // MARK: - Asynchronous High-Quality Thumbnail Fetching
    func loadThumbnail(for asset: PHAsset?, targetSize: CGSize = CGSize(width: 360, height: 360)) async -> UIImage? {
        guard let asset = asset else { return nil }
        
        // Fast in-memory cache lookup
        let cacheKey = "\(asset.localIdentifier)_\(Int(targetSize.width))"
        if let cached = thumbnailCache.object(forKey: cacheKey as NSString) {
            return cached
        }
        if let generalCached = thumbnailCache.object(forKey: asset.localIdentifier as NSString) {
            return generalCached
        }
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isSynchronous = false
        
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { [weak self] image, info in
                guard !hasResumed else { return }
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if let image = image, !isDegraded {
                    hasResumed = true
                    let cost = Int(image.size.width * image.size.height * 4)
                    self?.thumbnailCache.setObject(image, forKey: cacheKey as NSString, cost: cost)
                    self?.thumbnailCache.setObject(image, forKey: asset.localIdentifier as NSString, cost: cost)
                    continuation.resume(returning: image)
                } else if info?[PHImageErrorKey] != nil || info?[PHImageCancelledKey] != nil {
                    hasResumed = true
                    continuation.resume(returning: image)
                }
            }
        }
    }
    
    // MARK: - Video Player Item Fetching
    func loadPlayerItem(for asset: PHAsset) async -> AVPlayerItem? {
        guard asset.mediaType == .video else { return nil }
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            imageManager.requestPlayerItem(forVideo: asset, options: options) { playerItem, _ in
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: playerItem)
                }
            }
        }
    }
    
    // MARK: - Fetch Assets for a Given Album
    func fetchAssets(for album: AlbumItem) -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        if let categoryType = album.categoryType {
            switch categoryType {
            case .camera:
                options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                return PHAsset.fetchAssets(with: options)
                
            case .favorites:
                options.predicate = NSPredicate(format: "isFavorite = true")
                return PHAsset.fetchAssets(with: options)
                
            case .videos:
                options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
                return PHAsset.fetchAssets(with: options)
                
            case .screenshots:
                options.predicate = NSPredicate(
                    format: "mediaType = %d AND (mediaSubtypes & %d) != 0",
                    PHAssetMediaType.image.rawValue,
                    PHAssetMediaSubtype.photoScreenshot.rawValue
                )
                return PHAsset.fetchAssets(with: options)
                
            default:
                return PHAsset.fetchAssets(with: options)
            }
        } else {
            // Find by localIdentifier
            let collections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [album.id], options: nil)
            if let collection = collections.firstObject {
                return PHAsset.fetchAssets(in: collection, options: options)
            }
            return PHAsset.fetchAssets(with: options)
        }
    }
    
    // MARK: - Direct All Photos & All Videos Queries
    func fetchAllPhotos() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(with: options)
    }
    
    func fetchAllVideos() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(with: options)
    }
    
    // MARK: - High Resolution Image Fetching (Safe & Fast)
    func loadFullResolutionImage(for asset: PHAsset) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isSynchronous = false
        
        let targetSize = CGSize(
            width: max(asset.pixelWidth, 1200),
            height: max(asset.pixelHeight, 1200)
        )
        
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                guard !hasResumed else { return }
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if let image = image, !isDegraded {
                    hasResumed = true
                    continuation.resume(returning: image)
                } else if info?[PHImageErrorKey] != nil || info?[PHImageCancelledKey] != nil {
                    hasResumed = true
                    continuation.resume(returning: image)
                }
            }
        }
    }
    
    // MARK: - Favorite / Unfavorite Asset
    func toggleFavorite(for asset: PHAsset) async throws -> Bool {
        let targetState = !asset.isFavorite
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest(for: asset)
            request.isFavorite = targetState
        }
        await loadLibraryStatsAsync()
        return targetState
    }
    
    // MARK: - Delete Assets
    func deleteAssets(_ assets: [PHAsset]) async throws {
        // Archive to Recently Deleted so the user can recover them
        await RecentlyDeletedService.shared.archiveAssets(assets)
        
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }
    }
}
