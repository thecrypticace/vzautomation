//
//  ContentView.swift
//  VZAutomation
//
//  Created by Jordan Pittman on 8/15/24.
//

import SwiftUI
import simd

struct GridView: View {
  struct Tile {
    let size: CGSize
    let with: GraphicsContext.Shading
  }

  let tiles: [Tile]

  var body: some View {
    Canvas(opaque: true, rendersAsynchronously: true) { ctx, size in
      ctx.fill(
        Path(CGRect(origin: .zero, size: size)),
        with: .color(Color(white: 0.075))
      )

      for tile in tiles {
        let x = Path { path in
          for i in 0...Int(size.width/tile.size.width) {
            let x = tile.size.width * CGFloat(i)

            path.move(to: .init(x: x, y: 0))
            path.addLine(to: .init(x: x, y: size.height))
          }
        }

        let y = Path { path in
          for i in 0...Int(size.height/tile.size.height) {
            let y = tile.size.height * CGFloat(i)

            path.move(to: .init(x: 0, y: y))
            path.addLine(to: .init(x: size.width, y: y))
          }
        }

        ctx.stroke(x, with: tile.with, style: .init(lineWidth: 1, dash: [4, 4], dashPhase: 2.0))
        ctx.stroke(y, with: tile.with, style: .init(lineWidth: 1, dash: [4, 4], dashPhase: 2.0))
      }
    }
  }
}

struct SnapToGridLayout: Layout {
  struct Rect {
    let x: CGFloat
    let y: CGFloat
    let w: CGFloat
    let h: CGFloat
  }

  struct SnapTo: LayoutValueKey {
    static let defaultValue: Rect? = .init(x: 0, y: 0, w: 1, h: 1)
  }

  let size: CGSize

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    var minX: CGFloat = 0
    var minY: CGFloat = 0
    var maxX: CGFloat = 0
    var maxY: CGFloat = 0

    for subview in subviews {
      guard let rect = subview[SnapTo.self] else { continue }

      minX = min(minX, rect.x)
      minY = min(minY, rect.y)

      maxX = max(maxX, rect.x + rect.w)
      maxY = max(maxY, rect.y + rect.h)
    }

    let deltaX = (maxX - minX) + 1
    let deltaY = (maxY - minY) + 1
    let size = CGSize(width: deltaX * size.width, height: deltaY * size.height)

    return proposal.replacingUnspecifiedDimensions(by: size)
  }
  
  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    for subview in subviews {
      let rect = subview[SnapTo.self]

      guard let rect else {
        subview.place(at: bounds.origin, proposal: .unspecified)
        continue
      }

      let origin = CGPoint(
        x: bounds.origin.x + size.width * rect.x,
        y: bounds.origin.y + size.height * rect.y
      )

      let size = CGSize(width: size.width * rect.w, height: size.height * rect.h)

      subview.place(at: origin, anchor: .topLeading, proposal: .init(size))
    }
  }
}

struct Snapped<Content: View>: View {
  let x: CGFloat
  let y: CGFloat
  let w: CGFloat
  let h: CGFloat

  @ViewBuilder
  let content: () -> Content

  private var rect: SnapToGridLayout.Rect {
    .init(x: x, y: y, w: w, h: h)
  }

  var body: some View {
    ZStack {
      content()
    }
    .layoutValue(
      key: SnapToGridLayout.SnapTo.self,
      value: rect
    )
  }
}

struct ContentView: View {
  @State
  var controller = AppController()

  @State
  var type: Bool = false

  var body: some View {
    HStack(spacing: 0) {
      ZStack {
        Color.black

        if let vm = controller.vm {
          VirtualMachineView(vm: vm, expanded: type)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        PlayButton(action: controller.start)
          .opacity(controller.started ? 0.0 : 1.0)
      }

      GeometryReader { proxy in
        ScrollView {
          ZStack {
            GridView(tiles: [
              .init(size: CGSize(width: 24 * 1, height: 24 * 1), with: .color(white: 0.125)),
            ])
            .frame(minHeight: proxy.size.height, maxHeight: .infinity)

            SnapToGridLayout(size: CGSize(width: 24, height: 24)) {
              if
                let vm = controller.vm,
                let size = vm.vm.graphicsDevices.first?.displays.first?.sizeInPixels
              {
                Snapped(x: 1, y: 1, w: 8, h: 2) {
                  Button(action: {
                    type = true
                  }) {
                    ZStack {
                      RoundedRectangle(cornerRadius: 4.0)
                        .foregroundStyle(Color(white: 0.075, opacity: 0.75))
                        .overlay {
                          RoundedRectangle(cornerRadius: 4.0)
                            .inset(by: -0.5)
                            .strokeBorder(style: .init(lineWidth: 1.0))
                            .foregroundStyle(Color(white: 0.250, opacity: 0.75))
                        }

                      Text("\(size.width, format: .number.precision(.fractionLength(0))) × \(size.height, format: .number.precision(.fractionLength(0)))")
                        .monospacedDigit()
                    }
                  }
                  .buttonStyle(.plain)
                }
              }

//              Snapped(x: 1, y: 1, w: 8, h: 5) {
//                ZStack {
//                  Color.black
//
//                  if let screenshot = controller.screenshot {
//                    Image(nsImage: screenshot)
//                      .resizable()
//                      .aspectRatio(16.0/9.0, contentMode: .fit)
//                  }
//                }
//                .clipShape(.rect(cornerRadius: 8.0))
//              }

              ForEach(Array(controller.steps.enumerated()), id: \.element) { (idx, step) in
                Snapped(x: 1, y: 1 + 5 + 1 + CGFloat(idx*3), w: 8, h: 2) {
                  StepView(step: step)
                }
              }
            }
            .frame(maxHeight: .infinity)
          }
        }
        .background(Color(white: 0.075))
      }
      .frame(width: 240)

//      SidebarView()
//        .padding()
    }
    .environment(controller)
  }
}

struct StepView: View {
  var step: Step

