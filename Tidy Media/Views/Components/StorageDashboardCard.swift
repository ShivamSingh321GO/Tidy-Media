//
//  StorageDashboardCard.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/7/26.
//

import SwiftUI
import Photos

// MARK: - Concentric Fitness-Style Rings Component (Image Reference 2 & 3)
struct ConcentricStorageRingsView: View {
    let breakdown: StorageCategoryBreakdown
    var boxSize: CGFloat = 124
    var ringWidth: CGFloat = 9.5
    
    @State private var animatedProgress: CGFloat = 0.0
    
    // Ratios based on total media
    private var videoProgress: CGFloat {
        let total = max(1, breakdown.totalMediaBytes)
        return min(1.0, max(0.04, CGFloat(Double(breakdown.videosBytes) / Double(total))))
    }
    
    private var photoProgress: CGFloat {
        let total = max(1, breakdown.totalMediaBytes)
        return min(1.0, max(0.04, CGFloat(Double(breakdown.photosBytes) / Double(total))))
    }
    
    private var duplicateProgress: CGFloat {
        guard breakdown.recoverableBytes > 0 else { return 0.0 }
        let total = max(1, breakdown.totalMediaBytes)
        return min(1.0, max(0.06, CGFloat(Double(breakdown.recoverableBytes) / Double(total))))
    }
    
    var body: some View {
        ZStack {
            // MARK: - 1. Outer Ring: Videos (Royal Blue)
            ringView(
                diameter: 114,
                progress: videoProgress,
                gradient: [Color(red: 0.11, green: 0.42, blue: 0.98), Color(red: 0.32, green: 0.65, blue: 1.0)],
                trackColor: Color(red: 0.11, green: 0.42, blue: 0.98).opacity(0.18),
                shadowColor: Color(red: 0.11, green: 0.42, blue: 0.98).opacity(0.35),
                iconName: "video.fill",
                iconOffset: -57
            )
            
            // MARK: - 2. Middle Ring: Photos (Emerald / Mint)
            ringView(
                diameter: 90,
                progress: photoProgress,
                gradient: [Color(red: 0.05, green: 0.72, blue: 0.48), Color(red: 0.22, green: 0.90, blue: 0.66)],
                trackColor: Color(red: 0.05, green: 0.72, blue: 0.48).opacity(0.18),
                shadowColor: Color(red: 0.05, green: 0.72, blue: 0.48).opacity(0.35),
                iconName: "photo.fill",
                iconOffset: -45
            )
            
            // MARK: - 3. Inner Ring: Duplicates / Cleanable (Radiant Coral Pink)
            ringView(
                diameter: 66,
                progress: duplicateProgress,
                gradient: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 1.0, green: 0.48, blue: 0.58)],
                trackColor: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.18),
                shadowColor: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35),
                iconName: "sparkles",
                iconOffset: -33
            )
            
            // Center Core: Storage Symbol + Total Device Capacity in numbers below
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.04))
                    .frame(width: 48, height: 48)
                
                VStack(spacing: 1.5) {
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.appAccent)
                    
                    Text(StorageCalculatorService.deviceTotalCapacityFormatted)
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .frame(width: boxSize, height: boxSize)
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.75)) {
                animatedProgress = 1.0
            }
        }
        .onChange(of: breakdown) { _, _ in
            withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
                animatedProgress = 1.0
            }
        }
    }
    
    @ViewBuilder
    private func ringView(
        diameter: CGFloat,
        progress: CGFloat,
        gradient: [Color],
        trackColor: Color,
        shadowColor: Color,
        iconName: String,
        iconOffset: CGFloat
    ) -> some View {
        ZStack {
            // Background Track Ring
            Circle()
                .stroke(trackColor, lineWidth: ringWidth)
                .frame(width: diameter, height: diameter)
            
            // Active Foreground Progress Ring
            if progress > 0 {
                Circle()
                    .trim(from: 0, to: progress * animatedProgress)
                    .stroke(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: diameter, height: diameter)
                    .shadow(color: shadowColor, radius: 3, x: 0, y: 1.5)
            }
            
            // Mini Icon at 12 o'clock (Image Reference 3 Style)
            Image(systemName: iconName)
                .font(.system(size: 6.5, weight: .bold))
                .foregroundColor(.white)
                .frame(width: ringWidth, height: ringWidth)
                .offset(y: iconOffset)
        }
    }
}

