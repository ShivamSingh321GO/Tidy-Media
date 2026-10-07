//
//  AlbumDetailView.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/5/26.
//

import SwiftUI
import Photos

struct AlbumDetailView: View {
    let album: AlbumItem
    @ObservedObject var photoService: PhotoLibraryService
    @Environment(\.dismiss) private var dismiss
    
    // Grid State
    @State private var fetchResult: PHFetchResult<PHAsset>? = nil
    @State private var isSelectMode: Bool = false
    @State private var selectedAssetIds: Set<String> = []
    @State private var viewerIndex: Int? = nil
    @State private var showDeleteAlert: Bool = false
    
    init(album: AlbumItem, photoService: PhotoLibraryService) {
        self.album = album
        self.photoService = photoService
        self._fetchResult = State(initialValue: photoService.fetchAssets(for: album))
    }
    
    // 3-Column Square Grid matching Image 2 & 3
    private let columns = [
        GridItem(.flexible(), spacing: 5),
        GridItem(.flexible(), spacing: 5),
        GridItem(.flexible(), spacing: 5)
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Top Navigation Bar (Matching Image 2 & 3)
                HStack(spacing: 12) {
                    // Circular Back Button
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color(uiColor: .secondarySystemBackground))
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Pill Select / Done Button
                    if assetCount > 0 {
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
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color(uiColor: .secondarySystemBackground))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // MARK: - Title & Subtitle Header (Matching Image 2 & 3)
                VStack(alignment: .leading, spacing: 4) {
                    Text(album.title)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 5) {
                        Image(systemName: subtitleIcon)
                            .font(.system(size: 13, weight: .medium))
                        Text("\(assetCount) \(assetCount == 1 ? "Item" : "Items")")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 14)
                
                // MARK: - 3-Column Square Image Grid
                if let results = fetchResult, results.count > 0 {
                    ScrollView(showsIndicators: false) {
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
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if isSelectMode {
                                        if isSelected {
                                            selectedAssetIds.remove(asset.localIdentifier)
                                        } else {
                                            selectedAssetIds.insert(asset.localIdentifier)
                                        }
                                    } else {
                                        let trueIndex = results.index(of: asset)
                                        let finalIndex = (trueIndex != NSNotFound) ? trueIndex : index
                                        withAnimation(.easeInOut(duration: 0.22)) {
                                            viewerIndex = finalIndex
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                } else {
                    // Empty State
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: album.systemIcon)
                            .font(.system(size: 44, weight: .light))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No Items in \(album.title)")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("Photos and videos saved to this album will appear here.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            // MARK: - Batch Action Bar (When in Select Mode)
            if isSelectMode {
                // Batch Action Bar (When in Select Mode)
                HStack {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if let results = fetchResult {
                            if selectedAssetIds.count == results.count {
                                selectedAssetIds.removeAll()
                            } else {
                                var allIds = Set<String>()
                                for i in 0..<results.count {
                                    allIds.insert(results.object(at: i).localIdentifier)
                                }
                                selectedAssetIds = allIds
                            }
                        }
                    } label: {
                        Text(selectedAssetIds.count == assetCount ? "Deselect All" : "Select All")
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
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // MARK: - Fullscreen Photo Viewer Overlay (Swipable Paging)
            if let index = viewerIndex, let results = fetchResult, results.count > 0 {
                FullScreenMediaView(
                    fetchResult: results,
                    initialIndex: index,
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewerIndex = nil
                        }
                    },
                    onDelete: {
                        loadAssets()
                    },
                    photoService: photoService
                )
                .id("album_viewer_\(index)_\(results.count)")
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
        .onAppear {
            if let results = fetchResult, results.count > 0 {
                let count = min(results.count, 45)
                var initialAssets: [PHAsset] = []
                for i in 0..<count {
                    initialAssets.append(results.object(at: i))
                }
                photoService.preheatThumbnails(for: initialAssets, targetSize: CGSize(width: 360, height: 360))
            }
        }
    }
    
    private var assetCount: Int {
        fetchResult?.count ?? 0
    }
    
    private var subtitleIcon: String {
        switch album.categoryType {
        case .videos, .duplicateVideos, .largeVideos:
            return "video.fill"
        case .screenshots:
            return "iphone.gen3"
        default:
            return "photo.stack"
        }
    }
    
    private func loadAssets() {
        let results = photoService.fetchAssets(for: album)
        self.fetchResult = results
        if results.count > 0 {
            let count = min(results.count, 45)
            var initialAssets: [PHAsset] = []
            for i in 0..<count {
                initialAssets.append(results.object(at: i))
            }
            photoService.preheatThumbnails(for: initialAssets, targetSize: CGSize(width: 360, height: 360))
        }
    }
    
    private func deleteSelected() {
        guard let results = fetchResult else { return }
        var assetsToDelete: [PHAsset] = []
        for i in 0..<results.count {
            let asset = results.object(at: i)
            if selectedAssetIds.contains(asset.localIdentifier) {
                assetsToDelete.append(asset)
            }
        }
        
        Task {
            do {
                try await photoService.deleteAssets(assetsToDelete)
                selectedAssetIds.removeAll()
                isSelectMode = false
                loadAssets()
                photoService.loadLibraryStats()
            } catch {
                print("Failed to delete assets: \(error.localizedDescription)")
            }
        }
    }
}
