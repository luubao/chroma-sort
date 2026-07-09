import UIKit
import WebKit

final class GameViewController: UIViewController {
    private var webView: WKWebView!
    private let haptics = Haptics()
    private var isDark = true

    /// Match `--bg-0` for each theme in index.html, so there is no white flash
    /// before the first paint and no mismatched seam under the safe-area insets.
    private static let darkBackdrop = UIColor(red: 0x0d / 255.0, green: 0x0e / 255.0, blue: 0x1c / 255.0, alpha: 1)
    private static let lightBackdrop = UIColor(red: 0xe9 / 255.0, green: 0xeb / 255.0, blue: 0xf7 / 255.0, alpha: 1)

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.userContentController.add(HapticsBridge(haptics: haptics), name: "haptics")
        config.userContentController.add(ThemeBridge { [weak self] isDark in self?.applyTheme(isDark: isDark) }, name: "theme")
        // Web Audio still needs a user gesture; this only stops WebKit from
        // additionally gating <audio>/<video>.
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.isTextInteractionEnabled = false
        config.suppressesIncrementalRendering = true

        webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.allowsLinkPreview = false
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        // The page reads env(safe-area-inset-*) itself; a pinch-zoomed board
        // would just look broken.
        webView.scrollView.maximumZoomScale = 1
        webView.scrollView.minimumZoomScale = 1

        let container = UIView()
        container.backgroundColor = Self.darkBackdrop
        container.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        // Pinned to the view, not the safe area, so the gradient bleeds under
        // the notch and home indicator.
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: container.topAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let index = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "www") else {
            assertionFailure("index.html missing from bundle — check the pre-build copy script")
            return
        }
        // Read access scoped to the folder, not the whole bundle.
        webView.loadFileURL(index, allowingReadAccessTo: index.deletingLastPathComponent())
    }

    /// The page owns its light/dark theme (and persists it), so mirror it here
    /// rather than following the system appearance.
    private func applyTheme(isDark: Bool) {
        guard isDark != self.isDark else { return }
        self.isDark = isDark
        view.backgroundColor = isDark ? Self.darkBackdrop : Self.lightBackdrop
        setNeedsStatusBarAppearanceUpdate()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { isDark ? .lightContent : .darkContent }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
}

/// Receives `"dark"` / `"light"` whenever the page's theme changes.
private final class ThemeBridge: NSObject, WKScriptMessageHandler {
    private let onChange: (Bool) -> Void

    init(onChange: @escaping (Bool) -> Void) {
        self.onChange = onChange
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let theme = message.body as? String else { return }
        onChange(theme != "light")
    }
}

/// Kept separate so the view controller isn't retained by the
/// userContentController, which would otherwise leak it.
private final class HapticsBridge: NSObject, WKScriptMessageHandler {
    private let haptics: Haptics

    init(haptics: Haptics) {
        self.haptics = haptics
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        let pattern: [Double]
        switch message.body {
        case let number as NSNumber:
            pattern = [number.doubleValue]
        case let array as [NSNumber]:
            pattern = array.map(\.doubleValue)
        default:
            return
        }
        haptics.play(pattern: pattern)
    }
}
