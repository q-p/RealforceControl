//
//  APC.swift
//  RealforceControl
//
//  Created by Daniel Vollmer on 24.05.25.
//


import Foundation

/// The "global" APC mode (i.e. not per key settings).
public enum APCMode: UInt8, Sendable, CustomStringConvertible {
  // 0.8mm
  case depth08mm = 0x00
  // 1.5mm
  case depth15mm = 0x01
  // 2.2mm
  case depth22mm = 0x02
  // 3.0mm
  case depth30mm = 0x03
  // Custom1 (these are a set of "per key" APC settings)
  case custom1 = 0x04
  case custom2 = 0x05

  public var description: String {
    switch self {
    case .depth08mm: return "0.8mm"
    case .depth15mm: return "1.5mm"
    case .depth22mm: return "2.2mm"
    case .depth30mm: return "3.0mm"
    case .custom1:   return "Custom1"
    case .custom2:   return "Custom2"
    }
  }
}

/// APC settings for an individual key, active in global ``APCMode.custom1`` or ``APCMode.custom2`` mode.
public enum KeyAPCMode: UInt8, Sendable, CustomStringConvertible {
  // 0.8mm
  case depth08mm = 0x00
  // 1.5mm
  case depth15mm = 0x01
  // 2.2mm
  case depth22mm = 0x02
  // 3.0mm
  case depth30mm = 0x03
  // User1 (these are a user-defined setting for an individual key).
  case user1 = 0x06
  case user2 = 0x07
  case user3 = 0x08
  case user4 = 0x09
  case user5 = 0x0A
  case user6 = 0x0B
  case user7 = 0x0C
  case user8 = 0x0D
  case user9 = 0x0E
  case user10 = 0x0F
  case user11 = 0x10
  case user12 = 0x11
  case user13 = 0x12
  case user14 = 0x13
  case user15 = 0x14
  case user16 = 0x15

  public var description: String {
    switch self {
    case .depth08mm: return "0.8mm"
    case .depth15mm: return "1.5mm"
    case .depth22mm: return "2.2mm"
    case .depth30mm: return "3.0mm"
    case .user1:     return "User1"
    case .user2:     return "User2"
    case .user3:     return "User3"
    case .user4:     return "User4"
    case .user5:     return "User5"
    case .user6:     return "User6"
    case .user7:     return "User7"
    case .user8:     return "User8"
    case .user9:     return "User9"
    case .user10:    return "User10"
    case .user11:    return "User11"
    case .user12:    return "User12"
    case .user13:    return "User13"
    case .user14:    return "User14"
    case .user15:    return "User15"
    case .user16:    return "User16"
    }
  }
}

/// The priority settings for a KillSwitch pair.
public enum KillSwitchMode: UInt8, Sendable {
  /// KillSwitch is disabled.
  case off = 0x00
  /// Neither key outputs as active.
  case neutral = 0x01
  /// The key pressed first remains active, the one pressed second is released.
  case firstInputPriority = 0x02
  /// The key pressed first is released, the one pressed second remains active.
  case lastInputPriority = 0x03
  /// If both are pressed, Key1 will always be output (and Key2 will not).
  case key1InputPriority = 0x04
  /// If both are pressed, Key2 will always be output (and Key1 will not).
  case key2InputPriority = 0x05
}

// MARK: in memory representations

public struct KillSwitchPair: Sendable {
  /// The KeyCode of the first key.
  public let key1: KeyCode8
  /// The KeyCode of the second key.
  public let key2: KeyCode8
  /// The mode in which the keys oppose each other.
  public let mode: KillSwitchMode
}

public struct KillSwitch: Sendable {
  /// Whether the KillSwitch feature is enabled for this pair.
  public let isEnabled: Bool
  public let pair1: KillSwitchPair
  public let pair2: KillSwitchPair
}

/// For stuff that is only active / configure in either Custom1 or 2 APC settings.
public enum APCMap: Sendable {
  case custom1
  case custom2
}

// MARK: internal extensions

extension KillSwitchPair {
  static let dataSize = 3

  init(data: Data) {
    precondition(data.count == KillSwitchPair.dataSize)
    var i = data.startIndex
    key1 = KeyCode8(rawValue: data[i])
    i += 1
    key2 = KeyCode8(rawValue: data[i])
    i += 1
    mode = KillSwitchMode(rawValue: data[i])!
  }

  func serialize() -> Data {
    var data = Data(count: KillSwitchPair.dataSize)
    data[0] = key1.rawValue
    data[1] = key2.rawValue
    data[2] = mode.rawValue
    return data
  }
}

extension KillSwitch {
  static let dataSize = 1 + 2 * KillSwitchPair.dataSize

  init(data: Data) {
    precondition(data.count == KillSwitch.dataSize)
    var i = data.startIndex
    isEnabled = data[i] != 0
    i += 1
    pair1 = KillSwitchPair(data: data[i..<i + KillSwitchPair.dataSize])
    i += KillSwitchPair.dataSize
    pair2 = KillSwitchPair(data: data[i..<i + KillSwitchPair.dataSize])
  }

  func serialize() -> Data {
    var data = Data(count: KillSwitch.dataSize)
    data[0] = isEnabled ? 0x01 : 0x00
    data[1..<1 + KillSwitchPair.dataSize] = pair1.serialize()
    data[1 + KillSwitchPair.dataSize..<1 + 2 * KillSwitchPair.dataSize] = pair2.serialize()
    return data
  }
}

