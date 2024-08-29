//
//  Surface.swift
//  VZAutomation
//
//  Created by Jordan Pittman on 8/17/24.
//

import CoreImage
import IOSurface

class Pool<T> {
  let items: [T]

  var index: Int

  init(count: Int, create: () -> T?) {
    var items: [T] = []

    for _ in 0..<count {
      guard let item = create() else {
        continue
      }

      items.append(item)
    }

    self.index = 0
    self.items = items
  }

  func take() -> T {
    let item = items[index]

    index = (index + 1) % items.count

    return item
  }
}

import AppKit
import SwiftUI
import QuartzCore

/// Draw an IOSurface on screen using SwiftUI
@MainActor
struct SurfaceView: NSViewRepresentable {
  private let surface: IOSurface
  private let surfaceLayer: CALayer

  init(surface: IOSurface) {
    self.surface = surface
    self.surfaceLayer = CALayer()
  }

  func makeNSView(context: Context) -> some NSView {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.contents = surface
    view.layer?.contentsGravity = .resizeAspect
    return view
  }

  func updateNSView(_ view: NSViewType, context: Context) {
    view.layer?.contents = surface
  }
}

/// Draw an IOSurface on screen using SwiftUI
@MainActor
struct CroppedSurfaceView: View {
  typealias RenderPool = Pool<(IOSurface, CIRenderDestination)>

  /// The source IOSurface
  let source: IOSurface

  /// The cropped IOSurface
  @State
  var preview: IOSurface?

  @State
  var bounds: SIMD4<Double> = [0, 0, 1920, 1080]

  @State
  var link: DisplayLink?

  @State
  var renderPool: RenderPool?

  var body: some View {
    VStack {
      VStack {
        HStack {
          Text("X").monospaced()
          TextField("X", value: $bounds.x, format: .number.grouping(.never))
            .textFieldStyle(.roundedBorder)
            .monospacedDigit()

          Text("Y").monospaced()
          TextField("Y", value: $bounds.y, format: .number.grouping(.never))
            .textFieldStyle(.roundedBorder)
            .monospacedDigit()
        }
        HStack {
          Text("W").monospaced()
          TextField("W", value: $bounds.z, format: .number.grouping(.never))
            .textFieldStyle(.roundedBorder)
            .monospacedDigit()

          Text("H").monospaced()
          TextField("H", value: $bounds.w, format: .number.grouping(.never))
            .textFieldStyle(.roundedBorder)
            .monospacedDigit()
        }
      }
      .padding()

      SurfaceView(surface: source)
        .frame(width: 480, height: 270)
        .background(.purple.opacity(0.25))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.black)

      if let preview {
        VStack {
          SurfaceView(surface: preview)
            .frame(width: 480, height: 270)
            .background(.purple.opacity(0.25))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.black)
        }
      }
    }

    // 1. Make sure a render context is available for drawing
    .onAppear {
      guard let device = MTLCreateSystemDefaultDevice() else { return }

      let context = CIContext(mtlDevice: device)

      renderPool = createPool(w: Int(bounds.z), h: Int(bounds.w))

      // 2. Render to the IOSurface every frame
      link = DisplayLink(screen: .main!) {
        guard let renderPool else { return }

        let (preview, destination) = renderPool.take()

        try? self.render(to: destination, using: context)

        self.preview = preview
      }
    }

    // 3. Create new IOSurfaces when bounds change
    .onChange(of: bounds) {
      renderPool = createPool(w: Int(bounds.z), h: Int(bounds.w))
    }
  }

  func createPool(w: Int, h: Int, buffers: Int = 4) -> RenderPool {
    RenderPool(count: buffers) {
      let surface = IOSurface(properties: [
        .width: Int(bounds.z),
        .height: Int(bounds.w),
        .bytesPerElement: 4,
        .pixelFormat: kCVPixelFormatType_32BGRA
      ])

      guard let surface else {
        return nil
      }

      let renderer = CIRenderDestination(ioSurface: surface)

      return (surface, renderer)
    }
  }

  @MainActor
  func render(
    to destination: CIRenderDestination,
    using context: CIContext
  ) throws {
    let frame = CGRect(x: 0, y: 0, width: CGFloat(source.width), height: CGFloat(source.height))

    let heightDelta = frame.height - bounds.w

    let rect = CGRect(
      x: bounds.x,
      y: bounds.y + heightDelta,
      width: bounds.z,
      height: bounds.w
    )

    let frameBuffer = CIImage(ioSurface: source).cropped(to: rect).transformed(by: .init(translationX: -rect.origin.x, y: -rect.origin.y))

    let clearTask = try context.startTask(toClear: destination)
    let renderTask = try context.startTask(toRender: frameBuffer, to: destination)
    try clearTask.waitUntilCompleted()
    try renderTask.waitUntilCompleted()
  }
}

extension IOSurface {
  static func draw(image: CIImage) throws -> IOSurface? {
    guard let device = MTLCreateSystemDefaultDevice() else { return nil }
    let context = CIContext(mtlDevice: device)

    let surface = Self(properties: [
      .width: Int(image.extent.width),
      .height: Int(image.extent.height),
      .bytesPerElement: 4,
      .pixelFormat: kCVPixelFormatType_32BGRA
    ])

    guard let surface else { return nil }

    let renderer = CIRenderDestination(ioSurface: surface)
    let clearTask = try context.startTask(toClear: renderer)
    let renderTask = try context.startTask(toRender: image, to: renderer)

    try clearTask.waitUntilCompleted()
    try renderTask.waitUntilCompleted()

    return surface
  }
}

extension CIImage {
  func render(into destination: CIRenderDestination, using context: CIContext) throws {
    let clearTask = try context.startTask(toClear: destination)
    let renderTask = try context.startTask(toRender: self, to: destination)

    try clearTask.waitUntilCompleted()
    try renderTask.waitUntilCompleted()
  }
}

import CoreImage.CIFilterBuiltins

func starShine() -> CIImage? {
  let generator = CIFilter.starShineGenerator()
  generator.center = CGPoint(x: 1920/2, y: 1080/2)
  generator.color = .green
  generator.radius = 50
  generator.crossScale = 15
  generator.crossAngle = 0.60
  generator.crossOpacity = -2
  generator.crossWidth = 2.5
  generator.epsilon = -2.0

  let bg = CIFilter.linearGradient()
  bg.point0 = CGPoint(x: 0, y: 0)
  bg.point1 = CGPoint(x: 1920, y: 1080)
  bg.color0 = CIColor(red: 216/255, green: 232/255, blue: 146/255)
  bg.color1 = CIColor(red: 0/255, green: 112/255, blue: 201/255)

  let output = CIFilter.sourceAtopCompositing()
  output.inputImage = generator.outputImage
  output.backgroundImage = bg.outputImage

  return output.outputImage
}

#Preview {
  let sourceImage = starShine()?.cropped(to: CGRect(
    x: 0, y: 0, width: 1920, height: 1080
  ))

  let surface = try? IOSurface.draw(image: sourceImage!)

  CroppedSurfaceView(source: surface!)
}
