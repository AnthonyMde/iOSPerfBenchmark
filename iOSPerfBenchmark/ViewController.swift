//
//  ViewController.swift
//  iOSPerfBenchmark
//
//  Created by Paul-Anatole CLAUDOT on 28/05/2025.
//

import SwiftUI
import UIKit

class ViewController: UIViewController {

    private var hostingController: UIHostingController<ContentView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContentView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let launchTime = Date().timeIntervalSince(launchStart)
        print("🔥🔥🔥 TTID: \(launchTime) seconds")
    }

    private func setupContentView() {
        let contentView = ContentView()
        let hostingController = UIHostingController(rootView: contentView)
        self.hostingController = hostingController

        // Add the hosting controller as a child
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        // Set up constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            hostingController.view.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            hostingController.view.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            hostingController.view.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),
        ])
    }
}
