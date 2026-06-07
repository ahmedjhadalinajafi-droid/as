# تقرير شامل — تطبيق مسجد وحسينية أهل البيت
**تاريخ التقرير:** 2026-06-07  
**حالة المشروع:** قيد التطوير النشط

---

## 1. هوية المشروع

| البند | القيمة |
|---|---|
| اسم التطبيق | مسجد وحسينية أهل البيت |
| الموقع | بغداد — المنصور |
| اسم الحزمة (Android) | `com.masjid.app` |
| اسم الحزمة (iOS) | `com.ahmed.najafi.masjid` |
| الإصدار الحالي | 1.0.1 (Build 2) |
| اللغة | Arabic (RTL) |
| Repository | `ahmedjhadalinajafi-droid/as` |
| فرع التطوير | `claude/masjid-app-setup-MHlkW` |
| الفرع الرئيسي | `main` |
| موقع الخادم | `https://ahlulbaytmosque.site/app/server/` |
| لوحة الإدارة | `https://ahlulbaytmosque.site/app/server/admin/` |

---

## 2. بيانات الوصول والمفاتيح السرية (CREDENTIALS)

> ⚠️ هذا الملف سري — لا تشاركه مع أحد

### تطبيق Flutter
| المفتاح | القيمة |
|---|---|
| API Secret (يُرسل مع كل طلب) | `ahlulbayt-masjid-2026-Kx9mPq7Lz3Wn8Rv` |
| موقعه في Flutter | `lib/backend_config.dart` → `Backend.secret` |
| موقعه في PHP | `server/config.php` → `API_SECRET` |

### لوحة الإدارة
| المفتاح | القيمة |
|---|---|
| كلمة مرور لوحة الإدارة | `Masjid@Admin2026` |
| عبارة المسؤول السرية | `MasjidAhlAlBait-Admin-Baghdad-Mansour-2026` |

### Firebase
| المفتاح | القيمة |
|---|---|
| Project ID | `masjid-405c1` |
| Web API Key | `AIzaSyDXZ5eeDDV4Bv1UT281nvXdjTBDs-DfXZY` |
| FCM Topic (مسؤولون) | `admin_questions` |
| FCM Topic (جميع المستخدمين) | `announcements` |
| App Group ID (iOS) | `group.com.ahmed.najafi.masjid` |
| ملف الخدمة | `service-account.json` (في `.gitignore` — لا يُرفع أبداً) |

### GitHub Actions
| المفتاح | القيمة |
|---|---|
| GitHub PAT Token | `ghp_rZgG••••••••••••••••••••••••ftR` |
| موقعه | `server/config.php` → `GITHUB_TOKEN` |
| GitHub Actions Secret Name | `HOSTINGER_API_SECRET` |
| GitHub Actions Secret Value | `ahlulbayt-masjid-2026-Kx9mPq7Lz3Wn8Rv` |
| رابط إضافة السيكريت | `https://github.com/ahmedjhadalinajafi-droid/as/settings/secrets/actions/new` |

---

## 3. المكدس التقني (Tech Stack)

### Flutter / Dart
- **Flutter** 3.x / **Dart** 3.x
- SDK range: `>=3.0.0 <4.0.0`
- منصة الاستهداف: **Android** (OnePlus 9) + **iOS**
- الخط: ScheherazadeNew (عربي)

### Dependencies الرئيسية

