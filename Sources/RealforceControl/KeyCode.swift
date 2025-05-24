//
//  KeyCode.swift
//  RealforceControl
//
//  Created by Daniel Vollmer on 04.05.25.
//


nonisolated(unsafe)
public let hexNumRegex = /0[xX]([0-9,a-f,A-F]+)/

/// USB HID keycodes from page 0x07 (but internally the keyboard does not store the page for these, it's 0x00).
/**
 * These are largely from page 0x07 but the page is set to 0x00 for these internally.
 *
 * Also see IOHIDUsageTables.h
 */
public enum NamedKeyCode8: UInt8, CaseIterable, Sendable {
  case none = 0x00
  
  case errorRollOver = 0x01
  case POSTFail = 0x02
  case errorUndefined = 0x03
  
  case kbdA = 0x04
  case kbdB = 0x05
  case kbdC = 0x06
  case kbdD = 0x07
  case kbdE = 0x08
  case kbdF = 0x09
  case kbdG = 0x0A
  case kbdH = 0x0B
  case kbdI = 0x0C
  case kbdJ = 0x0D
  case kbdK = 0x0E
  case kbdL = 0x0F
  case kbdM = 0x10
  case kbdN = 0x11
  case kbdO = 0x12
  case kbdP = 0x13
  case kbdQ = 0x14
  case kbdR = 0x15
  case kbdS = 0x16
  case kbdT = 0x17
  case kbdU = 0x18
  case kbdV = 0x19
  case kbdW = 0x1A
  case kbdX = 0x1B
  case kbdY = 0x1C
  case kbdZ = 0x1D
  
  case kbd1 = 0x1E // !
  case kbd2 = 0x1F // @
  case kbd3 = 0x20 // #
  case kbd4 = 0x21 // $
  case kbd5 = 0x22 // %
  case kbd6 = 0x23 // ^
  case kbd7 = 0x24 // &
  case kbd8 = 0x25 // *
  case kbd9 = 0x26 // (
  case kbd0 = 0x27 // )
  
  case kbdReturnOrEnter = 0x28 // ENTER
  case kbdEscape = 0x29
  case kbdBackspace = 0x2A // DELETE
  case kbdTab = 0x2B
  case kbdSpace = 0x2C
  case kbdMinus = 0x2D // _
  case kbdEqual = 0x2E // +
  case kbdBracketLeft = 0x2F // {
  case kbdBracketRight = 0x30 // }
  case kbdBackslash = 0x31 // |
  case kbdNonUSHash = 0x32 // ~
  case kbdSemicolon = 0x33 // :
  case kbdApostrophe = 0x34 // "
  case kbdAccentGrave = 0x35 // ~
  case kbdComma = 0x36 // <
  case kbdPeriod = 0x37 // >
  case kbdSlash = 0x38 // ?
  case kbdCapsLock = 0x39
  
  case kbdF1 = 0x3A
  case kbdF2 = 0x3B
  case kbdF3 = 0x3C
  case kbdF4 = 0x3D
  case kbdF5 = 0x3E
  case kbdF6 = 0x3F
  case kbdF7 = 0x40
  case kbdF8 = 0x41
  case kbdF9 = 0x42
  case kbdF10 = 0x43
  case kbdF11 = 0x44
  case kbdF12 = 0x45
  
  case kbdPrintScreen = 0x46
  case kbdScrollLock = 0x47
  case kbdPause = 0x48
  case kbdInsert = 0x49
  case kbdHome = 0x4A
  case kbdPageUp = 0x4B
  case kbdDelete = 0x4C // "forward delete"
  case kbdEnd = 0x4D
  case kbdPageDown = 0x4E
  case kbdArrowRight = 0x4F
  case kbdArrowLeft = 0x50
  case kbdArrowDown = 0x51
  case kbdArrowUp = 0x52
  
  case kpNumLock = 0x53
  case kpSlash = 0x54
  case kpStar = 0x55
  case kpMinus = 0x56
  case kpPlus = 0x57
  case kpEnter = 0x58
  case kp1 = 0x59 // End
  case kp2 = 0x5A // ArrowDown
  case kp3 = 0x5B // PageDown
  case kp4 = 0x5C // ArrowLeft
  case kp5 = 0x5D
  case kp6 = 0x5E // ArrowRight
  case kp7 = 0x5F // Home
  case kp8 = 0x60 // ArrowUp
  case kp9 = 0x61 // PageUp
  case kp0 = 0x62 // Insert
  case kpPeriod = 0x63 // Delete
  
  case kbdNonUSBackslash = 0x64 // |
  case kbdApp = 0x65 // Application
  case kbdPower = 0x66
  
  case kpEqual = 0x67
  
