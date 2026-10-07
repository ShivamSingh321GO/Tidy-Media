//
//  StorageCalculatorService.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/7/26.
//

import SwiftUI
import Photos
import Combine

// MARK: - Storage Breakdown Model
struct StorageCategoryBreakdown: Codable, Equatable, Sendable {
    var videosBytes: Int64 = 0
    var photosBytes: Int64 = 0
    var screenshotsBytes: Int64 = 0
    var duplicatePhotosBytes: Int64 = 0
    var duplicateVideosBytes: Int64 = 0
    
    var videosCount: Int = 0
    var photosCount: Int = 0
    var screenshotsCount: Int = 0
    var duplicatePhotosCount: Int = 0
    var duplicateVideosCount: Int = 0
    
    var lastUpdated: Date = Date()
    
    var recoverableBytes: Int64 {
        duplicatePhotosBytes + duplicateVideosBytes
    }
    
    var recoverableCount: Int {
        duplicatePhotosCount + duplicateVideosCount
    }
    
    var totalMediaBytes: Int64 {
        max(1, videosBytes + photosBytes + screenshotsBytes)
    }
    
    // Proportions for Segmented Capacity Bar
    var videosRatio: Double {
        guard totalMediaBytes > 0 else { return 0 }
        return Double(videosBytes) / Double(totalMediaBytes)
    }
    
    var photosRatio: Double {
        guard totalMediaBytes > 0 else { return 0 }
        return Double(photosBytes) / Double(totalMediaBytes)
    }
    
    var screenshotsRatio: Double {
        guard totalMediaBytes > 0 else { return 0 }
        return Double(screenshotsBytes) / Double(totalMediaBytes)
    }
    
    var recoverableRatio: Double {
        guard totalMediaBytes > 0 else { return 0 }
        return Double(recoverableBytes) / Double(totalMediaBytes)
    }
    
    // Human-readable formatted sizes
    var formattedTotalSize: String {
        Self.formatBytes(totalMediaBytes)
    }
    
    var formattedVideosSize: String {
        Self.formatBytes(videosBytes)
    }
    
    var formattedPhotosSize: String {
        Self.formatBytes(photosBytes)
    }
    
    var formattedScreenshotsSize: String {
        Self.formatBytes(screenshotsBytes)
    }
    
    var formattedRecoverableSize: String {
        Self.formatBytes(recoverableBytes)
    }
    
    static func formatBytes(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 MB" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return formatter.string(fromByteCount: bytes)
    }
    
    // Total Hardware Storage Capacity of Device
    var deviceCapacityText: String {
        StorageCalculatorService.deviceTotalCapacityFormatted
    }
}

// MARK: - Storage Calculator Service
@MainActor
final class StorageCalculatorService: ObservableObject {
    static let shared = StorageCalculatorService()
    
