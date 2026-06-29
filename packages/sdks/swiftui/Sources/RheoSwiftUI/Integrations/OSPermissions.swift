import AVFoundation
import Contacts
import EventKit
import Foundation
import Photos
import UserNotifications

public enum OSPermissionRequester {
  public static func request(_ key: OSPermissionKey) async -> PermissionOutcome {
    switch key {
    case "notifications":
      return await requestNotifications()
    case "camera":
      return await requestAV(.video)
    case "microphone":
      return await requestAV(.audio)
    case "photo_library":
      return await requestPhotoLibrary()
    case "contacts":
      return await requestContacts()
    case "calendar":
      return await requestCalendar()
    default:
      return .denied
    }
  }

  private static func requestNotifications() async -> PermissionOutcome {
    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()
    if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
      return .granted
    }
    if settings.authorizationStatus == .denied {
      return .blocked
    }
    do {
      let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
      return granted ? .granted : .denied
    } catch {
      return .denied
    }
  }

  private static func requestAV(_ mediaType: AVMediaType) async -> PermissionOutcome {
    let status = AVCaptureDevice.authorizationStatus(for: mediaType)
    if status == .authorized { return .granted }
    if status == .denied || status == .restricted { return .blocked }
    let granted = await AVCaptureDevice.requestAccess(for: mediaType)
    return granted ? .granted : .denied
  }

  private static func requestPhotoLibrary() async -> PermissionOutcome {
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    if status == .authorized || status == .limited { return .granted }
    if status == .denied || status == .restricted { return .blocked }
    let next = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    return (next == .authorized || next == .limited) ? .granted : .denied
  }

  private static func requestContacts() async -> PermissionOutcome {
    let status = CNContactStore.authorizationStatus(for: .contacts)
    if status == .authorized { return .granted }
    if status == .denied || status == .restricted { return .blocked }
    do {
      let granted = try await CNContactStore().requestAccess(for: .contacts)
      return granted ? .granted : .denied
    } catch {
      return .denied
    }
  }

  private static func requestCalendar() async -> PermissionOutcome {
    let store = EKEventStore()
    let status = EKEventStore.authorizationStatus(for: .event)
    if #available(iOS 17.0, *), status == .fullAccess { return .granted }
    if status == .authorized { return .granted }
    if status == .denied || status == .restricted { return .blocked }
    if #available(iOS 17.0, *) {
      do {
        let granted = try await store.requestFullAccessToEvents()
        return granted ? .granted : .denied
      } catch {
        return .denied
      }
    }
    do {
      let granted = try await store.requestAccess(to: .event)
      return granted ? .granted : .denied
    } catch {
      return .denied
    }
  }
}
