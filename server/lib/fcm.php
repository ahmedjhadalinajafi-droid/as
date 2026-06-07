<?php
// ============================================================================
//  fcm.php — sends push notifications via Firebase Cloud Messaging HTTP v1.
//  Authenticates with a service-account JSON (no Blaze plan required).
// ============================================================================

require_once __DIR__ . '/../config.php';

// Returns a cached OAuth2 access token for the service account, refreshing it
// when it is close to expiry. Token is cached in a temp file for ~50 minutes.
function fcm_access_token(): string {
    $cacheFile = sys_get_temp_dir() . '/masjid_fcm_token.json';
    if (is_file($cacheFile)) {
        $c = json_decode((string)file_get_contents($cacheFile), true);
        if (is_array($c) && ($c['exp'] ?? 0) > time() + 60) {
            return $c['token'];
        }
    }

    if (!is_file(SERVICE_ACCOUNT_FILE)) {
        throw new RuntimeException('service-account.json not found');
    }
    $sa = json_decode((string)file_get_contents(SERVICE_ACCOUNT_FILE), true);
    if (!isset($sa['client_email'], $sa['private_key'])) {
        throw new RuntimeException('invalid service-account.json');
    }

    $now = time();
    $header  = ['alg' => 'RS256', 'typ' => 'JWT'];
    $claims  = [
        'iss'   => $sa['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud'   => 'https://oauth2.googleapis.com/token',
        'iat'   => $now,
        'exp'   => $now + 3600,
    ];

    $b64 = fn($d) => rtrim(strtr(base64_encode($d), '+/', '-_'), '=');
    $unsigned = $b64(json_encode($header)) . '.' . $b64(json_encode($claims));

    $signature = '';
    openssl_sign($unsigned, $signature, $sa['private_key'], 'sha256WithRSAEncryption');
    $jwt = $unsigned . '.' . $b64($signature);

    $ch = curl_init('https://oauth2.googleapis.com/token');
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion'  => $jwt,
        ]),
    ]);
    $res  = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    $data = json_decode((string)$res, true);
    if ($code !== 200 || !isset($data['access_token'])) {
        throw new RuntimeException('token exchange failed: ' . $res);
    }

    file_put_contents($cacheFile, json_encode([
        'token' => $data['access_token'],
        'exp'   => $now + (int)($data['expires_in'] ?? 3600),
    ]));
    return $data['access_token'];
}

// Sends one FCM message. $target is ['token' => '...'] or ['topic' => '...'].
// Returns [httpCode, responseBody].
function fcm_send(array $target, string $title, string $body, array $data = []): array {
    $token = fcm_access_token();

    $message = [
        'notification' => ['title' => $title, 'body' => $body],
        'data'         => array_map('strval', $data),
        'android'      => [
            'priority'     => 'high',
            'notification' => ['channel_id' => 'announcements'],
        ],
        'apns' => [
            'payload' => ['aps' => ['sound' => 'default']],
        ],
    ];
    if (isset($target['token'])) {
        $message['token'] = $target['token'];
    } elseif (isset($target['topic'])) {
        $message['topic'] = $target['topic'];
    } else {
        throw new InvalidArgumentException('target needs token or topic');
    }

    $url = 'https://fcm.googleapis.com/v1/projects/'
        . FIREBASE_PROJECT_ID . '/messages:send';

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_HTTPHEADER     => [
            'Authorization: Bearer ' . $token,
            'Content-Type: application/json',
        ],
        CURLOPT_POSTFIELDS     => json_encode(['message' => $message]),
    ]);
    $res  = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return [$code, $res];
}