// MARK: - Main Storage Dashboard Card
struct StorageDashboardCard: View {
    @ObservedObject var storageService = StorageCalculatorService.shared
    @ObservedObject var viewModel: MainViewModel
    var onOpenDetails: () -> Void = {}
    
    var body: some View {
        let breakdown = storageService.breakdown
        
        VStack(spacing: 12) {
            // MARK: - Primary Card: Concentric Rings on Left + Category Breakdown on Right
            VStack(alignment: .leading, spacing: 14) {
                // Top Header Row
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(breakdown.recoverableBytes > 0 ? Color.orange : Color.green)
                            .frame(width: 7, height: 7)
                        
                        Text("STORAGE OVERVIEW")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(0.6)
                        
                        if storageService.isCalculating {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                    }
                    
                    Spacer()
                    
                    // Top Right Button with Chevron (Redirects to Details View)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onOpenDetails()
                    } label: {
                        HStack(spacing: 4) {
                            Text("Details")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(Color.appAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.appAccent.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // Content Row: Rings (Left) + Details (Right)
                HStack(alignment: .center, spacing: 16) {
                    // LEFT: Concentric Rings (Activity Rings Style)
                    ConcentricStorageRingsView(breakdown: breakdown, boxSize: 124, ringWidth: 9.5)
                        .padding(.leading, 2)
                    
                    // RIGHT: Category Breakdown Rows (Matching Reference Images 2 & 3)
                    VStack(alignment: .leading, spacing: 8) {
                        // 1. Videos (Royal Blue)
                        categoryDetailRow(
                            dotColor: Color(red: 0.11, green: 0.42, blue: 0.98),
                            title: "Videos",
                            sizeText: breakdown.formattedVideosSize,
                            countText: "\(breakdown.videosCount) clips",
                            action: {
                                viewModel.selectTab(.videos)
                            }
                        )
                        
                        Divider()
                            .opacity(0.4)
                        
                        // 2. Photos (Emerald / Mint)
                        categoryDetailRow(
                            dotColor: Color(red: 0.05, green: 0.72, blue: 0.48),
                            title: "Photos",
                            sizeText: breakdown.formattedPhotosSize,
                            countText: "\(breakdown.photosCount) photos",
                            action: {
                                viewModel.selectTab(.photos)
                            }
                        )
                        
                        Divider()
                            .opacity(0.4)
                        
                        // 3. Duplicates (Radiant Coral Pink)
                        categoryDetailRow(
                            dotColor: Color(red: 0.95, green: 0.25, blue: 0.42),
                            title: "Duplicates",
                            sizeText: breakdown.formattedRecoverableSize,
                            countText: breakdown.recoverableCount > 0 ? "\(breakdown.recoverableCount) copies" : "0 copies",
                            isCleanable: breakdown.recoverableBytes > 0,
                            action: {
                                viewModel.navigateToDuplicates()
                            }
                        )
                        
                        Divider()
                            .opacity(0.4)
                        
                        // 4. Screenshots (Sunset Amber)
                        categoryDetailRow(
                            dotColor: Color(red: 0.98, green: 0.60, blue: 0.15),
                            title: "Screenshots",
                            sizeText: breakdown.formattedScreenshotsSize,
                            countText: "\(breakdown.screenshotsCount) shots",
                            action: {
                                viewModel.openScreenshotsAlbum()
                            }
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 0.8)
            )
        }
        .task {
            storageService.recalculate()
        }
    }
    
    // MARK: - Right Column Category Detail Row
    @ViewBuilder
    private func categoryDetailRow(
        dotColor: Color,
        title: String,
        sizeText: String,
        countText: String,
        isCleanable: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(alignment: .center, spacing: 8) {
                // Colored Dot
                Circle()
                    .fill(dotColor)
                    .frame(width: 7, height: 7)
                
                // Title with Count & Size placed together beside each other at the same font size
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 5) {
                        Text(countText)
                        
                        Text("•")
                            .foregroundColor(.secondary.opacity(0.45))
                        
                        Text(sizeText)
                            .foregroundColor(isCleanable ? dotColor : .secondary)
                    }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                }
                
                Spacer(minLength: 4)
                
                // Right Action indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
