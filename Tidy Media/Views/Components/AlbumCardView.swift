//
//  AlbumCardView.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/5/26.
//

import SwiftUI
import Photos

struct AlbumCardView: View {
    let item: AlbumItem
    @ObservedObject var photoService: PhotoLibraryService
    
    @State private var thumbnailImage: UIImage? = nil
    @State private var isLoadingImage: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Album Thumbnail Box
            ZStack {
                // Background Gradient Placeholder
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
                    // Placeholder Icon when no image or loading
                    VStack(spacing: 6) {
                        Image(systemName: item.systemIcon)
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .frame(height: 165)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            
            // Album Title & Count
            VStack(spacing: 3) {
                Text(item.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(item.count > 0 ? "\(item.count.formatted())" : "0")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
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
        isLoadingImage = true
        photoService.loadProgressiveThumbnail(for: asset, targetSize: CGSize(width: 600, height: 600)) { img in
            self.thumbnailImage = img
            self.isLoadingImage = false
        }
    }
}
