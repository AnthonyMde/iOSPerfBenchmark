//
//  ContentView.swift
//  iOSPerfBenchmark
//
//  Created by Anthony Mamode on 26/05/2025.
//

import SwiftUI

// MARK: - Rotating Image Component
struct RotatingImage: View {
    let imageName: String
    @State private var rotation: Double = 0
    let timer = Timer.publish(every: 1/120, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .rotationEffect(.degrees(rotation))
            .onReceive(timer) { _ in
                rotation += 3 // 360 degrees / 120 frames = 3 degrees per frame
                if rotation >= 360 {
                    rotation = 0
                }
            }
    }
}

// MARK: - Horizontal Image List Component
struct HorizontalImageList: View {
    let images: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 0) {
                ForEach(images, id: \.self) { imageName in
                    RotatingImage(imageName: imageName)
                        .frame(width: 50, height: 50)
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemGray6).opacity(0.3))
    }
}

// MARK: - List Item Component
struct ListItem: View {
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            HorizontalImageList(images: Array(repeating: ["image1", "image2", "image3"], count: 10).flatMap { $0 })
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(0..<300, id: \.self) { index in
                        ListItem(index: index)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}

#Preview {
    ContentView()
}
