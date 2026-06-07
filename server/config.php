<?php
// ============================================================================
//  config.php — central settings for the مسجد أهل البيت backend
//  Edit the values in this file after uploading to Hostinger.
// ============================================================================

// A shared secret the app sends with every request. Pick any long random
// string and put the SAME value in the Flutter app (lib/backend_config.dart →
// kBackendSecret). This stops strangers from abusing your endpoints.
const API_SECRET = 'ahlulbayt-masjid-2026-Kx9mPq7Lz3Wn8Rv';

// Password for the web admin panel (server/admin/). Change this to your own.
const ADMIN_PASSWORD = 'Masjid@Admin2026';

// Path to your Firebase service-account JSON (see README step 1).
// Keep it OUTSIDE public_html if you can; otherwise the .htaccess here blocks
// direct download of *.json.
const SERVICE_ACCOUNT_FILE = __DIR__ . '/service-account.json';

// Your Firebase project id (also inside the service-account file).
const FIREBASE_PROJECT_ID = 'masjid-405c1';

// Firebase Web API key — used by the admin panel to read/write Firestore over
// REST. Firestore rules are open (allow if true), so this is enough.
const FIREBASE_API_KEY = 'AIzaSyDXZ5eeDDV4Bv1UT281nvXdjTBDs-DfXZY';

// FCM topic that admin devices subscribe to. New-question pushes go here.
const ADMIN_TOPIC = 'admin_questions';

// FCM topic that EVERY app user subscribes to. Broadcast pushes (new event,
// new trip, new announcement, custom messages) go here so all devices get them.
const BROADCAST_TOPIC = 'announcements';

// Where uploaded images are stored and served from.
const UPLOAD_DIR = __DIR__ . '/uploads';
// Public base URL of the uploads folder. Set this to match your domain, e.g.
// 'https://yoursite.com/uploads'. Leave as null to auto-detect.
const UPLOAD_BASE_URL = 'https://ahlulbaytmosque.site/app/server/uploads';

// Max upload size in bytes (5 MB).
const MAX_UPLOAD_BYTES = 5 * 1024 * 1024;

// GitHub Personal Access Token — used to trigger the "Build & Deploy APK"
// GitHub Actions workflow from the admin panel.
// Create one at: https://github.com/settings/tokens/new
//   → Select scope: "Actions" → workflow (read + write)
// Paste the token here (starts with ghp_ or github_pat_).
const GITHUB_TOKEN = '';   // ← paste your token here

// GitHub repo that holds the workflow (owner/repo format).
const GITHUB_REPO = 'ahmedjhadalinajafi-droid/as';

// The workflow file name inside .github/workflows/.
const GITHUB_WORKFLOW = 'build_release.yml';

// The branch the workflow checks out and builds from.
const GITHUB_BRANCH = 'claude/masjid-app-setup-MHlkW';

// --- helpers ---------------------------------------------------------------

function require_secret(): void {
    $sent = $_SERVER['HTTP_X_API_SECRET']
        ?? ($_POST['secret'] ?? ($_GET['secret'] ?? ''));
    if (!hash_equals(API_SECRET, (string)$sent)) {
        http_response_code(401);
        header('Content-Type: application/json');
        echo json_encode(['ok' => false, 'error' => 'unauthorized']);
        exit;
    }
}

function json_out($data, int $code = 200): void {
    http_response_code($code);
    header('Content-Type: application/json');
    echo json_encode($data);
    exit;
}
