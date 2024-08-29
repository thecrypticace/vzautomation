//
//  Workflow+Steps.swift
//  VZAutomation
//
//  Created by Jordan Pittman on 8/25/24.
//

import Observation
import SwiftUI

extension VZWorkflow {
  func update(step id: String, state: Step.State) {
    guard let step = steps.first(where: { $0.id == id }) else { return }
    step.move(to: state)
  }
}

@Observable
final class Step: Identifiable {
  enum State {
    case idle
    case waiting
    case done
    case error
  }

  let id: String
  let name: String
  var state: State

  init(id: String, name: String, state: State = .idle) {
    self.id = id
    self.name = name
    self.state = state
  }
}

extension Step: Equatable, Hashable {
  static func ==(lhs: Step, rhs: Step) -> Bool {
    return lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension Step {
  func move(to state: Step.State) {
    withAnimation {
      self.state = state
    }
  }
}
