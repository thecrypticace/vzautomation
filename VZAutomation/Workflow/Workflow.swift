//
//  AutomationProgress.swift
//  VZAutomation
//
//  Created by Jordan Pittman on 8/25/24.
//

import AppKit

/// Represents a specific workflow used to automate a `VZVirtualMachine`
@MainActor
class VZWorkflow {
  var steps: [Step] = []
  var screenshots: [NSImage] = []

  init(steps: [Step]) {
    self.steps = steps
    self.screenshots = []
  }
}
