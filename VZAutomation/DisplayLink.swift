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

  private init(handler: @escaping Handler) {
    self.link = nil
    self.handler = handler
    super.init()
  }

  convenience init(view: NSView, handler: @escaping Handler) {
    self.init(handler: handler)

    link = view.displayLink(target: self, selector: #selector(handle(link:)))
    link.add(to: .main, forMode: .common)
  }

  convenience init(screen: NSScreen, handler: @escaping Handler) {
    self.init(handler: handler)

    link = screen.displayLink(target: self, selector: #selector(handle(link:)))
    link.add(to: .main, forMode: .common)
  }

  deinit {
    link.invalidate()
  }

  @objc
  func handle(link: CADisplayLink) {
    handler()
  }
}
