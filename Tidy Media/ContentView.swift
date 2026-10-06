//
//  ContentView.swift
//  Tidy Media
//
//  Created by shivam kumar singh on 10/5/26.
//

import SwiftUI
import Photos

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @StateObject private var viewModel = MainViewModel()
    @State private var isShowingLaunchScreen: Bool = true
    @Namespace private var tabNamespace
    @Namespace private var albumZoomNamespace
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            if isShowingLaunchScreen {
                LaunchScreenView()
                    .transition(.opacity)
                    .zIndex(10)
            } else {
                Group {
                    if !hasCompletedOnboarding {
                        OnboardingView {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                hasCompletedOnboarding = true
                            }
                            Task {
                                let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                                if status == .notDetermined {
                                    _ = await viewModel.photoService.requestPermission()
                                } else {
                                    viewModel.photoService.checkCurrentPermission()
                                }
                            }
                        }
                        .transition(.opacity)
                    } else {
                        mainContentView
                    }
                }
                .transition(.opacity)
            }
        }
        .tint(Color.appAccent)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    isShowingLaunchScreen = false
                }
            }
        }
        .task {
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            if status == .authorized || status == .limited {
                viewModel.photoService.checkCurrentPermission()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && hasCompletedOnboarding && !isShowingLaunchScreen {
                viewModel.photoService.checkCurrentPermission()
            }
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(uiColor: .systemBackground).ignoresSafeArea()
                
                // Main Content: All (Categories Dashboard), Photos (All Photos Grid), Videos (All Videos Grid)
                Group {
                    switch viewModel.selectedTab {
                    case .all:
                        AlbumsGridView(viewModel: viewModel, zoomNamespace: albumZoomNamespace)
                            .id("all")
                    case .photos:
                        MediaGridView(
                            mediaTab: .photos,
                            photoService: viewModel.photoService,
                            viewModel: viewModel
                        )
                        .id("photos")
                    case .videos:
                        MediaGridView(
                            mediaTab: .videos,
                            photoService: viewModel.photoService,
                            viewModel: viewModel
                        )
                        .id("videos")
                    }
                }
                .transition(.opacity)
                
                // Floating Apple Platter Bar (Hidden when viewing fullscreen photo/video)
                if !viewModel.isFullScreenViewerOpen {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Bottom Bar: Segmented Pill Tab Bar + Circular Search Button OR Floating Search Bar
                        if viewModel.isSearchPresented {
                            FloatingSearchBar(
                                searchText: $viewModel.searchText,
                                onClose: {
                                    viewModel.onSearchTapped()
                                }
                            )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.96)),
                                removal: .opacity.combined(with: .scale(scale: 0.96))
                            ))
                        } else {
                            HStack(spacing: 10) {
                                PillTabBar(
                                    selectedTab: $viewModel.selectedTab,
                                    namespace: tabNamespace,
                                    onTabSelected: { tab in
                                        viewModel.selectTab(tab)
                                    }
                                )
                                
                                SearchButton {
                                    viewModel.onSearchTapped()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.96)),
                                removal: .opacity.combined(with: .scale(scale: 0.96))
                            ))
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationDestination(item: $viewModel.selectedAlbum) { album in
                AlbumDetailView(album: album, photoService: viewModel.photoService)
                    .navigationBarBackButtonHidden(true)
                    .navigationTransition(.zoom(sourceID: album.id, in: albumZoomNamespace))
            }
        }
    }
}

#Preview {
    ContentView()
}
