# 📱 دليل نشر التطبيق على المتاجر | Store Publishing Guide

دليل عملي خطوة بخطوة لرفع تطبيق "مسجد وحسينية أهل البيت" على **Google Play** (و App Store).

---

## الجزء الأول: Google Play (أندرويد) — الأسهل

### ✅ ما تحتاجه أولاً
1. حساب **Google Play Console** — رسوم **25$ مرة واحدة** فقط مدى الحياة.
   👉 سجّل من: https://play.google.com/console/signup
2. جهازك (Mac) مع Flutter — موجود ✓
3. ~30 دقيقة

---

### الخطوة 1 — إنشاء مفتاح التوقيع (Keystore) مرة واحدة

التطبيق يجب أن يكون "موقّعاً". نفّذ هذا الأمر **مرة واحدة فقط** واحفظ الملف جيداً:

```bash
keytool -genkey -v -keystore ~/masjid-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias masjid
```

- سيسألك عن كلمة مرور — **احفظها في مكان آمن** (لو ضاعت لا تستطيع تحديث التطبيق أبداً).
- ملف `masjid-release.jks` سينشأ في مجلد المستخدم (`~`).

> ⚠️ **مهم جداً**: احتفظ بنسخة احتياطية من `masjid-release.jks` وكلمة المرور. بدونها لا يمكن نشر أي تحديث مستقبلي.

---

### الخطوة 2 — ربط المفتاح بالمشروع

**أ)** أنشئ ملف `android/key.properties` (بجانب مجلد app) واكتب فيه:

```properties
storePassword=كلمة_المرور_التي_اخترتها
keyPassword=كلمة_المرور_التي_اخترتها
keyAlias=masjid
storeFile=/Users/ahmed/masjid-release.jks
```

**ب)** افتح `android/app/build.gradle.kts` وأضف **قبل** `android {`:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

**ج)** داخل `android { ... }` أضف بلوك التوقيع وعدّل buildType:

```kotlin
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
```

> 🔒 لا ترفع `key.properties` ولا `*.jks` إلى git أبداً (أضفهما لـ `.gitignore`).

---

### الخطوة 3 — رفع رقم الإصدار

في `pubspec.yaml` غيّر:
```yaml
version: 1.0.0+1
```
- الرقم قبل `+` = الإصدار الظاهر للناس (1.0.0).
- الرقم بعد `+` = رقم البناء (يجب أن يزيد مع **كل** رفعة جديدة: 1.0.0+2، 1.0.1+3 ...).

---

### الخطوة 4 — بناء ملف الرفع (App Bundle)

Google Play يطلب **.aab** (وليس APK):

```bash
cd ~/Desktop/masjid_app
flutter build appbundle --release
```

الناتج:
```
build/app/outputs/bundle/release/app-release.aab
```

---

### الخطوة 5 — الرفع على Play Console

1. ادخل https://play.google.com/console
2. **Create app** → اكتب الاسم "مسجد وحسينية أهل البيت" → عربي → مجاني.
3. من القائمة، أكمل المطلوب (Google يرشدك بقائمة تحقّق):
   - **App content**: سياسة الخصوصية، الفئة العمرية، الإعلانات (لا يوجد)، Data safety.
   - **Store listing**: الوصف، أيقونة 512×512، صورة غلاف 1024×500، **لقطات شاشة** (4+).
   - **Category**: Lifestyle أو Books & Reference.
4. **Production → Create new release** → ارفع `app-release.aab`.
5. اكتب ملاحظات الإصدار → **Review release** → **Start rollout to Production**.
6. المراجعة تأخذ عادة **بضع ساعات إلى 3 أيام**، ثم يظهر على المتجر. ✅

---

### تحديث التطبيق لاحقاً (سهل جداً)
1. زِد رقم البناء في `pubspec.yaml` (مثلاً `+2`).
2. `flutter build appbundle --release`
3. Play Console → Production → Create new release → ارفع الـ aab الجديد.

---

## الجزء الثاني: Apple App Store (آيفون) — اختياري

> يحتاج: جهاز Mac (عندك ✓) + **Apple Developer 99$/سنة** + Xcode.

خطوات مختصرة:
1. سجّل في https://developer.apple.com ($99/سنة).
2. أضف تطبيق iOS في Firebase Console وحمّل `GoogleService-Info.plist` إلى `ios/Runner/`.
3. افتح `ios/Runner.xcworkspace` في Xcode، اضبط Signing & Team.
4. `flutter build ipa --release`
5. ارفع عبر **Transporter** أو Xcode إلى **App Store Connect**.
6. املأ بيانات المتجر وأرسل للمراجعة.

> ملاحظة: iOS يحتاج إعداداً إضافياً (APNs للإشعارات، أذونات الموقع) لم يُجهّز بعد.

---

## نصائح مهمة | Important Tips

- 🔑 **احفظ keystore + كلمات المرور** في مكان آمن (Google Drive خاص مثلاً). فقدانها = لا تحديثات.
- 📸 جهّز **لقطات شاشة** من التطبيق وأيقونة عالية الدقة قبل البدء.
- 📝 تحتاج **سياسة خصوصية** (رابط) — يمكن إنشاؤها مجاناً من مواقع مثل freeprivacypolicy.com.
- 🌐 إذا أردت أتمتة البناء، أستطيع إعداد **GitHub Actions** لبناء الـ aab تلقائياً عند كل رفعة.

---

## أسرع طريق للنشر الآن
```bash
# 1. أنشئ المفتاح (مرة واحدة)
keytool -genkey -v -keystore ~/masjid-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias masjid

# 2. أضف key.properties + signingConfig (الخطوة 2 أعلاه)

# 3. ابنِ ملف الرفع
flutter build appbundle --release

# 4. ارفعه على play.google.com/console
```
