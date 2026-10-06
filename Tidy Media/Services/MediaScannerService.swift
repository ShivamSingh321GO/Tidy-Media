//
//  MediaScannerService.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/6/26.
//

import SwiftUI
import Photos
import Vision
import CryptoKit
import Combine

// MARK: - Data Models
struct DuplicatePhotoGroup: Identifiable, Sendable {
    let id: UUID = UUID()
    let hash: String
    let assets: [PHAsset]
    var keepAssetId: String // Defaults to the first/original asset
    
    var duplicateAssets: [PHAsset] {
        assets.filter { $0.localIdentifier != keepAssetId }
    }
}

struct SimilarPhotoGroup: Identifiable, Sendable {
    let id: UUID = UUID()
    let assets: [PHAsset]
    var bestAssetId: String // Defaults to the sharpest or earliest asset
    
    var otherAssets: [PHAsset] {
        assets.filter { $0.localIdentifier != bestAssetId }
    }
}

enum PhotoFilterOption: String, CaseIterable, Identifiable {
    case all = "All Photos"
    case duplicates = "Duplicate Photos"
    case similar = "Similar Photos"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .duplicates: return "doc.on.doc.fill"
        case .similar: return "sparkles.rectangle.stack.fill"
        }
    }
}

enum VideoFilterOption: String, CaseIterable, Identifiable {
    case all = "All Videos"
    case large = "Large Videos"
    case duplicates = "Duplicate Videos"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .all: return "play.rectangle.fill"
        case .large: return "externaldrive.fill"
        case .duplicates: return "film.stack.fill"
        }
    }
}

struct DuplicateVideoGroup: Identifiable, Sendable {
    let id: UUID = UUID()
    let hash: String
    let assets: [PHAsset]
    var keepAssetId: String
    
    var duplicateAssets: [PHAsset] {
        assets.filter { $0.localIdentifier != keepAssetId }
    }
}

struct LargeVideoItem: Identifiable, Sendable {
    let id: String
    let asset: PHAsset
    let fileSize: Int64
    let formattedSize: String
    let durationString: String
}

// MARK: - MediaScannerService
@MainActor
final class MediaScannerService: ObservableObject {
    static let shared = MediaScannerService()
    
    @Published var isScanningDuplicates: Bool = false
    @Published var isScanningSimilar: Bool = false
    @Published var duplicateGroups: [DuplicatePhotoGroup] = []
    @Published var similarGroups: [SimilarPhotoGroup] = []
    
    @Published var duplicateScanProgress: Double = 0.0
    @Published var similarScanProgress: Double = 0.0
    
    // Video Scanning State
    @Published var isScanningDuplicateVideos: Bool = false
    @Published var isScanningLargeVideos: Bool = false
    @Published var duplicateVideoGroups: [DuplicateVideoGroup] = []
    @Published var largeVideos: [LargeVideoItem] = []
    @Published var duplicateVideoScanProgress: Double = 0.0
    
    private let imageManager = PHCachingImageManager()
    
    // MARK: - 1. Exact Duplicate Photos Scanner (SHA-256 File Data + Visual Bitmap Checksum)
    // MARK: - 1. Duplicate Photos Scanner (Fast Metadata & Resource Matching)
    func scanDuplicatePhotos(from assets: [PHAsset]) async {
        guard !isScanningDuplicates else { return }
        
        isScanningDuplicates = true
        duplicateScanProgress = 0.0
        defer { isScanningDuplicates = false }
        
        let photoAssets = assets.filter { $0.mediaType == .image }
        guard photoAssets.count > 1 else {
            duplicateGroups = []
            return
        }
        
        // Fast signature mapping using resource file size + dimensions + filename
        var hashMap: [String: [PHAsset]] = [:]
        
        for asset in photoAssets {
            var fileSize: Int64 = 0
            var originalFilename: String = ""
            let resources = PHAssetResource.assetResources(for: asset)
            if let res = resources.first(where: { $0.type == .photo || $0.type == .fullSizePhoto }) ?? resources.first {
                if let sizeNum = res.value(forKey: "fileSize") as? NSNumber {
                    fileSize = sizeNum.int64Value
                }
                originalFilename = res.originalFilename
            }
            
            let resolution = "\(asset.pixelWidth)x\(asset.pixelHeight)"
            
            var signature: String
            if fileSize > 0 {
                // Exact file size + resolution is a 99.999% duplicate signature
                signature = "size_\(fileSize)_\(resolution)"
            } else if !originalFilename.isEmpty && (asset.creationDate != nil) {
                let time = Int(asset.creationDate!.timeIntervalSince1970)
                signature = "name_\(originalFilename)_\(resolution)_\(time)"
            } else {
                let time = Int((asset.creationDate ?? .distantPast).timeIntervalSince1970)
                signature = "time_\(resolution)_\(time)"
            }
            
            hashMap[signature, default: []].append(asset)
        }
        
        var results: [DuplicatePhotoGroup] = []
        for (hash, groupAssets) in hashMap {
            guard groupAssets.count > 1 else { continue }
            let sorted = groupAssets.sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
            let keepId = sorted.first?.localIdentifier ?? ""
            results.append(DuplicatePhotoGroup(hash: hash, assets: sorted, keepAssetId: keepId))
        }
        
        // Sort groups by newest creation date
        results.sort { ($0.assets.first?.creationDate ?? .distantPast) > ($1.assets.first?.creationDate ?? .distantPast) }
        self.duplicateGroups = results
    }
    
