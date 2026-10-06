//
//  RecentlyDeletedView.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/6/26.
//

import SwiftUI
import Photos
import AVFoundation

struct RecentlyDeletedView: View {
    @ObservedObject private var service = RecentlyDeletedService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var isSelectMode: Bool = false
    @State private var selectedIds: Set<String> = []
    
    // Alert State
    @State private var showRecoverAlert: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var itemsForAction: [RecentlyDeletedItem] = []
    
    // Single Item Preview State
    @State private var previewItem: RecentlyDeletedItem? = nil
    
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
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color(uiColor: .secondarySystemBackground)))
                    }
                    .buttonStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recently Deleted")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(service.items.count) Items")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !service.items.isEmpty {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSelectMode.toggle()
                                if !isSelectMode {
                                    selectedIds.removeAll()
                                }
                            }
                        } label: {
                            Text(isSelectMode ? "Done" : "Select")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(Color(uiColor: .secondarySystemBackground)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // MARK: - Content
                if service.items.isEmpty {
                    emptyStateView
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            // Apple-style Policy Notice
                            HStack(spacing: 8) {
                                Image(systemName: "clock")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("Items show the days remaining before permanent deletion. You can recover them anytime.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            
                            // 3-Column Square Grid
                            LazyVGrid(columns: columns, spacing: 5) {
                                ForEach(service.items) { item in
                                    let isSelected = selectedIds.contains(item.id)
                                    
                                    RecentlyDeletedCell(
                                        item: item,
                                        isSelectMode: isSelectMode,
                                        isSelected: isSelected,
                                        onTap: {
                                            handleTap(item: item)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 120)
                    }
                }
            }
            
            // MARK: - Batch Action Bar (When in Select Mode)
            if isSelectMode || !selectedIds.isEmpty {
                batchActionBar
            }
        }
        .confirmationDialog(
            "Recover Items?",
            isPresented: $showRecoverAlert,
            titleVisibility: .visible
        ) {
            Button("Recover \(itemsForAction.count) Items to Photos") {
                Task {
                    do {
                        try await service.recoverItems(itemsForAction)
                        selectedIds.removeAll()
                        isSelectMode = false
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } catch {
                        print("Failed to recover: \(error)")
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("These items will be restored to your Photos library in their original order.")
        }
        .confirmationDialog(
            "Delete Permanently?",
            isPresented: $showDeleteAlert,
            titleVisibility: .visible
        ) {
            Button("Delete \(itemsForAction.count) Items Permanently", role: .destructive) {
                service.deletePermanently(itemsForAction)
                selectedIds.removeAll()
                isSelectMode = false
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("These items will be completely removed and cannot be recovered.")
        }
        .sheet(item: $previewItem) { item in
            RecentlyDeletedDetailView(
                item: item,
                onRecover: {
                    Task {
                        try? await service.recoverItems([item])
                        previewItem = nil
                    }
                },
                onDeletePermanently: {
                    service.deletePermanently([item])
                    previewItem = nil
                }
            )
        }
        .onAppear {
            service.reload()
        }
    }
    
    // MARK: - Tap Handler
    private func handleTap(item: RecentlyDeletedItem) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if isSelectMode || !selectedIds.isEmpty {
            if selectedIds.contains(item.id) {
                selectedIds.remove(item.id)
            } else {
                selectedIds.insert(item.id)
            }
        } else {
            previewItem = item
        }
    }
    
    // MARK: - Batch Action Bar
    private var batchActionBar: some View {
        HStack(spacing: 12) {
            // Delete Action Button
            Button {
                let targets = selectedIds.isEmpty ? service.items : service.items.filter { selectedIds.contains($0.id) }
                itemsForAction = targets
                showDeleteAlert = true
            } label: {
                Text(selectedIds.isEmpty ? "Delete All" : "Delete (\(selectedIds.count))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color(white: 0.20))
                    )
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            if !selectedIds.isEmpty {
                Text("\(selectedIds.count) of \(service.items.count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            // Recover Action Button
            Button {
                let targets = selectedIds.isEmpty ? service.items : service.items.filter { selectedIds.contains($0.id) }
                itemsForAction = targets
                showRecoverAlert = true
            } label: {
                Text(selectedIds.isEmpty ? "Recover All" : "Recover (\(selectedIds.count))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color(white: 0.20))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
                .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Spacer()
            
            Image(systemName: "trash")
                .font(.system(size: 52, weight: .light))
                .foregroundColor(.gray.opacity(0.45))
            
            Text("No Recently Deleted Items")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Photos and videos you delete will appear here for 30 days before being permanently removed.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

// MARK: - Grid Cell
private struct RecentlyDeletedCell: View {
    let item: RecentlyDeletedItem
    let isSelectMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var thumbnail: UIImage? = nil
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                if let thumb = thumbnail {
                    Image(uiImage: thumb)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(white: 0.12))
                        .overlay(ProgressView().scaleEffect(0.7).tint(.white))
                }
                
                // Days remaining badge (Top Left)
                VStack {
                    HStack {
                        Text("\(item.daysRemaining)d")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.65))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.5))
                            )
                            .padding(5)
                        
                        Spacer()
                    }
                    Spacer()
                }
                
                // Video duration badge (Bottom Left)
                if item.isVideo {
                    HStack(spacing: 3) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 8))
                        Text(item.formattedDuration)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.black.opacity(0.65)))
                    .padding(5)
                }
                
                // Select Checkmark (Top Right)
                if isSelectMode || isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Color.appAccent : Color.black.opacity(0.4))
                                    .frame(width: 22, height: 22)
                                Circle()
                                    .stroke(Color.white, lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(6)
                        }
                        Spacer()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            .onAppear {
                if thumbnail == nil {
                    thumbnail = RecentlyDeletedService.shared.loadThumbnail(for: item)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Single Item Detail & Recover Sheet
private struct RecentlyDeletedDetailView: View {
    let item: RecentlyDeletedItem
    let onRecover: () -> Void
    let onDeletePermanently: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer? = nil
    @State private var image: UIImage? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            
            // Media Preview
            VStack {
                Spacer()
                if item.isVideo {
                    if let player = player {
                        VideoPlayerRepresentable(player: player)
                            .aspectRatio(contentMode: .fit)
                    } else {
                        ProgressView().tint(.white)
                    }
                } else {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        ProgressView().tint(.white)
                    }
                }
                Spacer()
            }
            
            // Top Bar with Close Button
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color(white: 0.18)))
                    }
                    .padding(.leading, 16)
                    .padding(.top, 16)
                    
                    Spacer()
                }
                Spacer()
            }
            
            // Bottom Action Bar: Delete and Recover
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    // Simple Delete Button (Left)
                    Button(role: .destructive) {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        onDeletePermanently()
                    } label: {
                        Text("Delete")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color(white: 0.18))
                            )
                    }
                    .buttonStyle(.plain)
                    
                    // Simple Recover Button (Right)
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onRecover()
                    } label: {
                        Text("Recover")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color(white: 0.18))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.0), Color.black.opacity(0.8), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .task {
            let fileURL = RecentlyDeletedService.shared.getFileURL(for: item)
            if item.isVideo {
                self.player = AVPlayer(url: fileURL)
                self.player?.play()
            } else {
                self.image = UIImage(contentsOfFile: fileURL.path)
            }
        }
    }
}
