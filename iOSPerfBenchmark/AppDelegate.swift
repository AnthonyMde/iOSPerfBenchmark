//
//  AppDelegate.swift
//  iOSPerfBenchmark
//
//  Created by Paul-Anatole CLAUDOT on 28/05/2025.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("🕓🕓🕓 TTID: App launched at \(launchStart)")
        // Create window
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Create and set root view controller
        let viewController = ViewController()
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        
        // Show FPS counter
        FPSCounter.showInStatusBar()
        
        return true
    }
}

public class FPSCounter: NSObject {

    /// Helper class that relays display link updates to the FPSCounter
    ///
    /// This is necessary because CADisplayLink retains its target. Thus
    /// if the FPSCounter class would be the target of the display link
    /// it would create a retain cycle. The delegate has a weak reference
    /// to its parent FPSCounter, thus preventing this.
    ///
    internal class DisplayLinkProxy: NSObject {

        /// A weak ref to the parent FPSCounter instance.
        @objc weak var parentCounter: FPSCounter?

        /// Notify the parent FPSCounter of a CADisplayLink update.
        ///
        /// This method is automatically called by the CADisplayLink.
        ///
        /// - Parameters:
        ///   - displayLink: The display link that updated
        ///
        @objc func updateFromDisplayLink(_ displayLink: CADisplayLink) {
            parentCounter?.updateFromDisplayLink(displayLink)
        }
    }


    // MARK: - Initialization

    private let displayLink: CADisplayLink
    private let displayLinkProxy: DisplayLinkProxy

    /// Create a new FPSCounter.
    ///
    /// To start receiving FPS updates you need to start tracking with the
    /// `startTracking(inRunLoop:mode:)` method.
    ///
    public override init() {
        self.displayLinkProxy = DisplayLinkProxy()
        self.displayLink = CADisplayLink(
            target: self.displayLinkProxy,
            selector: #selector(DisplayLinkProxy.updateFromDisplayLink(_:))
        )

        super.init()

        self.displayLinkProxy.parentCounter = self
    }

    deinit {
        self.displayLink.invalidate()
    }


    // MARK: - Configuration

    /// The delegate that should receive FPS updates.
    public weak var delegate: FPSCounterDelegate?

    /// Delay between FPS updates. Longer delays mean more averaged FPS numbers.
    @objc public var notificationDelay: TimeInterval = 1.0


    // MARK: - Tracking

    private var runloop: RunLoop?
    private var mode: RunLoop.Mode?

    /// Start tracking FPS updates.
    ///
    /// You can specify wich runloop to use for tracking, as well as the runloop modes.
    /// Usually you'll want the main runloop (default), and either the common run loop modes
    /// (default), or the tracking mode (`RunLoop.Mode.tracking`).
    ///
    /// When the counter is already tracking, it's stopped first.
    ///
    /// - Parameters:
    ///   - runloop: The runloop to start tracking in
    ///   - mode:    The mode(s) to track in the runloop
    ///
    @objc public func startTracking(inRunLoop runloop: RunLoop = .main, mode: RunLoop.Mode = .common) {
        self.stopTracking()

        self.runloop = runloop
        self.mode = mode
        self.displayLink.add(to: runloop, forMode: mode)
    }

    /// Stop tracking FPS updates.
    ///
    /// This method does nothing if the counter is not currently tracking.
    ///
    @objc public func stopTracking() {
        guard let runloop = self.runloop, let mode = self.mode else { return }

        self.displayLink.remove(from: runloop, forMode: mode)
        self.runloop = nil
        self.mode = nil
    }


    // MARK: - Handling Frame Updates

    private var lastNotificationTime: CFAbsoluteTime = 0.0
    private var numberOfFrames = 0

    private func updateFromDisplayLink(_ displayLink: CADisplayLink) {
        if self.lastNotificationTime == 0.0 {
            self.lastNotificationTime = CFAbsoluteTimeGetCurrent()
            return
        }

        self.numberOfFrames += 1

        let currentTime = CFAbsoluteTimeGetCurrent()
        let elapsedTime = currentTime - self.lastNotificationTime

        if elapsedTime >= self.notificationDelay {
            self.notifyUpdateForElapsedTime(elapsedTime)
            self.lastNotificationTime = 0.0
            self.numberOfFrames = 0
        }
    }

    private func notifyUpdateForElapsedTime(_ elapsedTime: CFAbsoluteTime) {
        let fps = Int(round(Double(self.numberOfFrames) / elapsedTime))
        self.delegate?.fpsCounter(self, didUpdateFramesPerSecond: fps)
    }
}


/// The delegate protocol for the FPSCounter class.
///
/// Implement this protocol if you want to receive updates from a `FPSCounter`.
///
public protocol FPSCounterDelegate: NSObjectProtocol {

