import WidgetKit
import SwiftUI

// Brand teal #15564D and its soft tints, matching the Android widget.
private let qBackground = Color(red: 0.082, green: 0.337, blue: 0.302)
private let qSoft = Color(red: 0.655, green: 0.855, blue: 0.804)        // #A7DACD
private let qFaint = Color(red: 0.863, green: 0.914, blue: 0.894)       // #DCE9E4

/// App Group shared with the Flutter app (see AppDelegate + entitlements).
private let appGroup = "group.com.productivemuslim.app"

struct ProductiveMuslimEntry: TimelineEntry {
  let date: Date
  let configured: Bool
  let label: String
  let prayer: String
  let time: String
  let location: String
  let times: String
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> ProductiveMuslimEntry {
    ProductiveMuslimEntry(date: Date(), configured: false, label: "Productive Muslim",
                prayer: "Set up", time: "", location: "", times: "")
  }

  func getSnapshot(in context: Context, completion: @escaping (ProductiveMuslimEntry) -> Void) {
    completion(read())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ProductiveMuslimEntry>) -> Void) {
    // One entry now plus one at every upcoming prayer start, each showing
    // the prayer after it, so "next prayer" flips on time without the app.
    let now = Date()
    let starts = schedule().map { $0.at }.filter { $0 > now }
    let entries = [read(at: now)] + starts.map { read(at: $0) }
    // Past the pushed schedule: poll until the app pushes a fresh one.
    let policy: TimelineReloadPolicy = starts.isEmpty
      ? .after(now.addingTimeInterval(900)) : .atEnd
    completion(Timeline(entries: entries, policy: policy))
  }

  /// `widget_schedule` lines (`epochMillis<TAB>prayer<TAB>time`), in order.
  private func schedule() -> [(at: Date, prayer: String, time: String)] {
    let raw = UserDefaults(suiteName: appGroup)?.string(forKey: "widget_schedule") ?? ""
    return raw.split(separator: "\n").compactMap { line in
      let parts = line.split(separator: "\t", omittingEmptySubsequences: false)
      guard parts.count >= 3, let millis = Double(parts[0]) else { return nil }
      return (Date(timeIntervalSince1970: millis / 1000), String(parts[1]), String(parts[2]))
    }
  }

  private func read(at date: Date = Date()) -> ProductiveMuslimEntry {
    let d = UserDefaults(suiteName: appGroup)
    let configured = (d?.string(forKey: "widget_configured") ?? "0") == "1"
    // First prayer starting after `date`; past the schedule, the last
    // pushed snapshot.
    let next = schedule().first { $0.at > date }
    return ProductiveMuslimEntry(
      date: date,
      configured: configured,
      label: d?.string(forKey: "widget_label") ?? "",
      prayer: next?.prayer ?? d?.string(forKey: "widget_prayer") ?? "—",
      time: next?.time ?? d?.string(forKey: "widget_time") ?? "",
      location: d?.string(forKey: "widget_location") ?? "",
      times: d?.string(forKey: "widget_times") ?? ""
    )
  }
}

struct ProductiveMuslimWidgetEntryView: View {
  var entry: Provider.Entry

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      if entry.configured {
        Text(entry.label)
          .font(.caption2)
          .foregroundColor(qSoft)
        HStack(alignment: .lastTextBaseline) {
          Text(entry.prayer)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .lineLimit(1)
          Spacer()
          Text(entry.time)
            .font(.system(size: 22))
            .foregroundColor(.white)
            .lineLimit(1)
        }
        Text(entry.location)
          .font(.caption2)
          .foregroundColor(qSoft)
          .lineLimit(1)
        Spacer()
        Text(entry.times)
          .font(.system(size: 11))
          .foregroundColor(qFaint)
          .lineLimit(1)
      } else {
        Text("Productive Muslim")
          .font(.headline)
          .foregroundColor(.white)
        Text("Open the app to set your location")
          .font(.caption2)
          .foregroundColor(qSoft)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
