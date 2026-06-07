<?php
// ============================================================================
//  build_status.php — polling endpoint for the local build server.
//
//  GET  (local server polls):  returns pending build request + current status.
//  POST (local server reports): updates the build status while it works.
//
//  Both require X-Api-Secret header matching config.php → API_SECRET.
// ============================================================================
require_once __DIR__ . '/config.php';
require_secret();

$pendingFile = __DIR__ . '/pending_build.json';
$statusFile  = __DIR__ . '/build_status.json';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $s = trim($_POST['set_status'] ?? '');
    $m = trim($_POST['message']    ?? '');
    if (!in_array($s, ['building', 'done', 'failed'], true)) {
        json_out(['ok' => false, 'error' => 'invalid status'], 400);
    }
    file_put_contents($statusFile, json_encode([
        'status'  => $s,
        'message' => $m,
        'updated' => date('c'),
    ]));
    json_out(['ok' => true]);
}

// GET — return everything the local server needs
$pending = null;
if (is_file($pendingFile)) {
    $raw = @file_get_contents($pendingFile);
    $pending = $raw ? json_decode($raw, true) : null;
}
$status = [];
if (is_file($statusFile)) {
    $raw = @file_get_contents($statusFile);
    $status = $raw ? (json_decode($raw, true) ?? []) : [];
}
$ver = [];
if (is_file(__DIR__ . '/version.json')) {
    $raw = @file_get_contents(__DIR__ . '/version.json');
    $ver = $raw ? (json_decode($raw, true) ?? []) : [];
}

json_out([
    'pending'         => $pending,
    'status'          => $status,
    'current_version' => $ver,
]);