    /// Called in regular intervals while the counter is tracking FPS.
    ///
    /// - Parameters:
    ///   - counter: The FPSCounter that sent the update
    ///   - fps:     The current FPS of the application
    ///
    func fpsCounter(_ counter: FPSCounter, didUpdateFramesPerSecond fps: Int)
}

class FPSStatusBarViewController: UIViewController {

    fileprivate let fpsCounter = FPSCounter()
    private let label = UILabel()


    // MARK: - Initialization

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        self.commonInit()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)

        self.commonInit()
    }

    private func commonInit() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(FPSStatusBarViewController.updateStatusBarFrame(_:)),
            name: UIApplication.didChangeStatusBarOrientationNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    // MARK: - View Lifecycle and Events

    override func loadView() {
        self.view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0))

        let font = UIFont.boldSystemFont(ofSize: 10.0)
        let rect = self.view.bounds.insetBy(dx: 10.0, dy: 0.0)

        self.label.frame = CGRect(x: rect.origin.x, y: rect.maxY - font.lineHeight - 1.0, width: rect.width, height: font.lineHeight)
        self.label.autoresizingMask = [ .flexibleWidth, .flexibleTopMargin ]
        self.label.font = font
        self.view.addSubview(self.label)

        self.fpsCounter.delegate = self
    }

    @objc func updateStatusBarFrame(_ notification: Notification) {
        let application = notification.object as? UIApplication
        let frame = CGRect(x: 0.0, y: 0.0, width: application?.keyWindow?.bounds.width ?? 0.0, height: 20.0)

        FPSStatusBarViewController.statusBarWindow.frame = frame
    }


    // MARK: - Getting the shared status bar window

    @objc static var statusBarWindow: UIWindow = {
        let window = FPStatusBarWindow()
        window.windowLevel = .statusBar
        window.rootViewController = FPSStatusBarViewController()
        return window
    }()
}


// MARK: - FPSCounterDelegate

extension FPSStatusBarViewController: FPSCounterDelegate {

    @objc func fpsCounter(_ counter: FPSCounter, didUpdateFramesPerSecond fps: Int) {
        self.resignKeyWindowIfNeeded()

        let milliseconds = 1000 / max(fps, 1)
        self.label.text = "\(fps) FPS (\(milliseconds) milliseconds per frame)"

        switch fps {
        case 45...:
            self.view.backgroundColor = .green
            self.label.textColor = .black
        case 35...:
            self.view.backgroundColor = .orange
            self.label.textColor = .white
        default:
            self.view.backgroundColor = .red
            self.label.textColor = .white
        }
    }

    private func resignKeyWindowIfNeeded() {
        // prevent the status bar window from becoming the key window and steal events
        // from the main application window
        if FPSStatusBarViewController.statusBarWindow.isKeyWindow {
            UIApplication.shared.delegate?.window??.makeKey()
        }
    }
}


public extension FPSCounter {

    // MARK: - Show FPS in the status bar

    /// Add a label in the status bar that shows the applications current FPS.
    ///
    /// - Note:
    ///   Only do this in debug builds. Apple may reject your app if it covers the status bar.
    ///
    /// - Parameters:
    ///   - application: The `UIApplication` to show the FPS for
    ///   - runloop:     The `NSRunLoop` to use when tracking FPS. Default is the main run loop
    ///   - mode:        The run loop mode to use when tracking. Default uses `RunLoop.Mode.common`
    ///
    @objc class func showInStatusBar(
        application: UIApplication = .shared,
        runloop: RunLoop = .main,
        mode: RunLoop.Mode = .common
    ) {
        let window = FPSStatusBarViewController.statusBarWindow
        if let windowScene = application.connectedScenes.first as? UIWindowScene {
            window.frame = windowScene.statusBarManager?.statusBarFrame ?? .zero
        }
        window.isHidden = false

        if let controller = window.rootViewController as? FPSStatusBarViewController {
            controller.fpsCounter.startTracking(
                inRunLoop: runloop,
                mode: mode
            )
        }
    }

    /// Removes the label that shows the current FPS from the status bar.
    ///
    @objc class func hide() {
        let window = FPSStatusBarViewController.statusBarWindow

        if let controller = window.rootViewController as? FPSStatusBarViewController {
            controller.fpsCounter.stopTracking()
            window.isHidden = true
        }
    }

    /// Returns wether the FPS counter is currently visible or not.
    ///
    @objc class var isVisible: Bool {
        return !FPSStatusBarViewController.statusBarWindow.isHidden
    }
}

class FPStatusBarWindow: UIWindow {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // don't hijack touches from the main window
        return false
    }
}


