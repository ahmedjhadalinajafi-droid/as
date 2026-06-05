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

## 5. (Optional) Update alerts + APK

1. Build the APK: `flutter build apk --release`
2. Upload `app-release.apk` to your site (e.g. next to `version.json`)
3. Edit `version.json`: bump `build` to match `pubspec.yaml` (`1.0.1+2` → build `2`)
   and set `url` to the APK link.

When you later release a new build, raise `build` in `version.json` and the app
shows an "update available" dialog on launch.

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
