//
//  EventLog.swift
//  VZAutomation
//
//  Created by Jordan Pittman on 8/29/24.
//

import SwiftUI

struct EventLogView: View {
  let events: [NSEvent]

  var body: some View {
    ScrollView {
      VStack(spacing: 8) {
        ForEach(events, id: \.hashValue) { event in
          EventView(event: event)
            .background {
              RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(
                  .linearGradient(
                    colors: [
                      Color(white: 0.20),
                      Color(white: 0.15),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                  )
                  .shadow(.drop(color: .black.opacity(0.125), radius: 4))
                  .shadow(.drop(color: .black.opacity(0.250), radius: 4))
                  .shadow(.drop(color: .black.opacity(0.125), radius: 2))
                )
                .overlay {
                  RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(style: .init(lineWidth: 1))
                    .foregroundStyle(
                      Color(white: 0.75, opacity: 0.1)
                    )
                }
            }
        }
      }
      .padding(8)
    }
    .background(Color(white: 0.075))
  }
}

struct EventView: View {
  let event: NSEvent

  var body: some View {
    HStack(spacing: 4) {
      Text(eventTitle)
        .textCase(.uppercase)
        .font(.headline)

      Spacer()

      switch event.type {
      case .keyDown:
        KeyEventView(event: event)
      case .keyUp:
        KeyEventView(event: event)
      case .flagsChanged:
        FlagsChangedView(event: event)
      default:
        EmptyView()
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 4)
    .padding(.leading, 12)
    .padding(.trailing, 4)
  }

  var eventTitle: String {
    switch event.type {
    case .keyDown: "Key Down"
    case .keyUp: "Key Up"
    case .flagsChanged: "Flags Changed"
    case _: "Other"
    }
  }
}

struct KeyEventView: View {
  let event: NSEvent

  var body: some View {
    KeyView(active: true) {
      Text("12")
    }
  }
}

struct FlagsChangedView: View {
  let event: NSEvent

  var body: some View {
    KeyView(active: event.modifierFlags.contains(.capsLock)) {
      Image(systemName: "capslock")
    }

    KeyView(active: event.modifierFlags.contains(.shift)) {
      Image(systemName: "shift")
    }

    KeyView(active: event.modifierFlags.contains(.function)) {
      Image(systemName: "fn")
    }

    KeyView(active: event.modifierFlags.contains(.control)) {
      Image(systemName: "control")
    }

    KeyView(active: event.modifierFlags.contains(.option)) {
      Image(systemName: "option")
    }

    KeyView(active: event.modifierFlags.contains(.command)) {
      Image(systemName: "command")
    }
  }
}

struct KeyView<Content>: View where Content: View {
  let active: Bool

  @ViewBuilder
  let content: () -> Content

  var body: some View {
    content()
      .symbolRenderingMode(.monochrome)
      .font(.system(size: 16))
      .frame(width: 32, height: 32)
      .foregroundStyle(
        active
          ? Color(white: 1.0, opacity: 0.75)
          : Color(white: 1.0, opacity: 0.25)
      )
      .background {
        RoundedRectangle(cornerRadius: 4)

          .foregroundStyle(
            .linearGradient(
              colors: [
                active ? Color(white: 0.125) : .clear,
                active ? Color(white: 0.150) : .clear,
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          )

          .overlay {
            RoundedRectangle(cornerRadius: 4)
              .strokeBorder(style: .init(lineWidth: 1))
              .foregroundStyle(
                Color(white: 0.75, opacity: active ? 0.375 : 0.120)
              )
          }
      }
  }
}

#Preview {
  EventLogView(events: [
    NSEvent.keyEvent(
      with: .keyDown,
      location: .zero,
      modifierFlags: [],
      timestamp: 0,
      windowNumber: 0,
      context: nil,
      characters: "",
      charactersIgnoringModifiers: "",
      isARepeat: false,
      keyCode: 0
    )!,

    NSEvent.keyEvent(
      with: .keyUp,
      location: .zero,
      modifierFlags: [],
      timestamp: 0,
      windowNumber: 0,
      context: nil,
      characters: "",
      charactersIgnoringModifiers: "",
      isARepeat: false,
      keyCode: 0
    )!,

    NSEvent.keyEvent(
      with: .flagsChanged,
      location: .zero,
      modifierFlags: [
        .option,
        .command
      ],
      timestamp: 0,
      windowNumber: 0,
      context: nil,
      characters: "",
      charactersIgnoringModifiers: "",
      isARepeat: false,
      keyCode: 0
    )!
  ])
}
