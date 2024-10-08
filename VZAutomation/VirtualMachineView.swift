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

  override func mouseMoved(with event: NSEvent) {
    super.mouseMoved(with: event)

    guard let frameBufferView = subviews.first else {
      return
    }

    guard let displayResolution = virtualMachine?.graphicsDevices.first?.displays.first?.sizeInPixels else {
      return
    }

    // Get the point relative to the frame buffer's frame
    let windowRelativePoint = event.locationInWindow
    let bufferRelativePoint = frameBufferView.convert(
      windowRelativePoint,
      from: nil
    )

    let frameBufferSize = frameBufferView.frame.size

    // Rescale this coordinate to be relative to the VM's display
    let displayRelativePoint = CGPoint(
      x: bufferRelativePoint.x / frameBufferSize.width * displayResolution.width,
      y: bufferRelativePoint.y / frameBufferSize.height * displayResolution.height
    )

    print("mouse moved to: \(displayRelativePoint)")
  }

  override func mouseEntered(with event: NSEvent) {
    super.mouseEntered(with: event)

    print("mouse entered")
  }

  override func mouseExited(with event: NSEvent) {
    super.mouseExited(with: event)

    print("mouse exited")
  }
}
