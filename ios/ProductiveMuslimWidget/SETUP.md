# Productive Muslim iOS home-screen widget — Xcode setup

The widget's **source is complete** (this folder + `Runner/AppDelegate.swift` +
`Runner/Runner.entitlements`). What can't be scripted safely is wiring a new
**Widget Extension target** into `Runner.xcodeproj` — that edits
`project.pbxproj` and must be done in Xcode. One-time, ~10 minutes.

Approach: **native WidgetKit, no plugin** (keeps the project Swift Package
Manager–only, per the toolchain policy — no CocoaPods). Data flows
Flutter → `MethodChannel("com.productivemuslim.app/widget")` → App Group
`UserDefaults` → WidgetKit timeline.

## Steps

1. **Open** `ios/Runner.xcworkspace` in Xcode.

2. **Add the target:** File → New → Target… → **Widget Extension**.
   - Product Name: **ProductiveMuslimWidget**
   - Uncheck "Include Configuration Intent".
   - Finish. When asked to activate the scheme, **Activate**.
   - Xcode generates a `ProductiveMuslimWidget/` group with template files.

3. **Replace the generated sources with the files already in this folder:**
   - Delete Xcode's auto-generated `ProductiveMuslimWidget.swift` (and any
     `*Bundle.swift` / `Assets` it made that you don't need), then
     **Add Files to "Runner"…** and select this folder's
     `ProductiveMuslimWidget.swift` and `Localizable.xcstrings` (the String
     Catalog, en + bn), adding both to the **ProductiveMuslimWidget** target only.
   - Point the extension's **Info.plist** at this folder's `Info.plist`
     (or copy its `NSExtension` dict into the generated one), and set the
     extension's **Code Signing Entitlements** build setting to
     `ProductiveMuslimWidget/ProductiveMuslimWidget.entitlements`.

4. **App Group capability** (both targets share it):
   - Select the **Runner** target → Signing & Capabilities → **+ Capability**
     → **App Groups** → add `group.com.productivemuslim.app`.
     Confirm its "Code Signing Entitlements" points to
     `Runner/Runner.entitlements` (already committed with the group).
   - Select the **ProductiveMuslimWidget** target → same App Group
     `group.com.productivemuslim.app` (entitlements file is in this folder).

5. **Deployment target:** set ProductiveMuslimWidget's iOS Deployment Target to match
   Runner (or ≥ 14.0; the code degrades gracefully and uses
   `containerBackground` on iOS 17+).

6. **Build & run** the Runner scheme on a device/simulator, then long-press
   the home screen → **+** → search **Productive Muslim** → add the medium widget.

## Verify the data path

- Before location setup the widget shows "Open the app to set your location".
- After choosing a location it shows the next prayer + time + a 5-waqt strip,
  and updates when you change location, calculation params, or language
  (the app calls `PrayerWidgetService.update()` on those changes and on open).
- The app pushes 7 days of prayer starts and daily strips; the widget walks
  them on its own. Past the last pushed start it shows "Open the app" (no
  stale times) and stops reloading until the app pushes again. Test: device
  clock +8 days → the open-app state.

## Where things live

| Piece | File |
|---|---|
| Flutter → native bridge | `lib/features/home_widget/data/widget_bridge.dart` |
| Snapshot builder (pure) | `lib/features/home_widget/domain/widget_payload.dart`, `next_prayer.dart` |
| Snapshot service | `lib/features/home_widget/data/prayer_widget_service.dart` |
| iOS channel + App Group write | `ios/Runner/AppDelegate.swift` |
| iOS widget UI + timeline | `ios/ProductiveMuslimWidget/ProductiveMuslimWidget.swift` |
| Android equivalent | `android/.../ProductiveMuslimWidgetProvider.kt`, `MainActivity.kt` |

The channel name, App Group id, and `widget_*` keys must stay in sync across
`widget_payload.dart`, `AppDelegate.swift`, and `ProductiveMuslimWidget.swift`.
