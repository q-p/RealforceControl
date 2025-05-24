//
//  Illumination.swift
//  RealforceControl
//
//  Created by Daniel Vollmer on 24.05.25.
//


import Foundation

public enum Brightness: UInt8, Sendable {
  case off = 0x00
  case low = 0x01
  case mid = 0x02
  case high = 0x03
}

public enum BacklightMode: UInt8, Sendable {
  case Custom = 0x00
  case RainbowWave = 0x01
  case Windmill = 0x02
  case ColorBar = 0x03
  case Random = 0x04
  case DemoMode = 0x05
  case PressedKey = 0x06
  case Heatmap = 0x07
  case MonoMix = 0x08
  case MonoRed = 0x09
  case MonoGreen = 0x0A
  case MonoYellow = 0x0B
  case MonoBlue = 0x0C
  case MonoMagenta = 0x0D
  case MonoCyan = 0x0E
  case MonoWhite = 0x0F
  case APC = 0x10
  case OFF = 0xFF
}

public enum PowerOnEffect: UInt8, Sendable {
  case OFF = 0x00
  case Curtain = 0x01
  case Scan = 0x02
  case FillUp = 0x03
  case Join = 0x04
  case Spiral = 0x05
  case HOTARU = 0x06
}

// MARK: in memory representations

/// Backlight Settings to indicate "LED state" for classic keyboard LEDs
public enum LEDSelect: Sendable {
  case capsLock
  case scrollLock
  /// NumLock not present on GX1!
  case numLock
}

public struct LED: Sendable {
  /// Whether the "backlight as LED indicator" feature is enabled for this LED.
  public let isEnabled: Bool
  public let colorR: UInt8
  public let colorG: UInt8
  public let colorB: UInt8
}

public enum IdleTimer: UInt8, Sendable, CustomStringConvertible {
  case off = 0
  case _01min = 1
  case _02min = 2
  case _03min = 3
  case _04min = 4
  case _05min = 5
  case _06min = 6
  case _07min = 7
  case _08min = 8
  case _09min = 9
  case _10min = 10
  case _11min = 11
  case _12min = 12
  case _13min = 13
  case _14min = 14
  case _15min = 15
  case _16min = 16
  case _17min = 17
  case _18min = 18
  case _19min = 19
  case _20min = 20
  case _21min = 21
  case _22min = 22
  case _23min = 23
  case _24min = 24
  case _25min = 25
  case _26min = 26
  case _27min = 27
  case _28min = 28
  case _29min = 29
  case _30min = 30

  /// 0 minutes => off, minutes must be <= 30
  public init?(minutes: UInt8) {
    self.init(rawValue: minutes)
  }

  public var description: String {
    switch self {
    case .off: return "off"
    default  : return "\(self.rawValue)min"
    }
  }
}

// MARK: internal extensions

extension LED {
  static let dataSize = 4

  init(data: Data) {
    precondition(data.count == LED.dataSize)
    let i = data.startIndex
    isEnabled = data[i + 0] != 0
    colorR = data[i + 1]
    colorG = data[i + 2]
    colorB = data[i + 3]
  }

  func serialize() -> Data {
    var data = Data(count: LED.dataSize)
    data[0] = isEnabled ? 0x01 : 0x00
    data[1] = colorR
    data[2] = colorG
    data[3] = colorB
    return data
  }
}