| الحزمة | الإصدار | الغرض |
|---|---|---|
| `firebase_core` | `^3.13.1` | Firebase init |
| `cloud_firestore` | `^5.6.0` | قاعدة البيانات |
| `firebase_messaging` | `^15.2.5` | الإشعارات (FCM) |
| `firebase_auth` | `^5.5.2` | المصادقة |
| `firebase_analytics` | `^11.3.3` | التحليلات |
| `google_sign_in` | `^6.2.2` | تسجيل دخول Google |
| `flutter_local_notifications` | `^18.0.1` | إشعارات أذان محلية |
| `timezone` | `^0.9.4` | جدولة الإشعارات بالمنطقة الزمنية |
| `geolocator` | `^14.0.2` | الموقع الجغرافي |
| `flutter_compass` | `^0.8.0` | البوصلة (اتجاه القبلة) |
| `image_picker` | `^1.0.7` | رفع صور |
| `cached_network_image` | `^3.3.1` | تحميل وتخزين الصور |
| `just_audio` | `^0.9.36` | مشغل صوت للقرآن |
| `audio_session` | `^0.1.18` | إدارة جلسة الصوت |
| `hijri` | `^3.0.1` | التقويم الهجري |
| `intl` | `^0.20.2` | التنسيق والترجمة |
| `shared_preferences` | `^2.2.2` | تخزين محلي |
| `provider` | `^6.1.1` | إدارة الحالة |
| `path_provider` | `^2.1.2` | مسارات الملفات |
| `http` | `^1.2.1` | طلبات HTTP |
| `url_launcher` | `^6.2.5` | فتح روابط خارجية |
| `home_widget` | `^0.6.0` | ودجت الشاشة الرئيسية |
| `package_info_plus` | `^8.0.0` | معلومات الإصدار |
| `cupertino_icons` | `^1.0.2` | أيقونات iOS |

### Dev Dependencies
| الحزمة | الإصدار | الغرض |
|---|---|---|
| `flutter_launcher_icons` | `^0.14.1` | توليد أيقونات التطبيق |
| `flutter_lints` | `^3.0.0` | قواعد الكود |

---

## 4. الخادم الخلفي (Hostinger Backend)

### الروابط
```
Base URL:   https://ahlulbaytmosque.site/app/server/
Admin URL:  https://ahlulbaytmosque.site/app/server/admin/
APK URL:    https://ahlulbaytmosque.site/app/server/app-release.apk
Version:    https://ahlulbaytmosque.site/app/server/version.json
```

### ملفات PHP الكاملة

| الملف | الغرض |
|---|---|
| `config.php` | الإعدادات المركزية — secrets, Firebase, GitHub |
| `send_notification.php` | إرسال إشعارات FCM (سؤال / إجابة / broadcast) |
| `upload_image.php` | رفع صور وتخزينها في `uploads/` |
| `version.json` | بيانات الإصدار الحالي — يقرأها التطبيق |
| `receive_build.php` | يستقبل APK من GitHub Actions، يحفظه، يحدث `version.json`، يشعر المستخدمين |
| `build_status.php` | GET: حالة البناء الحالية — POST: تحديث الحالة |
| `lib/fcm.php` | مكتبة إرسال FCM |
| `lib/firestore.php` | مكتبة Firestore REST |
| `admin/index.php` | لوحة الإدارة الكاملة |

### ملفات الإعداد

| الملف | الغرض |
|---|---|
| `server/.user.ini` | رفع حد رفع الملفات إلى 200MB (LiteSpeed) |
| `server/admin/.user.ini` | نفس الإعداد لمجلد الإدارة |
| `server/.htaccess` | حماية `.json`, `.md`, `.ini` من التنزيل المباشر |
| `server/.gitignore` | يستثني `pending_build.json` و `build_status.json` |

### محتوى `.user.ini` (كلا الملفين)
```ini
upload_max_filesize = 200M
post_max_size = 210M
memory_limit = 256M
max_execution_time = 600
max_input_time = 600
```

### `version.json` الحالي
```json
{
  "version": "1.0.1",
  "build": 2,
  "url": "https://ahlulbaytmosque.site/app/server/app-release.apk",
  "mandatory": false,
  "notes": "أحدث إصدار من تطبيق مسجد وحسينية أهل البيت"
}
```

---

## 5. لوحة الإدارة (Web Admin Panel)

**الرابط:** `https://ahlulbaytmosque.site/app/server/admin/`  
**كلمة المرور:** `Masjid@Admin2026`

