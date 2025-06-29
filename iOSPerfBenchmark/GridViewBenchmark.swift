//
//  GridViewBenchmark.swift
//  iOSPerfBenchmark
//
//  Created by Anthony Mamode on 23/06/2025.
//

import SwiftUI

struct GridBenchmarkConstants {
    static let itemCount = 4_000
    static let textRefresh: TimeInterval = 0.008 // 8ms
    static let fontSize: CGFloat = 16
    static let scaleRefresh: TimeInterval = 0.5  // 500 ms
    static let rotateRefresh: TimeInterval = 0.5 // 500 ms
}

struct GridViewBenchmark: View {
    @State private var time: Int = 0
    private let timer = Timer.publish(every: GridBenchmarkConstants.textRefresh, on: .main, in: .common).autoconnect()

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 4)
        let elapsed = Double(time) * GridBenchmarkConstants.textRefresh

        // Shared animation values
        let scale = round((0.9 + 0.2 * abs(sin(.pi * elapsed / GridBenchmarkConstants.scaleRefresh))) * 100) / 100
        let rotation = Angle(degrees: (elapsed / GridBenchmarkConstants.rotateRefresh).truncatingRemainder(dividingBy: 1) * 360)
        let shadowOffset = CGSize(width: 4 * cos(rotation.radians), height: 4 * sin(rotation.radians))

        ScrollView {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<GridBenchmarkConstants.itemCount, id: \.self) { index in
                    var rng = SeededGenerator(seed: index + time)
                    let value = Int.random(in: 1..<10_000, using: &rng)

                    AnimatedCell(
                        value: value,
                        rotation: rotation,
                        scale: scale,
                        shadowOffset: shadowOffset
                    )
                }
            }
            .padding(4)
        }
        .onReceive(timer) { _ in
            time = (time + 1) % 10_000
        }
    }
}

struct AnimatedCell: View {
    let value: Int
    let rotation: Angle
    let scale: Double
    let shadowOffset: CGSize

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 4)
            Text("Item \(value)")
                .font(.system(size: GridBenchmarkConstants.fontSize * scale))
                .foregroundColor(.white)
                .shadow(
                    color: .black.opacity(0.5),
                    radius: 8,
                    x: shadowOffset.width,
                    y: shadowOffset.height
                )
        }
        .aspectRatio(1, contentMode: .fit)
        .rotation3DEffect(rotation, axis: (x: 1, y: 0, z: 0))
        .scaleEffect(scale)
    }
}


// MARK: - Seeded Random Generator (for deterministic randomness like Kotlin)
struct SeededGenerator: RandomNumberGenerator {
    init(seed: Int) {
        srand48(seed)
    }
    func next() -> UInt64 {
        UInt64(drand48() * Double(UInt64.max))
    }
}
