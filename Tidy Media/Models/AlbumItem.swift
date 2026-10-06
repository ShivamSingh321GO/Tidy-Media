//
//  AlbumItem.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/5/26.
//

import SwiftUI
import Photos

enum AlbumCategoryType: String, CaseIterable, Identifiable, Hashable {
    case camera = "Photo"
    case favorites = "Favourite"
    case videos = "Video"
    case screenshots = "Screenshots"
    case duplicatePhotos = "Duplicate Photos"
    case similarPhotos = "Similar Photos"
    case duplicateVideos = "Duplicate Videos"
    case largeVideos = "Large Videos"
    
    var id: String { rawValue }
    
    var isPinned: Bool {
        switch self {
        case .camera, .favorites, .videos, .screenshots:
            return true
        default:
            return false
        }
    }
    
    var systemIcon: String {
        switch self {
        case .camera: return "photo.fill"
        case .favorites: return "heart.fill"
        case .videos: return "play.rectangle.fill"
        case .screenshots: return "iphone.gen3"
        case .duplicatePhotos: return "doc.on.doc.fill"
        case .similarPhotos: return "photo.on.rectangle.angled"
        case .duplicateVideos: return "film.stack.fill"
        case .largeVideos: return "externaldrive.fill"
        }
    }
    
    var belongsToTabs: [MediaTab] {
        switch self {
        case .camera, .favorites, .screenshots, .duplicatePhotos, .similarPhotos:
            return [.all, .photos]
        case .videos, .duplicateVideos, .largeVideos:
            return [.all, .videos]
        }
    }
    
    var placeholderGradient: [Color] {
        switch self {
        case .camera:
            return [Color(red: 0.15, green: 0.20, blue: 0.30), Color(red: 0.08, green: 0.10, blue: 0.16)]
        case .favorites:
            return [Color(red: 0.30, green: 0.12, blue: 0.18), Color(red: 0.14, green: 0.06, blue: 0.09)]
        case .videos:
            return [Color(red: 0.12, green: 0.22, blue: 0.28), Color(red: 0.06, green: 0.11, blue: 0.16)]
        case .screenshots:
            return [Color(red: 0.20, green: 0.18, blue: 0.28), Color(red: 0.10, green: 0.08, blue: 0.15)]
        case .duplicatePhotos:
            return [Color(red: 0.28, green: 0.20, blue: 0.12), Color(red: 0.14, green: 0.09, blue: 0.05)]
        case .similarPhotos:
            return [Color(red: 0.15, green: 0.28, blue: 0.22), Color(red: 0.07, green: 0.14, blue: 0.10)]
        case .duplicateVideos:
            return [Color(red: 0.24, green: 0.14, blue: 0.26), Color(red: 0.11, green: 0.06, blue: 0.13)]
        case .largeVideos:
            return [Color(red: 0.30, green: 0.16, blue: 0.12), Color(red: 0.15, green: 0.07, blue: 0.05)]
        }
    }
}

struct AlbumItem: Identifiable, Hashable, Equatable {
    let id: String
    let title: String
    let count: Int
    var keyAsset: PHAsset?
    var systemIcon: String
    var gradient: [Color]
    var isPinned: Bool
    var belongsToTabs: [MediaTab]
    var categoryType: AlbumCategoryType? = nil
    
    static func == (lhs: AlbumItem, rhs: AlbumItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.count == rhs.count &&
        lhs.keyAsset?.localIdentifier == rhs.keyAsset?.localIdentifier
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(count)
        hasher.combine(keyAsset?.localIdentifier)
    }
}