### تبويبات اللوحة

| التبويب (عربي) | الوظيفة |
|---|---|
| الفعاليات | إنشاء / تعديل / حذف الفعاليات مع الصور والتاريخ |
| الرحلات | إدارة رحلات الزيارات (تواصل، حجز، تفاصيل) |
| الإعلانات | نشر وتعديل الإعلانات |
| الأسئلة | قراءة أسئلة المستخدمين والرد عليها مع إشعار تلقائي |
| القرآن | رفع تلاوات MP3 لكل سورة |
| معرض الصور | رفع / حذف صور الشريط الإعلاني |
| الإشعارات | إرسال إشعار broadcast لجميع المستخدمين |
| **إصدار التطبيق** | زر "🚀 ابدأ البناء" → GitHub Actions → APK تلقائي |

### تفاصيل تبويب "إصدار التطبيق"
- يعرض الإصدار الحالي ورقم البناء
- يعرض رسالة إعداد عندما يكون `GITHUB_TOKEN` فارغاً
- نموذج البناء: رقم الإصدار، رقم البناء، الملاحظات، تحديث إجباري، إشعار push
- يُحدِّث الحالة كل 8 ثوانٍ أثناء البناء
- بديل يدوي: رفع APK مباشرة من المتصفح (في قسم `<details>` مخفي)

---

## 6. منظومة بناء APK التلقائية (GitHub Actions)

### الفكرة الكاملة
```
المسؤول يضغط الزر
       ↓
PHP يستدعي GitHub API (workflow_dispatch)
       ↓
GitHub Actions (ubuntu-latest) يبني APK
       ↓
curl يرسل APK إلى receive_build.php على Hostinger
       ↓
يُحفظ APK + يُحدَّث version.json + يُشعَر جميع المستخدمين
```

### ملف الـ Workflow
**المسار:** `.github/workflows/build_release.yml`  
**موجود على فرعين:** `main` (مطلوب لـ API) + `claude/masjid-app-setup-MHlkW` (التطوير)

### خطوات الـ Workflow

| # | الخطوة | الأداة | التفاصيل |
|---|---|---|---|
| 1 | سحب الكود | `actions/checkout@v4` | يسحب فرع `claude/masjid-app-setup-MHlkW` |
| 2 | Java | `actions/setup-java@v4` | Java 17 (Temurin distribution) |
| 3 | Flutter | `subosito/flutter-action@v2` | Flutter Stable + Cache مفعّل |
| 4 | الحزم | `flutter pub get` | تحميل كل الحزم |
| 5 | البناء | `flutter build apk` | `--split-per-abi --release` → arm64 (~20MB) |
| 6 | الرفع | `curl POST` | يرسل APK + معلومات الإصدار لـ `receive_build.php` |
| 7 | الأرشيف | `actions/upload-artifact@v4` | يحتفظ بـ APK 30 يوماً في GitHub |

### مدخلات الـ Workflow

| المدخل | القيمة الافتراضية | الوصف |
|---|---|---|
| `version` | `1.0.2` | رقم الإصدار (مثال: 1.0.2) |
| `build` | `3` | رقم البناء — يجب أن يكون أكبر من الحالي |
| `notes` | نص عربي | ملاحظات التحديث للمستخدم |
| `mandatory` | `false` | `true` = يجبر المستخدم على التحديث |
| `notify` | `true` | `true` = يرسل FCM push لجميع المستخدمين |

### إعدادات `config.php` الخاصة بـ GitHub
```php
const GITHUB_TOKEN    = 'ghp_rZgG••••••••••••••••••••••••ftR';
const GITHUB_REPO     = 'ahmedjhadalinajafi-droid/as';
const GITHUB_WORKFLOW = 'build_release.yml';
const GITHUB_BRANCH   = 'claude/masjid-app-setup-MHlkW';
```

### قائمة إعداد GitHub Actions (مرة واحدة)

