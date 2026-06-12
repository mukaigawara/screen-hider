import AppKit
import Combine
import QuartzCore

enum FadeAnimation {
  static let standardDuration: TimeInterval = 0.35
}

/// 全接続ディスプレイに黒オーバーレイを重ねて画面を暗くする
final class OverlayManager: ObservableObject {
  static let shared = OverlayManager()

  @Published var isDimmed: Bool {
    didSet {
      guard oldValue != isDimmed else { return }
      UserDefaults.standard.set(isDimmed, forKey: "isDimmed")
      applyDimming()
    }
  }

  @Published var fadeAnimationEnabled: Bool {
    didSet {
      UserDefaults.standard.set(fadeAnimationEnabled, forKey: "fadeAnimationEnabled")
    }
  }

  private var overlayWindows: [OverlayWindow] = []
  private var screenObserver: NSObjectProtocol?
  private var localKeyMonitor: Any?

  private var fadeDuration: TimeInterval {
    fadeAnimationEnabled ? FadeAnimation.standardDuration : 0
  }

  private init() {
    isDimmed = UserDefaults.standard.bool(forKey: "isDimmed")
    if UserDefaults.standard.object(forKey: "fadeAnimationEnabled") != nil {
      fadeAnimationEnabled = UserDefaults.standard.bool(forKey: "fadeAnimationEnabled")
    } else if UserDefaults.standard.object(forKey: "fadeDuration") != nil {
      // 旧設定（fadeDuration）から移行: 0 以外ならアニメーションあり
      fadeAnimationEnabled = UserDefaults.standard.double(forKey: "fadeDuration") > 0
    } else {
      fadeAnimationEnabled = true
    }
  }

  func startObservingScreenChanges() {
    screenObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.didChangeScreenParametersNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      guard let self, self.isDimmed else { return }
      self.applyDimming()
    }
  }

  func toggle() {
    isDimmed.toggle()
  }

  func applyDimmingIfNeeded() {
    if isDimmed {
      applyDimming()
    }
  }

  func turnOff() {
    isDimmed = false
  }

  func setFadeAnimationEnabled(_ enabled: Bool) {
    fadeAnimationEnabled = enabled
  }

  private func applyDimming() {
    if isDimmed {
      installLocalKeyMonitor()
      removeOverlaysImmediately()
      createOverlaysWithFadeIn()
    } else {
      removeLocalKeyMonitor()
      fadeOutAndRemoveOverlays()
    }
  }

  private func createOverlaysWithFadeIn() {
    for screen in NSScreen.screens {
      let window = OverlayWindow(screen: screen)
      window.alphaValue = fadeAnimationEnabled ? 0 : 1.0
      window.orderFrontRegardless()
      overlayWindows.append(window)
    }

    guard fadeAnimationEnabled else { return }

    NSAnimationContext.runAnimationGroup { context in
      context.duration = fadeDuration
      context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      for window in overlayWindows {
        window.animator().alphaValue = 1.0
      }
    }
  }

  private func fadeOutAndRemoveOverlays() {
    guard !overlayWindows.isEmpty else { return }

    let windows = overlayWindows
    overlayWindows = []

    if !fadeAnimationEnabled {
      windows.forEach { $0.orderOut(nil) }
      return
    }

    NSAnimationContext.runAnimationGroup({ context in
      context.duration = fadeDuration
      context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      for window in windows {
        window.animator().alphaValue = 0
      }
    }, completionHandler: {
      windows.forEach { $0.orderOut(nil) }
    })
  }

  private func removeOverlaysImmediately() {
    overlayWindows.forEach { $0.orderOut(nil) }
    overlayWindows.removeAll()
  }

  private func installLocalKeyMonitor() {
    guard localKeyMonitor == nil else { return }
    localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
      guard OverlayManager.shared.isDimmed else { return event }
      if event.keyCode == 53 { // Esc
        OverlayManager.shared.turnOff()
        return nil
      }
      return event
    }
  }

  private func removeLocalKeyMonitor() {
    if let monitor = localKeyMonitor {
      NSEvent.removeMonitor(monitor)
      localKeyMonitor = nil
    }
  }
}
