//
//  LocationPostsView.swift
//  ExploreNow
//
//  Created by Saadman Rahman on 2024-12-13.
//


import SwiftUI
import CoreLocation
import MapKit
import Firebase
import FirebaseFirestore
import SDWebImageSwiftUI

/// A view that displays location details and associated posts
struct LocationPostsView: View {
    // MARK: - Properties
    
    /// ViewModel that manages the location data and business logic
    @StateObject private var viewModel: LocationViewModel
    
    /// Shared user manager for handling user-related data
    @EnvironmentObject var userManager: UserManager
    
    // MARK: - Initialization
    
    /// Initializes the view with a reference to a location document
    /// - Parameter locationRef: Firestore reference to the location document
    init(locationRef: DocumentReference) {
        _viewModel = StateObject(wrappedValue: LocationViewModel(locationRef: locationRef))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Show loading view while data is being fetched
                    if viewModel.isLoading {
                        loadingView
                    } else {
                        // Main content sections when data is loaded
                        VStack(spacing: 0) {
                            headerSection
                            locationInfoSection
                            postsSection
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)  // Extend content to top edge
            .background(AppTheme.background)
            .onAppear {
                // Fetch data when view appears
                viewModel.fetchLocationDetails()
                viewModel.fetchLocationPosts()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Loading View
    
    /// View shown while content is loading
    private var loadingView: some View {
        VStack(spacing: 16) {
            // Custom styled progress indicator
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.primaryPurple)
            Text("Loading location details...")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Header Section
    
    /// Header section displaying location image with gradient overlay
    private var headerSection: some View {
        ZStack(alignment: .bottom) {
            Group {
                // Display header image if available, otherwise show placeholder
                if let imageUrl = viewModel.headerImageUrl {
                    WebImage(url: URL(string: imageUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipped()
                } else {
                    // Placeholder for when no image is available
                    Rectangle()
                        .fill(AppTheme.secondaryBackground)
                        .frame(height: 250)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.secondaryText)
                        )
                }
            }
            
            // Gradient overlay for better text visibility
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.5),
                    Color.black.opacity(0)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 150)
        }
        .frame(height: 250)
    }
    
    // MARK: - Location Info Section
    
    /// Section displaying location details, address, and action buttons
    private var locationInfoSection: some View {
        VStack(spacing: 16) {
            // Location name/address
            Text(viewModel.locationDetails?.mainAddress ?? "Location")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 16)
            
            // Full address with map button
            if let fullAddress = viewModel.locationDetails?.fullAddress {
                Button(action: { viewModel.openInMaps() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 16))
                        Text(fullAddress)
                            .font(.system(size: 14))
                    }
                    .foregroundColor(AppTheme.primaryPurple)
                }
                .padding(.horizontal)
            }
            
            // Rating and directions buttons
            HStack(spacing: 20) {
                // Rating display
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", viewModel.locationDetails?.averageRating ?? 0))
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.lightPurple)
                .cornerRadius(12)
                
                // Get directions button
                Button(action: { viewModel.openInMapsWithDirections() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "car.fill")
                        Text("Get Directions")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.primaryPurple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.vertical, 8)
            
            Divider()
                .padding(.horizontal)
        }
        .background(AppTheme.background)
    }
    
    // MARK: - Posts Section
    
    /// Section displaying all posts associated with this location
    private var postsSection: some View {
        VStack(spacing: 16) {
            // Posts header with count
            HStack {
                Text("Posts")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                Text("\(viewModel.locationPosts.count)")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            // Posts list or empty state
            if viewModel.locationPosts.isEmpty {
                emptyPostsView
            } else {
                // Lazy loading list of posts
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.locationPosts) { post in
                        PostCardView(post: post)
                            .environmentObject(userManager)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Empty State View
    
    /// View shown when there are no posts for the location
    private var emptyPostsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.stack")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.secondaryText)
            
            Text("No posts yet for this location")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(AppTheme.background)
    }
}
