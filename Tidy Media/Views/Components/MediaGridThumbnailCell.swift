//
//  MediaGridThumbnailCell.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/5/26.
//

import SwiftUI
import Photos

struct MediaGridThumbnailCell: View {
    let asset: PHAsset
    let isSelectMode: Bool
    let isSelected: Bool
    @ObservedObject var photoService: PhotoLibraryService
    
    @State private var thumbnail: UIImage? = nil
    @State private var currentLoadedId: String? = nil
    @State private var requestID: PHImageRequestID? = nil
    
    init(asset: PHAsset, isSelectMode: Bool, isSelected: Bool, photoService: PhotoLibraryService) {
        self.asset = asset
        self.isSelectMode = isSelectMode
        self.isSelected = isSelected
        self.photoService = photoService
        if let cached = photoService.cachedThumbnail(for: asset.localIdentifier) {
            self._thumbnail = State(initialValue: cached)
            self._currentLoadedId = State(initialValue: asset.localIdentifier)
        }
    }
    
    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                GeometryReader { proxy in
                    ZStack(alignment: .bottomTrailing) {
                        // Base Image Container strictly clipped to cell geometry
                        ZStack {
                            Color(uiColor: .systemGray6)
                            
                            if let image = thumbnail {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: proxy.size.width, height: proxy.size.height)
                                    .clipped()
                                    .transition(.opacity.animation(.easeInOut(duration: 0.15)))
                            }
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        
                        // Video Duration Badge (Bottom Right)
                        if asset.mediaType == .video {
                            HStack(spacing: 3) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 8))
                                Text(formatDuration(asset.duration))
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.65))
                            )
                            .padding(5)
                        }
                        
                        // Favorite Star/Heart Badge (Top Right)
                        if asset.isFavorite {
                            VStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.pink)
                                        .shadow(color: .black.opacity(0.4), radius: 2)
                                        .padding(5)
                                }
                                Spacer()
                            }
                        }
                        
                        // Select Mode Circle Overlay (Top Left)
                        if isSelectMode {
                            VStack {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .stroke(Color.white, lineWidth: 1.5)
                                            .background(Circle().fill(Color.black.opacity(0.2)))
                                            .frame(width: 22, height: 22)
                                        
                                        if isSelected {
                                            Circle()
                                                .fill(Color.appAccent)
                                                .frame(width: 22, height: 22)
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(6)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onAppear {
                loadCellThumbnail()
            }
            .onChange(of: asset.localIdentifier) { _, _ in
                loadCellThumbnail()
            }
            .onDisappear {
                if let id = requestID {
                    photoService.cancelImageRequest(id)
                    requestID = nil
                }
            }
    }
    
    private func loadCellThumbnail() {
        if currentLoadedId == asset.localIdentifier && thumbnail != nil {
            return
        }
        
        if let id = requestID {
            photoService.cancelImageRequest(id)
            requestID = nil
        }
        
        if let cached = photoService.cachedThumbnail(for: asset.localIdentifier) {
            self.thumbnail = cached
            self.currentLoadedId = asset.localIdentifier
            return
        }
        
        self.thumbnail = nil
        self.currentLoadedId = asset.localIdentifier
        
        let targetId = asset.localIdentifier
        self.requestID = photoService.requestThumbnail(for: asset, targetSize: CGSize(width: 360, height: 360)) { img in
            if self.asset.localIdentifier == targetId {
                if let img = img {
                    self.thumbnail = img
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
