//
//  FullScreenMediaView.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/5/26.
//

import SwiftUI
import Photos
import AVFoundation
import AVKit

struct FullScreenMediaView: View {
    let fetchResult: PHFetchResult<PHAsset>
    let initialIndex: Int
    var onClose: () -> Void
    var onDelete: (() -> Void)? = nil
    @ObservedObject var photoService: PhotoLibraryService
    
    @State private var currentIndex: Int = 0
    @State private var isControlsVisible: Bool = true
    @State private var showDeleteConfirmation: Bool = false
    @State private var dragOffset: CGSize = .zero
    @State private var isCurrentFavorite: Bool = false
    
    init(
        fetchResult: PHFetchResult<PHAsset>,
        initialIndex: Int,
        onClose: @escaping () -> Void,
        onDelete: (() -> Void)? = nil,
        photoService: PhotoLibraryService
    ) {
        self.fetchResult = fetchResult
        self.initialIndex = initialIndex
        self.onClose = onClose
        self.onDelete = onDelete
        self.photoService = photoService
        self._currentIndex = State(initialValue: initialIndex)
        let initialFav = (initialIndex >= 0 && initialIndex < fetchResult.count) ? fetchResult.object(at: initialIndex).isFavorite : false
        self._isCurrentFavorite = State(initialValue: initialFav)
    }
    
    var currentAsset: PHAsset? {
        guard fetchResult.count > 0, currentIndex >= 0, currentIndex < fetchResult.count else {
            return nil
        }
        return fetchResult.object(at: currentIndex)
    }
    
    var body: some View {
        ZStack {
            // Background Fade that dynamically dims or lightens with drag
            Color.black
                .opacity(max(0.0, 1.0 - Double(dragOffset.height / 350.0)))
                .ignoresSafeArea()
            
            // Paging Swipable TabView (Horizontal Swipe Through All Images)
            if fetchResult.count > 0 {
                TabView(selection: $currentIndex) {
                    ForEach(0..<fetchResult.count, id: \.self) { index in
                        let asset = fetchResult.object(at: index)
                        SinglePhotoPageView(
                            asset: asset,
                            isCurrentPage: currentIndex == index,
                            isControlsVisible: isControlsVisible,
                            photoService: photoService,
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isControlsVisible.toggle()
                                }
                            }
                        )
                        .id(asset.localIdentifier)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .offset(y: max(0, dragOffset.height))
                .scaleEffect(max(0.82, 1.0 - (dragOffset.height / 1400.0)))
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            // Only handle downward drag for dismissal
                            if value.translation.height > 0 && abs(value.translation.height) > abs(value.translation.width) {
                                dragOffset = value.translation
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    onClose()
                                }
                            } else {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    dragOffset = .zero
                                }
                            }
                        }
                )
            }
            
            // Top Floating Navigation Bar
            if isControlsVisible, currentAsset != nil {
                VStack {
                    HStack(spacing: 12) {
                        // Close Button (Left)
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onClose()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Color(white: 0.18).opacity(0.85))
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // Counter Badge (Center/Right)
                        Text("\(currentIndex + 1) of \(fetchResult.count)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.black.opacity(0.5)))
                        
                        Spacer()
                        
                        // Heart / Favorite Button (To the left of Trash)
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            if let asset = currentAsset {
                                Task {
                                    do {
                                        let updated = try await photoService.toggleFavorite(for: asset)
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            isCurrentFavorite = updated
                                        }
                                    } catch {
                                        print("Failed to toggle favorite: \(error.localizedDescription)")
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: isCurrentFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isCurrentFavorite ? .pink : .white)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Color(white: 0.18).opacity(0.85))
                                )
                        }
                        .buttonStyle(.plain)
                        
                        // Trash / Delete Button
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Color(white: 0.18).opacity(0.85))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    Spacer()
                }
                .opacity(max(0.0, 1.0 - Double(dragOffset.height / 150.0)))
                .transition(.opacity)
            }
        }
        .onAppear {
            if currentIndex != initialIndex {
                currentIndex = initialIndex
            }
        }
        .task(id: currentIndex) {
            if let asset = currentAsset {
                isCurrentFavorite = asset.isFavorite
            }
        }
        .confirmationDialog(
            "Delete from Photos?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(currentAsset?.mediaType == .video ? "Delete Video" : "Delete Photo", role: .destructive) {
                if let asset = currentAsset {
                    Task {
                        do {
                            try await photoService.deleteAssets([asset])
                            onDelete?()
                            if fetchResult.count <= 1 {
                                onClose()
                            } else if currentIndex >= fetchResult.count - 1 {
                                currentIndex = max(0, fetchResult.count - 2)
                            }
                        } catch {
                            print("Failed to delete asset: \(error.localizedDescription)")
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This item will be deleted from your iCloud and device Photos.")
        }
    }
}

// MARK: - Lightweight AVPlayerLayer Representable
struct VideoPlayerRepresentable: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.player = player
        return view
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        if uiView.player !== player {
            uiView.player = player
        }
    }
}