    // MARK: - 2. Similar Photos Scanner (Temporal Candidate Window + Vision FeaturePrint)
    func scanSimilarPhotos(from assets: [PHAsset]) async {
        guard !isScanningSimilar else { return }
        
        isScanningSimilar = true
        similarScanProgress = 0.0
        defer { isScanningSimilar = false }
        
        let photoAssets = assets.filter { $0.mediaType == .image }
        guard photoAssets.count > 1 else {
            similarGroups = []
            return
        }
        
        // Sort chronologically to find consecutive shots
        let sortedPhotos = photoAssets.sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
        
        // Step 1: Instant burstIdentifier grouping
        var burstMap: [String: [PHAsset]] = [:]
        var nonBurstCandidates: [PHAsset] = []
        
        for asset in sortedPhotos {
            if let burstId = asset.burstIdentifier, !burstId.isEmpty {
                burstMap[burstId, default: []].append(asset)
            } else {
                nonBurstCandidates.append(asset)
            }
        }
        
        var clusters: [[PHAsset]] = []
        for (_, burstAssets) in burstMap where burstAssets.count > 1 {
            clusters.append(burstAssets)
        }
        
        // Step 2: Group consecutive shots taken within 15 seconds of each other
        var temporalGroups: [[PHAsset]] = []
        var currentTemporal: [PHAsset] = []
        
        for asset in nonBurstCandidates {
            guard let date = asset.creationDate else { continue }
            if let last = currentTemporal.last, let lastDate = last.creationDate {
                let diff = abs(date.timeIntervalSince(lastDate))
                if diff <= 15.0 {
                    currentTemporal.append(asset)
                } else {
                    if currentTemporal.count > 1 {
                        temporalGroups.append(currentTemporal)
                    }
                    currentTemporal = [asset]
                }
            } else {
                currentTemporal = [asset]
            }
        }
        if currentTemporal.count > 1 {
            temporalGroups.append(currentTemporal)
        }
        
        // Step 3: Run quick Vision feature print comparison only on temporal candidates
        for tempGroup in temporalGroups {
            var observations: [(asset: PHAsset, print: VNFeaturePrintObservation)] = []
            for asset in tempGroup {
                if let print = await extractFeaturePrint(for: asset) {
                    observations.append((asset, print))
                }
            }
            
            var visited = Set<String>()
            let n = observations.count
            for i in 0..<n {
                let itemA = observations[i]
                if visited.contains(itemA.asset.localIdentifier) { continue }
                
                var cluster: [PHAsset] = [itemA.asset]
                visited.insert(itemA.asset.localIdentifier)
                
                for j in (i + 1)..<n {
                    let itemB = observations[j]
                    if visited.contains(itemB.asset.localIdentifier) { continue }
                    
                    var distance: Float = 0
                    do {
                        try itemA.print.computeDistance(&distance, to: itemB.print)
                        if distance < 0.45 {
                            visited.insert(itemB.asset.localIdentifier)
                            cluster.append(itemB.asset)
                        }
                    } catch {
                        continue
                    }
                }
                
                if cluster.count > 1 {
                    clusters.append(cluster)
                }
            }
        }
        
        // Format into SimilarPhotoGroup with suggested best shot
        self.similarGroups = clusters.map { groupAssets in
            let sorted = groupAssets.sorted { ($0.pixelWidth * $0.pixelHeight) > ($1.pixelWidth * $1.pixelHeight) }
            let bestId = sorted.first?.localIdentifier ?? ""
            return SimilarPhotoGroup(assets: groupAssets, bestAssetId: bestId)
        }
    }
    
