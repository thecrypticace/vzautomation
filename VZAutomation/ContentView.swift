//
//  ContentView.swift
//  VZAutomation
//
//  Created by Jordan Pittman on 8/15/24.
//

import SwiftUI

struct ContentView: View {
  @State
  var controller = AppController()

  var body: some View {
    HStack(spacing: 0) {
      ZStack {
        Color.black

        if let vm = controller.vm {
          VirtualMachineView(vm: vm)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        PlayButton(action: controller.start)
          .opacity(controller.started ? 0.0 : 1.0)
      }

      SidebarView()
    }
    .environment(controller)
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
      withAnimation(.linear(duration: 0.125)) {
        hovering = switch phase {
        case .active(_): true
        case .ended: false
        }
      }
    }
  }

  var iconColors: [Color] {
    if hovering {
      [.white.opacity(0.60), .white.opacity(0.35)]
    } else {
      [.white.opacity(0.50), .white.opacity(0.25)]
    }
  }
}


struct SidebarView: View {
  enum SidebarTab: String, Hashable, CaseIterable {
    case workflow
    case inspect
  }

  @Environment(AppController.self)
  var controller

  @State
  var tab: SidebarTab = .workflow

  var body: some View {
    VStack(alignment: .trailing, spacing: 0) {
      Picker(selection: $tab, label: EmptyView()) {
        ForEach(SidebarTab.allCases, id: \.self) {
          switch $0 {
          case .workflow:
            Text("Workflow")
          case .inspect:
            Text("Inspect")
          }
        }
      }
      .pickerStyle(.segmented)
      .padding(8)
      .background {
        Rectangle()
          .padding(.horizontal, -16)
          .foregroundStyle(
            Color(white: 0.075)
              .shadow(.drop(color: .black.opacity(0.5), radius: 8))
          )
      }
      .zIndex(1)

      switch tab {
      case .workflow:
        WorkflowView(steps: controller.steps)
      case .inspect:
        InspectView()
      }
    }
    .frame(maxHeight: .infinity)
    .frame(width: 240)
    .background(Color(white: 0.075))
    .clipShape(Rectangle())
  }
}

struct InspectView: View {
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

#Preview {
    ContentView()
      .frame(width: 720, height: 480)
}

