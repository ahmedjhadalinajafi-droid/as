// MasjidWidget.swift
// أوقات الصلاة — مسجد وحسينية أهل البيت ع
//
// ══════════════════════════════════════════════════════════
//  XCODE SETUP (do this once on your Mac)
// ══════════════════════════════════════════════════════════
//  1. Open ios/Runner.xcworkspace in Xcode
//  2. File ▸ New ▸ Target ▸ Widget Extension
//     • Product Name : MasjidWidget
//     • Include Live Activity : NO
//     • Include Configuration App Intent : NO
//     • Finish ▸ Activate scheme
//  3. Select the Runner target ▸ Signing & Capabilities ▸ "+ Capability"
//     ▸ App Groups ▸ add:  group.com.ahmed.najafi.masjid
//  4. Select the MasjidWidget target ▸ Signing & Capabilities ▸ "+ Capability"
//     ▸ App Groups ▸ add the SAME group:  group.com.ahmed.najafi.masjid
//  5. In the MasjidWidget target, replace the auto-generated Swift file's
//     contents with THIS file's contents.
//  6. Build & run — long-press the home screen ▸ + ▸ search "أهل البيت".
// ══════════════════════════════════════════════════════════

import WidgetKit
import SwiftUI

// MARK: - Constants

private let kGroupId  = "group.com.ahmed.najafi.masjid"
private let kNavy     = Color(red: 0.106, green: 0.239, blue: 0.435)
private let kNavyDark = Color(red: 0.063, green: 0.133, blue: 0.251)
private let kGold     = Color(red: 0.788, green: 0.659, blue: 0.263)

// MARK: - Prayer model

struct Prayer: Identifiable {
    let id: String
    let arabic: String
    let time: String
}

// MARK: - Timeline Entry

struct PrayerEntry: TimelineEntry {
    let date: Date
    let fajr: String
    let dhuhr: String
    let maghrib: String
    let nextPrayer: String
    let nextPrayerTime: String

    static let sample = PrayerEntry(
        date: Date(),
        fajr: "04:15", dhuhr: "12:00", maghrib: "18:15",
        nextPrayer: "المغرب", nextPrayerTime: "18:15"
    )

    var prayers: [Prayer] {[
        Prayer(id: "fajr",    arabic: "الفجر",  time: fajr),
        Prayer(id: "dhuhr",   arabic: "الظهر",  time: dhuhr),
        Prayer(id: "maghrib", arabic: "المغرب", time: maghrib),
    ]}
}

// MARK: - Provider

struct PrayerProvider: TimelineProvider {

    func placeholder(in context: Context) -> PrayerEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        let entry = load()
        // Refresh every 30 minutes so the next-prayer highlight stays fresh
        let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func load() -> PrayerEntry {
        let ud = UserDefaults(suiteName: kGroupId)
        return PrayerEntry(
            date: Date(),
            fajr:    ud?.string(forKey: "fajr")              ?? "--:--",
            dhuhr:   ud?.string(forKey: "dhuhr")             ?? "--:--",
            maghrib: ud?.string(forKey: "maghrib")           ?? "--:--",
            nextPrayer:     ud?.string(forKey: "next_prayer")      ?? "الفجر",
            nextPrayerTime: ud?.string(forKey: "next_prayer_time") ?? "--:--"
        )
    }
}

// MARK: - Shared sub-views

struct GoldDivider: View {
    var body: some View {
        Rectangle().fill(kGold.opacity(0.45)).frame(height: 1)
    }
}

struct PrayerCell: View {
    let prayer: Prayer
    let entry: PrayerEntry
    let small: Bool

    private var isNext: Bool { prayer.arabic == entry.nextPrayer }

    var body: some View {
        VStack(spacing: small ? 2 : 4) {
            Text(prayer.arabic)
                .font(.system(size: small ? 10 : 12, weight: isNext ? .bold : .regular))
                .foregroundColor(isNext ? kGold : .white.opacity(0.6))
            Text(prayer.time)
                .font(.system(size: small ? 12 : 14, weight: .bold, design: .monospaced))
                .foregroundColor(isNext ? kGold : .white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, small ? 6 : 8)
        .background(isNext ? kGold.opacity(0.15) : Color.white.opacity(0.07))
        .cornerRadius(small ? 7 : 10)
        .overlay(
            RoundedRectangle(cornerRadius: small ? 7 : 10)
                .stroke(isNext ? kGold.opacity(0.55) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Small widget (next prayer only)

struct SmallView: View {
    let e: PrayerEntry

    var body: some View {
        VStack(spacing: 5) {
            Text("مسجد أهل البيت ع")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)

            GoldDivider().padding(.vertical, 2)

            Text("الصلاة القادمة")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.45))

            Text(e.nextPrayer.isEmpty ? "الفجر" : e.nextPrayer)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(kGold)

            Text(e.nextPrayerTime)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.12))
                .cornerRadius(8)
        }
        .padding(12)
    }
}

// MARK: - Medium / Large widget (next prayer + 3-prayer grid)

struct WideView: View {
    let e: PrayerEntry
    let large: Bool

    var body: some View {
        VStack(spacing: large ? 12 : 8) {
            HStack {
                Text("مسجد وحسينية أهل البيت ع")
                    .font(.system(size: large ? 14 : 12, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                if !e.nextPrayer.isEmpty {
                    HStack(spacing: 3) {
                        Circle().fill(kGold).frame(width: 5, height: 5)
                        Text("\(e.nextPrayer)  \(e.nextPrayerTime)")
                            .font(.system(size: large ? 11 : 9, weight: .semibold))
                            .foregroundColor(kGold)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(kGold.opacity(0.12))
                    .cornerRadius(8)
                }
            }

            GoldDivider()

            HStack(spacing: large ? 10 : 6) {
                ForEach(e.prayers) { p in
                    PrayerCell(prayer: p, entry: e, small: !large)
                }
            }

            if large { Spacer(minLength: 0) }
        }
        .padding(large ? 16 : 12)
    }
}

// MARK: - Entry View

struct MasjidWidgetEntryView: View {
    var entry: PrayerEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall: SmallView(e: entry)
        case .systemLarge: WideView(e: entry, large: true)
        default:           WideView(e: entry, large: false)
        }
    }
}

// MARK: - Widget

struct MasjidWidget: Widget {
    let kind = "MasjidWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
            if #available(iOS 17.0, *) {
                MasjidWidgetEntryView(entry: entry)
                    .containerBackground(
                        LinearGradient(colors: [kNavy, kNavyDark],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing),
                        for: .widget)
            } else {
                ZStack {
                    LinearGradient(colors: [kNavy, kNavyDark],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                    MasjidWidgetEntryView(entry: entry)
                }
            }
        }
        .configurationDisplayName("أوقات الصلاة")
        .description("أوقات صلاة مسجد وحسينية أهل البيت — بغداد")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Bundle entry point

@main
struct MasjidWidgetBundle: WidgetBundle {
    var body: some Widget {
        MasjidWidget()
    }
}

// MARK: - Preview

#Preview("Medium", as: .systemMedium) {
    MasjidWidget()
} timeline: {
    PrayerEntry.sample
}