final class PlayerUIView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
    
    var player: AVPlayer? {
        get { playerLayer.player }
        set {
            playerLayer.player = newValue
            playerLayer.videoGravity = .resizeAspect
            playerLayer.backgroundColor = UIColor.clear.cgColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

// MARK: - Single Photo & Video Page with Instant Thumbnail + Video Playback & Zoom
struct SinglePhotoPageView: View {
    let asset: PHAsset
    let isCurrentPage: Bool
    let isControlsVisible: Bool
    @ObservedObject var photoService: PhotoLibraryService
    var onTap: () -> Void
    
    @State private var displayImage: UIImage?
    @State private var zoomScale: CGFloat = 1.0
    
    // Video Playback State
    @State private var player: AVPlayer? = nil
    @State private var isPlaying: Bool = false
    @State private var isEnded: Bool = false
    @State private var currentTime: Double = 0.0
    @State private var timeObserverToken: Any? = nil
    
    init(
        asset: PHAsset,
        isCurrentPage: Bool,
        isControlsVisible: Bool,
        photoService: PhotoLibraryService,
        onTap: @escaping () -> Void
    ) {
        self.asset = asset
        self.isCurrentPage = isCurrentPage
        self.isControlsVisible = isControlsVisible
        self.photoService = photoService
        self.onTap = onTap
        
        // Fast non-blocking check of memory cache so preview opens immediately if already in RAM
        if let cached = photoService.cachedThumbnail(for: asset.localIdentifier) {
            self._displayImage = State(initialValue: cached)
        }
    }
    
    var body: some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width
            let screenHeight = proxy.size.height
            
            ZStack {
                Color.clear
                
                // Visual Content Container (Photo or Video Player)
                ZStack {
                    if asset.mediaType == .video {
                        if let player = player {
                            VideoPlayerRepresentable(player: player)
                                .frame(width: screenWidth, height: screenHeight)
                        } else if let image = displayImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: screenWidth, height: screenHeight)
                        } else {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.2)
                        }
                    } else {
                        if let image = displayImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: screenWidth, height: screenHeight)
                        } else {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.2)
                        }
                    }
                }
                .frame(width: screenWidth, height: screenHeight)
                .scaleEffect(zoomScale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            zoomScale = max(1.0, min(value, 4.0))
                        }
                        .onEnded { _ in
                            if zoomScale < 1.0 {
                                withAnimation(.spring()) {
                                    zoomScale = 1.0
                                }
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring()) {
                        zoomScale = zoomScale > 1.0 ? 1.0 : 2.5
                    }
                }
                .onTapGesture {
                    onTap()
                }
                
                // Video Controls Overlay (Center Play / Pause Button)
                if asset.mediaType == .video {
                    if !isPlaying || isControlsVisible {
                        Button {
                            togglePlayPause()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
                                
                                Image(systemName: isEnded ? "arrow.counterclockwise" : (isPlaying ? "pause.fill" : "play.fill"))
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                                    .offset(x: (!isEnded && !isPlaying) ? 3 : 0)
                            }
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale(scale: 0.88)))
                    }
                }
                    
                    // Bottom Controls: Video Timeline Scrubber + Metadata Banner
                    if isControlsVisible {
                        VStack(spacing: 12) {
                            Spacer()
                            
                            // Video Timeline Scrubber Bar (only if video)
                            if asset.mediaType == .video && asset.duration > 0 {
                                HStack(spacing: 8) {
                                    Text(formatDuration(currentTime))
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.85))
                                    
                                    GeometryReader { barGeo in
                                        let progress = asset.duration > 0 ? min(1.0, max(0.0, currentTime / asset.duration)) : 0.0
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color.white.opacity(0.25))
                                                .frame(height: 4)
                                            
                                            Capsule()
                                                .fill(Color.white)
                                                .frame(width: max(4, barGeo.size.width * CGFloat(progress)), height: 4)
                                        }
                                        .frame(maxHeight: .infinity)
                                        .contentShape(Rectangle())
                                        .gesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { value in
                                                    let pct = max(0.0, min(1.0, value.location.x / barGeo.size.width))
                                                    let targetSec = pct * asset.duration
                                                    currentTime = targetSec
                                                    player?.seek(to: CMTime(seconds: targetSec, preferredTimescale: 600))
                                                    isEnded = false
                                                }
                                        )
                                    }
                                    .frame(height: 20)
                                    
                                    Text(formatDuration(asset.duration))
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(Color(white: 0.14).opacity(0.85))
                                        .overlay(
                                            Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                                        )
                                )
                                .frame(maxWidth: 290)
                            }
                            
                            // Bottom Metadata Banner
                            VStack(spacing: 4) {
                                if let date = asset.creationDate {
                                    Text(date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                Text("\(asset.pixelWidth) × \(asset.pixelHeight) • \(asset.mediaType == .video ? "Video" : "Photo")")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.7))
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color(white: 0.16).opacity(0.85))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                    )
                            )
                        }
                        .padding(.bottom, 48)
                        .transition(.opacity)
                    }
                }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .task(id: asset.localIdentifier) {
            // Step 1: If synchronous cache wasn't populated yet, fetch standard thumbnail
            if displayImage == nil {
                if let thumb = await photoService.loadThumbnail(for: asset, targetSize: CGSize(width: 600, height: 600)) {
                    self.displayImage = thumb
                }
            }
            // Step 2: Asynchronously upgrade to full-resolution image if photo
            if asset.mediaType == .image {
                if let full = await photoService.loadFullResolutionImage(for: asset) {
                    self.displayImage = full
                }
            }
            // Step 3: Setup video player if video
            if asset.mediaType == .video {
                setupPlayer()
            }
        }
        .onChange(of: isCurrentPage) { _, isCurrent in
            if !isCurrent {
                player?.pause()
                isPlaying = false
            }
        }
        .onDisappear {
            player?.pause()
            isPlaying = false
            if let token = timeObserverToken {
                player?.removeTimeObserver(token)
                timeObserverToken = nil
            }
        }
    }
    
    private func togglePlayPause() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        guard let player = player else { return }
        
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            if isEnded {
                player.seek(to: .zero)
                currentTime = 0
                isEnded = false
            }
            player.play()
            isPlaying = true
        }
    }
    
    private func setupPlayer() {
        guard asset.mediaType == .video, player == nil else { return }
        
        Task {
            if let item = await photoService.loadPlayerItem(for: asset) {
                let newPlayer = AVPlayer(playerItem: item)
                newPlayer.actionAtItemEnd = .pause
                
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: item,
                    queue: .main
                ) { _ in
                    self.isPlaying = false
                    self.isEnded = true
                }
                
                let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
                let token = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                    self.currentTime = time.seconds
                }
                
                await MainActor.run {
                    self.player = newPlayer
                    self.timeObserverToken = token
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
