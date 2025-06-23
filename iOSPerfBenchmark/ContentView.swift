//
//  ContentView.swift
//  iOSPerfBenchmark
//
//  Created by Anthony Mamode on 26/05/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ImageListBenchmark()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transaction { $0.animation = nil }
    }
}

#Preview {
    ContentView()
}
