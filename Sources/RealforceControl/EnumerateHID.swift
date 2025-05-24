//
//  EnumerateHID.swift
//  RealforceControl
//
//  Created by Daniel Vollmer on 08.05.25.
//


import CoreHID
import os

fileprivate actor EnumerationActor {
  private let logger = Logger(subsystem: "de.maven.RealforceControl", category: "EnumerateHID")
  private var deviceEnumerationTask: Task<[HIDDeviceClient.DeviceReference], Error>?
  private var watchDogTask: Task<Void, Error>?
  
  /// Starts the internal watchdog for killing the deviceEnumerationTask.
  private func startWatchdog(timeoutNanoseconds: UInt64) {
    precondition(watchDogTask == nil, "trying to start multiple watchdogs")
    precondition(deviceEnumerationTask != nil, "no enumeration task")
    logger.debug("starting watchdog timout=\(timeoutNanoseconds)")
    watchDogTask = Task {
      try await Task.sleep(nanoseconds: timeoutNanoseconds)
      if !Task.isCancelled {
        deviceEnumerationTask!.cancel()
      }
      watchDogTask = nil
    }
  }
  
  /// Stops the internal watchdog for killing the deviceEnumerationTask.
  private func stopWatchdog() {
    precondition(watchDogTask != nil, "trying to stop non-existent watchdog")
    watchDogTask!.cancel()
    watchDogTask = nil
    logger.debug("stopped watchdog")
  }
  
  /// Returns the devices matching the query.
  func getDevices(searchCriteria:HIDDeviceManager.DeviceMatchingCriteria) async throws -> [HIDDeviceClient.DeviceReference] {
    defer {
      deviceEnumerationTask = nil
    }
    deviceEnumerationTask = Task {
      let manager = HIDDeviceManager()
      // we create the stream up front so make the watchdog only include actual wait time
      let deviceEnumerationStream = await manager.monitorNotifications(matchingCriteria: [searchCriteria])
      
      var matchedDevices: [HIDDeviceClient.DeviceReference] = []
      var deviceToIndex: [HIDDeviceClient.DeviceReference: Int] = [:]
      
      startWatchdog(timeoutNanoseconds: 20_000_000)
      for try await deviceNotification in deviceEnumerationStream {
        stopWatchdog()
        
        switch deviceNotification {
        case .deviceMatched(let deviceReference):
          if let _ = deviceToIndex[deviceReference] {
            logger.info("duplicate device?")
          } else {
            deviceToIndex[deviceReference] = matchedDevices.count
            matchedDevices.append(deviceReference)
          }
        case .deviceRemoved(let deviceReference):
          if let mapIndex = deviceToIndex.index(forKey: deviceReference) {
            matchedDevices.remove(at: deviceToIndex.remove(at: mapIndex).value)
          } else {
            // device removed we don't have
            break
          }
        @unknown default:
          break
        }
        
        startWatchdog(timeoutNanoseconds: 10_000_000)
      } // for deviceNotification
      return matchedDevices
    } // deviceEnumerationTask
    return try await deviceEnumerationTask!.value
  }
}

/// Enumerates all HID devices matching the given critera.
public func EnumerateHIDDevices(searchCriteria:HIDDeviceManager.DeviceMatchingCriteria) async throws -> [HIDDeviceClient.DeviceReference] {
  return try await EnumerationActor().getDevices(searchCriteria: searchCriteria)
}
