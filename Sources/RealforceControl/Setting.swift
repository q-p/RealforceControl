//
//  Setting.swift
//  RealforceControl
//
//  Created by Daniel Vollmer on 04.05.25.
//


// not sure whether they are valid, but the app reads only these on start-up
let validPages = [UInt8](0...0x31) + [0x35] + [UInt8](0x37...0x87) + [0xBE, 0xBF]

enum NamedSetting : UInt8, CaseIterable, Sendable {
  case modelInfoA = 0x00
  case modelInfoB = 0x01
  // 0x02 model info with some date string? 00M4 07 25 0486?
  // 0x03 empty-ish (single space), same as 0x04
  case customAPC_Flags = 0x04 // e.g. continue dynamic mode even if under activation point
  case customAPC_ActuationPointDistance = 0x05
  case customAPC_Dynamic_RelativeDistance = 0x06
  
  case macroEnabled = 0x07 // 01 => enabled, 00 => disabled
  case macro1Name = 0x08
  // events seem to be 2 bytes each: [flags] [hid key], OR [flags] [delay], flags = 0x20 => release; [A0 0F] = wait 15ms
  case macro1Events0 = 0x09
  case macro1Events1 = 0x0A
  case macro1Events2 = 0x0B
  case macro2Name = 0x0C
  case macro2Events0 = 0x0D
  case macro2Events1 = 0x0E
  case macro2Events2 = 0x0F
  case macro3Name = 0x10
  case macro3Events0 = 0x11
  case macro3Events1 = 0x12
  case macro3Events2 = 0x13
  case macro4Name = 0x14
  case macro4Events0 = 0x15
  case macro4Events1 = 0x16
  case macro4Events2 = 0x17
  case macro5Name = 0x18
  case macro5Events0 = 0x19
  case macro5Events1 = 0x1A
  case macro5Events2 = 0x1B
  case macro6Name = 0x1C
  case macro6Events0 = 0x1D
  case macro6Events1 = 0x1E
  case macro6Events2 = 0x1F
  case macro7Name = 0x20
  case macro7Events0 = 0x21
  case macro7Events1 = 0x22
  case macro7Events2 = 0x23
  case macro8Name = 0x24
  case macro8Events0 = 0x25
  case macro8Events1 = 0x26
  case macro8Events2 = 0x27
  
  case keyboardName = 0x28
  // 0x29-0x2C same name? or maybe default
  
  // 8x2 bytes per shortcut [modifier flags] [HID Keycode (1 byte)]
  // Modifier Flags = LCtrl = 0x01, LShift => 0x02, LWin = 0x04, LAlt => 0x08,
  //                  RCtrl = 0x10, RShift => 0x20, RWin = 0x40, RAlt => 0x80
  case shortcuts = 0x2D
  
  // 16 bytes, one bit per key (lower bit = lower idx); bit set = fixed, unset = dynamic; we probably have this for Custom2 as well somewhere?
  case perKeyFixedAPCEnabledCustom1 = 0x2E
  case perKeyFixedAPCEnabledCustom2 = 0x2F // this is only a guess, not tried this

  // response
  // [APCMode]
  // Custom1 [IsKillSwitchEnabled] [byte HIDKeyCode Key1] [byte HIDKeyCode Key2] [KillSwitchMode] [byte HIDKeyCode Key3] [byte HIDKeyCode Key4] [KillSwitchMode]
  // Custom2 [IsKillSwitchEnabled] [byte HIDKeyCode Key1] [byte HIDKeyCode Key2] [KillSwitchMode] [byte HIDKeyCode Key3] [byte HIDKeyCode Key4] [KillSwitchMode]
  // 00 32 32 32
  case apc = 0x30
  
  case keymapSelect = 0x31 // 00 => Map A, 01 => Map B
  
  // 0x35 empty
  // 0x37 ???
  
