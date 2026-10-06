//
//  AlbumsGridView.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/5/26.
//

import SwiftUI
import Photos

struct AlbumsGridView: View {
    @ObservedObject var viewModel: MainViewModel
    @ObservedObject private var photoService = PhotoLibraryService.shared
    @ObservedObject private var recentlyDeletedService = RecentlyDeletedService.shared
    var zoomNamespace: Namespace.ID? = nil
    
    @State private var showRecentlyDeleted: Bool = false
    
    // 2-Column Grid for the 4 Pinned Categories
    private let pinnedColumns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    // 3-Column Grid for All Other Categories (Smaller size)
    private let otherColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Pinned Top Header
            HStack(alignment: .center) {
                Text(headerTitle)
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color(uiColor: .systemBackground))
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Subtle Limited Access indicator
                    if viewModel.photoService.authorizationStatus == .limited {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                            Text("Limited photo access. Tap to manage selection.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary.opacity(0.85))
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemBackground))
                        )
                        .padding(.horizontal, 16)
                        .onTapGesture {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    
                    // MARK: - 1. Pinned Top 4 Categories (2-Column Grid, Large)
                    if !viewModel.pinnedAlbums.isEmpty {
                        LazyVGrid(columns: pinnedColumns, spacing: 20) {
                            ForEach(viewModel.pinnedAlbums) { album in
                                pinnedCard(for: album)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // MARK: - 2. Other Categories (3-Column Grid, Smaller Height & Width)
                    if !viewModel.otherAlbums.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            LazyVGrid(columns: otherColumns, spacing: 10) {
                                ForEach(viewModel.otherAlbums) { album in
                                    otherCard(for: album)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    } else if viewModel.photoService.authorizationStatus == .authorized ||
                                viewModel.photoService.authorizationStatus == .limited {
                        VStack(spacing: 8) {
                            Image(systemName: "square.stack.3d.down.forward")
                                .font(.system(size: 28, weight: .light))
                                .foregroundColor(.primary.opacity(0.35))
                                .padding(.top, 12)
                            
                            Text("No Third-Party App Albums")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Photos saved from apps like WhatsApp, Telegram, or Downloads will automatically appear here.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                    
                    if viewModel.isSearchPresented && !viewModel.searchText.isEmpty &&
                       viewModel.pinnedAlbums.isEmpty && viewModel.otherAlbums.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 38, weight: .light))
                                .foregroundColor(.primary.opacity(0.35))
                                .padding(.top, 40)
                            
                            Text("No Results for \"\(viewModel.searchText)\"")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Check your spelling or search for another album.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    }
                    
                    // MARK: - 3. Utilities Section (Recently Deleted)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Utilities")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showRecentlyDeleted = true
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Recently Deleted")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("\(recentlyDeletedService.items.count) Items")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
                                )
                        )
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer(minLength: 120) // Extra padding for the floating bottom bar
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                viewModel.refresh()
            }
        }
        }
        .navigationDestination(isPresented: $showRecentlyDeleted) {
            RecentlyDeletedView()
                .navigationBarBackButtonHidden(true)
        }
        .task {
            if photoService.authorizationStatus == .authorized || photoService.authorizationStatus == .limited {
                photoService.loadLibraryStats()
            }
        }
        .onAppear {
            recentlyDeletedService.reload()
        }
    }
    
    private var headerTitle: String {
        if viewModel.isSearchPresented {
            return viewModel.searchText.isEmpty ? "Search" : "Results"
        }
        switch viewModel.selectedTab {
        case .all: return "Albums"
        case .photos: return "Photos"
        case .videos: return "Videos"
        }
    }
    
    @ViewBuilder
    private func pinnedCard(for album: AlbumItem) -> some View {
        let card = AlbumCardView(
            item: album,
            photoService: viewModel.photoService
        )
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.selectedAlbum = album
        }
        
        if let ns = zoomNamespace {
            card.matchedTransitionSource(id: album.id, in: ns)
        } else {
            card
        }
    }
    
    @ViewBuilder
    private func otherCard(for album: AlbumItem) -> some View {
        let card = CompactAlbumCardView(
            item: album,
            photoService: viewModel.photoService
        )
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.selectedAlbum = album
        }
        
        if let ns = zoomNamespace {
            card.matchedTransitionSource(id: album.id, in: ns)
        } else {
            card
        }
    }
}
