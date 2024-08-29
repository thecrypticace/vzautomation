//
//  AutomationView.swift
//  VZAutomation
//
//  Created by Jordan Pittman on 8/15/24.
//

import SwiftUI
import AppKit
import Virtualization

struct VirtualMachineView: NSViewRepresentable {
  let vm: VirtualMachine
  let expanded: Bool

  func makeNSView(context: Context) -> VZVirtualMachineView {
    let view = vm.view

    updateNSView(view, context: context)

    return view
  }

  func updateNSView(_ view: VZVirtualMachineView, context: Context) {
    //
  }
}

class VMView: VZVirtualMachineView {
  override func flagsChanged(with event: NSEvent) {
    super.flagsChanged(with: event)

    print("flagsChanged \(event)")
  }

  override func keyDown(with event: NSEvent) {
    super.keyDown(with: event)

    print("keyDown \(event)")

    print("\(NSEvent.ModifierFlags.deviceIndependentFlagsMask)")
  }

  override func keyUp(with event: NSEvent) {
    super.keyUp(with: event)

    print("keyUp \(event)")
  }

  override func mouseEntered(with event: NSEvent) {
    print("mouse entered")

    super.mouseEntered(with: event)
  }

  override func mouseExited(with event: NSEvent) {
    print("mouse exited")

    super.mouseExited(with: event)
  }
}