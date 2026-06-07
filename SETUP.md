# إعداد مسجد وحسينية أهل البيت

## 1. pubspec.yaml — إضافة الحزم الجديدة

أضف هذه الحزم إلى `pubspec.yaml` الحالي:

```yaml
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.3.0
  just_audio: ^0.9.36
  audio_session: ^0.1.18
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  hijri: ^2.0.1
```

ثم نفّذ:
```bash
flutter pub get
```

---

## 2. ملفات lib/ الجديدة والمحدّثة

انسخ هذه الملفات إلى `lib/` في مشروعك:

| الملف | الوصف |
|-------|-------|
| `main.dart` | التطبيق الرئيسي + إعداد Firebase + شريط التنقل السفلي |
| `notification_service.dart` | ✅ **جديد** — إشعارات FCM + محلية |
| `ziyarat_page.dart` | ✅ **جديد** — 8 زيارات إسلامية كاملة |
| `quran_page.dart` | ✅ **محدَّث** — مشغل صوتي + تنقل سور مُصلَح |
| `prayer_times_page.dart` | ✅ **محدَّث** — عداد تنازلي + جدول شهري |
| `hijri_calendar_page.dart` | ✅ **محدَّث** — تقويم كامل + مناسبات |
| `mafatih_page.dart` | ✅ **محدَّث** — قارئ بصفحات قابل للتمرير |
| `qibla_page.dart` | ✅ **محدَّث** — بوصلة بيانية محسّنة |
| `announcements_page.dart` | ✅ **محدَّث** — دعم رفع الصور |

---

## 3. AndroidManifest.xml

أضف داخل `<application>` في `android/app/src/main/AndroidManifest.xml`:

### FCM
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="announcements" />
```

### الودجت (Home Screen Widget)
```xml
<receiver
    android:name=".MasjidWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/masjid_widget_info" />
</receiver>
```

### الأذونات (في `<manifest>`)
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```

---

## 4. ملفات Android الجديدة

انسخ هذه الملفات إلى مشروعك:

```
android/app/src/main/kotlin/com/example/masjid_app/MasjidWidgetProvider.kt
android/app/src/main/res/layout/masjid_widget.xml
android/app/src/main/res/xml/masjid_widget_info.xml
android/app/src/main/res/drawable/widget_background.xml
android/app/src/main/res/values/strings.xml
```

> **تنبيه:** إذا كان اسم الحزمة (package name) مختلفاً عن `com.example.masjid_app`،
> غيّره في `MasjidWidgetProvider.kt` السطر الأول.

---

## 5. إعداد FCM في Firebase Console

1. افتح [Firebase Console](https://console.firebase.google.com) → مشروع `masjid-405c1`
2. **Project Settings → Cloud Messaging** → تأكد من تفعيل FCM API
3. للإرسال لجميع المستخدمين: استخدم **Topic** → `announcements`
4. لاختبار الإشعار:

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "/topics/announcements",
    "notification": {
      "title": "إعلان جديد",
      "body": "تفضلوا لزيارة المسجد..."
    },
    "data": {"type": "announcement"}
  }'
```

---

## 6. إضافة الودجت للشاشة الرئيسية

1. اضغط مطولاً على الشاشة الرئيسية للهاتف
2. اختر **Widgets**
3. ابحث عن **مسجد أهل البيت**
4. اسحبه وضعه في المكان المناسب

---

## 7. القرآن الصوتي

الصوت يُحمَّل تلقائياً من CDN:
```
https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/001.mp3
```
(المنشد: مشاري راشد العفاسي — يحتاج اتصال إنترنت)

---

## الميزات المكتملة ✅

- [x] الصفحة الرئيسية + شعار + أوقات الصلاة من Firebase
- [x] التقويم الهجري مع المناسبات الإسلامية
- [x] قارئ القرآن الكامل (offline)
- [x] قارئ المفاتيح (offline)
- [x] أوقات الصلاة من ملف JSON
- [x] بوصلة القبلة بـ GPS
- [x] الإعلانات مع رفع الصور
- [x] الوضع الليلي/النهاري
- [x] **إشعارات FCM** ✨
- [x] **صفحة الزيارات** (8 زيارات كاملة) ✨
- [x] **ودجت الشاشة الرئيسية** (أوقات الصلاة) ✨
- [x] **مشغل صوت القرآن** (مشاري العفاسي) ✨
- [x] **تنقل السور (السابقة/التالية) مُصلَح** ✨