| الخطوة | الإجراء | الحالة |
|---|---|---|
| 1 | إنشاء GitHub PAT بصلاحية `workflow` | ✅ تم |
| 2 | لصق Token في `server/config.php` على Hostinger | ⚠️ يوجد خطأ — `l` مكتوبة `1` في الـ token |
| 3 | إضافة Secret `HOSTINGER_API_SECRET` في GitHub Repo Settings | يجب التحقق |
| 4 | الـ Workflow موجود على `main` | ✅ تم |
| 5 | رفع ملفات السيرفر المحدثة لـ Hostinger | يجب التنفيذ |

### ⚠️ تصحيح مهم في الـ Token
```
خاطئ:  ghp_rZgGtnEXDMJzetMbZS1SWbSPrdZ1Qw0e1ftR   ← رقم 1
صحيح:  ghp_rZgG••••••••••••••••••••••••ftR   ← حرف L صغير
                                              ↑
```

### كيفية إضافة GitHub Actions Secret
1. افتح: `https://github.com/ahmedjhadalinajafi-droid/as/settings/secrets/actions/new`
2. Name: `HOSTINGER_API_SECRET`
3. Value: `ahlulbayt-masjid-2026-Kx9mPq7Lz3Wn8Rv`
4. اضغط **Add secret**

---

## 7. تدفق نشر APK الكامل (خطوة بخطوة)

