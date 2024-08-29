//
//  VirtualMachine.swift
//  VZAutomation
//
//  Created by Jordan Pittman on 8/15/24.
//

import Virtualization
import Observation

enum CreationError: Error {
  case missingBundle(path: String)
  case invalidHardwareModel
  case unsupportedHardwareModel
  case invalidMachineIdentifier
}

struct MachineBundle {
  let baseURL: URL

  init(url: URL) {
    self.baseURL = url
  }

  static func create() -> Self {
    let path = NSHomeDirectory() + "/VM.bundle/"

    return Self(url: URL(fileURLWithPath: path))
  }

  var auxiliaryStorageURL: URL { baseURL.appendingPathComponent("AuxiliaryStorage") }
  var diskImageURL: URL { baseURL.appendingPathComponent("Disk.img") }
  var hardwareModelURL: URL { baseURL.appendingPathComponent("HardwareModel") }
  var machineIdentifierURL: URL { baseURL.appendingPathComponent("MachineIdentifier") }
  var restoreImageURL: URL { baseURL.appendingPathComponent("RestoreImage.ipsw") }
  var saveFileURL: URL { baseURL.appendingPathComponent("SaveFile.vzvmsave") }

  func hardwareModel() throws -> VZMacHardwareModel? {
    VZMacHardwareModel(dataRepresentation: try Data(contentsOf: hardwareModelURL))
  }

  func machineIdentifier() throws -> VZMacMachineIdentifier? {
    VZMacMachineIdentifier(dataRepresentation: try Data(contentsOf: machineIdentifierURL))
  }

  func createPlatform() throws -> VZPlatformConfiguration {
    let platform = VZMacPlatformConfiguration()

    let bundlePath = baseURL.path(percentEncoded: false)

    guard FileManager.default.fileExists(atPath: bundlePath) else {
      throw CreationError.missingBundle(path: bundlePath)
    }

    guard let hardwareModel = try hardwareModel() else {
      throw CreationError.invalidHardwareModel
    }

    guard hardwareModel.isSupported else {
      throw CreationError.unsupportedHardwareModel
    }

    guard let machineIdentifier = try machineIdentifier() else {
      throw CreationError.invalidMachineIdentifier
    }

    let auxiliaryStorage = VZMacAuxiliaryStorage(contentsOf: auxiliaryStorageURL)
    platform.auxiliaryStorage = auxiliaryStorage
    platform.hardwareModel = hardwareModel
    platform.machineIdentifier = machineIdentifier

    return platform
  }

  func computeCPUCount() -> Int {
    let totalAvailableCPUs = ProcessInfo.processInfo.processorCount

    var virtualCPUCount = totalAvailableCPUs <= 1 ? 1 : totalAvailableCPUs - 1
    virtualCPUCount = max(virtualCPUCount, VZVirtualMachineConfiguration.minimumAllowedCPUCount)
    virtualCPUCount = min(virtualCPUCount, VZVirtualMachineConfiguration.maximumAllowedCPUCount)

    return virtualCPUCount
  }

  func computeMemorySize() -> UInt64 {
    // Set the amount of system memory to 4 GB; this is a baseline value
    // that you can change depending on your use case.
    var memorySize = (4 * 1024 * 1024 * 1024) as UInt64
    memorySize = max(memorySize, VZVirtualMachineConfiguration.minimumAllowedMemorySize)
    memorySize = min(memorySize, VZVirtualMachineConfiguration.maximumAllowedMemorySize)

    return memorySize
  }

  func createBootLoader() -> VZMacOSBootLoader {
    return VZMacOSBootLoader()
  }

  func createGraphicsDeviceConfiguration() -> VZMacGraphicsDeviceConfiguration {
    let config = VZMacGraphicsDeviceConfiguration()

    config.displays = [
      VZMacGraphicsDisplayConfiguration(widthInPixels: 1920, heightInPixels: 1080, pixelsPerInch: 80)
    ]

    return config
  }

  func createBlockDeviceConfiguration() throws -> VZVirtioBlockDeviceConfiguration {
    let diskImageAttachment = try VZDiskImageStorageDeviceAttachment(url: diskImageURL, readOnly: false)
    let disk = VZVirtioBlockDeviceConfiguration(attachment: diskImageAttachment)
    return disk
  }

