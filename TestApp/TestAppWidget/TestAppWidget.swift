import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), selectedOption: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), selectedOption: 0)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date(), selectedOption: UserDefaults(suiteName: "group.testapp")?.integer(forKey: "selectedOption") ?? 0)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let selectedOption: Int
}

struct TestAppWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color.black.opacity(0.05)
            
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    OptionButton(title: "Тест 1", isSelected: entry.selectedOption == 0, index: 0)
                    OptionButton(title: "Тест 2", isSelected: entry.selectedOption == 1, index: 1)
                    OptionButton(title: "Тест 3", isSelected: entry.selectedOption == 2, index: 2)
                }
                .padding(.horizontal)
                
                Link(destination: URL(string: "testapp://open?option=\(entry.selectedOption)")!) {
                    Text("Открыть")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

struct OptionButton: View {
    let title: String
    let isSelected: Bool
    let index: Int
    
    var body: some View {
        Link(destination: URL(string: "testapp://select?option=\(index)")!) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(isSelected ? .white : .primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

@main
struct TestAppWidget: Widget {
    let kind: String = "TestAppWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TestAppWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Test App")
        .description("Выберите тест и откройте приложение")
        .supportedFamilies([.systemMedium])
    }
}
