//
//  CompactAlbumCardView.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/5/26.
//

import SwiftUI
import Photos

struct CompactAlbumCardView: View {
    let item: AlbumItem
    @ObservedObject var photoService: PhotoLibraryService
    
    @State private var thumbnailImage: UIImage? = nil
    @State private var isLoadingImage: Bool = false
    
    init(item: AlbumItem, photoService: PhotoLibraryService) {
        self.item = item
        self.photoService = photoService
        if let asset = item.keyAsset, let cached = photoService.cachedThumbnail(for: asset.localIdentifier) {
            self._thumbnailImage = State(initialValue: cached)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background Image or Placeholder Gradient
            ZStack {
                LinearGradient(
                    colors: item.gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipped()
                        .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                } else {
                    Image(systemName: item.systemIcon)
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.white.opacity(0.55))
                        .offset(y: -10)
                }
            }
            .frame(height: 115)
            
            // Bottom Dark Gradient for Title & Count Readability
            LinearGradient(
                colors: [
                    Color.black.opacity(0.88),
                    Color.black.opacity(0.55),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 55)
            
            // Compact Title & Item Count Overlay
            VStack(spacing: 2) {
                Text(item.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                
                Text(item.count > 0 ? "\(item.count.formatted())" : "0")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.75))
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 6)
            .padding(.bottom, 8)
        }
        .frame(height: 115)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.7)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
        .contentShape(Rectangle())
        .task(id: item.keyAsset?.localIdentifier) {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        guard let asset = item.keyAsset else {
            thumbnailImage = nil
            return
        }
        if let cached = photoService.cachedThumbnail(for: asset.localIdentifier) {
            self.thumbnailImage = cached
            return
        }
        isLoadingImage = true
        photoService.loadHighQualityThumbnail(for: asset, targetSize: CGSize(width: 400, height: 400)) { img in
            self.thumbnailImage = img
            self.isLoadingImage = false
        }
    }
}
