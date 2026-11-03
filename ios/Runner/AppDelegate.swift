import CoreMotion
import Flutter
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Shared App Group between the app and the WidgetKit extension. Must
  /// match `ProductiveMuslimWidget`'s suite and both .entitlements files.
  private let appGroup = "group.com.productivemuslim.app"
  private let channelName = "com.productivemuslim.app/widget"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    excludeBundledDataFromBackup()
    LockKeychain.clearAfterReinstall()
    // flutter_local_notifications: show alerts in the foreground and route
    // taps/actions to Dart.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Re-creatable bundled databases (hadith.db) live in
  /// `Application Support/bundled/` (Dart: `bundledDbFile`). Flagging the
  /// directory keeps it and everything in it out of iCloud/iTunes backups.
  /// Runs before the engine starts, so the flag exists before Dart copies.
  private func excludeBundledDataFromBackup() {
    guard var dir = FileManager.default
      .urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
      .appendingPathComponent("bundled", isDirectory: true) else { return }
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? dir.setResourceValues(values)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Registered here, not in didFinishLaunching: under the scene lifecycle
    // `window` is nil there, so the channel never existed.
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ProductiveMuslimWidget") else { return }
    FlutterEventChannel(
      name: "com.productivemuslim.app/magnetic",
      binaryMessenger: registrar.messenger()
    ).setStreamHandler(CalibratedMagnetometer())
    FlutterMethodChannel(
      name: "com.productivemuslim.app/keychain",
      binaryMessenger: registrar.messenger()
    ).setMethodCallHandler(LockKeychain.handle)
    // App lock's PIN cooldown clock. Darwin's CLOCK_MONOTONIC counts sleep
    // (systemUptime does not) and ignores wall-clock changes.
    FlutterMethodChannel(
      name: "com.productivemuslim.app/boot_clock",
      binaryMessenger: registrar.messenger()
    ).setMethodCallHandler { call, result in
      if call.method == "sinceBootMs" {
        result(Int(clock_gettime_nsec_np(CLOCK_MONOTONIC) / 1_000_000))
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    // Quran reader / tasbih open → no auto-lock. Handlers run on the main
    // thread, as UIApplication requires.
    FlutterMethodChannel(
      name: "com.productivemuslim.app/screen",
      binaryMessenger: registrar.messenger()
    ).setMethodCallHandler { call, result in
      if call.method == "keepOn" {
        UIApplication.shared.isIdleTimerDisabled = (call.arguments as? Bool) ?? false
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    // Per-ayah share → the system activity sheet, plain text.
    FlutterMethodChannel(
      name: "com.productivemuslim.app/share",
      binaryMessenger: registrar.messenger()
    ).setMethodCallHandler { call, result in
      guard call.method == "shareText", let text = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      let scene = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first { $0.activationState == .foregroundActive }
      guard var top = scene?.keyWindow?.rootViewController else {
        result(FlutterError(code: "NO_UI", message: "No window to present from", details: nil))
        return
      }
      while let presented = top.presentedViewController { top = presented }
      let sheet = UIActivityViewController(activityItems: [text], applicationActivities: nil)
      // iPad shows it as a popover, which needs an anchor.
      if let popover = sheet.popoverPresentationController {
        popover.sourceView = top.view
        popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
        popover.permittedArrowDirections = []
      }
      top.present(sheet, animated: true)
      result(nil)
    }
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      if call.method == "updateWidget" {
        // Store the Dart-formatted snapshot in the shared App Group, then
        // ask WidgetKit to repaint. Best-effort, never fails the app.
        if let args = call.arguments as? [String: Any],
           let defaults = UserDefaults(suiteName: self.appGroup) {
          for (key, value) in args {
            defaults.set("\(value)", forKey: key)
          }
        }
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
        }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

/// App-lock record (PIN hash, throttle) for Dart's `KeychainPrefs`. The
/// Keychain, ThisDeviceOnly, never reaches iCloud/Finder backups as
/// UserDefaults does. AfterFirstUnlock, not WhenUnlocked: a launch while
/// the screen is locked must still read the lock, not find it "unset".
enum LockKeychain {
  private static let service = "com.productivemuslim.app.lock"
  private static let ownedKey = "lock_keychain_owned"

  /// Keychain items outlive an uninstall, UserDefaults don't: a fresh
  /// install must not come up locked behind a forgotten PIN.
  static func clearAfterReinstall() {
    guard !UserDefaults.standard.bool(forKey: ownedKey) else { return }
    SecItemDelete([
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
    ] as CFDictionary)
    UserDefaults.standard.set(true, forKey: ownedKey)
  }

  static func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let key = args["key"] as? String else {
      result(FlutterError(code: "ARGS", message: "missing key", details: nil))
      return
    }
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
    ]
    var status: OSStatus
    switch call.method {
    case "get":
      var item: CFTypeRef?
      var get = query
      get[kSecReturnData as String] = true
      get[kSecMatchLimit as String] = kSecMatchLimitOne
      status = SecItemCopyMatching(get as CFDictionary, &item)
      if status == errSecSuccess, let data = item as? Data {
        result(String(data: data, encoding: .utf8))
        return
      }
    case "set":
      let data = Data((args["value"] as? String ?? "").utf8)
      status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
      if status == errSecItemNotFound {
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        status = SecItemAdd(add as CFDictionary, nil)
      }
    case "remove":
      status = SecItemDelete(query as CFDictionary)
    default:
      result(FlutterMethodNotImplemented)
      return
    }
    // Not found is "no value" for get/remove; any other failure surfaces in
    // Dart rather than reading as an unset (unlocked) lock.
    if status == errSecSuccess || (status == errSecItemNotFound && call.method != "set") {
      result(nil)
    } else {
      result(FlutterError(code: "KEYCHAIN", message: "OSStatus \(status)", details: nil))
    }
  }
}

/// Qibla: the magnetic field with the iPhone's own hardware bias removed
/// (CMDeviceMotion.magneticField). sensors_plus only offers the raw
/// magnetometer, which on iOS includes that bias and skews the heading.
/// Same device frame and units (µT) as the raw stream.
final class CalibratedMagnetometer: NSObject, FlutterStreamHandler {
  private let manager = CMMotionManager()

  func onListen(withArguments arguments: Any?, eventSink sink: @escaping FlutterEventSink) -> FlutterError? {
    guard manager.isDeviceMotionAvailable else {
      return FlutterError(code: "UNAVAILABLE", message: "No device motion", details: nil)
    }
    manager.deviceMotionUpdateInterval = 1.0 / 60
    manager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: .main) { motion, _ in
      guard let field = motion?.magneticField.field else { return }
      sink([field.x, field.y, field.z])
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    manager.stopDeviceMotionUpdates()
    return nil
  }
}
