//
//  GroupMediaDetailView.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/6/26.
//

import SwiftUI
import Photos

// MARK: - Group Detail Presentation Item
struct GroupDetailItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let filterType: PhotoFilterOption
    let initialAssets: [PHAsset]
    let keepOrBestAssetId: String?
    let creationDate: Date?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: GroupDetailItem, rhs: GroupDetailItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Group Media Detail View
struct GroupMediaDetailView: View {
    let groupItem: GroupDetailItem
    @ObservedObject var photoService: PhotoLibraryService
    var onUpdate: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentAssets: [PHAsset] = []
    @State private var isSelectMode: Bool = false
    @State private var selectedAssetIds: Set<String> = []
    @State private var viewerIndex: Int? = nil
    @State private var viewerFetchResult: PHFetchResult<PHAsset>? = nil
    @State private var viewerSessionId: UUID = UUID()
    @State private var showDeleteAlert: Bool = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 5),
        GridItem(.flexible(), spacing: 5),
        GridItem(.flexible(), spacing: 5)
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Top Navigation Bar
                HStack(spacing: 12) {
                    // Back Button
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
                    
                    // Select / Done Pill Button
                    if currentAssets.count > 0 {
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
                                .padding(.vertical, 8)
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
                
                // MARK: - Title & Date Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(groupItem.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 6) {
                        if let date = groupItem.creationDate {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                            Text("•")
                        }
                        Text("\(currentAssets.count) Photos")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                // MARK: - Full Grid Showing All Photos in Group
                if !currentAssets.isEmpty {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 5) {
                            ForEach(0..<currentAssets.count, id: \.self) { index in
                                let asset = currentAssets[index]
                                let isSpecial = asset.localIdentifier == groupItem.keepOrBestAssetId
                                let isSelected = selectedAssetIds.contains(asset.localIdentifier)
                                
                                ZStack(alignment: .bottomTrailing) {
                                    MediaGridThumbnailCell(
                                        asset: asset,
                                        isSelectMode: isSelectMode || !selectedAssetIds.isEmpty,
                                        isSelected: isSelected,
                                        photoService: photoService
                                    )
                                    .id(asset.localIdentifier)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        handleAssetTap(asset: asset, index: index)
                                    }
                                    
                                    // Special Badge (KEEP or BEST)
                                    if isSpecial {
                                        Text(groupItem.filterType == .duplicates ? "KEEP" : "BEST")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(
                                                Capsule().fill(
                                                    groupItem.filterType == .duplicates ? Color.green.opacity(0.85) : Color.appAccent.opacity(0.85)
                                                )
                                            )
                                            .padding(6)
                                            .allowsHitTesting(false)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 110)
                    }
                } else {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.green)
                        Text("All Cleaned Up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            // MARK: - Batch Action Bar (When in Select Mode)
            if isSelectMode || !selectedAssetIds.isEmpty {
                HStack {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if selectedAssetIds.count == currentAssets.count {
                            selectedAssetIds.removeAll()
                        } else {
                            selectedAssetIds = Set(currentAssets.map(\.localIdentifier))
                        }
                    } label: {
                        Text(selectedAssetIds.count == currentAssets.count && !currentAssets.isEmpty ? "Deselect All" : "Select All")
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
                .padding(.bottom, 30)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Fullscreen Photo Viewer Overlay
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
                        reloadAssetsAfterDelete()
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
        .onAppear {
            self.currentAssets = groupItem.initialAssets
        }
    }
    
    private func handleAssetTap(asset: PHAsset, index: Int) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if isSelectMode || !selectedAssetIds.isEmpty {
            if selectedAssetIds.contains(asset.localIdentifier) {
                selectedAssetIds.remove(asset.localIdentifier)
            } else {
                selectedAssetIds.insert(asset.localIdentifier)
            }
        } else {
            let ids = currentAssets.map(\.localIdentifier)
            let fetch = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
            var finalIndex = 0
            for i in 0..<fetch.count {
                if fetch.object(at: i).localIdentifier == asset.localIdentifier {
                    finalIndex = i
                    break
                }
            }
            self.viewerFetchResult = fetch
            self.viewerSessionId = UUID()
            withAnimation(.easeInOut(duration: 0.22)) {
                self.viewerIndex = finalIndex
            }
        }
    }
    
    private func deleteSelected() {
        guard !selectedAssetIds.isEmpty else { return }
        let toDelete = currentAssets.filter { selectedAssetIds.contains($0.localIdentifier) }
        Task {
            do {
                try await photoService.deleteAssets(toDelete)
                selectedAssetIds.removeAll()
                isSelectMode = false
                reloadAssetsAfterDelete()
                onUpdate()
            } catch {
                print("Failed to delete group assets: \(error)")
            }
        }
    }
    
    private func reloadAssetsAfterDelete() {
        let remainingIds = currentAssets.map(\.localIdentifier)
        let freshFetch = PHAsset.fetchAssets(withLocalIdentifiers: remainingIds, options: nil)
        var updated: [PHAsset] = []
        for i in 0..<freshFetch.count {
            updated.append(freshFetch.object(at: i))
        }
        self.currentAssets = updated
        if updated.count <= 1 {
            // Dismiss if 1 or 0 photos left in group
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        }
    }
}
