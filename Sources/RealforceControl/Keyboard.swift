//
//  Keyboard.swift
//  RealforceControl
//
//  Created by Daniel Vollmer on 10.05.25.
//


import CoreHID
import os
import Foundation

extension Data {
  /// Return a string with the hex bytes of the data.
  public func hexDump() -> String {
    let trimmedData = self.reversed().trimmingPrefix(while: { $0 == 0 }).reversed()
    return "[\(trimmedData.map { String(format: "%02x", $0) }.joined(separator: " "))]"
  }

  /// Replace the first `header.count` bytes with `header`.
  mutating func setHeader(_ header: [UInt8]) {
    precondition(header.count == 2, "header should be 2 bytes, but got \(header.count)")
    self.replaceSubrange(0..<header.count, with: header)
  }

  /// Replaces the bytes after the header with `cmd`.
  mutating func setCommand(_ cmd: [UInt8]) {
    precondition(cmd.count >= 4, "cmd should be >=4 bytes, but got \(cmd.count)")
    self.replaceSubrange(2..<Keyboard.pageDataOffset, with: cmd)
  }
}

enum KeyboardInitError : Error {
  /// couldn't create the client
  case noClient(HIDDeviceClient.DeviceReference)
  /// we expect very specific types of reports, so it the HID descriptor doesn't match our hard-coded reference, we bail
  case unexpectedHIDDescriptor(HIDDeviceClient, Data)
  /// couldn't get exclusive access to the device
  case cannotSeize(HIDDeviceClient, Error)
}

struct USBResponseError : Error {
  enum ErrorKind {
    case DeviceSeized
    case DeviceUnseized
    case DeviceRemoved
    case NoReply
    case UnexpectedData(Data)
  }
  let deviceClient : HIDDeviceClient
  let kind : ErrorKind
}

