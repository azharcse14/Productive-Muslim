import WidgetKit
import SwiftUI

// Brand teal #15564D and its soft tints, matching the Android widget.
private let qBackground = Color(red: 0.082, green: 0.337, blue: 0.302)
private let qSoft = Color(red: 0.655, green: 0.855, blue: 0.804)        // #A7DACD
private let qFaint = Color(red: 0.863, green: 0.914, blue: 0.894)       // #DCE9E4

/// App Group shared with the Flutter app (see AppDelegate + entitlements).
private let appGroup = "group.com.qalbee.qalbee"

struct QalbeeEntry: TimelineEntry {
  let date: Date
  let configured: Bool
  let label: String
  let prayer: String
  let time: String
  let location: String
  let times: String
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> QalbeeEntry {
    QalbeeEntry(date: Date(), configured: false, label: "Qalbee",
                prayer: "Set up", time: "", location: "", times: "")
  }

  func getSnapshot(in context: Context, completion: @escaping (QalbeeEntry) -> Void) {
    completion(read())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<QalbeeEntry>) -> Void) {
    // The app pushes fresh data on open / settings change; between those we
    // refresh roughly every 15 minutes so the "next prayer" stays current.
    let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date())
      ?? Date().addingTimeInterval(900)
    completion(Timeline(entries: [read()], policy: .after(next)))
  }

  private func read() -> QalbeeEntry {
    let d = UserDefaults(suiteName: appGroup)
    let configured = (d?.string(forKey: "widget_configured") ?? "0") == "1"
    return QalbeeEntry(
      date: Date(),
      configured: configured,
      label: d?.string(forKey: "widget_label") ?? "",
      prayer: d?.string(forKey: "widget_prayer") ?? "—",
      time: d?.string(forKey: "widget_time") ?? "",
      location: d?.string(forKey: "widget_location") ?? "",
      times: d?.string(forKey: "widget_times") ?? ""
    )
  }
}

struct QalbeeWidgetEntryView: View {
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
        Text("Qalbee")
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
struct QalbeeWidget: Widget {
  let kind = "QalbeeWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      if #available(iOS 17.0, *) {
        QalbeeWidgetEntryView(entry: entry)
          .padding(16)
          .containerBackground(qBackground, for: .widget)
      } else {
        QalbeeWidgetEntryView(entry: entry)
          .padding(16)
          .background(qBackground)
      }
    }
    .configurationDisplayName("Next Prayer")
    .description("Next prayer time at a glance")
    .supportedFamilies([.systemMedium])
  }
}
