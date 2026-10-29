import WidgetKit
import SwiftUI

// Brand teal #15564D and its soft tints, matching the Android widget.
private let qBackground = Color(red: 0.082, green: 0.337, blue: 0.302)
private let qSoft = Color(red: 0.655, green: 0.855, blue: 0.804)        // #A7DACD
private let qFaint = Color(red: 0.863, green: 0.914, blue: 0.894)       // #DCE9E4

/// App Group shared with the Flutter app (see AppDelegate + entitlements).
private let appGroup = "group.com.productivemuslim.app"

/// Mirrors `WidgetSchedule.kt` (the Kotlin side has the unit tests) — keep
/// the two in sync. Reads the `widget_*` strings pushed by the app.
enum WidgetSchedule {
  /// `widget_schedule`: `epochMillis<TAB>prayer<TAB>time` per prayer start.
  static func starts(_ d: UserDefaults?) -> [(at: Date, prayer: String, time: String)] {
    lines(d, "widget_schedule").compactMap { p in
      guard p.count >= 3, let ms = Double(p[0]) else { return nil }
      return (date(ms), p[1], p[2])
    }
  }

  /// `widget_strips`: `startMillis<TAB>endMillis<TAB>strip` per day. Before
  /// the first push after an upgrade: the legacy today/tomorrow strips.
  static func strips(_ d: UserDefaults?) -> [(start: Date, end: Date, text: String)] {
    let pushed: [(start: Date, end: Date, text: String)] =
      lines(d, "widget_strips").compactMap { p in
        guard p.count >= 3, let s = Double(p[0]), let e = Double(p[1]) else { return nil }
        return (date(s), date(e), p[2])
      }
    if !pushed.isEmpty { return pushed }
    let today = d?.string(forKey: "widget_times") ?? ""
    let tomorrow = d?.string(forKey: "widget_times_next") ?? ""
    guard let flip = Double(d?.string(forKey: "widget_day_flip") ?? ""), flip > 0,
          !tomorrow.isEmpty else {
      return [(.distantPast, .distantFuture, today)]
    }
    return [(.distantPast, date(flip), today), (date(flip), .distantFuture, tomorrow)]
  }

  private static func lines(_ d: UserDefaults?, _ key: String) -> [[String]] {
    (d?.string(forKey: key) ?? "").split(separator: "\n").map {
      $0.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
    }
  }

  private static func date(_ millis: Double) -> Date {
    Date(timeIntervalSince1970: millis / 1000)
  }
}

enum WidgetState {
  case setup(hint: String)
  case next(prayer: String, time: String, strip: String)
  /// Past the last pushed start: never show times that have passed.
  case stale(title: String, hint: String)
}

struct ProductiveMuslimEntry: TimelineEntry {
  let date: Date
  let label: String
  let location: String
  let state: WidgetState
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> ProductiveMuslimEntry {
    ProductiveMuslimEntry(date: Date(), label: "", location: "",
                          state: .setup(hint: ""))
  }

  func getSnapshot(in context: Context, completion: @escaping (ProductiveMuslimEntry) -> Void) {
    completion(read(at: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ProductiveMuslimEntry>) -> Void) {
    // One entry now plus one at every upcoming prayer start and day start,
    // so the widget stays right for the pushed days without the app.
    let now = Date()
    let d = UserDefaults(suiteName: appGroup)
    let changes = WidgetSchedule.starts(d).map { $0.at }
      + WidgetSchedule.strips(d).map { $0.start }
    let entries = [read(at: now)] + changes.filter { $0 > now }.sorted().map { read(at: $0) }
    // Only the app can produce new times, and it reloads timelines whenever
    // it pushes — so once stale (or not set up), don't poll.
    let policy: TimelineReloadPolicy
    if case .next = entries[0].state { policy = .atEnd } else { policy = .never }
    completion(Timeline(entries: entries, policy: policy))
  }

  private func read(at date: Date) -> ProductiveMuslimEntry {
    let d = UserDefaults(suiteName: appGroup)
    func text(_ key: String) -> String { d?.string(forKey: key) ?? "" }
    let state: WidgetState
    if text("widget_configured") != "1" {
      state = .setup(hint: text("widget_setup_hint"))
    } else if let next = WidgetSchedule.starts(d).first(where: { $0.at > date }) {
      let strip = WidgetSchedule.strips(d).first { date >= $0.start && date < $0.end }
      state = .next(prayer: next.prayer, time: next.time, strip: strip?.text ?? "")
    } else {
      state = .stale(title: text("widget_stale_title"), hint: text("widget_stale_hint"))
    }
    return ProductiveMuslimEntry(date: date, label: text("widget_label"),
                                 location: text("widget_location"), state: state)
  }
}

struct ProductiveMuslimWidgetEntryView: View {
  var entry: Provider.Entry

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      switch entry.state {
      case let .next(prayer, time, strip):
        pushed(entry.label, or: "Next prayer")
          .font(.caption2)
          .foregroundColor(qSoft)
        HStack(alignment: .lastTextBaseline) {
          Text(prayer)
            .font(.title2.weight(.bold))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
          Spacer()
          Text(time)
            .font(.title2)
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        Text(entry.location)
          .font(.caption2)
          .foregroundColor(qSoft)
          .lineLimit(1)
        Spacer()
        Text(strip)
          .font(.caption2)
          .foregroundColor(qFaint)
          .lineLimit(1)
          .minimumScaleFactor(0.5)
      case let .stale(title, hint):
        // Texts pushed in the in-app language; the String Catalog covers
        // the time before the app first pushes them.
        brand
        pushed(title, or: "Open the app")
          .font(.title2.weight(.bold))
          .foregroundColor(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.6)
        pushed(hint, or: "Prayer times need updating")
          .font(.caption2)
          .foregroundColor(qSoft)
      case let .setup(hint):
        brand
        pushed(hint, or: "Open the app to set your location")
          .font(.caption2)
          .foregroundColor(qSoft)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  /// A text pushed by the app (in-app language), or the String Catalog
  /// [fallback] before the app has pushed one.
  private func pushed(_ text: String, or fallback: LocalizedStringKey) -> Text {
    text.isEmpty ? Text(fallback) : Text(verbatim: text)
  }

  /// Brand name — never translated.
  private var brand: some View {
    Text(verbatim: "Productive Muslim")
      .font(.headline)
      .foregroundColor(.white)
  }
}

@main
struct ProductiveMuslimWidget: Widget {
  let kind = "ProductiveMuslimWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      if #available(iOS 17.0, *) {
        ProductiveMuslimWidgetEntryView(entry: entry)
          .padding(16)
          .containerBackground(qBackground, for: .widget)
      } else {
        ProductiveMuslimWidgetEntryView(entry: entry)
          .padding(16)
          .background(qBackground)
      }
    }
    .configurationDisplayName("Next Prayer")
    .description("Next prayer time at a glance")
    .supportedFamilies([.systemMedium])
  }
}
