//
//  KeyID.swift
//  RealforceControl
//
//  Created by Daniel Vollmer on 24.05.25.
//


/// An ID that identifies a keyswitch in the Keyboard.
public enum NamedSwitch: UInt8, CaseIterable, Sendable {
  // number row
  case keyAccentGrave = 0x00
  case key1 = 0x01
  case key2 = 0x02
  case key3 = 0x03
  case key4 = 0x04
  case key5 = 0x05
  case key6 = 0x06
  case key7 = 0x07
  case key8 = 0x08
  case key9 = 0x09
  case key0 = 0x0A
  case keyMinus = 0x0B
  case keyEqual = 0x0C
  case keyBackspace = 0x0E // missing before
  
  // letter top row
  case keyTab = 0xF
  case keyQ = 0x10
  case keyW = 0x11
  case keyE = 0x12
  case keyR = 0x13
  case keyT = 0x14
  case keyY = 0x15
  case keyU = 0x16
  case keyI = 0x17
  case keyO = 0x18
  case keyP = 0x19
  case keyBracketLeft = 0x1A
  case keyBracketRight = 0x1B
  case keyBackslash = 0x1C
  
  // letter middle row
  case keyCapsLock = 0x1D
  case keyA = 0x1E
  case keyS = 0x1F
  case keyD = 0x20
  case keyF = 0x21
  case keyG = 0x22
  case keyH = 0x23
  case keyJ = 0x24
  case keyK = 0x25
  case keyL = 0x26
  case keySemicolon = 0x27
  case keyApostrophe = 0x28
  case keyReturnOrEnter = 0x2A // missing before
  
  // letter bottom how
  case keyLeftShift = 0x2B
  case keyZ = 0x2D // where is 2C?
  case keyX = 0x2E
  case keyC = 0x2F
  case keyV = 0x30
  case keyB = 0x31
  case keyN = 0x32
  case keyM = 0x33
  case keyComma = 0x34
  case keyPeriod = 0x35
  case keySlash = 0x36
  case keyRightShift = 0x38 // missing before
  
  // bottom row
  case keyLeftControl = 0x39
  case keyLeftGUI = 0x3B
  case keyLeftAlt = 0x43
  case keySpace = 0x3C
  case keyRightAlt = 0x3D
  case keyRightGUI = 0x44
  case keyFn = 0x45
  case keyRightControl = 0x3F
  
  // movement block
  case keyInsert = 0x4A
  case keyDelete = 0x4B
  case keyArrowLeft = 0x4E
  case keyHome = 0x4F
  case keyEnd = 0x50
  case keyArrowUp = 0x52
  case keyArrowDown = 0x53
  case keyPageUp = 0x54
  case keyPageDown = 0x55
  case keyArrowRight = 0x58
  
  // function row
  case keyEscape = 0x6D
  case keyF1 = 0x6F
  case keyF2 = 0x70
  case keyF3 = 0x71
  case keyF4 = 0x72
  case keyF5 = 0x73
  case keyF6 = 0x74
  case keyF7 = 0x75
  case keyF8 = 0x76
  case keyF9 = 0x77
  case keyF10 = 0x78
  case keyF11 = 0x79
  case keyF12 = 0x7A
  case keyPrintScreen = 0x7B
  case keyScrollLock = 0x7C
  case keyPause = 0x7D

  private static let name2Value = Dictionary(uniqueKeysWithValues: allCases.map { (String(describing: $0), $0) })
}

extension NamedSwitch {
  init?(name: String) {
    if let v = Self.name2Value[name] {
      self = v
    } else {
      return nil
    }
  }
}

public enum KeyID: Sendable, CustomStringConvertible {
  case named(NamedSwitch)
  case raw(UInt8)

  public init(rawValue: UInt8) {
    if let s = NamedSwitch(rawValue: rawValue) {
      self = .named(s)
    } else {
      self = .raw(rawValue)
    }
  }

  var rawValue: UInt8 {
    switch self {
    case .named(let s): return s.rawValue
    case .raw(let s):   return s
    }
  }

  public var description: String {
    switch self {
    case .named(let n): return String(format: "0x%02x[.\(n)]", self.rawValue)
    case .raw(let r):   return String(format: "0x%02x", r)
    }
  }
}

extension KeyID {
  public init?(_ text: String) {
    if let named = NamedSwitch(name: text) { // enum string
      self = .named(named)
    } else if let match = text.wholeMatch(of: hexNumRegex), let num = UInt8(match.output.1) { // hex num
      self = .raw(num)
    } else if let num = UInt8(text) { // num
      self = .raw(num)
    }
    return nil
  }
}

// MARK: in memory representations

public struct ShortcutModifierKeys: OptionSet, Sendable {
  public let rawValue: UInt8
  public init(rawValue: UInt8) {
    self.rawValue = rawValue
  }

  public static let leftControl  = ShortcutModifierKeys(rawValue: 0x01)
  public static let leftShift    = ShortcutModifierKeys(rawValue: 0x02)
  public static let leftWin      = ShortcutModifierKeys(rawValue: 0x04)
  public static let leftAlt      = ShortcutModifierKeys(rawValue: 0x08)
  public static let rightControl = ShortcutModifierKeys(rawValue: 0x10)
  public static let rightShift   = ShortcutModifierKeys(rawValue: 0x20)
  public static let rightWin     = ShortcutModifierKeys(rawValue: 0x40)
  public static let rightAlt     = ShortcutModifierKeys(rawValue: 0x80)
}

extension ShortcutModifierKeys: CustomStringConvertible {
  static let debugDescriptions: [(Self, String)] = [
    (.leftControl,  "LCtrl"),
    (.leftShift,    "LShift"),
    (.leftWin,      "LWin"),
    (.leftAlt,      "LAlt"),
    (.rightControl, "RCtrl"),
    (.rightShift,   "RShift"),
    (.rightWin,     "RWin"),
    (.rightAlt,     "RAlt"),
  ]

  public var description: String {
    let result: [String] = Self.debugDescriptions.filter { contains($0.0) }.map { $0.1 }
    return "ShortcutModifierKeys(rawValue: \(self.rawValue)) \(result)"
  }
}

public struct Shortcut: Sendable {
  /// The KeyCode the shortcut triggers, see ``KeyCode`` (but truncated to UInt8).
  public let key: KeyCode8
  /// The modifier keys to send with the shortcut.
  public let modifier: ShortcutModifierKeys

  public init(key: KeyCode8, modifier: ShortcutModifierKeys) {
    self.key = key
    self.modifier = modifier
  }
}

/// The active key map (within the map, there two mappings: Normal, and when Fn is pressed).
public enum Keymap: UInt8, Sendable {
  /// Keymap A
  case mapA = 0x00
  /// Keymap B
  case mapB = 0x01
}
