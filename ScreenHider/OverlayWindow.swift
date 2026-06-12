import AppKit
import QuartzCore

/// メニューバー含む画面全体を覆うオーバーレイウィンドウ
final class OverlayWindow: NSWindow {
  init(screen: NSScreen) {
    super.init(
      contentRect: screen.frame,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    setFrame(screen.frame, display: true)
    backgroundColor = .black
    isOpaque = true
    alphaValue = 1.0
    level = .screenSaver
    collectionBehavior = [
      .canJoinAllSpaces,
      .fullScreenAuxiliary,
      .stationary,
      .ignoresCycle,
    ]
    ignoresMouseEvents = false
    hasShadow = false
    isReleasedWhenClosed = false
    contentView = OverlayContentView(frame: screen.frame)
  }

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { false }
}

/// クリックで暗転を解除できるビュー
final class OverlayContentView: NSView {
  private let hintView = HintView()

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    addSubview(hintView)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layout() {
    super.layout()
    let size = hintView.intrinsicContentSize
    let margin: CGFloat = 22
    hintView.frame = NSRect(
      x: bounds.width - size.width - margin,
      y: bounds.height - size.height - margin,
      width: size.width,
      height: size.height
    )
  }

  override func draw(_ dirtyRect: NSRect) {
    NSColor.black.setFill()
    dirtyRect.fill()
  }

  override func mouseDown(with event: NSEvent) {
    OverlayManager.shared.turnOff()
  }

  override var acceptsFirstResponder: Bool { true }

  override func keyDown(with event: NSEvent) {
    if event.keyCode == 53 { // Esc
      OverlayManager.shared.turnOff()
      return
    }
    super.keyDown(with: event)
  }
}