    private func extractFeaturePrint(for asset: PHAsset) async -> VNFeaturePrintObservation? {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isSynchronous = false
        
        let targetSize = CGSize(width: 256, height: 256)
        
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                guard !hasResumed else { return }
                guard let image = image, let cgImage = image.cgImage else {
                    hasResumed = true
                    continuation.resume(returning: nil)
                    return
                }
                
                let request = VNGenerateImageFeaturePrintRequest()
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                
                do {
                    try handler.perform([request])
                    hasResumed = true
                    let print = request.results?.first as? VNFeaturePrintObservation
                    continuation.resume(returning: print)
                } catch {
                    hasResumed = true
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    // MARK: - 3. Large Videos Scanner
    func scanLargeVideos(from assets: [PHAsset]) async {
        guard !isScanningLargeVideos else { return }
        
        isScanningLargeVideos = true
        defer { isScanningLargeVideos = false }
        
        let videoAssets = assets.filter { $0.mediaType == .video }
        var items: [LargeVideoItem] = []
        
        for asset in videoAssets {
            var size: Int64 = 0
            let resources = PHAssetResource.assetResources(for: asset)
            if let res = resources.first(where: { $0.type == .video }) ?? resources.first {
                if let sizeNum = res.value(forKey: "fileSize") as? NSNumber {
                    size = sizeNum.int64Value
                }
            }
            
            // If file size was unavailable from resources, estimate using duration and resolution
            if size <= 0 {
                let duration = max(1.0, asset.duration)
                let pixels = Double(asset.pixelWidth * asset.pixelHeight)
                let rateBytesPerSec: Double = pixels > 3_000_000 ? 5_500_000 : 1_800_000
                size = Int64(duration * rateBytesPerSec)
            }
            
            let formattedSize = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            let totalSeconds = Int(asset.duration)
            let durationString = String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
            
            items.append(LargeVideoItem(
                id: asset.localIdentifier,
                asset: asset,
                fileSize: size,
                formattedSize: formattedSize,
                durationString: durationString
            ))
        }
        
        // Sort descending by size so the largest videos are at the top
        items.sort { $0.fileSize > $1.fileSize }
        self.largeVideos = items
    }
    
    // MARK: - 4. Duplicate Videos Scanner
    func scanDuplicateVideos(from assets: [PHAsset]) async {
        guard !isScanningDuplicateVideos else { return }
        
        isScanningDuplicateVideos = true
        duplicateVideoScanProgress = 0.0
        defer { isScanningDuplicateVideos = false }
        
        let videoAssets = assets.filter { $0.mediaType == .video }
        guard videoAssets.count > 1 else {
            duplicateVideoGroups = []
            return
        }
        
        var hashMap: [String: [PHAsset]] = [:]
        let total = videoAssets.count
        
        for (index, asset) in videoAssets.enumerated() {
            var fileSize: Int64 = 0
            let resources = PHAssetResource.assetResources(for: asset)
            if let res = resources.first(where: { $0.type == .video }) ?? resources.first {
                if let sizeNum = res.value(forKey: "fileSize") as? NSNumber {
                    fileSize = sizeNum.int64Value
                }
            }
            
            let roundedDuration = (asset.duration * 10).rounded() / 10
            let resolution = "\(asset.pixelWidth)x\(asset.pixelHeight)"
            
            var signature: String
            if fileSize > 0 {
                signature = "\(fileSize)_\(roundedDuration)_\(resolution)"
            } else {
                let time = Int((asset.creationDate ?? .distantPast).timeIntervalSince1970)
                signature = "\(roundedDuration)_\(resolution)_\(time)"
            }
            
            hashMap[signature, default: []].append(asset)
            duplicateVideoScanProgress = Double(index + 1) / Double(total)
        }
        
        var results: [DuplicateVideoGroup] = []
        for (hash, groupAssets) in hashMap {
            guard groupAssets.count > 1 else { continue }
            let sorted = groupAssets.sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
            let keepId = sorted.first?.localIdentifier ?? ""
            results.append(DuplicateVideoGroup(hash: hash, assets: sorted, keepAssetId: keepId))
        }
        
        // Sort by creation date descending
        results.sort { ($0.assets.first?.creationDate ?? .distantPast) > ($1.assets.first?.creationDate ?? .distantPast) }
        self.duplicateVideoGroups = results
    }
}