  func createNetworkDeviceConfiguration() -> VZVirtioNetworkDeviceConfiguration {
    let networkDevice = VZVirtioNetworkDeviceConfiguration()
    networkDevice.macAddress = VZMACAddress(string: "d6:a7:58:8e:78:d4")!

    let networkAttachment = VZNATNetworkDeviceAttachment()
    networkDevice.attachment = networkAttachment

    return networkDevice
  }

  func createPointingDeviceConfiguration() -> VZPointingDeviceConfiguration {
    return VZMacTrackpadConfiguration()
  }

  func createKeyboardConfiguration() -> VZKeyboardConfiguration {
    return VZMacKeyboardConfiguration()
  }

  func createConsoleConfiguration() -> VZConsoleDeviceConfiguration {
    let config = VZVirtioConsoleDeviceConfiguration()
    let port = VZVirtioConsolePortConfiguration()
    port.isConsole = true
    port.attachment = VZFileHandleSerialPortAttachment(
      fileHandleForReading: nil,
      fileHandleForWriting: nil
    )

    config.ports[0] = port

    return config
  }

  func configuration() throws -> VZVirtualMachineConfiguration {
    let config = VZVirtualMachineConfiguration()

    config.platform = try createPlatform()
    config.bootLoader = createBootLoader()
    config.cpuCount = computeCPUCount()
    config.memorySize = computeMemorySize()
    config.graphicsDevices = [createGraphicsDeviceConfiguration()]
    config.storageDevices = [try createBlockDeviceConfiguration()]
    config.networkDevices = [createNetworkDeviceConfiguration()]
    config.pointingDevices = [createPointingDeviceConfiguration()]
    config.keyboards = [createKeyboardConfiguration()]

    return config
  }
}

class VirtualMachineCoordinator: NSObject, VZVirtualMachineDelegate {
  func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
    print("Virtual machine did stop with error: \(error.localizedDescription)")
  }

  func guestDidStop(_ virtualMachine: VZVirtualMachine) {
    print("Guest did stop virtual machine.")
  }
}

@Observable
@MainActor
class VirtualMachine {
  let vm: VZVirtualMachine
  let bundle: MachineBundle
  let coordinator: VirtualMachineCoordinator
  let view: VZVirtualMachineView
  var automator: VZAutomator
  var slice = CIImage()

  required init(vm: VZVirtualMachine, bundle: MachineBundle, coordinator: VirtualMachineCoordinator) {
    self.vm = vm
    self.bundle = bundle
    self.coordinator = coordinator

    view = VMView()
    view.automaticallyReconfiguresDisplay = false
    view.virtualMachine = vm
    view.capturesSystemKeys = true

    automator = VZAutomator(view: view)
  }

  public static func create(bundle: MachineBundle) throws -> Self {
    let config = try bundle.configuration()
    try config.validate()
    try config.validateSaveRestoreSupport()

    let vm = VZVirtualMachine(configuration: config)
    let coordinator = VirtualMachineCoordinator()
    vm.delegate = coordinator

    return Self(vm: vm, bundle: bundle, coordinator: coordinator)
  }

  func start() async throws {
    let opts = VZMacOSVirtualMachineStartOptions()
    try await vm.start(options: opts)
  }

  var surface: IOSurface? {
    let frameBufferView = view.subviews.first

    return frameBufferView?.layer?.contents as? IOSurface
  }

  func test() async throws {
    // Wait for the machine to boot
    try await automator.wait(forState: .running)
    try await automator.waitForDisplay()

    // Press enter once the hello screen is visible
    try await automator.wait(forText: "get started")
    try await automator.hold(key: .keyboardReturn)
    try await automator.release(key: .keyboardReturn)

    // Detect the language chooser image
//    guard let imageGlobe = NSImage(named: "globe")?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
//      print("NO IMAGE")
//      return
//    }

    // Detect the language chooser image
//    guard let imageCountry = NSImage(named: "country")?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
//      print("NO IMAGE")
//      return
//    }


//    slice = CIImage()

//    try await replay(event: .wait(for: .time(.milliseconds(5_000))))

//    let found = try await automator.detect(image: imageGlobe, at: .init(x: 660*2, y: 760*2))
//    print("Found Image? \(found)")
//
//    let found2 = try await automator.detect(image: imageCountry, at: .init(x: 660*2, y: 760*2))
//    print("Found Image? \(found2)")
  }
}
