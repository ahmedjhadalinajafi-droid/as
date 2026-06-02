# تقرير تطبيق "مسجد وحسينية أهل البيت" — Technical Handover Report

> وثيقة تسليم كاملة لأي مبرمج يستلم التطبيق للتطوير أو الصيانة.
> Full handover document for any developer taking over the app.

---

## 1. نظرة عامة | Overview

| | |
|---|---|
| **اسم التطبيق** | مسجد وحسينية أهل البيت (ع) |
| **الموقع** | بغداد – المنصور / مواقيت الكرخ |
| **المنصة** | Flutter (Android primary, iOS-ready) |
| **package name** | `masjid_app` (Android namespace: `com.example.masjid_app`) |
| **الإصدار** | 1.0.0+1 |
| **اللغة** | عربي بالكامل (RTL) |
| **حجم الكود** | ~9,400 سطر Dart + 113 Kotlin + 487 XML + 347 Python |
| **الفرع الحالي** | `claude/masjid-app-setup-MHlkW` |

التطبيق يعمل **بالكامل بدون إنترنت** (offline-first): أوقات الصلاة، القرآن، المفاتيح، القبلة كلها مخزّنة محلياً.

---

## 2. البيئة والمتطلبات | Environment & Requirements

- **Flutter SDK**: Dart `>=3.0.0 <4.0.0` (Flutter 3.x)
- **Android**: target/compile recent SDK; min SDK ~21+
- **Java/Kotlin**: required for Android build (Gradle KTS)
- **iOS**: dependencies are iOS-compatible but iOS build not yet configured

### أوامر البناء | Build commands
```bash
flutter pub get
flutter run                 # debug على جهاز متصل
flutter build apk --release # APK كامل
flutter build apk --release --split-per-abi  # APK أصغر لكل معالج
```
الناتج: `build/app/outputs/flutter-apk/app-release.apk`

> ⚠️ ملف `android/app/google-services.json` مطلوب من Firebase Console (غير مرفوع في git).

---

## 3. الحزم المستخدمة | Dependencies

| الحزمة | الغرض |
|--------|-------|
| `firebase_core`, `cloud_firestore` | قاعدة البيانات (إعلانات، فعاليات، حملات، إعدادات) |
| `firebase_storage` | تخزين الصور |
| `firebase_messaging` | إشعارات Push (FCM) |
| `firebase_auth`, `google_sign_in` | تسجيل دخول الأدمن |
| `flutter_local_notifications`, `timezone` | إشعارات أوقات الصلاة المجدولة |
| `geolocator`, `flutter_compass` | اتجاه القبلة |
| `just_audio`, `audio_session` | تشغيل تلاوة القرآن |
| `image_picker`, `cached_network_image` | الصور |
| `hijri`, `intl` | التقويم الهجري والتواريخ |
| `shared_preferences`, `provider`, `path_provider`, `http` | تخزين محلي / حالة / شبكة |
| `url_launcher` | فتح روابط التواصل وواتساب |
| `home_widget` | ودجة الشاشة الرئيسية لأوقات الصلاة |

---

## 4. هيكل المشروع | Project Structure

```
lib/
├── main.dart                  (2073) الجذر، التنقّل، الثيم، الصفحة الرئيسية، الودجة
├── prayer_times_page.dart     (731)  أوقات الصلاة + إشعاراتها
├── notification_service.dart  (312)  جدولة إشعارات الصلاة + FCM
├── quran_page.dart            (1018) القرآن + الصوت + كاش محلي
├── mafatih_page.dart          (810)  مفاتيح الجنان
├── ziyarat_page.dart          (513)  الزيارات
├── qibla_page.dart            (791)  بوصلة القبلة
├── hijri_calendar_page.dart   (591)  التقويم الهجري
├── date_converter_page.dart   (424)  محوّل التاريخ
├── campaigns_page.dart        (653)  حملات الزيارة (بغداد ← النجف/كربلاء)
├── events_page.dart           (475)  الفعاليات (قادمة/سابقة + boosted)
├── announcements_page.dart    (443)  الإعلانات
├── social_media_page.dart     (406)  روابط التواصل
└── islamic_background.dart    (136)  الزخرفة الإسلامية المرسومة

android/app/src/main/
├── kotlin/.../MasjidWidgetProvider.kt   ودجة أوقات الصلاة (native)
├── res/layout/masjid_widget.xml         تصميم الودجة
└── AndroidManifest.xml                  الصلاحيات + المستقبِلات

assets/
├── prayer_times_2026.json   مواقيت الكرخ 2026 (365 يوم) — مدمجة offline
├── quran.json               نص القرآن كامل
├── mafatih.json             مفاتيح الجنان (2.3MB)
└── fonts/ScheherazadeNew-Regular.ttf  الخط العربي

tools/
├── upload_prayer_times.py   رفع أوقات الصلاة إلى Firestore
└── add_sample_trip.py       إضافة حملة زيارة تجريبية
```

### التنقّل (Bottom Nav) — 6 تبويبات
`0` الرئيسية · `1` الصلاة · `2` تواصل · `3` الفعاليات · `4` الحملات · `5` المزيد
صفحة "المزيد" تحوي: القرآن، الفعاليات، التواصل، التقويم الهجري، محوّل التاريخ، المفاتيح، القبلة، الإعلانات، الزيارات.

---

## 5. Firebase

- **Project ID**: `masjid-405c1`
- **Sender ID**: `658803064168`
- **Storage bucket**: `masjid-405c1.firebasestorage.app`
- **Offline persistence**: مفعّلة (`persistenceEnabled: true`, cache unlimited)

### Firestore Collections