```
┌─────────────────────────────────────────────────────────────┐
│                    المسؤول (Admin Panel)                    │
│  يملأ: رقم الإصدار / البناء / الملاحظات / إجباري / إشعار  │
│                 يضغط "🚀 ابدأ البناء"                       │
└──────────────────────────┬──────────────────────────────────┘
                           │  POST إلى admin/index.php
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              PHP (admin/index.php → trigger_build)           │
│  curl → api.github.com/repos/.../actions/workflows/         │
│                  dispatches  (رمز 204 = نجاح)               │
└──────────────────────────┬──────────────────────────────────┘
                           │  workflow_dispatch
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  GitHub Actions (ubuntu-latest)              │
│  المدة: ~5 دقائق                                            │
│  1. Checkout claude/masjid-app-setup-MHlkW                  │
│  2. Java 17 + Flutter Stable                                 │
│  3. flutter pub get                                          │
│  4. flutter build apk --split-per-abi --release             │
│  5. curl POST arm64 APK → receive_build.php                 │
│  6. Upload artifact (30 days retention)                     │
└──────────────────────────┬──────────────────────────────────┘
                           │  multipart POST (arm64 APK ~20MB)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│           receive_build.php (Hostinger)                      │
│  1. يتحقق من صلاحية الـ APK (PK magic bytes — ZIP header)  │
│  2. يحفظ APK كـ app-release.apk                            │
│  3. يعيد كتابة version.json (version, build, url, notes)   │
│  4. يمسح pending_build.json                                 │
│  5. يكتب build_status.json = "done"                         │
│  6. يرسل FCM broadcast → topic: announcements               │
└──────────────────────────┬──────────────────────────────────┘
                           │  FCM Push Notification
                           ▼
┌─────────────────────────────────────────────────────────────┐
│            جميع مستخدمي التطبيق                              │
│  إشعار: "تحديث متوفر 🚀 — الإصدار X.X.X متوفر الآن"        │
│  عند فتح التطبيق: checkForUpdate() يقرأ version.json        │
│  إذا serverBuild > currentBuild → نافذة "تحديث الآن"        │
│  إذا mandatory=true → لا يمكن إغلاق النافذة                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 8. شاشات التطبيق (Screens)

| الملف | الشاشة | الوصف |
|---|---|---|
| `lib/main.dart` | الصفحة الرئيسية | بطاقة العداد التنازلي + شريط الفعاليات + الإعلانات |
| `lib/prayer_times_page.dart` | أوقات الصلاة | جدول أوقات اليوم الكامل |
| `lib/prayer_widget_service.dart` | خدمة الودجت | تحديث ودجت الشاشة الرئيسية |
| `lib/quran_page.dart` | القرآن الكريم | نص + تلاوة صوتية + تحميل |
| `lib/mafatih_page.dart` | المفاتيح | الأدعية والزيارات مع البحث |
| `lib/hijri_calendar_page.dart` | التقويم الهجري | تقويم مع المناسبات |
| `lib/date_converter_page.dart` | محول التاريخ | ميلادي ↔ هجري |
| `lib/qibla_page.dart` | اتجاه القبلة | بوصلة حية |
| `lib/events_page.dart` | الفعاليات | قائمة الفعاليات مع التعديل للمسؤول |
| `lib/trips_page.dart` | الرحلات والزيارات | تفاصيل الرحلات + حجز + تواصل |
| `lib/announcements_page.dart` | الإعلانات | قراءة وتعديل الإعلانات |
| `lib/ask_page.dart` | الأسئلة الدينية | إرسال سؤال + عرض الإجابة |
| `lib/campaigns_page.dart` | الحملات والتبرعات | إحصاءات + أزرار تواصل |
| `lib/social_media_page.dart` | منصات التواصل | روابط القنوات الرسمية |
| `lib/ziyarat_page.dart` | الزيارات | نصوص الزيارات |
| `lib/photo_viewer.dart` | عارض الصور | ملء الشاشة |
| `lib/brand.dart` | نظام الألوان | ثوابت اللون + دالة brandColor |
| `lib/backend_config.dart` | إعدادات الخادم | Backend class |
| `lib/analytics_service.dart` | التحليلات | Firebase Analytics |
| `lib/notification_service.dart` | إدارة الإشعارات | FCM + Local Notifications |
| `lib/islamic_background.dart` | خلفية إسلامية | مكون ديكوري |

---

## 9. ودجت الشاشة الرئيسية

### Android
- **الكلاس:** `MasjidWidgetProvider.kt`
- **ملف التخطيط:** `android/app/src/main/res/layout/masjid_widget.xml`

### iOS
- **الاسم:** `MasjidWidget`
- **App Group ID:** `group.com.ahmed.najafi.masjid`

### البيانات المكتوبة في الودجت (SharedPreferences keys)

| المفتاح | البيانات |
|---|---|
| `fajr` | وقت صلاة الفجر |
| `dhuhr` | وقت صلاة الظهر |
| `maghrib` | وقت صلاة المغرب |
| `next_prayer` | اسم الصلاة التالية |
| `next_prayer_time` | وقت الصلاة التالية |
| `day_name` | اسم اليوم بالعربية (مضاف في هذه الجلسة) |
| `date` | التاريخ بصيغة dd/mm/yyyy (مضاف في هذه الجلسة) |

---

## 10. منطق أوقات الصلاة

### ترتيب البحث في `_findNextPrayer()`
1. يبحث عن أول صلاة لم تمضِ بعد (الفجر → الظهر → المغرب)
2. **إذا مضت جميع الصلوات (بعد المغرب):** يستدعي `_loadTomorrowTimes()`
3. `_loadTomorrowTimes()` يقرأ بيانات الغد من `prayer_times_2026.json`
4. يحدّث الودجت والبطاقة بأوقات الغد + اسم يوم الغد وتاريخه

### أسماء الأيام بالعربية
```dart
static String _arabicDayName(DateTime d) {
  const days = [
    'الاثنين','الثلاثاء','الأربعاء',
    'الخميس','الجمعة','السبت','الأحد'
  ];
  return days[d.weekday - 1]; // weekday: 1=Mon..7=Sun
}
```

### تنسيق التاريخ
```dart
static String _formatDate(DateTime d) {
  return '${d.day.toString().padLeft(2,'0')}/'
         '${d.month.toString().padLeft(2,'0')}/'
         '${d.year}';
}
```

---

## 11. نظام الألوان (Brand System)

### الألوان الأساسية (`lib/brand.dart`)

| الاسم | HEX | RGB | الاستخدام |
|---|---|---|---|
| `kBrandNavy` | `#1B3D6F` | (27, 61, 111) | النصوص والأيقونات — وضع فاتح |
| `kBrandGold` | `#C9A843` | (201, 168, 67) | النصوص والأيقونات — وضع داكن |

