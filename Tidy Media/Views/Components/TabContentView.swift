//
//  TabContentView.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/5/26.
//

import SwiftUI

struct TabContentView: View {
    let tab: MediaTab
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: tab.systemImage)
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.85))
                .padding(.bottom, 8)
            
            Text(tab.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Text(tab.subtitle)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }
}
