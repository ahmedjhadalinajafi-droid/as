<?php
// ============================================================================
//  receive_build.php — called by the local build server after it finishes.
//
//  Accepts the built APK via multipart POST, saves it, rewrites version.json,
//  clears the pending flag, and optionally fires a push notification.
//
//  Required header:  X-Api-Secret: <API_SECRET from config.php>
//  Required POST:    apk (file), version, build, notes, mandatory, notify
// ============================================================================
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/lib/fcm.php';
require_secret();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_out(['ok' => false, 'error' => 'POST only'], 405);
}

// ── 1. Validate and save the APK ────────────────────────────────────────────
if (empty($_FILES['apk']) || $_FILES['apk']['error'] !== UPLOAD_ERR_OK) {
    $errCode = $_FILES['apk']['error'] ?? -1;
    json_out(['ok' => false, 'error' => "upload error code $errCode"], 400);
}

$fh    = @fopen($_FILES['apk']['tmp_name'], 'rb');
$magic = $fh ? fread($fh, 2) : '';
if ($fh) fclose($fh);
if ($magic !== 'PK') {
    json_out(['ok' => false, 'error' => 'invalid apk (not a zip)'], 400);
}

$dest = __DIR__ . '/app-release.apk';
if (!move_uploaded_file($_FILES['apk']['tmp_name'], $dest)) {
    json_out(['ok' => false, 'error' => 'could not save apk to server'], 500);
}

// ── 2. Rewrite version.json ──────────────────────────────────────────────────
$scheme  = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$host    = $_SERVER['HTTP_HOST'] ?? 'localhost';
$dir     = rtrim(dirname($_SERVER['SCRIPT_NAME']), '/');
$apkUrl  = "$scheme://$host$dir/app-release.apk";

$version   = trim($_POST['version']   ?? '1.0.0');
$build     = max(1, (int)($_POST['build'] ?? 1));
$notes     = trim($_POST['notes']     ?? '');
$mandatory = in_array(strtolower($_POST['mandatory'] ?? 'false'), ['true','1','yes'], true);
$notify    = in_array(strtolower($_POST['notify']    ?? '1'),     ['true','1','yes'], true);

if ($notes === '') {
    $notes = 'أحدث إصدار من تطبيق مسجد وحسينية أهل البيت';
}

$versionData = [
    'version'   => $version,
    'build'     => $build,
    'url'       => $apkUrl,
    'mandatory' => $mandatory,
    'notes'     => $notes,
];
file_put_contents(
    __DIR__ . '/version.json',
    json_encode($versionData, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)
);

// ── 3. Clear pending flag + write final status ───────────────────────────────
@unlink(__DIR__ . '/pending_build.json');
file_put_contents(__DIR__ . '/build_status.json', json_encode([
    'status'  => 'done',
    'message' => "✅ تم نشر الإصدار $version (build $build)",
    'updated' => date('c'),
    'version' => $version,
    'build'   => $build,
    'apk_url' => $apkUrl,
]));

// ── 4. Push notification to all users (optional) ────────────────────────────
$pushResult = 'skipped';
if ($notify && defined('BROADCAST_TOPIC')) {
    try {
        [$code, $res] = fcm_send(
            ['topic' => BROADCAST_TOPIC],
            'تحديث متوفر 🚀',
            "الإصدار $version متوفر الآن — اضغط للتحديث",
            ['page' => 'home']
        );
        $pushResult = $code === 200 ? 'ok' : "failed(code=$code): $res";
    } catch (Throwable $e) {
        $pushResult = 'error: ' . $e->getMessage();
    }
}

json_out([
    'ok'      => true,
    'version' => $version,
    'build'   => $build,
    'url'     => $apkUrl,
    'push'    => $pushResult,
]);
