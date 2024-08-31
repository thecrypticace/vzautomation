//
//  WorkflowView.swift
//  VZAutomation
//
//  Created by Jordan Pittman on 8/31/24.
//

import SwiftUI

struct WorkflowView: View {
  let steps: [Step]

  var body: some View {
    GeometryReader { proxy in
      ScrollView {
        ZStack {
          GridView(tiles: [
            .init(width: 24, height: 24, with: .color(white: 0.125)),
          ])
          .frame(minHeight: proxy.size.height, maxHeight: .infinity)

          SnapToGridLayout(size: CGSize(width: 24, height: 24)) {
            ForEach(Array(steps.enumerated()), id: \.element) { (idx, step) in
              Snapped(x: 1, y: 1 + CGFloat(idx*3), w: 8, h: 2) {
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
  }
}

struct StepView: View {
  var step: Step

  var body: some View {
    ZStack(alignment: .leading) {
      RoundedRectangle(cornerRadius: 4.0)
        .phaseAnimator(phases) { content, phase in
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
                color: shadowColor(phase: phase),
                radius: 8
              ))
              .shadow(.drop(color: .black.opacity(0.250), radius: 4))
              .shadow(.drop(color: .black.opacity(0.125), radius: 2))
            )
            .overlay {
              RoundedRectangle(cornerRadius: 4.0)
                .strokeBorder(style: .init(lineWidth: 1))
                .foregroundStyle(
                  borderColor(phase: phase)
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
    case .running: 1.0
    case .error: 1.0
    case .done: 1.0
    }
  }

  var phases: [Bool] {
    switch step.state {
    case .idle: [false]
    case .running: [false, true]
    case .done: [false]
    case .error: [false]
    }
  }

  func shadowColor(phase: Bool) -> Color {
    switch step.state {
    case .idle:
      Color(white: 0.0, opacity: 0.1)
    case .running:
      Color(white: 1.0, opacity: phase == true ? 0.125 : 0.375)
    case .done:
      Color(white: 0.0, opacity: 0.1)
    case .error:
      Color.yellow.opacity(0.25)
    }
  }


  func borderColor(phase: Bool) -> Color {
    switch step.state {
    case .idle:
      Color(white: 0.75, opacity: 0.1)
    case .running:
      Color(white: 1.0, opacity: phase == true ? 0.125 : 0.375)
    case .done:
      Color(white: 0.75, opacity: 0.1)
    case .error:
      Color.yellow.opacity(0.375)
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
      case .running:
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

#Preview {
  WorkflowView(steps: [
    Step(id: "idle", name: "Idle", state: .idle),
    Step(id: "waiting", name: "Running", state: .running),
    Step(id: "Done", name: "Done", state: .done),
    Step(id: "error", name: "Error", state: .error),
  ])
    .environment(AppController())
}
