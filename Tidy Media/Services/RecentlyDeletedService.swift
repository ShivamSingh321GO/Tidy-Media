//
//  RecentlyDeletedService.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/6/26.
//

import SwiftUI
import Photos
import AVFoundation
import Combine
import ImageIO

// MARK: - Recently Deleted Data Model
struct RecentlyDeletedItem: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let originalLocalIdentifier: String
    let filename: String
    var thumbFilename: String? = nil
    let isVideo: Bool
    let deletedDate: Date
    let originalCreationDate: Date?
    let pixelWidth: Int
    let pixelHeight: Int
    let duration: Double
    
    var daysRemaining: Int {
        let thirtyDaysSeconds: TimeInterval = 30 * 24 * 60 * 60
        let expiryDate = deletedDate.addingTimeInterval(thirtyDaysSeconds)
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 30
        return max(0, remaining)
    }
    
    var formattedDuration: String {
        guard isVideo && duration > 0 else { return "" }
        let total = Int(duration)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

// MARK: - Recently Deleted Service
@MainActor
final class RecentlyDeletedService: ObservableObject {
    static let shared = RecentlyDeletedService()
    
    @Published var items: [RecentlyDeletedItem] = []
    
    private let thumbnailCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private var storageDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("RecentlyDeleted", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private var metadataURL: URL {
        storageDirectory.appendingPathComponent("recently_deleted_index.json")
    }
    
    init() {
        loadItems()
        pruneExpiredItems()
    }
    
    func reload() {
        loadItems()
    }
    
    // MARK: - Persistence
    private func loadItems() {
        guard fileManager.fileExists(atPath: metadataURL.path) else {
            self.items = []
            return
        }
        
        do {
            let data = try Data(contentsOf: metadataURL)
            let decoder = JSONDecoder()
            self.items = try decoder.decode([RecentlyDeletedItem].self, from: data)
            print("RecentlyDeleted: Loaded \(items.count) items from disk")
        } catch {
            print("RecentlyDeleted: Failed to load items: \(error)")
            self.items = []
        }
    }
    
    private func saveItems() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(items)
            try data.write(to: metadataURL)
            print("RecentlyDeleted: Saved \(items.count) items to index")
        } catch {
            print("RecentlyDeleted: Failed to save items: \(error)")
        }
    }
    
    func getFileURL(for item: RecentlyDeletedItem) -> URL {
        storageDirectory.appendingPathComponent(item.filename)
    }
    
    // MARK: - Archive Before Delete
    func archiveAssets(_ assets: [PHAsset]) async {
        print("RecentlyDeleted: Archiving \(assets.count) assets...")
        var newArchived: [RecentlyDeletedItem] = []
        
        for asset in assets {
            if let item = await archiveSingleAsset(asset) {
                print("RecentlyDeleted: Archived item \(item.id) (type: \(item.isVideo ? "video" : "photo"))")
                newArchived.append(item)
            } else {
                print("RecentlyDeleted: Warning: Could not archive asset \(asset.localIdentifier)")
            }
        }
        
        self.items.insert(contentsOf: newArchived, at: 0)
        saveItems()
        print("RecentlyDeleted: Current total items in store: \(self.items.count)")
    }
    
    private func archiveSingleAsset(_ asset: PHAsset) async -> RecentlyDeletedItem? {
        let id = UUID().uuidString
        let isVideo = asset.mediaType == .video
        let ext = isVideo ? "mov" : "jpg"
        let filename = "\(id).\(ext)"
        let thumbFilename = "\(id)_thumb.jpg"
        let destinationURL = storageDirectory.appendingPathComponent(filename)
        let thumbURL = storageDirectory.appendingPathComponent(thumbFilename)
        
        // 1. Capture and save thumbnail immediately
        if let thumbImage = await fetchThumbnailImage(asset: asset) {
            if let thumbData = thumbImage.jpegData(compressionQuality: 0.8) {
                try? thumbData.write(to: thumbURL)
            }
        }
        
        if isVideo {
            _ = await exportVideoWithFallbacks(asset: asset, to: destinationURL)
            // Even if video stream file export has an issue in simulator, always keep the item record and poster!
            return RecentlyDeletedItem(
                id: id,
                originalLocalIdentifier: asset.localIdentifier,
                filename: filename,
                thumbFilename: thumbFilename,
                isVideo: true,
                deletedDate: Date(),
                originalCreationDate: asset.creationDate,
                pixelWidth: asset.pixelWidth,
                pixelHeight: asset.pixelHeight,
                duration: asset.duration
            )
        } else {
            let success = await exportPhotoWithFallbacks(asset: asset, to: destinationURL)
            if success {
                return RecentlyDeletedItem(
                    id: id,
                    originalLocalIdentifier: asset.localIdentifier,
                    filename: filename,
                    thumbFilename: thumbFilename,
                    isVideo: false,
                    deletedDate: Date(),
                    originalCreationDate: asset.creationDate,
                    pixelWidth: asset.pixelWidth,
                    pixelHeight: asset.pixelHeight,
                    duration: 0
                )
            }
        }
        
        return nil
    }
    
    // MARK: - Photo Export with Guaranteed Fallbacks
    private func exportPhotoWithFallbacks(asset: PHAsset, to destinationURL: URL) async -> Bool {
        // Method 1: Direct Image Data
        if let data = await fetchImageData(asset: asset), !data.isEmpty {
            do {
                try data.write(to: destinationURL)
                return true
            } catch {
                print("RecentlyDeleted: Method 1 write error: \(error)")
            }
        }
        
        // Method 2: PHAssetResource writeData
        let resources = PHAssetResource.assetResources(for: asset)
        if let photoRes = resources.first(where: { $0.type == .photo || $0.type == .fullSizePhoto }) ?? resources.first {
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            let resSuccess: Bool = await withCheckedContinuation { continuation in
                PHAssetResourceManager.default().writeData(for: photoRes, toFile: destinationURL, options: options) { error in
                    continuation.resume(returning: error == nil)
                }
            }
            if resSuccess && fileManager.fileExists(atPath: destinationURL.path) {
                return true
            }
        }
        
        // Method 3: Rendered High-Resolution UIImage (100% reliable)
        if let highResImage = await fetchFullResolutionImage(asset: asset) {
            if let jpegData = highResImage.jpegData(compressionQuality: 0.92) {
                do {
                    try jpegData.write(to: destinationURL)
                    return true
                } catch {
                    print("RecentlyDeleted: Method 3 write error: \(error)")
                }
            }
        }
        
        // Method 4: Rendered Screen Thumbnail UIImage
        if let screenImage = await fetchThumbnailImage(asset: asset) {
            if let jpegData = screenImage.jpegData(compressionQuality: 0.88) {
                do {
                    try jpegData.write(to: destinationURL)
                    return true
                } catch {
                    print("RecentlyDeleted: Method 4 write error: \(error)")
                }
            }
        }
        
        return false
    }
    
    private func fetchImageData(asset: PHAsset) async -> Data? {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.version = .current
        
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(returning: data)
            }
        }
    }
    
    private func fetchFullResolutionImage(asset: PHAsset) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none
        options.isSynchronous = false
        
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                guard !hasResumed else { return }
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded || (info?[PHImageErrorKey] != nil) {
                    hasResumed = true
                    continuation.resume(returning: image)
                }
            }
        }
    }
    
    private func fetchThumbnailImage(asset: PHAsset) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isSynchronous = false
        
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 600, height: 600),
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                guard !hasResumed else { return }
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded || (info?[PHImageErrorKey] != nil) {
                    hasResumed = true
                    continuation.resume(returning: image)
                }
            }
        }
    }
    
    // MARK: - Video Export with Guaranteed Fallbacks
    private func exportVideoWithFallbacks(asset: PHAsset, to destinationURL: URL) async -> Bool {
        try? fileManager.removeItem(at: destinationURL)
        
        // Method 1: PHAssetResourceManager writeData
        let resources = PHAssetResource.assetResources(for: asset)
        if let videoRes = resources.first(where: { $0.type == .video || $0.type == .fullSizeVideo }) ?? resources.first {
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            let success: Bool = await withCheckedContinuation { continuation in
                PHAssetResourceManager.default().writeData(for: videoRes, toFile: destinationURL, options: options) { error in
                    continuation.resume(returning: error == nil)
                }
            }
            if success && fileManager.fileExists(atPath: destinationURL.path) {
                return true
            }
        }
        
        // Method 2: AVAssetExportSession
        let exportOptions = PHVideoRequestOptions()
        exportOptions.isNetworkAccessAllowed = true
        exportOptions.deliveryMode = .highQualityFormat
        
        let exportSuccess: Bool = await withCheckedContinuation { continuation in
            PHImageManager.default().requestExportSession(
                forVideo: asset,
                options: exportOptions,
                exportPreset: AVAssetExportPresetHighestQuality
            ) { session, _ in
                guard let session = session else {
                    continuation.resume(returning: false)
                    return
                }
                session.outputURL = destinationURL
                session.outputFileType = .mov
                session.exportAsynchronously {
                    continuation.resume(returning: session.status == .completed)
                }
            }
        }
        
        if exportSuccess && fileManager.fileExists(atPath: destinationURL.path) {
            return true
        }
        
        // Method 3: Copy AVURLAsset
        let urlSuccess: Bool = await withCheckedContinuation { continuation in
            PHImageManager.default().requestAVAsset(forVideo: asset, options: exportOptions) { avAsset, _, _ in
                if let urlAsset = avAsset as? AVURLAsset {
                    do {
                        try FileManager.default.copyItem(at: urlAsset.url, to: destinationURL)
                        continuation.resume(returning: true)
                    } catch {
                        continuation.resume(returning: false)
                    }
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
        
        return urlSuccess && fileManager.fileExists(atPath: destinationURL.path)
    }
    
    // MARK: - Recovery
    func recoverItems(_ itemsToRecover: [RecentlyDeletedItem]) async throws {
        for item in itemsToRecover {
            let fileURL = getFileURL(for: item)
            let thumbURL = item.thumbFilename.map { storageDirectory.appendingPathComponent($0) }
            
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                if item.isVideo {
                    if self.fileManager.fileExists(atPath: fileURL.path) {
                        request.addResource(with: .video, fileURL: fileURL, options: nil)
                    } else if let tURL = thumbURL, self.fileManager.fileExists(atPath: tURL.path) {
                        request.addResource(with: .photo, fileURL: tURL, options: nil)
                    }
                } else {
                    if let data = try? Data(contentsOf: fileURL) {
                        request.addResource(with: .photo, data: data, options: nil)
                    } else if let tURL = thumbURL, let data = try? Data(contentsOf: tURL) {
                        request.addResource(with: .photo, data: data, options: nil)
                    }
                }
                if let date = item.originalCreationDate {
                    request.creationDate = date
                }
            }
            
            // Clean up files from disk
            try? self.fileManager.removeItem(at: fileURL)
            if let tURL = thumbURL {
                try? self.fileManager.removeItem(at: tURL)
            }
        }
        
        let recoveredIds = Set(itemsToRecover.map(\.id))
        for item in itemsToRecover {
            thumbnailCache.removeObject(forKey: item.id as NSString)
        }
        self.items.removeAll { recoveredIds.contains($0.id) }
        saveItems()
        
        PhotoLibraryService.shared.loadLibraryStats()
    }
    
    // MARK: - Delete Permanently
    func deletePermanently(_ itemsToDelete: [RecentlyDeletedItem]) {
        for item in itemsToDelete {
            let fileURL = getFileURL(for: item)
            try? fileManager.removeItem(at: fileURL)
            if let thumbName = item.thumbFilename {
                let thumbURL = storageDirectory.appendingPathComponent(thumbName)
                try? fileManager.removeItem(at: thumbURL)
            }
            thumbnailCache.removeObject(forKey: item.id as NSString)
        }
        
        let deletedIds = Set(itemsToDelete.map(\.id))
        self.items.removeAll { deletedIds.contains($0.id) }
        saveItems()
    }
    
    // MARK: - Thumbnail Generator
    func loadThumbnail(for item: RecentlyDeletedItem) -> UIImage? {
        let cacheKey = item.id as NSString
        if let cached = thumbnailCache.object(forKey: cacheKey) {
            return cached
        }
        
        let fileURL = getFileURL(for: item)
        
        // 1. For photos: Load from full-quality original file with retina downsampling
        if !item.isVideo && fileManager.fileExists(atPath: fileURL.path) {
            if let img = downsampleImage(at: fileURL, to: CGSize(width: 450, height: 450)) {
                thumbnailCache.setObject(img, forKey: cacheKey)
                return img
            } else if let img = UIImage(contentsOfFile: fileURL.path) {
                thumbnailCache.setObject(img, forKey: cacheKey)
                return img
            }
        }
        
        // 2. For videos: Extract crisp frame from video file if available
        if item.isVideo && fileManager.fileExists(atPath: fileURL.path) {
            let asset = AVURLAsset(url: fileURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 600, height: 600)
            if let cgImage = try? generator.copyCGImage(at: CMTime(seconds: 0.1, preferredTimescale: 600), actualTime: nil) {
                let img = UIImage(cgImage: cgImage)
                thumbnailCache.setObject(img, forKey: cacheKey)
                return img
            }
        }
        
        // 3. Fallback to saved thumbnail file
        if let thumbName = item.thumbFilename {
            let thumbURL = storageDirectory.appendingPathComponent(thumbName)
            if let img = UIImage(contentsOfFile: thumbURL.path) {
                thumbnailCache.setObject(img, forKey: cacheKey)
                return img
            }
        }
        
        return nil
    }
    
    private func downsampleImage(at url: URL, to targetSize: CGSize) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else {
            return nil
        }
        
        let scale = UIScreen.main.scale
        let maxDimensionInPixels = max(targetSize.width, targetSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as [CFString : Any] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        
        return UIImage(cgImage: downsampledImage)
    }
    
    // MARK: - Prune Expired (> 30 days)
    private func pruneExpiredItems() {
        let expired = items.filter { $0.daysRemaining <= 0 }
        if !expired.isEmpty {
            deletePermanently(expired)
        }
    }
}
