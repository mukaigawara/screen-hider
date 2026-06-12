import AppKit
import QuartzCore

/// 暗転中に右上へ表示する、控えめな解除ヒント
final class HintView: NSView {
  private let padding = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
  private let label = NSTextField(labelWithString: "クリック · Esc · ⌘⇧D")

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    wantsLayer = true
    layer?.backgroundColor = NSColor.white.withAlphaComponent(0.07).cgColor
    layer?.borderColor = NSColor.white.withAlphaComponent(0.12).cgColor
    layer?.borderWidth = 0.5

    label.font = NSFont.systemFont(ofSize: 11, weight: .regular)
    label.textColor = NSColor.white.withAlphaComponent(0.5)
    label.alignment = .center
    label.maximumNumberOfLines = 1
    addSubview(label)

    startPulseAnimation()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: NSSize {
    let labelSize = label.sizeThatFits(NSMakeSize(280, 20))
    return NSMakeSize(
      labelSize.width + padding.left + padding.right,
      labelSize.height + padding.top + padding.bottom
    )
  }

  override func layout() {
    super.layout()
    layer?.cornerRadius = bounds.height / 2
    label.frame = NSRect(
      x: padding.left,
      y: padding.bottom,
      width: bounds.width - padding.left - padding.right,
      height: bounds.height - padding.top - padding.bottom
    )
  }

  /// クリックは下のオーバーレイへ透過
  override func hitTest(_ point: NSPoint) -> NSView? {
    nil
  }

  private func startPulseAnimation() {
    let opacity = CABasicAnimation(keyPath: "opacity")
    opacity.fromValue = 0.45
    opacity.toValue = 0.85
    opacity.duration = 2.8
    opacity.autoreverses = true
    opacity.repeatCount = .infinity
    opacity.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

    let float = CABasicAnimation(keyPath: "transform.translation.y")
    float.fromValue = 0
    float.toValue = 2
    float.duration = 2.8
    float.autoreverses = true
    float.repeatCount = .infinity
    float.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

    layer?.add(opacity, forKey: "hintPulse")
    layer?.add(float, forKey: "hintFloat")
  }
}
