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
