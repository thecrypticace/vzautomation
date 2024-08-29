//
//  DisplayLink.swift
//  VZAutomation
//
//  Created by Jordan Pittman on 8/15/24.
//

import AppKit

@MainActor
class DisplayLink: NSObject {
  typealias Handler = () -> Void

  private var link: CADisplayLink!
  private let handler: Handler

  init(link: CADisplayLink?, handler: @escaping Handler) {
    self.link = link
    self.handler = handler
    super.init()
  }

  convenience init(view: NSView, handler: @escaping Handler) {
    self.init(link: nil, handler: handler)

    let link = view.displayLink(target: self, selector: #selector(handle(link:)))
    link.add(to: .main, forMode: .common)

    self.link = link
  }

  convenience init(screen: NSScreen, handler: @escaping Handler) {
    self.init(link: nil, handler: handler)

    let link = screen.displayLink(target: self, selector: #selector(handle(link:)))
    link.add(to: .main, forMode: .common)

    self.link = link
  }

  func stop() {
    link.invalidate()
  }

  @objc
  func handle(link: CADisplayLink) {
    handler()
  }
}
