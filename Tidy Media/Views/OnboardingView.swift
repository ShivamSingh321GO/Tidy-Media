//
//  OnboardingView.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/6/26.
//

import SwiftUI

struct OnboardingItem: Identifiable {
    let id: Int
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let features: [(icon: String, text: String)]
}

struct OnboardingView: View {
    var onComplete: () -> Void
    
    @State private var currentPage: Int = 0
    @Environment(\.colorScheme) private var colorScheme
    
    private let pages: [OnboardingItem] = [
        OnboardingItem(
            id: 0,
            icon: "doc.on.doc.fill",
            title: "Clean Duplicate Photos",
            subtitle: "Spot duplicates and bursts. Keep the best shot.",
            gradient: [Color.appAccent, Color.appCyanBlue],
            features: [
                ("sparkles", "Auto-picks best photo"),
                ("doc.on.doc.fill", "Groups similar shots"),
                ("bolt.fill", "Frees up storage fast")
            ]
        ),
        OnboardingItem(
            id: 1,
            icon: "film.stack.fill",
            title: "Tidy Heavy Videos",
            subtitle: "Find large video files and duplicate clips quickly.",
            gradient: [Color.appCyanBlue, Color.appPurple],
            features: [
                ("externaldrive.fill", "Sorted by file size"),
                ("play.circle.fill", "Instant video preview"),
                ("trash.fill", "Safe cleanup with undo")
            ]
        ),
        OnboardingItem(
            id: 2,
            icon: "lock.shield.fill",
            title: "100% Private",
            subtitle: "All scanning stays strictly on your iPhone.",
            gradient: [Color.appPurple, Color.appMagenta],
            features: [
                ("lock.shield.fill", "Zero cloud uploads"),
                ("folder.fill", "Auto-categorized albums"),
                ("checkmark.seal.fill", "Direct Photos app sync")
            ]
        )
    ]
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Top Header (App Logo + Skip Button)
                HStack(alignment: .center) {
                    HStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .shadow(color: Color.black.opacity(0.15), radius: 4, y: 2)
                        
                        Text("Tidy Media")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            completeOnboarding()
                        } label: {
                            Text("Skip")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(Color(uiColor: .secondarySystemBackground))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // MARK: - Paging Carousel
                TabView(selection: $currentPage) {
                    ForEach(pages) { page in
                        pageCardView(for: page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // MARK: - Bottom Controls: Page Dots & Primary Action
                VStack(spacing: 20) {
                    // Custom Animated Indicator Dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? Color.appAccent : Color.primary.opacity(0.18))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    .padding(.bottom, 4)
                    
                    // "Get Started" Button (Only on the 3rd Onboarding Screen)
                    ZStack {
                        if currentPage == pages.count - 1 {
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                completeOnboarding()
                            } label: {
                                HStack(spacing: 8) {
                                    Text("Get Started")
                                        .font(.system(size: 17, weight: .semibold))
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Color.appAccent, Color.appCyanBlue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .shadow(color: Color.appAccent.opacity(colorScheme == .dark ? 0.45 : 0.28), radius: 14, y: 6)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 24)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                    .frame(height: 56)
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentPage)
                .padding(.bottom, 36)
            }
        }
    }
    
    // MARK: - Individual Page View
    @ViewBuilder
    private func pageCardView(for page: OnboardingItem) -> some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)
            
            // Hero Icon Badge with Glowing Gradient
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: page.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                    .shadow(color: page.gradient.first?.opacity(colorScheme == .dark ? 0.45 : 0.25) ?? .clear, radius: 18, y: 8)
                
                Image(systemName: page.icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.top, 6)
            
            // Title & Subtitle (Short & Small)
            VStack(spacing: 6) {
                Text(page.title)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Text(page.subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 32)
            }
            
            // Clean Bullet Points
            VStack(alignment: .leading, spacing: 12) {
                ForEach(page.features, id: \.text) { feature in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(page.gradient.first ?? Color.appAccent)
                            .frame(width: 6, height: 6)
                        
                        Text(feature.text)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary.opacity(0.88))
                    }
                }
            }
            .padding(.top, 6)
            .padding(.horizontal, 24)
            
            Spacer(minLength: 12)
        }
    }
    
    private func completeOnboarding() {
        onComplete()
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
