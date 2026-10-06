//
//  LaunchScreenView.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/6/26.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Spacer()
                
                // MARK: - App Icon with Brand Glow
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.8)
                    )
                    .shadow(
                        color: Color.appAccent.opacity(colorScheme == .dark ? 0.45 : 0.25),
                        radius: 24,
                        x: 0,
                        y: 10
                    )
                    .scaleEffect(isAnimating ? 1.0 : 0.86)
                    .opacity(isAnimating ? 1.0 : 0.0)
                
                // MARK: - App Name & Tagline
                VStack(spacing: 8) {
                    Text("Tidy Media")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Bring order to your media")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .tracking(0.3)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.92)
                .opacity(isAnimating ? 1.0 : 0.0)
                
                Spacer()
                
                // Subtle bottom branding
                Text("Private & On-Device")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.bottom, 36)
                    .opacity(isAnimating ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.76)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