  // 32 APCMode flags per page (KeyAPCMode)
  case perKey_Custom1_APCFlags0 = 0x38
  case perKey_Custom1_APCFlags1 = 0x39
  case perKey_Custom1_APCFlags2 = 0x3A
  case perKey_Custom1_APCFlags3 = 0x3B
  case perKey_Custom2_APCFlags0 = 0x3C
  case perKey_Custom2_APCFlags1 = 0x3D
  case perKey_Custom2_APCFlags2 = 0x3E
  case perKey_Custom2_APCFlags3 = 0x3F
  // 16x(2 byte) KeyCode per page
  case perKey_MapA_Normal0 = 0x40
  case perKey_MapA_Normal1 = 0x41
  case perKey_MapA_Normal2 = 0x42
  case perKey_MapA_Normal3 = 0x43
  case perKey_MapA_Normal4 = 0x44
  case perKey_MapA_Normal5 = 0x45
  case perKey_MapA_Normal6 = 0x46
  case perKey_MapA_Normal7 = 0x47
  case perKey_MapA_Fn0 = 0x48
  case perKey_MapA_Fn1 = 0x49
  case perKey_MapA_Fn2 = 0x4A
  case perKey_MapA_Fn3 = 0x4B
  case perKey_MapA_Fn4 = 0x4C
  case perKey_MapA_Fn5 = 0x4D
  case perKey_MapA_Fn6 = 0x4E
  case perKey_MapA_Fn7 = 0x4F
  case perKey_MapB_Normal0 = 0x50
  case perKey_MapB_Normal1 = 0x51
  case perKey_MapB_Normal2 = 0x52
  case perKey_MapB_Normal3 = 0x53
  case perKey_MapB_Normal4 = 0x54
  case perKey_MapB_Normal5 = 0x55
  case perKey_MapB_Normal6 = 0x56
  case perKey_MapB_Normal7 = 0x57
  case perKey_MapB_Fn0 = 0x58
  case perKey_MapB_Fn1 = 0x59
  case perKey_MapB_Fn2 = 0x5A
  case perKey_MapB_Fn3 = 0x5B
  case perKey_MapB_Fn4 = 0x5C
  case perKey_MapB_Fn5 = 0x5D
  case perKey_MapB_Fn6 = 0x5E
  case perKey_MapB_Fn7 = 0x5F
  
  // [Brightness 0-3] [Caps Lock Key On/Off] [R] [G] [B] [Scroll Lock Key On/Off] [R] [G] [B] [Num Lock Key On/Off] [R] [G] [B] [Power On Effect]
  case illumination1 = 0x60
  // [BacklightMode] [BacklightMode Idle Effect] [Idle Timer min]
  case illumination2 = 0x61
  
  // pages 62-71 for custom background effect?
  // 0x72-0x75 empty
  // 0x76 Effect1 name + stuff, 0x77 colors?
  // 0x78 Effect2 name + stuff, 0x79 colors?
  // 0x7A Effect3 name + stuff, 0x7B colors?
  // 0x7C Effect4 name + stuff, 0x7D colors?
  // 0x7E Effect5 name + stuff, 0x7F colors?
  // 0x80 Effect6 name + stuff, 0x81 colors?
  // 0x82 Action1 name + stuff
  // 0x83 Action2 name + stuff
  // 0x84 Action3 name + stuff
  // 0x85 Action4 name + stuff
  // 0x86 Action5 name + stuff
  // 0x87 Action6 name + stuff
  
  // 0xBE empty
  // 0xBF some data
  
  fileprivate static let name2Value = Dictionary(uniqueKeysWithValues: allCases.map { (String(describing: $0), $0) })
}

extension NamedSetting {
  public init?(name: String) {
    if let v = Self.name2Value[name] {
      self = v
    } else {
      return nil
    }
  }
}

enum Setting: Sendable, Comparable, Hashable, CustomStringConvertible {
  case named(NamedSetting)
  case raw(UInt8)

  public init(rawValue: UInt8) {
    if let s = NamedSetting(rawValue: rawValue) {
      self = .named(s)
    } else {
      self = .raw(rawValue)
    }
  }

  var rawValue: UInt8 {
    switch self {
    case .named(let s):
      return s.rawValue
    case .raw(let s):
      return s
    }
  }

  public static func < (lhs: Setting, rhs: Setting) -> Bool {
    lhs.rawValue < rhs.rawValue
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

extension Setting {
  public init?(_ text: String) {
    if let named = NamedSetting(name: text) { // enum string
      self = .named(named)
    } else if let match = text.wholeMatch(of: hexNumRegex), let num = UInt8(match.output.1) { // hex num
      self = .raw(num)
    } else if let num = UInt8(text) { // num
      self = .raw(num)
    }
    return nil
  }
}
