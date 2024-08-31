//
//  Workflow+Run.swift
//  VZAutomation
//
//  Created by Jordan Pittman on 8/25/24.
//

import AppKit

extension VZAutomator {
  func run(workflow: VZWorkflow) async throws {
    try await workflow.run(automator: self)
  }
}

extension VZWorkflow {
  fileprivate func step(_ id: String, callback: () async throws -> Void) async throws {
    update(step: id, state: .running)
    do {
      try await callback()
      update(step: id, state: .done)
    } catch {
      update(step: id, state: .error)
      throw error
    }
  }

  fileprivate func screenshot(automator: VZAutomator) async throws {
    guard let screenshot = try await automator.screenshot() else {
      return
    }

    self.screenshots.append(screenshot)
  }

  fileprivate func run(automator: VZAutomator) async throws {
    try await step("booting") {
      try await automator.wait(forState: .running)
      try await automator.waitForDisplay()
    }

    try await screenshot(automator: automator)

    try await step("hello") {
      try await automator.wait(forText: "get started")
      try await automator.press(key: .keyboardReturn)
    }

    try await screenshot(automator: automator)

    try await step("language") {
      try await automator.wait(forImage: NSImage.globe, at: .init(x: 915, y: 682))

      try await automator.press(key: .keyboardTab)
      try await automator.press(key: .keyboardReturn)

      try await automator.wait(forText: .none(["language", "english", "english (uk)"]))
    }

    try await screenshot(automator: automator)

    try await step("country") {
      try await automator.wait(forText: "select your country or region")
      try await automator.press(key: .keyboardTab, times: 3)
      try await automator.press(key: .keyboardSpacebar)
    }

    try await screenshot(automator: automator)

    try await step("localization") {
      try await automator.wait(forText: "written and spoken languages")
      try await automator.press(key: .keyboardTab, times: 3)
      try await automator.press(key: .keyboardSpacebar)
    }

    try await screenshot(automator: automator)

    try await step("accessibility") {
      try await automator.wait(forText: "accessibility")
      try await automator.press(key: .keyboardTab, times: 6)
      try await automator.press(key: .keyboardSpacebar)

      try await automator.wait(forText: .none(["accessibility"]))
    }

    try await screenshot(automator: automator)

    try await step("privacy") {
      try await automator.wait(forText: "data & privacy")
      try await automator.press(key: .keyboardTab, times: 3)
      try await automator.press(key: .keyboardSpacebar)
    }

    try await screenshot(automator: automator)

    try await step("migration") {
      try await automator.wait(forText: "migration assistant")
      try await automator.press(key: .keyboardTab, times: 3)
      try await automator.press(key: .keyboardSpacebar)
    }

    try await screenshot(automator: automator)

    try await step("appleid") {
      try await automator.wait(forText: "create new apple id")
      try await automator.press(key: .keyboardTab.shift, times: 2)

//      try await automator.hold(key: .keyboardLeftShift)
//      try await automator.press(key: .keyboardTab, times: 2)
//      try await automator.release(key: .keyboardLeftShift)

      try await automator.press(key: .keyboardSpacebar)

      // -> Tap the "Skip" button
      try await automator.wait(forText: "are you sure you want to skip")
      try await automator.press(key: .keyboardReturn)
    }

    try await screenshot(automator: automator)

    try await step("terms") {
      try await automator.wait(forText: "terms and conditions")
      try await automator.press(key: .keyboardTab, times: 2)
      try await automator.press(key: .keyboardSpacebar)

      // Tap the "Agree" button
      try await automator.wait(forText: .all([
        "i have read",
        "disagree",
        "agree",
      ]))
      try await automator.press(key: .keyboardTab)
      try await automator.press(key: .keyboardSpacebar)
    }

    try await screenshot(automator: automator)

    try await step("account") {
      try await automator.wait(forText: "create a computer account")

      // -> Fill in username
      try await automator.type("admin")

      // -> Fill in account name (automatic)
      try await automator.press(key: .keyboardTab)

      // Fill in password
      try await automator.press(key: .keyboardTab)
      try await automator.type("secret123")

      // Fill in confirmation
      try await automator.press(key: .keyboardTab)

      if try await automator.has(text: "keyboard requirements") {
        // todo: fail
        return
      }

      try await automator.type("secret123")

      // Fill in hint (empty b/c optional)
      try await automator.press(key: .keyboardTab)

      // Select "Continue" button
      try await automator.press(key: .keyboardTab, times: 2)
      // try await automator.press(key: .keyboardSpacebar)
    }
  }
}
