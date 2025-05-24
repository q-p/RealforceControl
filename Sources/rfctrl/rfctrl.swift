//
//  rfctrl.swift
//  USBHIDTest
//
//  Created by Daniel Vollmer on 03.05.25.
//


import CoreHID
import RealforceControl
import ArgumentParser

@main
struct rfctrl: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "A utility for configuring Topre Realforce USB keyboards (GX1).",
    version: "0.0.1",
    subcommands: [List.self, Info.self],
    defaultSubcommand: List.self,
  )

  @OptionGroup var options: Options
}

protocol HexOrDec {}

struct PreferHex: HexOrDec {}
struct PreferDec: HexOrDec {}

struct HexIntArg<Value: FixedWidthInteger & CVarArg, PrintAs: HexOrDec>: ExpressibleByArgument, CustomStringConvertible {
  let value: Value

  init(_ value: Value) {
    self.value = value
  }

  init?(argument: String) {
    if let match = argument.wholeMatch(of: hexNumRegex), let value = Value(match.output.1, radix: 16) {
      self.value = value
    } else if let value = Value(argument) {
      self.value = value
    } else {
      return nil
    }
  }

  var description: String {
    if PrintAs.self == PreferDec.self {
      return String(value)
    } else {
      return String(format: "0x%x", value)
    }
  }
}

typealias HexUInt32Arg = HexIntArg<UInt32, PreferHex>
typealias HexUInt16ArgDec = HexIntArg<UInt16, PreferDec>
typealias HexUInt64Arg = HexIntArg<UInt64, PreferHex>

struct Options: ParsableArguments {
  static let usbVendorIDTopre : UInt32 = 0x853;
  static let usbProductIDRealforceGX1 : UInt32 = 0x317;
  static let usbVendorUsage = HIDUsage(page: 0xff00, usage: 1)

  @Option(help: "USB VendorID of the keyboard")
  var vendorID = HexUInt32Arg(usbVendorIDTopre)
  @Option(help: "USB ProductID of the keyboard")
  var productID = HexUInt32Arg(usbProductIDRealforceGX1)
  @Option(help: "USB LocationID of the keyboard")
  var locationID: HexUInt64Arg?
  @Option(help: "HID UsagePage of the keyboard")
  var usagePage = HexUInt16ArgDec(usbVendorUsage.page)
  @Option(help: "HID Usage of the keyboard")
  var usage = HexUInt16ArgDec(usbVendorUsage.usage!)
  @Option(help: "USB RegistryID of the keyboard")
  var registryID: HexUInt64Arg?

  func getDeviceRefs() async throws -> [HIDDeviceClient.DeviceReference] {
    let vendorID: UInt32? = vendorID.value != 0 ? vendorID.value : nil
    let productID: UInt32? = productID.value != 0 ? productID.value : nil
    let usage: UInt16? = usage.value != 0 ? usage.value : nil
    let usagePage: UInt16? = usagePage.value != 0 ? usagePage.value : nil
    let hidUsage: HIDUsage? = usagePage != nil ? HIDUsage(page: usagePage!, usage: usage) : nil
    let locationID: UInt64? = locationID?.value ?? nil
    let searchCriteria = HIDDeviceManager.DeviceMatchingCriteria(primaryUsage: hidUsage, vendorID: vendorID, productID: productID, locationID: locationID)
    var deviceRefs = try await EnumerateHIDDevices(searchCriteria: searchCriteria)
    // remove mismatches if we have a registry / device ID (we still need to enumerate, as we cannot create a DeviceRef directly)
    if let registryID = registryID {
      deviceRefs.removeAll(where: { $0.deviceID != registryID.value })
    }
    return deviceRefs
  }
}


func getDeviceHeaders() -> [String] {
  return ["VendorID", "ProductID", "LocationID", "UsagePage", "Usage", "RegistryID", "Manufacturer", "Product"]
}

func queryDevice(client: HIDDeviceClient) async -> [String] {
  let null = "(null)"
  async let vendorID = client.vendorID
  async let productID = client.productID
  async let locationID = client.locationID
  async let usage = client.primaryUsage
  async let manufacturer = client.manufacturer
  async let product = client.product

  return await [
    String(format: "0x%x", vendorID),
    String(format: "0x%x", productID),
    locationID != nil ? String(format: "0x%llx", locationID!) : null,
    String(usage.page),
    usage.usage != nil ? String(usage.usage!) : null,
    String(format: "0x%llx", client.deviceReference.deviceID),
    manufacturer ?? null,
    product ?? null
  ]
}


func printPadded(rows: [[String]]) {
  guard !rows.isEmpty else { return }

  let columnsLengths = rows.reduce(into: Array(repeating: 0, count: rows.first!.count)) { partialResult, columns in
    for i in 0..<partialResult.count {
      partialResult[i] = max(partialResult[i], columns[i].count)
    }
  }
  for row in rows {
    var str: String = ""
    for (j, col) in row.enumerated() {
      str.append(col.padding(toLength: columnsLengths[j] + 1, withPad: " ", startingAt: 0))
    }
    print(str)
  }
}


struct List: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "list all USB devices matching the given options",
  )

  @OptionGroup var options: Options

  mutating func run() async throws {
    let deviceRefs = try await options.getDeviceRefs()
    var results = [getDeviceHeaders()]

    for ref in deviceRefs {
      guard let client = HIDDeviceClient(deviceReference: ref) else {
        continue
      }
      results.append(await queryDevice(client: client))
    }
    printPadded(rows: results)
  }
}


struct Info: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "connect to all matching devices and query basic information (requires Realforce keyboard)",
  )

  @OptionGroup var options: Options

  mutating func run() async throws {
    let deviceRefs = try await options.getDeviceRefs()
    var results = [getDeviceHeaders() + ["Model", "Firmware", "Name"]]

    for ref in deviceRefs {
      let kbd = try await Keyboard(deviceRef: ref)
      let (model, firmware) = try await kbd.getInfo()
      let name = try await kbd.getName()
      results.append(await queryDevice(client: kbd.deviceClient) + [model, firmware, name])
    }
    printPadded(rows: results)
  }
}
