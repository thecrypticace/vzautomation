//
//  VZAutomationTests.swift
//  VZAutomationTests
//
//  Created by Jordan Pittman on 8/15/24.
//

import Testing

@testable
import VZAutomation

struct VZAutomationTests {

  @Test
  func example() async throws {
    let keys = VZAutomator.Key.from("admin")
    let codes = keys.map(\.code)

    #expect(codes == [
      0, 2, 46, 34, 45,
    ])
  }

}
