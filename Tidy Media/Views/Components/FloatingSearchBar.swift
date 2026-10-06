//
//  FloatingSearchBar.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/5/26.
//

import SwiftUI

struct FloatingSearchBar: View {
    @Binding var searchText: String
    var onClose: () -> Void
    
    @FocusState private var isFocused: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 10) {
            // Search Input Platter (Pill)
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField(
                    "",
                    text: $searchText,
                    prompt: Text("Search your library...").foregroundColor(.secondary)
                )
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.primary)
                .tint(Color.appAccent)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($isFocused)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .frame(height: 58)
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
            
            // Circular Close Button (Matching SearchButton Style)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                isFocused = false
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isFocused = true
            }
        }
    }
}