    // Total Hardware Storage Capacity of Device (e.g. 128 GB, 256 GB, 512 GB)
    nonisolated static var deviceTotalCapacityFormatted: String {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory())
        var totalBytes: Int64 = 0
        if let values = try? fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey]),
           let capacity = values.volumeTotalCapacity {
            totalBytes = Int64(capacity)
        } else if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
                  let size = attrs[.systemSize] as? Int64 {
            totalBytes = size
        }
        
        guard totalBytes > 0 else { return "128 GB" }
        
        // Map to commercial Apple device storage tiers (accounting for OS formatting overhead)
        let gigaBytes = Double(totalBytes) / 1_000_000_000.0
        if gigaBytes >= 850 { return "1 TB" }
        if gigaBytes >= 420 { return "512 GB" }
        if gigaBytes >= 200 { return "256 GB" }
        if gigaBytes >= 100 { return "128 GB" }
        if gigaBytes >= 50 { return "64 GB" }
        if gigaBytes >= 25 { return "32 GB" }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useTB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return formatter.string(fromByteCount: totalBytes)
    }
    
    private let cacheKey = "TidyMedia_StorageCategoryBreakdown_v1"
    
    @Published var breakdown: StorageCategoryBreakdown
    @Published var isCalculating: Bool = false
    
    private var calculationTask: Task<Void, Never>? = nil
    
    private init() {
        // Load persistent snapshot from UserDefaults for instantaneous 0ms rendering
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode(StorageCategoryBreakdown.self, from: data) {
            self.breakdown = cached
        } else {
            self.breakdown = StorageCategoryBreakdown()
        }
    }
    
    func recalculate(force: Bool = false) {
        calculationTask?.cancel()
        calculationTask = Task { [weak self] in
            await self?.performCalculation()
        }
    }
    
    private func performCalculation() async {
        let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard authStatus == .authorized || authStatus == .limited else { return }
        
        self.isCalculating = true
        defer { self.isCalculating = false }
        
        // Run intensive resource & asset size calculations on a background detached task
        let computedBreakdown = await Task.detached(priority: .userInitiated) { () -> StorageCategoryBreakdown in
            var result = StorageCategoryBreakdown()
            
            // 1. VIDEOS CALCULATION & DUPLICATE VIDEOS
            let videoFetchOptions = PHFetchOptions()
            videoFetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared, .typeiTunesSynced]
            let allVideosFetch = PHAsset.fetchAssets(with: .video, options: videoFetchOptions)
            result.videosCount = allVideosFetch.count
            
            var videoBytesTotal: Int64 = 0
            var videoHashMap: [String: [(asset: PHAsset, size: Int64)]] = [:]
            
            for i in 0..<allVideosFetch.count {
                if Task.isCancelled { break }
                let asset = allVideosFetch.object(at: i)
                var size: Int64 = 0
                
                let resources = PHAssetResource.assetResources(for: asset)
                if let res = resources.first(where: { $0.type == .video }) ?? resources.first {
                    if let sizeNum = res.value(forKey: "fileSize") as? NSNumber {
                        size = sizeNum.int64Value
                    }
                }
                
                if size <= 0 {
                    let duration = max(1.0, asset.duration)
                    let pixels = Double(asset.pixelWidth * asset.pixelHeight)
                    let rateBytesPerSec: Double = pixels > 3_000_000 ? 5_000_000 : 1_800_000
                    size = Int64(duration * rateBytesPerSec)
                }
                
                videoBytesTotal += size
                
                // Track for duplicate video calculation
                let roundedDuration = (asset.duration * 10).rounded() / 10
                let resolution = "\(asset.pixelWidth)x\(asset.pixelHeight)"
                let sig = size > 0 ? "\(size)_\(roundedDuration)_\(resolution)" : "\(roundedDuration)_\(resolution)"
                videoHashMap[sig, default: []].append((asset, size))
            }
            result.videosBytes = videoBytesTotal
            
            // Calculate duplicate video savings (saving 1 copy, trashing remainder)
            var dupVideoBytes: Int64 = 0
            var dupVideoCount: Int = 0
            for (_, group) in videoHashMap where group.count > 1 {
                // Keep the first, count the rest as recoverable
                let redundant = group.dropFirst()
                for item in redundant {
                    dupVideoBytes += item.size
                    dupVideoCount += 1
                }
            }
            result.duplicateVideosBytes = dupVideoBytes
            result.duplicateVideosCount = dupVideoCount
            
            // 2. SCREENSHOTS CALCULATION
            let screenshotFetchOptions = PHFetchOptions()
            screenshotFetchOptions.predicate = NSPredicate(
                format: "(mediaSubtype & %d) != 0",
                PHAssetMediaSubtype.photoScreenshot.rawValue
            )
            let screenshotFetch = PHAsset.fetchAssets(with: .image, options: screenshotFetchOptions)
            result.screenshotsCount = screenshotFetch.count
            
            var screenshotBytesTotal: Int64 = 0
            for i in 0..<screenshotFetch.count {
                if Task.isCancelled { break }
                let asset = screenshotFetch.object(at: i)
                var size: Int64 = 0
                let resources = PHAssetResource.assetResources(for: asset)
                if let res = resources.first(where: { $0.type == .photo || $0.type == .fullSizePhoto }) ?? resources.first {
                    if let sizeNum = res.value(forKey: "fileSize") as? NSNumber {
                        size = sizeNum.int64Value
                    }
                }
                if size <= 0 {
                    size = Int64(asset.pixelWidth * asset.pixelHeight * 4 / 8) // ~1.5MB - 3MB estimate
                }
                screenshotBytesTotal += size
            }
            result.screenshotsBytes = screenshotBytesTotal
            
            // 3. ALL PHOTOS & DUPLICATE PHOTOS CALCULATION
            let photoFetchOptions = PHFetchOptions()
            photoFetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared, .typeiTunesSynced]
            let allPhotosFetch = PHAsset.fetchAssets(with: .image, options: photoFetchOptions)
            let totalPhotos = allPhotosFetch.count
            result.photosCount = totalPhotos
            
            var photoHashMap: [String: [(asset: PHAsset, size: Int64)]] = [:]
            var sampleSizes: [Int64] = []
            let sampleCount = min(totalPhotos, 120) // Fast statistically accurate sample
            
            for i in 0..<totalPhotos {
                if Task.isCancelled { break }
                let asset = allPhotosFetch.object(at: i)
                var size: Int64 = 0
                
                let resources = PHAssetResource.assetResources(for: asset)
                if let res = resources.first(where: { $0.type == .photo || $0.type == .fullSizePhoto }) ?? resources.first {
                    if let sizeNum = res.value(forKey: "fileSize") as? NSNumber {
                        size = sizeNum.int64Value
                    }
                }
                
                if size > 0 && sampleSizes.count < sampleCount {
                    sampleSizes.append(size)
                }
                
                // Track duplicate photo signatures
                let resolution = "\(asset.pixelWidth)x\(asset.pixelHeight)"
                var sig: String
                if size > 0 {
                    sig = "sz_\(size)_\(resolution)"
                } else {
                    let time = Int((asset.creationDate ?? .distantPast).timeIntervalSince1970)
                    sig = "tm_\(resolution)_\(time)"
                }
                photoHashMap[sig, default: []].append((asset, max(size, 2_400_000)))
            }
            
            // Average photo size derived from real metadata
            let avgPhotoSize: Int64 = sampleSizes.isEmpty
                ? 2_800_000
                : sampleSizes.reduce(0, +) / Int64(sampleSizes.count)
            
            // Total photos size (subtracting screenshots from photo count to avoid double count)
            let nonScreenshotPhotos = max(0, totalPhotos - result.screenshotsCount)
            result.photosBytes = Int64(nonScreenshotPhotos) * avgPhotoSize
            
            // Calculate duplicate photos recoverable space
            var dupPhotoBytes: Int64 = 0
            var dupPhotoCount: Int = 0
            for (_, group) in photoHashMap where group.count > 1 {
                let redundant = group.dropFirst()
                for item in redundant {
                    dupPhotoBytes += item.size
                    dupPhotoCount += 1
                }
            }
            result.duplicatePhotosBytes = dupPhotoBytes
            result.duplicatePhotosCount = dupPhotoCount
            result.lastUpdated = Date()
            
            return result
        }.value
        
        guard !Task.isCancelled else { return }
        
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            self.breakdown = computedBreakdown
        }
        
        // Cache snapshot
        if let encoded = try? JSONEncoder().encode(computedBreakdown) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
}
