//
//  GridLayout.swift
//  VZAutomation
//
//  Created by Jordan Pittman on 8/31/24.
//

import SwiftUI

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
