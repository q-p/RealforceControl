//
//  main.swift
//  USBHIDTest
//
//  Created by Daniel Vollmer on 03.05.25.
//

import CoreHID
import RealforceControl

/*
 * Commands:
 * - list devices
 * - set / get
 * Shared Options:
 * - USB Vendor & Product ID, maybe HIDUsage?
 * Shared nouns for get and set:
 * - name
 * - APCMode, KillSwitch, KeyAPCMode
 * - KeyMap, KeyAction, Shortcut
 * - Brightness, LED, PowerOnEffect, Backlight
 */

let usbVendorIDTopre : UInt32 = 0x853;
let usbProductIDRealforceGX1 : UInt32 = 0x317;
let usbVendorUsage = HIDUsage(page: 0xff00, usage: 1)

let searchCriteria = HIDDeviceManager.DeviceMatchingCriteria(primaryUsage: usbVendorUsage, vendorID: usbVendorIDTopre)

let deviceReferences = try await EnumerateHIDDevices(searchCriteria: searchCriteria)

guard deviceReferences.count <= 1 else {
  fatalError("Multiple devices matching \(searchCriteria) found. Please narrow the search.")
}
guard let deviceReference = deviceReferences.first else {
  fatalError("No devices matching \(searchCriteria) found.")
}

let kbd = try! await Keyboard(deviceRef: deviceReference)

print(try await kbd.getInfo())
print(try await kbd.getName())

// try await kbd.hello()

// try await kbd.goodbye() // FIXME: no writing for now
