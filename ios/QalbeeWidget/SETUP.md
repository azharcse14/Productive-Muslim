# Qalbee iOS home-screen widget — Xcode setup

The widget's **source is complete** (this folder + `Runner/AppDelegate.swift` +
`Runner/Runner.entitlements`). What can't be scripted safely is wiring a new
**Widget Extension target** into `Runner.xcodeproj` — that edits
`project.pbxproj` and must be done in Xcode. One-time, ~10 minutes.

Approach: **native WidgetKit, no plugin** (keeps the project Swift Package
Manager–only, per the toolchain policy — no CocoaPods). Data flows
Flutter → `MethodChannel("com.qalbee.qalbee/widget")` → App Group
`UserDefaults` → WidgetKit timeline.

## Steps

1. **Open** `ios/Runner.xcworkspace` in Xcode.

2. **Add the target:** File → New → Target… → **Widget Extension**.
   - Product Name: **QalbeeWidget**
   - Uncheck "Include Configuration Intent".
   - Finish. When asked to activate the scheme, **Activate**.
   - Xcode generates a `QalbeeWidget/` group with template files.

3. **Replace the generated sources with the files already in this folder:**
   - Delete Xcode's auto-generated `QalbeeWidget.swift` (and any
     `*Bundle.swift` / `Assets` it made that you don't need), then
     **Add Files to "Runner"…** and select this folder's
     `QalbeeWidget.swift`, adding it to the **QalbeeWidget** target only.
   - Point the extension's **Info.plist** at this folder's `Info.plist`
     (or copy its `NSExtension` dict into the generated one), and set the
     extension's **Code Signing Entitlements** build setting to
     `QalbeeWidget/QalbeeWidget.entitlements`.

4. **App Group capability** (both targets share it):
   - Select the **Runner** target → Signing & Capabilities → **+ Capability**
     → **App Groups** → add `group.com.qalbee.qalbee`.
     Confirm its "Code Signing Entitlements" points to
     `Runner/Runner.entitlements` (already committed with the group).
   - Select the **QalbeeWidget** target → same App Group
     `group.com.qalbee.qalbee` (entitlements file is in this folder).

5. **Deployment target:** set QalbeeWidget's iOS Deployment Target to match
   Runner (or ≥ 14.0; the code degrades gracefully and uses
   `containerBackground` on iOS 17+).

6. **Build & run** the Runner scheme on a device/simulator, then long-press
   the home screen → **+** → search **Qalbee** → add the medium widget.

## Verify the data path

- Before location setup the widget shows "Open the app to set your location".
- After choosing a location it shows the next prayer + time + a 5-waqt strip,
  and updates when you change location, calculation params, or language
  (the app calls `PrayerWidgetService.update()` on those changes and on open).

## Where things live

| Piece | File |
|---|---|
| Flutter → native bridge | `lib/features/home_widget/data/widget_bridge.dart` |
| Snapshot builder (pure) | `lib/features/home_widget/domain/widget_payload.dart`, `next_prayer.dart` |
| Snapshot service | `lib/features/home_widget/data/prayer_widget_service.dart` |
| iOS channel + App Group write | `ios/Runner/AppDelegate.swift` |
| iOS widget UI + timeline | `ios/QalbeeWidget/QalbeeWidget.swift` |
| Android equivalent | `android/.../QalbeeWidgetProvider.kt`, `MainActivity.kt` |

The channel name, App Group id, and `widget_*` keys must stay in sync across
`widget_payload.dart`, `AppDelegate.swift`, and `QalbeeWidget.swift`.
