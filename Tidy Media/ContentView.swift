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
    @State private var visitedTabs: Set<MediaTab> = [.all]
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeInOut(duration: 0.3)) {
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
                ZStack {
                    AlbumsGridView(viewModel: viewModel, zoomNamespace: albumZoomNamespace)
                        .opacity(viewModel.selectedTab == .all ? 1 : 0)
                        .allowsHitTesting(viewModel.selectedTab == .all)
                        .zIndex(viewModel.selectedTab == .all ? 1 : 0)
                    
                    if visitedTabs.contains(.photos) {
                        MediaGridView(
                            mediaTab: .photos,
                            photoService: viewModel.photoService,
                            viewModel: viewModel
                        )
                        .opacity(viewModel.selectedTab == .photos ? 1 : 0)
                        .allowsHitTesting(viewModel.selectedTab == .photos)
                        .zIndex(viewModel.selectedTab == .photos ? 1 : 0)
                    }
                    
                    if visitedTabs.contains(.videos) {
                        MediaGridView(
                            mediaTab: .videos,
                            photoService: viewModel.photoService,
                            viewModel: viewModel
                        )
                        .opacity(viewModel.selectedTab == .videos ? 1 : 0)
                        .allowsHitTesting(viewModel.selectedTab == .videos)
                        .zIndex(viewModel.selectedTab == .videos ? 1 : 0)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: viewModel.selectedTab)
                .onChange(of: viewModel.selectedTab) { _, newTab in
                    visitedTabs.insert(newTab)
                }
                
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
