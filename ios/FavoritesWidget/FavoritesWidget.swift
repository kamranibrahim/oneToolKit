import WidgetKit
import SwiftUI

private let widgetGroupId = "group.com.onetoolkit.one_toolkit"

struct FavoritesProvider: TimelineProvider {
  func placeholder(in context: Context) -> FavoritesEntry {
    FavoritesEntry(
      date: Date(),
      title: "OneToolkit",
      subtitle: "Favorites",
      tools: ["Merge PDF", "OCR", "Translate", "Scan to PDF"]
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (FavoritesEntry) -> Void) {
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<FavoritesEntry>) -> Void) {
    let entry = loadEntry()
    completion(Timeline(entries: [entry], policy: .atEnd))
  }

  private func loadEntry() -> FavoritesEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    var tools: [String] = []
    for i in 0..<4 {
      if let name = data?.string(forKey: "tool_\(i)"), !name.isEmpty {
        tools.append(name)
      }
    }
    return FavoritesEntry(
      date: Date(),
      title: data?.string(forKey: "title") ?? "OneToolkit",
      subtitle: data?.string(forKey: "subtitle") ?? "Favorites",
      tools: tools
    )
  }
}

struct FavoritesEntry: TimelineEntry {
  let date: Date
  let title: String
  let subtitle: String
  let tools: [String]
}

struct FavoritesWidgetEntryView: View {
  var entry: FavoritesEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(entry.title)
        .font(.headline)
        .foregroundStyle(Color.primary)
      Text(entry.subtitle)
        .font(.caption)
        .foregroundStyle(Color.secondary)

      if entry.tools.isEmpty {
        Text("Star tools in the app to pin them here")
          .font(.caption)
          .foregroundStyle(Color.secondary)
          .padding(.top, 4)
      } else {
        ForEach(entry.tools, id: \.self) { tool in
          Text(tool)
            .font(.subheadline)
            .foregroundStyle(Color(red: 0, green: 0.48, blue: 1))
            .lineLimit(1)
        }
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .containerBackground(for: .widget) {
      Color(red: 0.949, green: 0.949, blue: 0.969)
    }
  }
}

@main
struct FavoritesWidget: Widget {
  let kind: String = "FavoritesWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FavoritesProvider()) { entry in
      FavoritesWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("OneToolkit Favorites")
    .description("Quick access to your starred tools.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