public actor Keyboard {
  static public let packetSize = 64
  static public let sendPrefix: [UInt8] = [0xAA, 0xAA]
  static public let recvPrefix: [UInt8] = [0x55, 0x55]
  static public let readPageCmd: [UInt8] = [0xC1, 0x00, 0x01] // followed by page
  static public let writePageCmd: [UInt8] = [0xC2, 0x00, 0x21] // followed by page
  static public let pageDataOffset = 6; // 2 bytes header, 1 byte cmd, 3 byte cmd args
  
  public enum WritePolicy {
    case cache
    case flush
  }
  
  public let deviceClient: HIDDeviceClient
  private let logger = Logger(subsystem: "de.maven.RealforceControl", category: "Keyboard")
  private let loggerUsb = Logger(subsystem: "de.maven.RealforceControl", category: "USB")
  
  private enum CacheEntry {
    case reading(Task<Data, Error>)
    case writing(Data, Task<Void, Error>)
    case ready(Data)
    case dirty(Data)
  }
  private var pageCache: [Setting: CacheEntry] = [:]

  // we don't have a failable initializer, since if we cannot set us up, then we don't want to continue
  public init(deviceRef: HIDDeviceClient.DeviceReference) async throws
  {
    guard let client = HIDDeviceClient(deviceReference: deviceRef) else {
      throw KeyboardInitError.noClient(deviceRef)
    }
    
    let descriptor = await client.descriptor
    // extracted from model X1UD with firmware A0.15
    let expectedDescriptor: [UInt8] = [0x06, 0x00, 0xFF, 0x09, 0x01, 0xA1, 0x01, 0x09, 0x02, 0x15, 0x00, 0x26, 0xFF, 0x00, 0x75, 0x08, 0x95, 0x40, 0x81, 0x02, 0x09, 0x03, 0x15, 0x00, 0x26, 0xFF, 0x00, 0x75, 0x08, 0x95, 0x40, 0x91, 0x02, 0xC0]
    
    guard descriptor.elementsEqual(expectedDescriptor) else {
      throw KeyboardInitError.unexpectedHIDDescriptor(client, descriptor)
    }
    
    do {
      try await client.seizeDevice()
    } catch {
      throw KeyboardInitError.cannotSeize(client, error)
    }
    deviceClient = client
  }
  
  /// Sends the packet.
  func send(packet: Data) async throws {
    precondition(packet.count == Keyboard.packetSize, "Packet only contains \(packet.count) bytes")
    precondition(packet.starts(with: Keyboard.sendPrefix), "Packet contains unexpected prefix")
    loggerUsb.debug("send \(packet.hexDump())")
    try await deviceClient.dispatchSetReportRequest(type: .output, data: packet)
  }
  
  /// Sends the packet and returns the (required) response.
  public func sendAndReceive(packet: Data) async throws -> Data {
    precondition(packet.count == Keyboard.packetSize, "Require packet to contain \(Keyboard.packetSize) bytes")
    precondition(packet.starts(with: Keyboard.sendPrefix), "Expect packet to start with \(Keyboard.sendPrefix)")
    let monitorStream = await deviceClient.monitorNotifications(reportIDsToMonitor: [], elementsToMonitor: [])
    let timeSent = SuspendingClock.now
    try await send(packet: packet)
    // TODO: timeout watchdog?
    monitorRecv: for try await notification in monitorStream {
      switch notification {
      case .inputReport(_, let response, let timestamp):
        if timestamp >= timeSent {
          loggerUsb.debug("recv \(response.hexDump())")
          guard response.count == Keyboard.packetSize && response.starts(with: Keyboard.recvPrefix) &&
                  response[Keyboard.recvPrefix.count] == response[Keyboard.sendPrefix.count] else {
            throw USBResponseError(deviceClient: deviceClient, kind: .UnexpectedData(response))
          }
          return response
        } else {
          loggerUsb.warning("sendAndReceive(): skipped old response?")
        }
      case .deviceRemoved:
        throw USBResponseError(deviceClient: deviceClient, kind: .DeviceRemoved)
      case .deviceSeized:
        throw USBResponseError(deviceClient: deviceClient, kind: .DeviceSeized)
      case .deviceUnseized:
        throw USBResponseError(deviceClient: deviceClient, kind: .DeviceUnseized)
      default:
        loggerUsb.info("sendAndReceive(): unknown HIDDeviceClient.Notification")
        continue
      }
    }
    throw USBResponseError(deviceClient: deviceClient, kind: .NoReply)
  }

  // MARK: basic operations

  /// This one is definitely OK to do before ``hello()`` (but the hello seems pretty optional, it may just restore settings).
  public func getInfo() async throws -> (model: String, firmware: String) {
    var tmp = Data(capacity: Keyboard.packetSize)
    tmp.append(contentsOf: Keyboard.sendPrefix)
    tmp.append(contentsOf: [0x02])
    tmp.resetBytes(in: tmp.count..<Keyboard.packetSize)
    let data = try await sendAndReceive(packet: tmp)
    let model = String(data: data[Keyboard.pageDataOffset..<Keyboard.pageDataOffset + 6], encoding: .nonLossyASCII)!
    // idx 6-7 = [16 06] (hex) no idea what those are; 6 could be HID Usage "Keyboard"?
    let fwOfs = Keyboard.pageDataOffset + 8
    let firmware = String(format: "%X%X.%X%X", data[fwOfs], data[fwOfs + 1], data[fwOfs + 2], data[fwOfs + 3])
    return (model, firmware)
  }


  /// Say hello to the keyboard.
  public func hello() async throws {
    pageCache.removeAll(keepingCapacity: true)
    try await handShake(isGoodBye: false)
  }

  /// Return the given page (from the cache if already present, otherwise it will be requested first).
  func get(page: Setting) async throws -> Data {
    logger.debug("get(page: \(page))")
    switch pageCache[page] {
    case .none:
      break
    case .ready(let data):
      return data
    case .dirty(let data):
      return data
    case .writing(let data, _):
      return data
    case .reading(let task):
      return try await task.value
    }
    
    let task = Task {
      do {
        let packetData = try await request(page: page)
        switch pageCache[page] {
        case .none:
          assert(false, "shouldn't have removed our cacheEntry")
        case .reading(_):
          pageCache[page] = .ready(packetData)
          return packetData
        case .ready(_):
          assert(false, "shouldn't have started a second read")
        case .dirty(let data):
          return data // we want to return the most recent data
        case .writing(let data, _):
          return data // we want to return the most recent data
        }
      } catch {
        if case .reading(_) = pageCache[page] {
          pageCache[page] = nil
        }
        throw error
      }
    }
    pageCache[page] = .reading(task)
    return try await task.value
  }
  
  /// Set the given page to the given data (either caching or actually writing).
  func set(page: Setting, data: Data, writePolicy: WritePolicy = .cache) async throws {
    logger.debug("set(page: \(page), data: \(data.hexDump()), writePolicy: \(String(describing: writePolicy)))")
    pageCache[page] = .dirty(data)
    switch writePolicy {
    case .cache: break
    case .flush: try await flush(page: page)
    }
  }
  
  /// Flush any changes made (i.e. dirty pages in the cache) to the keyboard.
  public func flush() async throws {
    logger.debug("flush()")
    // collect dirty pages and wait for any outstanding write tasks to complete
    var dirtyPages: [Setting] = []
    var writeTasks: [Task<Void, Error>] = []
    
    for (page, cacheEntry) in pageCache {
      switch cacheEntry {
      case .reading(_):
        break
      case .ready(_):
        break
      case .dirty(_):
        dirtyPages.append(page)
      case .writing(_, let task):
        writeTasks.append(task)
      }
    }
    for task in writeTasks {
      try await task.value
    }
    // flush in page order
    dirtyPages.sort()
    for page in dirtyPages {
      try await flush(page: page)
    }
  }
  
  /// Transfer any settings changed to the keyboard and commit them to keyboard memory.
  public func save() async throws {
    try await flush()
    var saveSettings = Data(capacity: Keyboard.packetSize)
    saveSettings.append(contentsOf: Keyboard.sendPrefix)
    saveSettings.append(contentsOf: [0xC0, 0x00, 0x01, 0x01])
    saveSettings.resetBytes(in: saveSettings.count..<Keyboard.packetSize)
    _ = try await sendAndReceive(packet: saveSettings)
  }

  /// Flush any outstanding writes, says good-bye, and then resets the cache.
  /**
   * You still need to ``save()`` the changes before if you want them to take effect, otherwise this restores the
   * saved settings.
   */
  public func goodbye() async throws {
    try await flush()
    try await handShake(isGoodBye: true)
    pageCache.removeAll(keepingCapacity: true)
  }

  // MARK: high level properties

  /// Return the name associated with this keyboard.
  public func getName() async throws -> String {
    logger.debug("getName()")
    let data = try await get(page: Setting.named(.keyboardName))
    // response: 0x55 0x55 0xC1 0x00 0x00 0x20 [chars] 0x00
    if let lastValIndex = data.lastIndex(where: { $0 != 0x00 }) {
      return String(data: data[Keyboard.pageDataOffset...lastValIndex], encoding: .nonLossyASCII)!
    }
    return String(data: data[Keyboard.pageDataOffset...], encoding: .nonLossyASCII)!
  }
  
  /// Set the name associated with this keyboard.
  public func setName(name: String, writePolicy: WritePolicy = .cache) async throws {
    logger.debug("setName(name: \(name)")
    let page = Setting.named(.keyboardName)
    var data = Data(capacity: Keyboard.packetSize)
    data.append(contentsOf: Keyboard.sendPrefix)
    data.append(contentsOf: Keyboard.writePageCmd)
    data.append(contentsOf: [page.rawValue])
    var strData = name.data(using: .utf8, allowLossyConversion: true) ?? Data()
    if strData.count + data.count > Keyboard.packetSize {
      strData.removeSubrange((Keyboard.packetSize - data.count)...)
    }
    data.append(strData)
    if (data.count < Keyboard.packetSize) {
      data.resetBytes(in: data.count..<Keyboard.packetSize)
    }
    assert(data.count == Keyboard.packetSize, "wrong size of message")
    try await set(page: page, data: data, writePolicy: writePolicy)
  }

  // MARK: APC (Actuation Point Control)

  public func getAPCMode() async throws -> APCMode {
    logger.debug("getAPCMode()")
    let data = try await get(page: Setting.named(.apc))
    return APCMode(rawValue: data[Keyboard.pageDataOffset])!
  }

  public func setAPCMode(mode: APCMode, writePolicy: WritePolicy = .cache) async throws {
    logger.debug("setAPCMode(apcMode: \(String(describing: mode)))")
    let page = Setting.named(.apc)
    var data = try await get(page: page)
    data.setHeader(Keyboard.sendPrefix)
    data.setCommand(Keyboard.writePageCmd + [page.rawValue])
    data[Keyboard.pageDataOffset] = mode.rawValue
    try await set(page: page, data: data, writePolicy: writePolicy)
  }


  public func getKillSwitch(map: APCMap) async throws -> KillSwitch {
    logger.debug("getKillSwitch(map: \(String(describing: map)))")
    let data = try await get(page: Setting.named(.apc))
    let ofs = Keyboard.pageDataOffset + 1 + {
      switch map {
      case .custom1: return 0
      case .custom2: return KillSwitch.dataSize
      }
    }()
    return KillSwitch(data: data[ofs..<ofs + KillSwitch.dataSize])
  }

  public func setKillSwitch(map: APCMap, killSwitch: KillSwitch, writePolicy: WritePolicy = .cache) async throws {
    logger.debug("setKillSwitch(map: \(String(describing: map)), killSwitch: \(String(describing: killSwitch)))")
    let page = Setting.named(.apc)
    var data = try await get(page: page)
    data.setHeader(Keyboard.sendPrefix)
    data.setCommand(Keyboard.writePageCmd + [page.rawValue])
    let ofs = Keyboard.pageDataOffset + 1 + {
      switch map {
      case .custom1: return 0
      case .custom2: return KillSwitch.dataSize
      }
    }()
    data[ofs..<ofs + KillSwitch.dataSize] = killSwitch.serialize()
    try await set(page: page, data: data, writePolicy: writePolicy)
  }

  public func getKeyAPC(map: APCMap, key: KeyID) async throws -> KeyAPCMode {
    precondition(key.rawValue < 0x80) // we only have 4 pages with 32 flags each
    logger.debug("getKeyAPC(map: \(String(describing: map)), key: \(key))")
    let (page, offset) = getAPCModeIndex(map: map, key: key)
    let data = try await get(page: page)
    return KeyAPCMode(rawValue: data[offset])!
  }

  public func setKeyAPC(map: APCMap, key: KeyID, mode: KeyAPCMode, writePolicy: WritePolicy = .cache) async throws {
    precondition(key.rawValue < 0x80) // we only have 4 pages with 32 flags each
    logger.debug("setKeyAPC(map: \(String(describing: map)), key: \(key), mode: \(String(describing: mode)))")
    let (page, offset) = getAPCModeIndex(map: map, key: key)
    var data = try await get(page: page)
    data.setHeader(Keyboard.sendPrefix)
    data.setCommand(Keyboard.writePageCmd + [page.rawValue])
    data[offset] = mode.rawValue
    try await set(page: page, data: data, writePolicy: writePolicy)
  }

  // MARK: Keymap

  public func getKeymap() async throws -> Keymap {
    logger.debug("getKeymap()")
    let data = try await get(page: Setting.named(.keymapSelect))
    return Keymap(rawValue: data[Keyboard.pageDataOffset])!
  }

  public func setKeymap(keymap: Keymap, writePolicy: WritePolicy = .cache) async throws{
    logger.debug("setKeymap(layout: \(String(describing: keymap)))")
    let page = Setting.named(.keymapSelect)
    var data = try await get(page: page)
    data.setHeader(Keyboard.sendPrefix)
    data.setCommand(Keyboard.writePageCmd + [page.rawValue])
    data[Keyboard.pageDataOffset] = keymap.rawValue
    try await set(page: page, data: data, writePolicy: writePolicy)
  }

  public func getKeyAction(keymap: Keymap, fn: Bool, key:KeyID) async throws -> KeyCode {
    precondition(key.rawValue < 0x80) // we only have 8 pages with 16 codes each
    logger.debug("getKeyAction(keymap: \(String(describing: keymap)), fn: \(fn), key: \(key))")
    let (page, offset) = getKeyActionIndex(keymap: keymap, fn: fn, key: key)
    let data = try await get(page: page)
    return KeyCode(rawValue: UInt16(data[offset]) << 8 + UInt16(data[offset + 1]))
  }

  public func setKeyAction(keymap: Keymap, fn: Bool, key: KeyID, action: KeyCode, writePolicy: WritePolicy = .cache) async throws {
    precondition(key.rawValue < 0x80) // we only have 8 pages with 16 codes each
    logger.debug("setKeyAction(keymap: \(String(describing: keymap)), fn: \(fn), key: \(key), action: \(action))")
    let (page, offset) = getKeyActionIndex(keymap: keymap, fn: fn, key: key)
    var data = try await get(page: page)
    data.setHeader(Keyboard.sendPrefix)
    data.setCommand(Keyboard.writePageCmd + [page.rawValue])
    data[offset + 0] = UInt8(truncatingIfNeeded: action.rawValue >> 8)
    data[offset + 1] = UInt8(truncatingIfNeeded: action.rawValue & 0xFF)
    try await set(page: page, data: data, writePolicy: writePolicy)
  }

  /// Return the shortcut (`oneBasedIndex` in (1...8)).
  public func getShortcut(oneBasedIndex: Int) async throws -> Shortcut {
    precondition((1...8).contains(oneBasedIndex), "Shortcut index needs to be in (1...8)")
    logger.debug("getShortcut(oneBasedIndex: \(oneBasedIndex))")
    let index = oneBasedIndex - 1
    let data = try await get(page: Setting.named(.shortcuts))
    // response: 2 bytes per shortcut [modifier flags] [HID Keycode (1 byte)]
    // Modifier Flags = LCtrl = 0x01, LShift => 0x02, LWin = 0x04, LAlt => 0x08,
    //                  RCtrl = 0x10, RShift => 0x20, RWin = 0x40, RAlt => 0x80
    let modifier = data[Keyboard.pageDataOffset + index * 2 + 0]
    let key      = data[Keyboard.pageDataOffset + index * 2 + 1]
    return Shortcut(key: KeyCode8(rawValue: key), modifier: ShortcutModifierKeys(rawValue: modifier))
  }

  /// Set the shortcut (`oneBasedIndex` in (1...8)) to `shortcut`.
  public func setShortcut(oneBasedIndex: Int, shortcut: Shortcut, writePolicy: WritePolicy = .cache) async throws {
    precondition((1...8).contains(oneBasedIndex), "Shortcut index needs to be in (1...8)")
    logger.debug("setShortcut(oneBasedIndex: \(oneBasedIndex), shortcut: \(String(describing: shortcut)))")
    let page = Setting.named(.shortcuts)
    var data = try await get(page: page)
    data.setHeader(Keyboard.sendPrefix)
    data.setCommand(Keyboard.writePageCmd + [page.rawValue])
    let index = oneBasedIndex - 1
    data[Keyboard.pageDataOffset + index * 2 + 0] = shortcut.modifier.rawValue
    data[Keyboard.pageDataOffset + index * 2 + 1] = shortcut.key.rawValue
    try await set(page: page, data: data, writePolicy: writePolicy)
  }

  // MARK: Illumination

  public func getBrightness() async throws -> Brightness {
    logger.debug("getBrightness()")
    let data = try await get(page: Setting.named(.illumination1))
    return Brightness(rawValue: data[Keyboard.pageDataOffset])!
  }

  public func setBrightness(brightness: Brightness, writePolicy: WritePolicy = .cache) async throws {
    logger.debug("setBrightness(brightness: \(String(describing:brightness)))")
    let page = Setting.named(.illumination1)
    var data = try await get(page: page)
    data.setHeader(Keyboard.sendPrefix)
    data.setCommand(Keyboard.writePageCmd + [page.rawValue])
    data[Keyboard.pageDataOffset] = brightness.rawValue
    try await set(page: page, data: data, writePolicy: writePolicy)
  }


  public func getLED(led: LEDSelect) async throws -> LED {
    logger.debug("getLED(led: \(String(describing: led)))")
    let data = try await get(page: Setting.named(.illumination1))
    let ofs = getLEDOffset(led: led)
    return LED(data: data[ofs..<ofs + LED.dataSize])
  }

  public func setLED(led: LEDSelect, config: LED, writePolicy: WritePolicy = .cache) async throws {
    logger.debug("setLED(led: \(String(describing: led)), config: \(String(describing: config)))")
    let page = Setting.named(.illumination1)
    var data = try await get(page: page)
    data.setHeader(Keyboard.sendPrefix)
    data.setCommand(Keyboard.writePageCmd + [page.rawValue])
    let ofs = getLEDOffset(led: led)
    data[ofs..<ofs + LED.dataSize] = config.serialize()
    try await set(page: page, data: data, writePolicy: writePolicy)
  }


  public func getPowerOnEffect() async throws -> PowerOnEffect {
    logger.debug("getPowerOnEffect()")
    let data = try await get(page: Setting.named(.illumination1))
    return PowerOnEffect(rawValue: data[Keyboard.powerOnEffectOffset])!
  }

  public func setPowerOnEffect(effect: PowerOnEffect, writePolicy: WritePolicy = .cache) async throws {
    logger.debug("setPowerOnEffect(effect: \(String(describing:effect)))")
    let page = Setting.named(.illumination1)
    var data = try await get(page: page)
    data.setHeader(Keyboard.sendPrefix)
    data.setCommand(Keyboard.writePageCmd + [page.rawValue])
    data[Keyboard.powerOnEffectOffset] = effect.rawValue
    try await set(page: page, data: data, writePolicy: writePolicy)
  }


  public func getBacklight() async throws -> BacklightMode {
    logger.debug("getBacklight()")
    let data = try await get(page: Setting.named(.illumination2))
    return BacklightMode(rawValue: data[Keyboard.pageDataOffset])!
  }

  public func setBacklight(mode: BacklightMode, writePolicy: WritePolicy = .cache) async throws {
    logger.debug("setBacklight(mode: \(String(describing:mode)))")
    let page = Setting.named(.illumination2)
    var data = try await get(page: page)
    data.setHeader(Keyboard.sendPrefix)
    data.setCommand(Keyboard.writePageCmd + [page.rawValue])
    data[Keyboard.pageDataOffset] = mode.rawValue
    try await set(page: page, data: data, writePolicy: writePolicy)
  }


  public func getBacklightIdle() async throws -> BacklightMode {
    logger.debug("getBacklightIdle()")
    let data = try await get(page: Setting.named(.illumination2))
    return BacklightMode(rawValue: data[Keyboard.pageDataOffset + 1 /* normal Backlight mode */])!
  }

  public func setBacklightIdle(mode: BacklightMode, writePolicy: WritePolicy = .cache) async throws {
    logger.debug("setBacklightIdle(mode: \(String(describing:mode)))")
    let page = Setting.named(.illumination2)
    var data = try await get(page: page)
    data.setHeader(Keyboard.sendPrefix)
    data.setCommand(Keyboard.writePageCmd + [page.rawValue])
    data[Keyboard.pageDataOffset + 1 /* normal Backlight mode */] = mode.rawValue
    try await set(page: page, data: data, writePolicy: writePolicy)
  }

  public func getBacklightIdleTimer() async throws -> IdleTimer {
    logger.debug("getBacklightIdleTimer()")
    let data = try await get(page: Setting.named(.illumination2))
    return IdleTimer(rawValue: data[Keyboard.pageDataOffset + 2 /* normal + idle Backlight mode */])!
  }

  public func setBacklightIdleTimer(timer: IdleTimer, writePolicy: WritePolicy = .cache) async throws {
    logger.debug("setBacklightIdleTimer(mode: \(timer)")
    let page = Setting.named(.illumination2)
    var data = try await get(page: page)
    data.setHeader(Keyboard.sendPrefix)
    data.setCommand(Keyboard.writePageCmd + [page.rawValue])
    data[Keyboard.pageDataOffset + 2 /* normal + idle Backlight mode */] = timer.rawValue
    try await set(page: page, data: data, writePolicy: writePolicy)
  }

  // MARK: internal stuff

  /// Get page (based on ``NamedSetting.perKey_Custom1_APCFlags0``) and offset for the given key.
  private func getAPCModeIndex(map: APCMap, key: KeyID) -> (page: Setting, offset: Int) {
    let (pageOffset, keyOffset) = key.rawValue.quotientAndRemainder(dividingBy: 32)
    let page = Setting(rawValue: {
      switch map {
      case .custom1: return Setting.named(.perKey_Custom1_APCFlags0)
      case .custom2: return Setting.named(.perKey_Custom2_APCFlags0)
      }
    }().rawValue + pageOffset)
    return (page, Keyboard.pageDataOffset + Int(keyOffset))
  }

  /// Get page (based on ``NamedSetting.perKey_MapA_Normal0``) and offset for the given key.
  private func getKeyActionIndex(keymap: Keymap, fn: Bool, key:KeyID) -> (page: Setting, offset: Int) {
    let (pageOffset, keyOffset) = key.rawValue.quotientAndRemainder(dividingBy: 16)
    let page = Setting(rawValue: {
      switch (keymap, fn) {
      case (.mapA, false): return Setting.named(.perKey_MapA_Normal0)
      case (.mapA, true):  return Setting.named(.perKey_MapA_Fn0)
      case (.mapB, false): return Setting.named(.perKey_MapB_Normal0)
      case (.mapB, true):  return Setting.named(.perKey_MapB_Fn0)
      }
    }().rawValue + pageOffset)
    return (page, Keyboard.pageDataOffset + Int(keyOffset) * 2 /* two bytes perKeyCode */)
  }

  /// Get offset for the given LED in the ``NamedSetting.Illumination1`` page.
  private func getLEDOffset(led: LEDSelect) -> Int {
    switch led {
    case .capsLock  : return Keyboard.pageDataOffset + 1 /* Brightness */
    case .scrollLock: return Keyboard.pageDataOffset + 1 /* Brightness */ + LED.dataSize
    case .numLock   : return Keyboard.pageDataOffset + 1 /* Brightness */ + 2 * LED.dataSize
    }
  }
  /// Offset for the PowerOnEffect on the ``NamedSetting.illumination1`` page.
  private static let powerOnEffectOffset = Keyboard.pageDataOffset + 1 /* Brightness */ + 3 * LED.dataSize


  /// Send AA AA 01 00 01 00 for hello, AA AA 01 00 01 01 for goodbye.
  /**
   * The goodBye actually restores the settings saved on the keyboard, so if the changes sent weren't saved, this
   * resets them.
   */
  private func handShake(isGoodBye: Bool) async throws {
    var handShake = Data(capacity: Keyboard.packetSize)
    handShake.append(contentsOf: Keyboard.sendPrefix)
    handShake.append(contentsOf: [0x01, 0x00, 0x01, isGoodBye ? 0x01 : 0x00])
    handShake.resetBytes(in: handShake.count..<Keyboard.packetSize)
    _ = try await sendAndReceive(packet: handShake)
  }

  /// Request the given page from the device.
  private func request(page: Setting) async throws -> Data {
    logger.debug("request(page: \(page))")
    var pageRequest = Data(capacity: Keyboard.packetSize)
    pageRequest.append(contentsOf: Keyboard.sendPrefix)
    pageRequest.append(contentsOf: Keyboard.readPageCmd)
    pageRequest.append(contentsOf: [page.rawValue])
    pageRequest.resetBytes(in: pageRequest.count..<Keyboard.packetSize)
    let result = try await sendAndReceive(packet: pageRequest)
    guard result[3] == 0x00 && result[4] == 0x00 && result[5] == 0x20 else {
      throw USBResponseError(deviceClient: deviceClient, kind: .UnexpectedData(result))
    }
    return result
  }
  
  /// Flush the given page to the device if it is dirty.
  private func flush(page: Setting) async throws {
    logger.debug("flush(page: \(page))")
    switch pageCache[page] {
    case .none:
      preconditionFailure("flushing page \(page) that isn't present")
    case .dirty(_):
      break
    case .reading(_):
      return
    case .ready(_):
      return
    case .writing(_, let task):
      return try await task.value // wait for any pending write to complete
    }
    
    guard case let .dirty(data) = pageCache[page] else { return }
    let task = Task {
      do {
        _ = try await sendAndReceive(packet: data)
        switch pageCache[page] {
        case .none:
          pageCache[page] = .ready(data)
        case .writing(_, _):
          pageCache[page] = .ready(data)
        case .dirty(_):
          break // remain dirty (since this must be a new write)
        case .reading(_):
          fatalError("shouldn't have started a read while writing")
        case .ready(_):
          fatalError("shouldn't have finished a read while writing")
        }
      } catch {
        // mark as dirty again (since the write failed)
        if case let .writing(data, _) = pageCache[page] {
          pageCache[page] = .dirty(data)
        }
        throw error
      }
    }
    pageCache[page] = .writing(data, task)
    return try await task.value
  }
}
