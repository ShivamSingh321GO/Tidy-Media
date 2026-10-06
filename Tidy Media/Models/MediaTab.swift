//
//  MediaTab.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/5/26.
//

import Foundation

enum MediaTab: String, CaseIterable, Identifiable {
    case all = "All"
    case photos = "Photos"
    case videos = "Videos"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .all:
            return "This is All tab"
        case .photos:
            return "This is Photos tab"
        case .videos:
            return "This is Videos tab"
        }
    }
    
    var subtitle: String {
        switch self {
        case .all:
            return "View all screenshots, photos, and videos"
        case .photos:
            return "Manage screenshots, duplicates & similar photos"
        case .videos:
            return "Manage large videos & duplicate videos"
        }
    }
    
    var systemImage: String {
        switch self {
        case .all:
            return "square.grid.2x2.fill"
        case .photos:
            return "photo.stack.fill"
        case .videos:
            return "video.fill"
        }
    }
}