### دالة `brandColor(context)`
```dart
Color brandColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? kBrandGold
        : kBrandNavy;
```

### الملفات المُحدَّثة لدعم Dark Mode Gold

| الملف | العنصر المُحدَّث |
|---|---|
| `main.dart` | chips الشعائر |
| `mafatih_page.dart` | أيقونة البحث + نص التحميل |
| `hijri_calendar_page.dart` | اليوم المحدد + عنوان الأحداث |
| `ask_page.dart` | أيقونة السؤال + أزرار التعديل |
| `events_page.dart` | أيقونة التعديل + حقل التاريخ |
| `date_converter_page.dart` | أزرار التبديل + القيم |
| `trips_page.dart` | أيقونة التعديل + chips المعلومات |
| `campaigns_page.dart` | صندوق الإحصاء + زر الاتصال |
| `prayer_times_page.dart` | عنوان القسم |
| `social_media_page.dart` | العنوان الرئيسي |

---

## 12. أيقونة التطبيق

### الإعداد في `pubspec.yaml`
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  remove_alpha_ios: true
  adaptive_icon_background: "#1B3D6F"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

### خطوات التطبيق (لم تُنفَّذ بعد — تحتاج ملف PNG)
1. ضع صورة المسجد 1024×1024 px في `assets/icon/app_icon.png`
2. ضع نفس الصورة في `assets/icon/app_icon_foreground.png`
3. نفّذ في terminal المشروع:
   ```bash
   dart run flutter_launcher_icons
   ```
4. ابنِ التطبيق من جديد

---

## 13. الأصول (Assets)

| الأصل | المحتوى |
|---|---|
| `assets/prayer_times_2026.json` | أوقات الصلاة لكل يوم في 2026 (الفجر، الظهر، المغرب) |
| `assets/quran.json` | نص القرآن الكريم (114 سورة) |
| `assets/mafatih.json` | كتاب مفاتيح الجنان (الأدعية والزيارات) |
| `assets/fonts/ScheherazadeNew-Regular.ttf` | خط عربي للنصوص القرآنية |
| `assets/icon/app_icon.png` | أيقونة التطبيق 1024×1024 — **يجب إضافتها** |
| `assets/icon/app_icon_foreground.png` | طبقة الأيقونة التكيفية Android 8+ — **يجب إضافتها** |

---

## 14. الأمان (Security Architecture)

### آلية المصادقة
- كل طلب من التطبيق يحمل `X-API-Secret` header
- PHP يتحقق منه عبر `hash_equals()` (آمن من Timing Attacks)
- لوحة الإدارة: كلمة مرور + عبارة سرية

### الحماية في `.htaccess`
```apache
# يمنع تنزيل الملفات الحساسة مباشرة من المتصفح
<FilesMatch "\.(json|md|ini)$">
    Require all denied
</FilesMatch>
```

### ملفات مُستثناة من git
```gitignore
service-account.json    # مفتاح Firebase الخاص
pending_build.json      # ملف runtime
build_status.json       # ملف runtime
```

### ملاحظات أمنية مهمة
- `service-account.json` لا يُرفع إلى GitHub أبداً — يُرفع مباشرة لـ Hostinger
- GitHub PAT لا يُحفظ في الكود المصدري — فقط في `config.php` على Hostinger
- `.user.ini` محمي من التنزيل المباشر عبر `.htaccess`

---

## 15. سجل الـ Commits الكامل

