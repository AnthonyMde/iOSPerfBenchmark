//
//  ImageListBenchmark.swift
//  iOSPerfBenchmark
//
//  Created by Anthony Mamode on 23/06/2025.
//
import SwiftUI

// MARK: - MainListView
struct ImageListBenchmark: View {
    var body: some View {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(0..<300, id: \.self) { index in
                        HorizontalImageList(images: Array(repeating: ["image1", "image2", "image3"], count: 10).flatMap { $0 })
                    }
                }
            }
    }
}

// MARK: - Horizontal Image List Component
struct HorizontalImageList: View {
    let images: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(images, id: \.self) { imageName in
                    RotatingImage(imageName: imageName)
                        .frame(width: 50, height: 50)
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.white))
    }
}

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
