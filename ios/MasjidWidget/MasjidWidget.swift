// MasjidWidget.swift
// أوقات الصلاة — مسجد وحسينية أهل البيت ع
//
// ══════════════════════════════════════════════════════════
//  XCODE SETUP (do this once)
// ══════════════════════════════════════════════════════════
//  1. Open Runner.xcworkspace in Xcode
//  2. File ▸ New ▸ Target ▸ Widget Extension
//     • Product Name : MasjidWidget
//     • Include Configuration Intent : NO (uncheck)
//     • Finish — Xcode asks to activate scheme, tap Activate
//  3. Main app target (Runner):
//     Signing & Capabilities ▸ "+" ▸ App Groups
//     Add: group.com.ahmed.najafi.masjid
//  4. MasjidWidget target:
//     Signing & Capabilities ▸ "+" ▸ App Groups
//     Add: group.com.ahmed.najafi.masjid
//  5. In MasjidWidget target, delete Xcode-generated Swift file
//     and add THIS file instead (or just replace its content)
//  6. Build & run — long-press home screen to add widget
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
    let asr: String
    let maghrib: String
    let isha: String
    let nextPrayer: String
    let nextPrayerTime: String

    static let sample = PrayerEntry(
        date: Date(),
        fajr: "04:15", dhuhr: "12:00",
        asr:  "15:30", maghrib: "18:15", isha: "19:45",
        nextPrayer: "المغرب", nextPrayerTime: "18:15"
    )

    var prayers: [Prayer] {[
        Prayer(id: "fajr",    arabic: "الفجر",  time: fajr),
        Prayer(id: "dhuhr",   arabic: "الظهر",  time: dhuhr),
        Prayer(id: "asr",     arabic: "العصر",  time: asr),
        Prayer(id: "maghrib", arabic: "المغرب", time: maghrib),
        Prayer(id: "isha",    arabic: "العشاء", time: isha),
    ]}

    // 24-hour "HH:mm" → 12-hour "h:mm a"
    func display(_ t: String) -> String {
        guard t != "--:--", !t.isEmpty else { return "--:--" }
        let f24 = DateFormatter(); f24.dateFormat = "HH:mm"
        let f12 = DateFormatter(); f12.dateFormat = "h:mm a"
        f12.locale = Locale(identifier: "en_US")
        guard let d = f24.date(from: t) else { return t }
        return f12.string(from: d)
    }
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
            fajr:    ud?.string(forKey: "fajr")             ?? "--:--",
            dhuhr:   ud?.string(forKey: "dhuhr")            ?? "--:--",
            asr:     ud?.string(forKey: "asr")               ?? "--:--",
            maghrib: ud?.string(forKey: "maghrib")           ?? "--:--",
            isha:    ud?.string(forKey: "isha")              ?? "--:--",
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
                .font(.system(size: small ? 9 : 11, weight: isNext ? .bold : .regular))
                .foregroundColor(isNext ? kGold : .white.opacity(0.6))

            Text(entry.display(prayer.time))
                .font(.system(size: small ? 11 : 13, weight: .bold, design: .monospaced))
                .foregroundColor(isNext ? kGold : .white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, small ? 5 : 7)
        .background(isNext ? kGold.opacity(0.15) : Color.white.opacity(0.07))
        .cornerRadius(small ? 6 : 9)
        .overlay(
            RoundedRectangle(cornerRadius: small ? 6 : 9)
                .stroke(isNext ? kGold.opacity(0.55) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Small widget  (next prayer only)

struct SmallView: View {
    let e: PrayerEntry

    var body: some View {
        ZStack {
            LinearGradient(colors: [kNavy, kNavyDark],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            VStack(spacing: 5) {
                // Mosque icon + name
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 18))
                    .foregroundColor(kGold)

                Text("مسجد أهل البيت ع")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)

                GoldDivider().padding(.vertical, 2)

                Text("الصلاة القادمة")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.45))

                Text(e.nextPrayer.isEmpty ? "الفجر" : e.nextPrayer)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(kGold)

                Text(e.display(e.nextPrayerTime))
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(8)
            }
            .padding(12)
        }
    }
}