  var body: some View {
    ZStack(alignment: .leading) {
      RoundedRectangle(cornerRadius: 4.0)
        .phaseAnimator([false, true]) { content, phase in
          content
            .foregroundStyle(
              .linearGradient(
                colors: [
                  Color(white: 0.20),
                  Color(white: 0.15),
                ],
                startPoint: .top,
                endPoint: .bottom
              )
              .shadow(.drop(
                color: step.state == .waiting
                  ? .white.opacity(phase == true ? 0.125 : 0.375)
                  : .black.opacity(0.375),
                radius: 8
              ))
              .shadow(.drop(color: .black.opacity(0.250), radius: 4))
              .shadow(.drop(color: .black.opacity(0.125), radius: 2))
            )
            .overlay {
              RoundedRectangle(cornerRadius: 4.0)
                .strokeBorder(style: .init(lineWidth: 1))
                .foregroundStyle(
                  step.state == .waiting
                    ? Color.white.opacity(phase == true ? 0.125 : 0.375)
                    : Color(white: 0.75, opacity: 0.1)
                )
            }
        } animation: { phase in
          if phase {
            .easeOut(duration: 3)
          } else {
            .easeIn(duration: 1)
          }
        }

      HStack {
        Text(step.name)
          .font(.headline)

        Spacer()

        stateView()
          .frame(width: 16, height: 16)
      }
      .foregroundStyle(Color(white: 0.75))
      .padding(.leading, 16)
      .padding(.trailing, 12)
    }
  }

  var opacity: CGFloat {
    switch step.state {
    case .idle: 0.25
    case .waiting: 1.0
    case .error: 1.0
    case .done: 1.0
    }
  }

  @ViewBuilder
  func stateView() -> some View {
    ZStack(alignment: .center) {
      switch step.state {
      case .idle:
        Image(systemName: "circle.dashed")
          .symbolRenderingMode(.monochrome)
          .foregroundStyle(.foreground.opacity(0.5))
      case .waiting:
        ProgressView()
          .progressViewStyle(.circular)
          .scaleEffect(.init(width: 0.5, height: 0.5))
      case .done:
        Image(systemName: "checkmark.circle.fill")
          .symbolRenderingMode(.monochrome)
          .foregroundColor(.green)
      case .error:
        Image(systemName: "exclamationmark.triangle.fill")
          .symbolRenderingMode(.monochrome)
          .foregroundColor(.yellow)
      }
    }
  }
}


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

struct SidebarView: View {
  @Environment(AppController.self)
  var controller

  @State
  private var x = 0.0
  @State
  private var y = 0.0
  @State
  private var w = 1920
  @State
  private var h = 1080

  var body: some View {
    VStack(spacing: 0) {

      VStack {
        HStack {
          Text("X")
          TextField("X", value: $x, format: .number.grouping(.never))
              .textFieldStyle(.roundedBorder)

          Text("Y")
          TextField("Y", value: $y, format: .number.grouping(.never))
              .textFieldStyle(.roundedBorder)
        }
        HStack {
          Text("W")
          TextField("W", value: $w, format: .number.grouping(.never))
              .textFieldStyle(.roundedBorder)

          Text("H")
          TextField("H", value: $h, format: .number.grouping(.never))
              .textFieldStyle(.roundedBorder)
        }
      }

      Spacer()

      if let surface = controller.surface {
        VStack {
          SurfaceView(surface: surface)
            .aspectRatio(16/9, contentMode: .fit)
            .frame(width: 250)
            .background(.black)

          Text("\(controller.resolution.width, format: .number.grouping(.never))⨉\(controller.resolution.height, format: .number.grouping(.never))")
            .monospacedDigit()
        }
      }

      Spacer()

      Image("globe")

      Text("Similarity: \(controller.similarity)")
        .padding()
    }
    .navigationTitle("VZ Automation")
  }
}

struct PlayButton: View {
  let action: () -> Void

  @State
  var hovering: Bool = false

  var body: some View {
    Button(action: action) {
      Image(systemName: "play.fill")
        .font(.system(size: 48))
        .foregroundStyle(
          .linearGradient(
            colors: iconColors,
            startPoint: .top,
            endPoint: .bottom
          )
          .shadow(.drop(color: .black, radius: 4))
        )
    }
    .buttonStyle(.plain)
    .onContinuousHover { phase in
      hovering = switch phase {
      case .active(_): true
      case .ended: false
      }
    }
  }

  var iconColors: [Color] {
    if hovering {
      [.white.opacity(0.55), .white.opacity(0.30)]
    } else {
      [.white.opacity(0.50), .white.opacity(0.25)]
    }
  }
}

import Carbon.HIToolbox.Events
import IOKit

#Preview {
    ContentView()
      .frame(width: 720, height: 480)
      .onAppear {
        print("\(kVK_ANSI_A)")
      }
}

