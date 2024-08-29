//
//  Automator+Display.swift
//  VZAutomation
//
//  Created by Jordan Pittman on 8/17/24.
//

import AppKit
import QuartzCore
import CoreGraphics
import CoreImage
import Vision

// MARK: - Detecting text on the display
extension VZAutomator {
  /// Represents a block of text on the display
  struct Text {
    let string: String
    let bounds: CGRect
  }

  enum TextCondition {
    case none([String])
    case any([String])
    case all([String])
  }

  /// Wait for the given string to be displayed on screen
  /// case-insensitive
  public func wait(forText str: String) async throws {
    try await wait(forText: .any([str]))
  }

  /// Wait for the given string(s) to be displayed on screen
  /// case-insensitive
  public func wait(forText cond: TextCondition) async throws {
    try await wait {
      try await has(text: cond)
    }
  }

  /// Wait for the given string(s) to be displayed on screen
  /// case-insensitive
  public func has(text str: String) async throws -> Bool {
    try await has(text: .any([str]))
  }

  /// Wait for the given string(s) to be displayed on screen
  /// case-insensitive
  public func has(text cond: TextCondition) async throws -> Bool {
    let texts = try await readText()
    let text = texts.map(\.string).joined(separator: "\n").lowercased()

    return switch cond {
    case .none(let strs): !strs.contains(where: text.contains)
    case .any(let strs): strs.contains(where: text.contains)
    case .all(let strs): strs.allSatisfy(text.contains)
    }
  }

  /// Reads text on the screen
  private func readText() async throws -> [Text] {
    let request = VNRecognizeTextRequest()

    try await analyzeDisplay([request])

    let observations = request.results ?? []

    return observations.map { observation in
      let candidates = observation.topCandidates(10)
      let string = candidates.map(\.string).joined(separator: "\n").lowercased()

      return Text(string: string, bounds: observation.boundingBox)
    }
  }
}

// MARK: - Detecting images on the display
extension VZAutomator {
  /// Wait for an image to be displayed
  public func wait(forImage image: CGImage, in rect: CGRect) async throws {
    try await wait {
      try await detect(image: image, in: rect)
    }
  }

  /// Detect the location of a specific image on the display
  public func detect(image: CGImage, at point: CGPoint) async throws -> Bool {
    try await detect(image: image, in: .init(x: point.x, y: point.y, width: CGFloat(image.width), height: CGFloat(image.height)))
  }

  /// Detect the location of a specific image on the display
  public func detect(image: CGImage, in rect: CGRect) async throws -> Bool {
    let target = CIImage(cgImage: image)
    guard let targetPrint = try await featurePrint(for: target) else { return false }

    var found = false

    try await withSurface { surface in
      let display = CIImage(ioSurface: surface).cropped(to: rect)
      guard let displayPrint = try await featurePrint(for: display) else { return }

      var distance: Float = 0
      try displayPrint.computeDistance(&distance, to: targetPrint)

      found = distance < 2.0
    }

    return found
  }

  private func featurePrint(for image: CIImage) async throws -> VNFeaturePrintObservation? {
    let requestHandler = VNImageRequestHandler(ciImage: image, options: [:])
    let req = VNGenerateImageFeaturePrintRequest()
    try requestHandler.perform([req])
    return req.results?.first as? VNFeaturePrintObservation
  }
}

// MARK: - Detecting that the display is active
extension VZAutomator {
  /// Wait for an image to be displayed
  public func waitForDisplay() async throws {
    try await wait {
      await frameBuffer != nil
    }
  }
}

// MARK: - Screenshots
extension VZAutomator {
  /// Take a screenshot of the display
  @MainActor
  public func screenshot(rect: CGRect? = nil) async throws -> NSImage? {
    // Take a screenshot of the display
    try await withSurface { surface in
      var display = CIImage(ioSurface: surface)

      if let rect {
        display = display.cropped(to: rect)
      }

      let rep = NSCIImageRep(ciImage: display)
      let image = NSImage(size: rep.size)
      image.addRepresentation(rep)

      return image
    }
  }
}

// MARK: - Helpers
extension VZAutomator {
  private func analyzeDisplay(_ requests: [VNRequest]) async throws {
    try await withSurface { surface in
      let image = CIImage(ioSurface: surface)
      let handler = VNImageRequestHandler(ciImage: image)
      try handler.perform(requests)
    }
  }

  @MainActor
  var frameBuffer: IOSurface? {
    return view.subviews.first?.layer?.contents as? IOSurface
  }

  @MainActor
  private func withSurface<T>(_ cb: (IOSurface) async throws -> T) async throws -> T? {
    guard
      let frameBufferView = view.subviews.first,
      let surface = frameBufferView.layer?.contents as? IOSurface
    else {
      return nil
    }

    surface.lock(options: .readOnly, seed: nil)

    let result = try await cb(surface)

    surface.unlock(options: .readOnly, seed: nil)

    return result
  }
}
