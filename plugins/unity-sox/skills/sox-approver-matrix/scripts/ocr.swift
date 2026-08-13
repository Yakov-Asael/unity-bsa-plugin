// ocr.swift — read text out of a screenshot using Apple's Vision framework.
//
// Usage: ocr <image.png> [xFrac yFrac wFrac hFrac]
//        ocr --boxes <image.png>
//
// Fractions crop a region (origin top-left) before recognition, which keeps the
// result focused and avoids picking up unrelated numbers elsewhere on screen.
//
// --boxes prints "text<TAB>x<TAB>y<TAB>w<TAB>h" in image pixels with a top-left
// origin, so a caller can locate a control and click it instead of relying on
// hardcoded coordinates that break when the layout or display changes.
import Foundation
import Vision
import AppKit

var args = CommandLine.arguments
var wantBoxes = false
if args.count >= 2, args[1] == "--boxes" {
    wantBoxes = true
    args.remove(at: 1)
}

guard args.count >= 2, let img = NSImage(contentsOfFile: args[1]),
      var cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    FileHandle.standardError.write("cannot read image\n".data(using: .utf8)!)
    exit(1)
}

if args.count >= 6, let xf = Double(args[2]), let yf = Double(args[3]),
   let wf = Double(args[4]), let hf = Double(args[5]) {
    let W = Double(cg.width), H = Double(cg.height)
    let rect = CGRect(x: xf * W, y: yf * H, width: wf * W, height: hf * H)
    if let cropped = cg.cropping(to: rect) { cg = cropped }
}

let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = false

let handler = VNImageRequestHandler(cgImage: cg, options: [:])
do {
    try handler.perform([request])
} catch {
    FileHandle.standardError.write("vision failed: \(error)\n".data(using: .utf8)!)
    exit(1)
}

let W = Double(cg.width), H = Double(cg.height)
for obs in (request.results ?? []) {
    guard let top = obs.topCandidates(1).first else { continue }
    if wantBoxes {
        // Vision's boundingBox is normalised with a bottom-left origin; convert to
        // pixels with a top-left origin to match how screenshots are addressed.
        let b = obs.boundingBox
        let x = b.minX * W
        let y = (1.0 - b.maxY) * H
        let w = b.width * W
        let h = b.height * H
        print(String(format: "%@\t%.0f\t%.0f\t%.0f\t%.0f", top.string, x, y, w, h))
    } else {
        print(top.string)
    }
}
