//
//  AppController.swift
//  VZAutomation
//
//  Created by Jordan Pittman on 8/31/24.
//

import SwiftUI

@Observable
@MainActor
class AppController {
  var vm: VirtualMachine?
  var started: Bool = false
  var surface: IOSurface?
  var similarity: Float = 0.0

  var steps: [Step] {
    workflow.steps
  }

  var workflow = VZWorkflow(steps: [
    Step(id: "booting", name: "Booting"),
    Step(id: "hello", name: "Hello"),
    Step(id: "language", name: "Language"),
    Step(id: "country", name: "Country"),
    Step(id: "localization", name: "Localization"),
    Step(id: "accessibility", name: "Accessibility"),
    Step(id: "privacy", name: "Data"),
    Step(id: "migration", name: "Migration"),
    Step(id: "appleid", name: "Apple"),
    Step(id: "terms", name: "Terms"),
    Step(id: "account", name: "Account"),
  ])

  var screenshot: NSImage? = nil

  var resolution: CGSize {
    vm?.vm.graphicsDevices.first?.displays.first?.sizeInPixels ?? .zero
  }

  func start() {
    Task.detached {
      try await self.start()
    }
  }

  private func start() async throws {
    let bundle = MachineBundle.create()
    let vm = try VirtualMachine.create(bundle: bundle)
    self.vm = vm

    do {
      try await vm.start()
    } catch {
      print("\(error)")
      throw error
    }

    withAnimation {
      started = true
    }

    try await vm.automator.run(workflow: workflow)

    //    try await renderSnapshot()

//    print("\(vm.vm.graphicsDevices.first?.displays.first?.sizeInPixels ?? .zero)")
  }

  private func renderSnapshot() async throws {
    guard let vm else { return }
    guard let device = MTLCreateSystemDefaultDevice() else { return }

    try await vm.automator.waitForDisplay()

    // Detect the language chooser image
//    guard let imageGlobe = NSImage(named: "globe")?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
//      print("NO IMAGE")
//      return
//    }

    let rect = CGRect(x: 900, y: 1080-300, width: 1020, height: 100)
    let w = Int(rect.width)
    let h = Int(rect.height)

    let pool = Pool<(IOSurface, CIRenderDestination)>(count: 4) {
      let surface = IOSurface(properties: [
        .width: w,
        .height: h,
        .bytesPerElement: 4,
        .pixelFormat: kCVPixelFormatType_32BGRA
      ])

      guard let surface else {
        return nil
      }

      let renderer = CIRenderDestination(ioSurface: surface)

      return (surface, renderer)
    }

    let context = CIContext(mtlDevice: device)

    _ = DisplayLink(view: vm.view) {
      let (preview, destination) = pool.take()

      try? self.render(
        to: destination,
        using: context,
        crop: rect
      )

      self.surface = preview
    }
  }

  @MainActor
  func render(
    to destination: CIRenderDestination,
    using context: CIContext,
    crop rect: CGRect
  ) throws {
    guard let buffer = vm?.automator.frameBuffer else { return }

    let frameBuffer = CIImage(ioSurface: buffer)
      .cropped(to: rect)
      .transformed(by: .init(translationX: -rect.origin.x, y: -rect.origin.y))

    let clearTask = try context.startTask(toClear: destination)
    let renderTask = try context.startTask(toRender: frameBuffer, to: destination)
    try clearTask.waitUntilCompleted()
    try renderTask.waitUntilCompleted()
  }
}
