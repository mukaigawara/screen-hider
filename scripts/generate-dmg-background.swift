import AppKit
import Foundation

let outputPath = CommandLine.arguments.count > 1
  ? CommandLine.arguments[1]
  : "assets/dmg-background.png"

let width: CGFloat = 660
let height: CGFloat = 400
let size = NSSize(width: width, height: height)

let image = NSImage(size: size)
image.lockFocus()

let gradient = NSGradient(
  colors: [
    NSColor(red: 0.11, green: 0.16, blue: 0.24, alpha: 1),
    NSColor(red: 0.07, green: 0.10, blue: 0.16, alpha: 1),
  ]
)!
gradient.draw(in: NSRect(origin: .zero, size: size), angle: 270)

let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 250, y: 198))
arrow.curve(
  to: NSPoint(x: 410, y: 198),
  controlPoint1: NSPoint(x: 310, y: 238),
  controlPoint2: NSPoint(x: 350, y: 162)
)
NSColor.white.withAlphaComponent(0.22).setStroke()
arrow.lineWidth = 2.5
arrow.stroke()

let head = NSBezierPath()
head.move(to: NSPoint(x: 408, y: 198))
head.line(to: NSPoint(x: 388, y: 186))
head.move(to: NSPoint(x: 408, y: 198))
head.line(to: NSPoint(x: 388, y: 210))
head.lineWidth = 2.5
head.stroke()

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let textAttributes: [NSAttributedString.Key: Any] = [
  .font: NSFont.systemFont(ofSize: 13, weight: .medium),
  .foregroundColor: NSColor.white.withAlphaComponent(0.62),
  .paragraphStyle: paragraph,
]
let instruction = "ScreenHider.app を Applications フォルダへドラッグしてインストール"
(instruction as NSString).draw(
  in: NSRect(x: 40, y: 42, width: width - 80, height: 28),
  withAttributes: textAttributes
)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:])
else {
  fputs("Failed to generate DMG background\n", stderr)
  exit(1)
}

try png.write(to: URL(fileURLWithPath: outputPath))
print("Generated \(outputPath)")