  case kbdF13 = 0x68
  case kbdF14 = 0x69
  case kbdF15 = 0x6A
  case kbdF16 = 0x6B
  case kbdF17 = 0x6C
  case kbdF18 = 0x6D
  case kbdF19 = 0x6E
  case kbdF20 = 0x6F
  case kbdF21 = 0x70
  case kbdF22 = 0x71
  case kbdF23 = 0x72
  case kbdF24 = 0x73
  
  case kbdExecute = 0x74
  case kbdHelp = 0x75
  case kbdMenu = 0x76
  case kbdSelect = 0x77
  case kbdStop = 0x78
  case kbdAgain = 0x79
  case kbdUndo = 0x7A
  case kbdCut = 0x7B
  case kbdCopy = 0x7C
  case kbdPaste = 0x7D
  case kbdFind = 0x7E
  case kbdMute = 0x7F
  
  case kbdVolumeUp = 0x80
  case kbdVolumeDown = 0x81
  case kbdLockingCapsLock = 0x82
  case kbdLockingNumLock = 0x83
  case kbdLockingScrollLock = 0x84
  
  case kpComma = 0x85
  case kpEqualAS400 = 0x86
  
  case kbdInternational1 = 0x87
  case kbdInternational2 = 0x88
  case kbdInternational3 = 0x89
  case kbdInternational4 = 0x8A
  case kbdInternational5 = 0x8B
  case kbdInternational6 = 0x8C
  case kbdInternational7 = 0x8D
  case kbdInternational8 = 0x8E
  case kbdInternational9 = 0x8F
  
  case kbdLANG1 = 0x90
  case kbdLANG2 = 0x91
  case kbdLANG3 = 0x92
  case kbdLANG4 = 0x93
  case kbdLANG5 = 0x94
  case kbdLANG6 = 0x95
  case kbdLANG7 = 0x96
  case kbdLANG8 = 0x97
  case kbdLANG9 = 0x98
  
  case kbdAlternateErase = 0x99
  case kbdSysReqOrAttention = 0x9A
  case kbdCancel = 0x9B
  case kbdClear = 0x9C
  case kbdPrior = 0x9D
  case kbdReturn = 0x9E // you probably want kbdReturnOrEnter
  case kbdSeparator = 0x9F
  
  case kbdOut = 0xA0
  case kbdOper = 0xA1
  case kbdClearOrAgain = 0xA2
  case kbdCrSelOrProps = 0xA3
  case kbdExSel = 0xA4
  
  // leaving out a whole lot
  
  case kbdLeftControl = 0xE0
  case kbdLeftShift = 0xE1
  case kbdLeftAlt = 0xE2
  case kbdLeftGUI = 0xE3
  case kbdRightControl = 0xE4
  case kbdRightShift = 0xE5
  case kbdRightAlt = 0xE6
  case kbdRightGUI = 0xE7

  fileprivate static let name2Value = Dictionary(uniqueKeysWithValues: allCases.map { (String(describing: $0), $0) })
}

extension NamedKeyCode8 {
  public init?(name: String) {
    if let v = Self.name2Value[name] {
      self = v
    } else {
      return nil
    }
  }
}

public enum KeyCode8: Sendable, CustomStringConvertible {
  case named(NamedKeyCode8)
  case raw(UInt8)

  public init(rawValue: UInt8) {
    if let v = NamedKeyCode8(rawValue: rawValue) {
      self = .named(v)
    } else {
      self = .raw(rawValue)
    }
  }

  var rawValue: UInt8 {
    switch self {
    case .named(let v):
      return v.rawValue
    case .raw(let v):
      return v
    }
  }

  public var description: String {
    switch self {
    case .named(let n):
      return String(format: "0x%02x[.\(n)]", self.rawValue)
    case .raw(let r):
      return String(format: "0x%02x", r)
    }
  }
}

extension KeyCode8 {
  public init?(_ text: String) {
    if let named = NamedKeyCode8(name: text) { // enum string
      self = .named(named)
    } else if let match = text.wholeMatch(of: hexNumRegex), let num = UInt8(match.output.1, radix: 16) { // hex num
      self = .raw(num)
    } else if let num = UInt8(text) { // num
      self = .raw(num)
    }
    return nil
  }
}


/// Key-codes as used by the Realforce keyboard controller.
/**
 * These are only the codes not present in ``NamedKeyCode8``, mainly from the consumer page, and the "internal" functions.
 *
 * Also see IOHIDUsageTables.h
 */
public enum NamedKeyCode: UInt16, CaseIterable, Sendable {
  // match USB HID Keyboard Page 0x07 but page is 0x00