// MARK: - Medium widget  (next prayer + 5-prayer grid)

struct MediumView: View {
    let e: PrayerEntry

    var body: some View {
        ZStack {
            LinearGradient(colors: [kNavy, Color(red: 0.165, green: 0.357, blue: 0.659)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            VStack(spacing: 7) {
                // Header row
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 11))
                            .foregroundColor(kGold)
                        Text("مسجد أهل البيت ع")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    // Next prayer pill
                    if !e.nextPrayer.isEmpty {
                        HStack(spacing: 3) {
                            Circle().fill(kGold).frame(width: 5, height: 5)
                            Text("\(e.nextPrayer)  \(e.display(e.nextPrayerTime))")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(kGold)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(kGold.opacity(0.12))
                        .cornerRadius(8)
                    }
                }

                GoldDivider()

                // Row 1: Fajr, Dhuhr, Asr
                HStack(spacing: 6) {
                    ForEach(e.prayers.prefix(3)) { p in
                        PrayerCell(prayer: p, entry: e, small: true)
                    }
                }

                // Row 2: Maghrib, Isha (+ invisible filler)
                HStack(spacing: 6) {
                    ForEach(e.prayers.suffix(2)) { p in
                        PrayerCell(prayer: p, entry: e, small: true)
                    }
                    // Filler to keep same width as row 1
                    Color.clear.frame(maxWidth: .infinity)
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Large widget  (full branded + big next prayer + grid)

struct LargeView: View {
    let e: PrayerEntry

    var body: some View {
        ZStack {
            LinearGradient(colors: [kNavy, kNavyDark, kNavy],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────
                VStack(spacing: 4) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 32))
                        .foregroundColor(kGold)
                        .padding(.top, 4)

                    Text("مسجد وحسينية أهل البيت ع")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)

                    Text("بغداد — المنصور")
                        .font(.system(size: 10))
                        .foregroundColor(kGold.opacity(0.8))
                }
                .padding(.bottom, 10)

                GoldDivider().padding(.horizontal, 20)

                // ── Next Prayer ─────────────────────────────
                VStack(spacing: 5) {
                    Text("الصلاة القادمة")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 10)

                    Text(e.nextPrayer.isEmpty ? "الفجر" : e.nextPrayer)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(kGold)

                    Text(e.display(e.nextPrayerTime))
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(kGold.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(kGold.opacity(0.5), lineWidth: 1)
                                )
                        )
                }

                // ── All Prayers ─────────────────────────────
                VStack(spacing: 8) {
                    HStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 1)
                        Text("أوقات الصلاة")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal, 8)
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 1)
                    }
                    .padding(.top, 12)

                    // Row 1: 3 prayers
                    HStack(spacing: 8) {
                        ForEach(e.prayers.prefix(3)) { p in
                            PrayerCell(prayer: p, entry: e, small: false)
                        }
                    }
                    // Row 2: 2 prayers
                    HStack(spacing: 8) {
                        ForEach(e.prayers.suffix(2)) { p in
                            PrayerCell(prayer: p, entry: e, small: false)
                        }
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 2)

                Spacer(minLength: 0)
            }
            .padding(14)
        }
    }
}

// MARK: - Entry View (dispatches by family)

struct MasjidWidgetEntryView: View {
    var entry: PrayerEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:  SmallView(e: entry)
        case .systemLarge:  LargeView(e: entry)
        default:            MediumView(e: entry)
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
                    .containerBackground(kNavy, for: .widget)
            } else {
                MasjidWidgetEntryView(entry: entry)
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

#Preview("Small", as: .systemSmall) {
    MasjidWidget()
} timeline: {
    PrayerEntry.sample
}

#Preview("Large", as: .systemLarge) {
    MasjidWidget()
} timeline: {
    PrayerEntry.sample
}
