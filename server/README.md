# مسجد أهل البيت — Hostinger backend

This `server/` folder is a small PHP backend you upload to your Hostinger
hosting. It adds four things the free Firebase plan can't do on its own:

1. **Push notifications** that reach the admin/client even when the app is closed
2. **Image hosting** (no more 700 KB base64 limit)
3. **Update alerts** (`version.json` + APK hosting)
4. **A web admin panel** to manage events / announcements / questions

---

## 1. Get a Firebase service-account key (for push)

1. Open the [Firebase Console](https://console.firebase.google.com/) → your
   project → ⚙️ **Project settings** → **Service accounts**
2. Click **Generate new private key** → it downloads a JSON file
3. Rename it to **`service-account.json`**

## 2. Upload the files

Using Hostinger **hPanel → File Manager** (or FTP), upload the **contents** of
this `server/` folder into your site. Two common layouts:

- Into `public_html/`  → your URLs are `https://yoursite.com/send_notification.php`
- Into `public_html/app/` → your URLs are `https://yoursite.com/app/send_notification.php`

Then upload `service-account.json` next to `config.php`.
Make sure the `uploads/` folder exists and is writable (chmod 755).

## 3. Edit `config.php`

| Setting | Set it to |
|---|---|
| `API_SECRET` | any long random string (keep it secret) |
| `ADMIN_PASSWORD` | the password for the web admin panel |
| `FIREBASE_PROJECT_ID` | already set to `masjid-405c1` — change if different |
| `FIREBASE_API_KEY` | your Firebase **Web API key** |
| `UPLOAD_BASE_URL` | e.g. `https://yoursite.com/uploads` (or leave `null` to auto-detect) |

## 4. Point the app at your server

In **`lib/backend_config.dart`** set:

```dart
static const String baseUrl = 'https://yoursite.com';      // or .../app
static const String secret  = 'the SAME API_SECRET as config.php';
```

Rebuild the app. That's it — questions now push to admins, answers push to the
asker, and images upload to your domain.

## 5. Releasing a new version (APK) — from the web panel

You **build** the APK on your computer (Hostinger can't compile Flutter), then
**publish** it from the panel:

1. On your Mac/PC: `flutter build apk --release`
   (the file lands in `build/app/outputs/flutter-apk/app-release.apk`)
2. Open the admin panel → **إصدار التطبيق** tab
3. Choose the `app-release.apk` file, set the **version** (e.g. `1.0.2`) and
   bump the **build** number, write release notes, and press **نشر الإصدار**.
4. Leave **🔔 إرسال إشعار** checked to push an "update available" alert to
   everyone.

The panel saves the APK to your site root and rewrites `version.json`
automatically, so the app's launch check offers the new download.

> **Big APK (e.g. 60 MB)?** The included `.user.ini` files raise the upload
> limit to **200 MB**, so a 60 MB universal APK uploads fine. (LiteSpeed reads
> `.user.ini`; the change can take ~5 minutes to take effect after upload.)
> If it still fails, raise `upload_max_filesize` / `post_max_size` in hPanel →
> **PHP Configuration**.

### Smaller APK (optional)

The default `flutter build apk --release` makes one **universal** APK (~60 MB)
that contains every CPU architecture. To get much smaller files:

```bash
flutter build apk --split-per-abi
```

This produces separate APKs in `build/app/outputs/flutter-apk/`:

- `app-arm64-v8a-release.apk`  (~20 MB) — virtually all phones from the last
  ~7 years, including the OnePlus 9. **Upload this one.**
- `app-armeabi-v7a-release.apk` — only very old 32-bit phones.

Upload `app-arm64-v8a-release.apk` for a fast ~20 MB download. (Keep the
universal APK if you need to support very old 32-bit devices.)

You can still edit `version.json` by hand if you prefer.

## 6. Web admin panel

Open `https://yoursite.com/admin/` and log in with `ADMIN_PASSWORD`.
You can add/delete events & announcements and answer questions from the browser
(answering also pushes the notification to the asker).

---

### How push works (no Blaze plan needed)

- Admin devices subscribe to the FCM **topic** `admin_questions` (the app does
  this automatically when admin mode is on).
- When someone asks a question, the app calls `send_notification.php`, which
  uses your service-account to send an FCM push to that topic.
- When the admin answers, the app sends the asker's saved FCM token to
  `send_notification.php`, which pushes the answer to just that device.

### Security notes

- `.htaccess` blocks direct download of `config.php`, `service-account.json`
  and other `.json`/`.md` files (except `version.json`).
- The `uploads/.htaccess` disables PHP execution in the uploads folder.
- Every endpoint requires the `API_SECRET`. If you think it leaked, change it in
  both `config.php` and `lib/backend_config.dart`.
