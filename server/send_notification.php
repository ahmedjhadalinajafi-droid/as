<?php
// ============================================================================
//  send_notification.php — the app calls this to send a push.
//
//  POST fields (JSON body or form):
//    secret : API_SECRET (or send header X-API-Secret)
//    type   : "new_question" | "answer"
//    title  : optional override
//    body   : preview text
//    token  : (answer only) the client's FCM token
// ============================================================================

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/lib/fcm.php';

// Accept either a JSON body or normal form fields.
$raw = file_get_contents('php://input');
$in  = json_decode($raw, true);
if (!is_array($in)) $in = $_POST;

// Auth (allow secret in body for JSON posts).
$sent = $_SERVER['HTTP_X_API_SECRET'] ?? ($in['secret'] ?? '');
if (!hash_equals(API_SECRET, (string)$sent)) {
    json_out(['ok' => false, 'error' => 'unauthorized'], 401);
}

$type = $in['type'] ?? '';
$body = trim((string)($in['body'] ?? ''));

try {
    if ($type === 'new_question') {
        $title = $in['title'] ?? 'سؤال جديد 📩';
        [$code, $res] = fcm_send(
            ['topic' => ADMIN_TOPIC],
            $title,
            $body !== '' ? $body : 'وصل سؤال جديد بانتظار الرد',
            ['page' => 'questions']
        );
        json_out(['ok' => $code === 200, 'code' => $code, 'res' => $res]);
    }

    if ($type === 'answer') {
        $token = trim((string)($in['token'] ?? ''));
        if ($token === '') json_out(['ok' => false, 'error' => 'missing token'], 400);
        $title = $in['title'] ?? 'تم الرد على سؤالك ✅';
        [$code, $res] = fcm_send(
            ['token' => $token],
            $title,
            $body !== '' ? $body : 'افتح التطبيق لمشاهدة الجواب',
            ['page' => 'questions']
        );
        json_out(['ok' => $code === 200, 'code' => $code, 'res' => $res]);
    }

    json_out(['ok' => false, 'error' => 'unknown type'], 400);
} catch (Throwable $e) {
    json_out(['ok' => false, 'error' => $e->getMessage()], 500);
}