```
0f24711  Add GitHub Actions auto-build pipeline — no local Flutter needed
42fdf36  Auto-build pipeline: admin panel triggers local server to build + publish APK
8a85abe  Web release: raise upload limit to 200M for large APKs
cf2cc97  Web admin: publish app releases (upload APK + bump version)
91ad90f  Dark mode: brand-navy text & icons now turn gold
6e37824  Set up flutter_launcher_icons for mosque app icon
c89bd6d  After Maghrib: show next-day Fajr + day name and date in widget and prayer card
326c32e  Web admin: photo slider tab (معرض الصور)
120fae4  Unify trips, robust call/WhatsApp buttons, sturdier adhan scheduling
b6b40d3  Mafatih: bold the recited dua, light the narration
0b6f9e9  Mafatih reader: nicer reading shape (text unchanged)
d91b7b8  Quran reader: compact audio bar so more text lines are visible
6c927f6  Q&A: stop the 'sending question' message from getting stuck
d70b858  Trips: show trips reliably regardless of how the date was stored
14ae094  Announcements edit in web panel + trip contacts get holder names
d0d0cfc  Quran: download-all surahs + playback speed (1x/1.5x/2x)
73725c2  Quran: let any user clear downloaded recitations to free storage
d32b2cf  Quran: admin-uploaded recitation per surah
1bf31d7  Trips: support multiple booking numbers
c0f3ce1  Home page scrolls as one — prayer time scrolls up instead of staying fixed
a80bc7e  Notification taps open the correct sub-page (trips, announcements, questions)
e4a1c98  Add edit for events/trips/questions and full-screen photo viewer
```

---

## 16. سجل المهام المنجزة

| # | المهمة | التفاصيل |
|---|---|---|
| 1 | بعد المغرب: عرض أوقات الغد | `_loadTomorrowTimes()` في `main.dart` |
| 2 | اسم اليوم والتاريخ في البطاقة والودجت | `_displayDayName` + `_displayDate` state vars |
| 3 | Dark Mode: ذهبي لكل النصوص الزرقاء | `brand.dart` + 10 ملفات محدثة |
| 4 | إعداد أيقونة التطبيق | `flutter_launcher_icons` في `pubspec.yaml` |
| 5 | رفع حد PHP upload إلى 200MB | `.user.ini` في مكانه على الخادم |
| 6 | لوحة إدارة: تبويب إصدار التطبيق | نموذج البناء + عرض الحالة + auto-refresh |
| 7 | GitHub Actions Workflow | `.github/workflows/build_release.yml` |
| 8 | الـ Workflow على `main` | مطلوب لـ workflow_dispatch API |
| 9 | `receive_build.php` | استقبال APK + تحديث version.json + FCM |
| 10 | `build_status.php` | GET/POST لحالة البناء |
| 11 | `build_deploy.sh` | سكريبت السيرفر المحلي (بديل اختياري) |
| 12 | معرض صور الشريط | تبويب في لوحة الإدارة |
| 13 | تعديل الفعاليات والرحلات والأسئلة | واجهة تعديل للمسؤول |
| 14 | عارض صور بملء الشاشة | `photo_viewer.dart` |
| 15 | تسريع تنزيل Quran | تنزيل جميع السور دفعة واحدة |
| 16 | سرعة تشغيل القرآن | 1x / 1.5x / 2x |
| 17 | إشعارات الأسئلة والإجابات | FCM لجهاز المسؤول + جهاز السائل |

---

## 17. المهام المتبقية (TODO)

| المهمة | الأولوية | الإجراء |
|---|---|---|
| تصحيح خطأ Token في `config.php` على Hostinger | 🔴 فوري | استبدل `Z1Qw` بـ `ZlQw` (L وليس 1) |
| إضافة `HOSTINGER_API_SECRET` في GitHub Secrets | 🔴 فوري | GitHub → Settings → Secrets → Actions |
| رفع ملفات السيرفر المحدثة لـ Hostinger | 🟡 مهم | `config.php`, `admin/index.php`, `receive_build.php`, `build_status.php`, `.user.ini` |
| إضافة أيقونة التطبيق PNG | 🟡 مهم | ضع في `assets/icon/` ثم نفّذ `dart run flutter_launcher_icons` |
| ربط API التاريخ الهجري | 🟢 مستقبلي | مؤجل بطلب المستخدم |
| بناء وإطلاق الإصدار 1.0.2 | 🟢 مستقبلي | بعد اكتمال الإعداد أعلاه |

