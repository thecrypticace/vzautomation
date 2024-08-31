# VZAutomation

This is an app that showcases how to automate a VZVirtualMachine.

I plan on making this installable via Swift PM once more of the APIs are stable and thought out but for now good ol' copy & paste is required. All APIs for automating the VM are located under the `VZAutomator` directory and are attached to the `VZAutomator` actor.

PRs welcome!

## How to use

1. Create an instance of `VZAutomator` by giving it a `VZVirtualMachineView`
2. Call the appropriate methods on VZAutomator like `wait(forText:)`, `waitForDisplay`, `press(key:)`, etc… in an async function

Very rough example code (look through the app for a more complete, correct example):

```swift
import Virtualization

// Create a `VZVirtualMachineView`
let vmView = VZVirtualMachineView()
vmView.virtualMachine = myVm

// Add it to your window
let myWindow = NSWindow()
myWindow.contentView!.addSubview(vmView)

// Create an automator
let automator = VZAutomator(vmView)

// Make sure to start the VM!
let opts = VZMacOSVirtualMachineStartOptions()
try await myVm.start(options: opts)

// Wait for the VM to boot and the display to be ready
try await automator.wait(forState: .running)
try await automator.waitForDisplay()

// Once we see "get started" we can press enter to continue
try await automator.wait(forText: "get started")
try await automator.press(key: .keyboardReturn)
```

## Features

### Waiting for state

You can use `automator.wait(forState:)` to wait for the VM to reach a certain state. The states are from `VZVirtualMachine.State`:

```swift
// Wait for the VM to be running
try await automator.wait(forState: .running)
```

### Waiting for the display to be ready

When you first start a virutal machine it's framebuffer may not be ready yet. You can use `automator.waitForDisplay()` which will wait for the frame buffer to be attached to the `VZVirtualMachineView` (at which point it should be actively rendering):

```swift
// Wait for the display to be showing something
try await automator.waitForDisplay()
```

## Waiting for text

You can use `automator.wait(forText:)` to wait for text to appear on the screen. All text queries are currently case-insensitive.

You may pass a `String`:

```swift
// Wait for "get started" to appear on the screen
try await automator.wait(forText: "get started")
```

or a `TextCondition` for more complex queries:

```swift
// Wait for all of the following text to appear on the screen:
try await automator.wait(forText: .all([
  "language", "english", "english (uk)",
]))

// Wait until none of the following text appear on the screen:
// This is useful for waiting for a screen to disappear
try await automator.wait(forText: .none([
  "language", "english", "english (uk)",
]))
```

## Detecting text on screen

Sometimes, instead of waiting for text to appear, you may want to check if text is currently on the screen. You can use `automator.has(text:)` to check if text is currently on the screen. This will return a `Bool` indicating if the text is currently on the screen. It can take a `String` or a `TextCondition` just like `wait(forText:)`.

```swift
// Change what you do based on "keyboard requirements" is on the screen
if try await automator.has(text: "keyboard requirements") {
  // Do something
} else {
  // Do something else
}
```

## Waiting a specific image to appear on screen

**This is a work in progress API**.

You may use the `automator.wait(forImage: myImage, at: somePoint)` API to detect an image on the screen at a specific location. There is also an API to determine if an image is currently on screen (at a location) or not. For now the coordinates are such that +Y points in the up direction — matching the macOS coordinate system. This is likely to change to be +Y points down.

```swift
// Wait for the image to appear on the screen at (915, 682)
try await automator.wait(forImage: myImage, at: CGPoint(x: 915, y: 682))

// Do something if the image exists on screen at (381, 293)
if try await automator.has(image: myImage, at: CGPoint(x: 381, y: 293)) {
  // Do something
}
```

## Taking a screenshot of the framebuffer

You may use the `automator.screenshot()` method to take a screenshot of the VM's framebuffer. The resolution will be the same as the resolution of the display. This will return a `NSImage` of the framebuffer at the time of the call. You may optionally pass a `CGRect` to only take a screenshot of a specific region of the framebuffer.

Note that macOS coordinate system is y-flipped. This is quite unintuitive and I will probably change these APIs so the y-axis is +y in the down direction like iOS.

```swift
// Take a screenshot of the entire framebuffer
let image = automator.screenshot()

// Take a screenshot of a specific region of the framebuffer
// This will take a screenshot of the region from (0, 0) to (100, 100)
let image = automator.screenshot(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
```

## Interacting with the keyboard

### Pressing keys on the keyboard

You may use `automator.press(key:)` to press a key on the keyboard. The keys are defined with constants as they're device independent.

```swift
// Press the return key
try await automator.press(key: .keyboardReturn)

// Press the return key 3 times
try await automator.press(key: .keyboardReturn, times: 3)

// Pressing multiple keys in sequence
try await automator.press(keys: [
  .keyboardReturn,
  .keyboardTab,
  .keyboardReturn,
  .keyboardReturn,
])

// Holding down a key
try await automator.hold(key: .keyboardShift)

// Releasing a key
try await automator.release(key: .keyboardShift)

// You may also use modifiers to simplify key presses
// This will press shift+tab twice by:
// Holding shift, pressing tab, releasing shift, holding shift, pressing tab, releasing shift
try await automator.press(key: .keyboardTab.shift, times: 2)
```

### Typing text

Attempting to type text by pressing individual keys is boring, slow, and error-prone. Instead use `automator.type()` to type text into the VM. This will type the given string into the VM by pressing the appropriate keys. Right now the mapping assumes a US QWERTY keyboard layout.

```swift
// For example, this workflow navigates to the appropriate text fields and types in the username, password, password confirmation, and creates the account

try await automator.type("admin")
try await automator.press(key: .keyboardTab, times: 2)
try await automator.type("secret123")
try await automator.press(key: .keyboardTab)
try await automator.type("secret123")
try await automator.press(key: .keyboardTab)
try await automator.press(key: .keyboardTab, times: 2)
try await automator.press(key: .keyboardSpacebar)
```
