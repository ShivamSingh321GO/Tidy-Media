//
//  PillTabBar.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/5/26.
//

import SwiftUI

struct PillTabBar: View {
    @Binding var selectedTab: MediaTab
    var namespace: Namespace.ID
    var onTabSelected: ((MediaTab) -> Void)? = nil
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(MediaTab.allCases) { tab in
                let isSelected = selectedTab == tab
                
                Button {
                    if let onTabSelected = onTabSelected {
                        onTabSelected(tab)
                    } else {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            selectedTab = tab
                        }
                    }
                } label: {
                    Image(systemName: tab.systemImage)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? Color.appAccent : .primary.opacity(0.75))
                        .frame(width: 50, height: 46)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color(uiColor: .systemFill))
                            .matchedGeometryEffect(id: "ActiveTabIndicator", in: namespace)
                    }
                }
            }
        }
        .padding(5)
        .background(
            Capsule()
                .fill(Color(uiColor: .secondarySystemBackground).opacity(colorScheme == .dark ? 0.92 : 0.85))
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.12), radius: 12, x: 0, y: 6)
    }
}