---

## 18. `build_deploy.sh` — السيرفر المحلي (بديل اختياري)

> **ملاحظة:** هذا الملف للسيرفر المحلي فقط. GitHub Actions هو الحل الرئيسي لأن المستخدم لا يملك Flutter مُنصَّباً محلياً.

```bash
# الإعدادات التي تحتاج تعديل:
SERVER_URL="https://ahlulbaytmosque.site/app/server"
API_SECRET="ahlulbayt-masjid-2026-Kx9mPq7Lz3Wn8Rv"
REPO_DIR="$HOME/masjid_app"
GIT_BRANCH="claude/masjid-app-setup-MHlkW"
FLUTTER_BIN="$HOME/flutter/bin/flutter"
APK_FILE="app-arm64-v8a-release.apk"
```

**لتفعيله على سيرفر محلي:**
```bash
chmod +x build_deploy.sh
crontab -e
# أضف:
* * * * * /full/path/to/build_deploy.sh >> /full/path/to/build.log 2>&1
```

---

## 19. ملفات الإعداد في الـ Repository

```
as/
├── .github/
│   └── workflows/
│       └── build_release.yml          ← GitHub Actions pipeline
├── lib/
│   ├── main.dart                      ← الشاشة الرئيسية + منطق الصلاة
│   ├── brand.dart                     ← نظام الألوان (navy/gold)
│   ├── backend_config.dart            ← Backend class (Hostinger API)
│   ├── prayer_widget_service.dart     ← خدمة الودجت
│   ├── prayer_times_page.dart
│   ├── quran_page.dart
│   ├── mafatih_page.dart
│   ├── hijri_calendar_page.dart
│   ├── date_converter_page.dart
│   ├── qibla_page.dart
│   ├── events_page.dart
│   ├── trips_page.dart
│   ├── announcements_page.dart
│   ├── ask_page.dart
│   ├── campaigns_page.dart
│   ├── social_media_page.dart
│   ├── ziyarat_page.dart
│   ├── photo_viewer.dart
│   ├── analytics_service.dart
│   ├── notification_service.dart
│   └── islamic_background.dart
├── server/
│   ├── config.php                     ← الإعدادات المركزية
│   ├── send_notification.php
│   ├── upload_image.php
│   ├── receive_build.php              ← يستقبل APK من GitHub Actions
│   ├── build_status.php               ← حالة البناء
│   ├── version.json                   ← بيانات الإصدار الحالي
│   ├── .user.ini                      ← حد رفع 200MB
│   ├── .htaccess                      ← حماية الملفات
│   ├── .gitignore
│   ├── lib/
│   │   ├── fcm.php
│   │   └── firestore.php
│   └── admin/
│       ├── index.php                  ← لوحة الإدارة
│       └── .user.ini
├── assets/
│   ├── prayer_times_2026.json
│   ├── quran.json
│   ├── mafatih.json
│   ├── fonts/ScheherazadeNew-Regular.ttf
│   └── icon/
│       ├── app_icon.png               ← يجب إضافتها
│       └── app_icon_foreground.png    ← يجب إضافتها
├── android/
│   └── app/src/main/
│       ├── kotlin/.../MasjidWidgetProvider.kt
│       └── res/layout/masjid_widget.xml
├── pubspec.yaml
└── build_deploy.sh                    ← للسيرفر المحلي (اختياري)
```

---

*نهاية التقرير — جميع المعلومات دقيقة حتى تاريخ 2026-06-07*
