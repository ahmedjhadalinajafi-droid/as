<?php
// ============================================================================
//  upload_image.php — receives an image file, stores it, returns a public URL.
//
//  POST (multipart/form-data):
//    secret : API_SECRET (or header X-API-Secret)
//    image  : the file
//  Response: { "ok": true, "url": "https://.../uploads/abc.jpg" }
// ============================================================================

require_once __DIR__ . '/config.php';

require_secret();

if (!isset($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
    json_out(['ok' => false, 'error' => 'no file'], 400);
}

$file = $_FILES['image'];
if ($file['size'] > MAX_UPLOAD_BYTES) {
    json_out(['ok' => false, 'error' => 'file too large'], 413);
}

// Validate it is really an image and pick a safe extension.
$info = @getimagesize($file['tmp_name']);
if ($info === false) {
    json_out(['ok' => false, 'error' => 'not an image'], 400);
}
$ext = match ($info[2]) {
    IMAGETYPE_JPEG => 'jpg',
    IMAGETYPE_PNG  => 'png',
    IMAGETYPE_GIF  => 'gif',
    IMAGETYPE_WEBP => 'webp',
    default        => null,
};
if ($ext === null) {
    json_out(['ok' => false, 'error' => 'unsupported image type'], 400);
}

if (!is_dir(UPLOAD_DIR)) {
    @mkdir(UPLOAD_DIR, 0755, true);
}

$name = bin2hex(random_bytes(12)) . '.' . $ext;
$dest = UPLOAD_DIR . '/' . $name;
if (!move_uploaded_file($file['tmp_name'], $dest)) {
    json_out(['ok' => false, 'error' => 'save failed'], 500);
}

// Build the public URL.
$base = UPLOAD_BASE_URL;
if ($base === null) {
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
        ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
    $dir  = rtrim(dirname($_SERVER['SCRIPT_NAME']), '/');
    $base = "$scheme://$host$dir/uploads";
}

json_out(['ok' => true, 'url' => $base . '/' . $name]);
