import AppKit
import Foundation

func isYellowContent(r: UInt8, g: UInt8, b: UInt8) -> Bool {
  return r > 170 && g > 110 && b < 150 && r >= g
}

func shouldUseIconBlue(r: UInt8, g: UInt8, b: UInt8, br: UInt8, bg: UInt8, bb: UInt8) -> Bool {
  if isYellowContent(r: r, g: g, b: b) { return false }

  let ri = Int(r)
  let gi = Int(g)
  let bi = Int(b)
  let sum = ri + gi + bi
  let spread = max(ri, gi, bi) - min(ri, gi, bi)
  let iconLum = Int(br) + Int(bg) + Int(bb)

  // 白・チェッカー用グレー
  if sum > 720 && spread < 30 { return true }
  if ri > 185 && gi > 185 && bi > 185 && spread < 25 { return true }

  // 角の白い縁（アンチエイリアス）
  if sum - iconLum > 90 { return true }

  return false
}

func sampleIconBlue(from pixels: [UInt8], width: Int, height: Int, bytesPerRow: Int, bpp: Int) -> (UInt8, UInt8, UInt8) {
  let points = [
    (width / 2, height / 2),
    (width / 3, height / 2),
    (2 * width / 3, height / 2),
    (width / 2, height / 3),
    (width / 2, 2 * height / 3),
  ]

  var rs: [Int] = []
  var gs: [Int] = []
  var bs: [Int] = []

  for (x, y) in points {
    let offset = y * bytesPerRow + x * bpp
    guard offset + 2 < pixels.count else { continue }
    let r = pixels[offset]
    let g = pixels[offset + 1]
    let b = pixels[offset + 2]
    let sum = Int(r) + Int(g) + Int(b)
    if sum > 320 || isYellowContent(r: r, g: g, b: b) { continue }
    rs.append(Int(r))
    gs.append(Int(g))
    bs.append(Int(b))
  }

  if rs.isEmpty {
    return (30, 45, 70)
  }

  return (
    UInt8(rs.reduce(0, +) / rs.count),
    UInt8(gs.reduce(0, +) / gs.count),
    UInt8(bs.reduce(0, +) / bs.count)
  )
}

let sourcePath = CommandLine.arguments.count > 1
  ? CommandLine.arguments[1]
  : "assets/AppIcon-source.png"
let outputPath = CommandLine.arguments.count > 2
  ? CommandLine.arguments[2]
  : "assets/AppIcon-1024.png"

guard let sourceImage = NSImage(contentsOfFile: sourcePath),
      let tiff = sourceImage.tiffRepresentation,
      let sourceRep = NSBitmapImageRep(data: tiff),
      let cgImage = sourceRep.cgImage
else {
  fputs("Failed to read source image: \(sourcePath)\n", stderr)
  exit(1)
}

let width = cgImage.width
let height = cgImage.height
let bpp = cgImage.bitsPerPixel / 8
let rowBytes = cgImage.bytesPerRow

guard let data = cgImage.dataProvider?.data,
      let srcPtr = CFDataGetBytePtr(data)
else {
  fputs("Failed to read pixel data\n", stderr)
  exit(1)
}

var srcPixels = [UInt8](repeating: 0, count: rowBytes * height)
for y in 0..<height {
  for x in 0..<width {
    let srcOffset = y * rowBytes + x * bpp
    let dstOffset = y * width * 4 + x * 4
    srcPixels[dstOffset] = srcPtr[srcOffset]
    srcPixels[dstOffset + 1] = srcPtr[srcOffset + 1]
    srcPixels[dstOffset + 2] = srcPtr[srcOffset + 2]
    srcPixels[dstOffset + 3] = bpp >= 4 ? srcPtr[srcOffset + 3] : 255
  }
}

let (br, bg, bb) = sampleIconBlue(
  from: srcPixels,
  width: width,
  height: height,
  bytesPerRow: width * 4,
  bpp: 4
)

var outPixels = [UInt8](repeating: 0, count: width * height * 4)
for y in 0..<height {
  for x in 0..<width {
    let offset = (y * width + x) * 4
    let r = srcPixels[offset]
    let g = srcPixels[offset + 1]
    let b = srcPixels[offset + 2]
    if shouldUseIconBlue(r: r, g: g, b: b, br: br, bg: bg, bb: bb) {
      outPixels[offset] = br
      outPixels[offset + 1] = bg
      outPixels[offset + 2] = bb
      outPixels[offset + 3] = 255
    } else {
      outPixels[offset] = r
      outPixels[offset + 1] = g
      outPixels[offset + 2] = b
      outPixels[offset + 3] = 255
    }
  }
}

guard let provider = CGDataProvider(
  data: Data(outPixels) as CFData
) else {
  fputs("Failed to create data provider\n", stderr)
  exit(1)
}

guard let outCG = CGImage(
  width: width,
  height: height,
  bitsPerComponent: 8,
  bitsPerPixel: 32,
  bytesPerRow: width * 4,
  space: CGColorSpaceCreateDeviceRGB(),
  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
  provider: provider,
  decode: nil,
  shouldInterpolate: true,
  intent: .defaultIntent
) else {
  fputs("Failed to create output image\n", stderr)
  exit(1)
}

let outputRep = NSBitmapImageRep(cgImage: outCG)
guard let png = outputRep.representation(using: .png, properties: [:]) else {
  fputs("Failed to encode PNG\n", stderr)
  exit(1)
}

try png.write(to: URL(fileURLWithPath: outputPath))
print("Fixed icon: \(outputPath)")
