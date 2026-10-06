//
//  SearchButton.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/5/26.
//

import SwiftUI

struct SearchButton: View {
    var action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 58, height: 58)
                .background(
                    Circle()
                        .fill(Color(uiColor: .secondarySystemBackground).opacity(colorScheme == .dark ? 0.92 : 0.85))
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                )
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.12), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}