  // multimedia keys
  case csmrDisplayBrightnessIncrement = 0xC06F
  case csmrDisplayBrightnessDecrement = 0xC070
  case csmrScanNextTrack = 0xC0B5
  case csmrScanPrevTrack = 0xC0B6
  case csmrStop = 0xC0B7
  case csmrEject = 0xC0B8
  case csmrPlayOrPause = 0xC0CD
  case csmrVolumeIncrement = 0xC0E9
  case csmrVolumeDecrement = 0xC0EA
  // app keys
  case csmrALPlayer = 0xC183
  case csmrALMail = 0xC18A
  case csmrALCalculator = 0xC192
  case csmrALLocalMachineBrowser = 0xC194
  // browser keys
  case csmrACSearch = 0xC221
  case csmrACHome = 0xC223
  case csmrACBack = 0xC224
  case csmrACForward = 0xC225
  case csmrACRefresh = 0xC227
  case csmrACBookmarks = 0xC22A

  // special internal functions of the keyboard
  case xkbdFn = 0x1000

  case xSave = 0x1001

  case xSwitchLayout = 0x1013

  case xAPCPlus = 0x1020
  case xAPCMinus = 0x1021
  case xAPCCustom1 = 0x1023
  case xAPCCustom2 = 0x1024

  case xStrokeClear = 0x1050 // clear heatmap

  case xIlluminationBrightPlus = 0x1060
  case xIlluminationBrightMinus = 0x1061
  case xIlluminationModePlus = 0x1063
  case xIlluminationModeMinus = 0x1064
  case xIlluminationEasyColor = 0x1066
  case xIlluminationPowerOnEffectPlus = 0x1068
  case xIlluminationPowerOnEffectMinus = 0x1069

  case xMacroM1 = 0x10C0
  case xMacroM2 = 0x10C1
  case xMacroM3 = 0x10C2
  case xMacroM4 = 0x10C3
  case xMacroM5 = 0x10C4
  case xMacroM6 = 0x10C5
  case xMacroM7 = 0x10C6

  case xEasyMacroRecord = 0x10D0
  case xEasyMacroPlay = 0x10D1

  case xShortcut1 = 0x10E0
  case xShortcut2 = 0x10E1
  case xShortcut3 = 0x10E2
  case xShortcut4 = 0x10E3
  case xShortcut5 = 0x10E4
  case xShortcut6 = 0x10E5
  case xShortcut7 = 0x10E6
  case xShortcut8 = 0x10E7

  fileprivate static let name2Value = Dictionary(uniqueKeysWithValues: allCases.map { (String(describing: $0), $0) })
}

extension NamedKeyCode {
  public init?(name: String) {
    if let v = Self.name2Value[name] {
      self = v
    } else {
      return nil
    }
  }
}

public enum KeyCode: Sendable, CustomStringConvertible {
  case basic(KeyCode8)
  case extended(NamedKeyCode)
  case raw(UInt16)

  public init(rawValue: UInt16) {
    if rawValue <= UInt8.max {
      self = .basic(KeyCode8(rawValue: UInt8(rawValue)))
    } else if let v = NamedKeyCode(rawValue: rawValue) {
      self = .extended(v)
    } else {
      self = .raw(rawValue)
    }
  }

  public var rawValue: UInt16 {
    switch self {
    case .basic(let v):
      return UInt16(v.rawValue)
    case .extended(let v):
      return v.rawValue
    case .raw(let v):
      return v
    }
  }

  public var description: String {
    switch self {
    case .basic(let v):
      switch v {
      case .named(let n):
        return String(format: "0x%04x[.\(n)]", self.rawValue)
      case .raw(let r):
        return String(format: "0x%04x", r)
      }
    case .extended(let e):
      return String(format: "0x%04x[.\(e)]", self.rawValue)
    case .raw(let r):
      return String(format: "0x%04x", r)
    }
  }
}

extension KeyCode {
  public init?(_ text: String) {
    // first try all enums
    if let named = NamedKeyCode8.name2Value[text] {
      self = .basic(.named(named))
    } else if let named = NamedKeyCode.name2Value[text] {
      self = .extended(named)
    } else { // try as raw
      if let match = text.wholeMatch(of: hexNumRegex) { // hex
        if let u8 = UInt8(match.output.1) {
          self = .basic(.raw(u8))
        } else if let u16 = UInt16(match.output.1) {
          assert(u16 > 0xFF) // otherwise it should be .basic
          self = .raw(u16)
        } else {
          return nil
        }
      } else if let u8 = UInt8(text) {
        self = .basic(.raw(u8))
      } else if let u16 = UInt16(text) {
        assert(u16 > 0xFF) // otherwise it should be .basic
        self = .raw(u16)
      } else {
        return nil
      }
    }
  }
}