| Collection | الغرض | الحقول الرئيسية |
|-----------|-------|------------------|
| `prayer_times` | أوقات الصلاة (تجاوز الأدمن) | docId=`YYYY-MM-DD`؛ `fajr, sunrise, dhuhr, sunset, maghrib, midnight` |
| `announcements` | الإعلانات | `title, body, imageUrl, createdAt` |
| `events` | الفعاليات | `title, description, location, imageUrl, category, date(timestamp), boosted(bool)` |
| `trips` | حملات الزيارة | `title, destination, departureFrom, departureDate, returnDate, price, seats, imageUrl, description, contacts[]` |
| `home_slider` | صور الصفحة الرئيسية | `imageUrl, title, order` |
| `settings/hijri` | تعديل اليوم الهجري | `offset` (int, ±) |

`contacts` في `trips` = مصفوفة من `{name, label, phone}`.

---

## 6. الميزات الرئيسية | Key Features

1. **أوقات الصلاة** — 6 أوقات (فجر/شروق/ظهر/غروب/مغرب/منتصف الليل) لمواقيت الكرخ.
   - ترتيب التحميل: Firestore → الملف المدمج → aladhan API (method 13) → الكاش المحلي.
   - عدّاد تنازلي للصلاة القادمة، وإشعارات مجدولة 7 أيام.
2. **القرآن الكريم** — نص كامل + تلاوة صوتية مع كاش محلي (يعمل offline بعد التحميل).
3. **مفاتيح الجنان + الزيارات** — مدمجة بالكامل offline.
4. **اتجاه القبلة** — بوصلة مصمّمة باستخدام `flutter_compass` + `geolocator`.
5. **التقويم الهجري + محوّل التاريخ** — مع إمكانية تعديل اليوم عبر `settings/hijri`.
6. **حملات الزيارة** — تبويب قادمة/منتهية، أزرار واتساب/اتصال، أرقام متعددة بأسماء.
7. **الفعاليات** — تبويب قادمة/سابقة، تمييز (boosted) يظهر بالرئيسية.
8. **الإعلانات + معرض الصور** — من Firestore، تظهر فوراً بلا تحديث للتطبيق.
9. **ودجة الشاشة الرئيسية** — أوقات الصلاة (home_widget plugin).
10. **الوضع الليلي** + دعم RTL كامل.

---

## 7. لوحة الإدارة | Content Management

كل المحتوى الديناميكي يُدار من **Firebase Console مباشرة** — لا حاجة لتحديث التطبيق عند:
- إضافة/تعديل إعلان، فعالية، حملة زيارة، صورة في المعرض.
- تمييز فعالية (`boosted: true`) أو إنهاء حملة.
- تعديل وقت صلاة ليوم معيّن (`prayer_times/YYYY-MM-DD`).

يلزم تحديث التطبيق (rebuild) فقط عند تغيير الكود أو الملف `assets/prayer_times_2026.json`.

### سكربتات مساعدة (Python)
```bash
pip install firebase-admin requests
# رفع كل أوقات السنة من الملف المدمج:
python3 tools/upload_prayer_times.py --json assets/prayer_times_2026.json --key serviceAccountKey.json
# إضافة حملة زيارة تجريبية:
python3 tools/add_sample_trip.py --key serviceAccountKey.json
```
`serviceAccountKey.json` يُولَّد من: Firebase Console → Project Settings → Service Accounts.

---

## 8. الإشعارات | Notifications

- **محلية مجدولة**: `notification_service.dart` يجدول إشعارات فجر/ظهر/مغرب لـ 7 أيام من الملف المدمج.
  - يستخدم timezone `Asia/Baghdad`.
  - fallback من exact → inexact alarms (لتفادي قيود Android 12+).
- **Push (FCM)**: مواضيع `announcements` و `prayer_times`.
- صلاحيات Android مطلوبة: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`.

---

## 9. نقاط مهمة للمطوّر القادم | Notes for Next Developer

1. **android/ gradle files غير مرفوعة في git** — موجودة محلياً فقط (build.gradle.kts, MainActivity.kt, settings.gradle). يُفضّل رفعها ومعالجة `.gitignore`.
2. **namespace ≠ applicationId محتمل**: الكود الأصلي بحزمة `com.example.masjid_app`؛ تأكّد من `applicationId` في `build.gradle.kts`.
3. **google-services.json** مطلوب ولا يُرفع في git.
4. **مفاتيح Firebase** مكتوبة في `main.dart` لإصدار الويب فقط؛ Android يقرأ من google-services.json.
5. **تحذيرات Kotlin Gradle Plugin (KGP)** عند البناء — غير مانعة حالياً، لكن يُنصح بالهجرة إلى Built-in Kotlin مستقبلاً.
6. **iOS** يحتاج إعداد (Firebase iOS app, APNs, signing) — الحزم متوافقة لكن لم يُختبر.
7. **استضافة صوت القرآن**: روابط MP3 يمكن نقلها لاستضافة خاصة (Hostinger) — حدّث الروابط في `quran_page.dart`.

---

## 10. أفكار للتطوير | Suggested Upgrades

- لوحة إدارة داخل التطبيق (بدل Firebase Console) لإضافة الحملات/الفعاليات.
- دعم iOS كامل ونشر على App Store.
- ترجمة إنجليزية اختيارية.
- إشعار Push تلقائي عند إضافة حملة/فعالية جديدة.
- تحديث أوقات الصلاة لسنة 2027 وما بعدها (الملف المدمج حالياً 2026 فقط).
- إحصاءات/تحليلات (Firebase Analytics).

---

*تم إعداد هذا التقرير آلياً من الشيفرة المصدرية الحالية.*
