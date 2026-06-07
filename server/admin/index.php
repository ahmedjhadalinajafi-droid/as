<?php
// ============================================================================
//  admin/index.php — browser admin panel for events, announcements, questions.
//  Login with ADMIN_PASSWORD from config.php. Talks to Firestore over REST.
// ============================================================================

session_start();
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../lib/firestore.php';
require_once __DIR__ . '/../lib/fcm.php';

// ---- auth ----------------------------------------------------------------
if (isset($_POST['login'])) {
    if (hash_equals(ADMIN_PASSWORD, (string)($_POST['password'] ?? ''))) {
        $_SESSION['admin'] = true;
    } else {
        $loginError = 'كلمة المرور غير صحيحة';
    }
}
if (isset($_GET['logout'])) {
    session_destroy();
    header('Location: index.php');
    exit;
}
$authed = !empty($_SESSION['admin']);

// Saves an uploaded image (if any) to the uploads folder, returns its URL or ''.
function admin_save_image(string $field): string {
    if (empty($_FILES[$field]) || $_FILES[$field]['error'] !== UPLOAD_ERR_OK) {
        return '';
    }
    $info = @getimagesize($_FILES[$field]['tmp_name']);
    if ($info === false) return '';
    $ext = match ($info[2]) {
        IMAGETYPE_JPEG => 'jpg', IMAGETYPE_PNG => 'png',
        IMAGETYPE_GIF  => 'gif', IMAGETYPE_WEBP => 'webp', default => null,
    };
    if ($ext === null) return '';
    if (!is_dir(UPLOAD_DIR)) @mkdir(UPLOAD_DIR, 0755, true);
    $name = bin2hex(random_bytes(10)) . '.' . $ext;
    if (!move_uploaded_file($_FILES[$field]['tmp_name'], UPLOAD_DIR . '/' . $name)) {
        return '';
    }
    return upload_public_url($name);
}

// Builds the public URL for a file saved in the uploads/ folder.
function upload_public_url(string $name): string {
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host   = $_SERVER['HTTP_HOST'] ?? 'localhost';
    // admin/ is one level below the server root that holds uploads/
    $dir    = rtrim(dirname(dirname($_SERVER['SCRIPT_NAME'])), '/');
    return "$scheme://$host$dir/uploads/$name";
}

// Saves an uploaded Quran recitation (mp3/m4a/ogg/wav/aac), returns URL or ''.
function admin_save_audio(string $field): string {
    if (empty($_FILES[$field]) || $_FILES[$field]['error'] !== UPLOAD_ERR_OK) {
        return '';
    }
    $size = (int)($_FILES[$field]['size'] ?? 0);
    if ($size <= 0 || $size > 50 * 1024 * 1024) return ''; // 50 MB cap
    $ext = strtolower(pathinfo($_FILES[$field]['name'] ?? '', PATHINFO_EXTENSION));
    if (!in_array($ext, ['mp3', 'm4a', 'ogg', 'wav', 'aac'], true)) return '';
    if (!is_dir(UPLOAD_DIR)) @mkdir(UPLOAD_DIR, 0755, true);
    $name = 'quran_' . bin2hex(random_bytes(8)) . '.' . $ext;
    if (!move_uploaded_file($_FILES[$field]['tmp_name'], UPLOAD_DIR . '/' . $name)) {
        return '';
    }
    return upload_public_url($name);
}

// Saves an uploaded Android APK to the server root as app-release.apk and
// returns its public URL, or '' on failure. APKs are ZIP files, so we verify
// the "PK" signature instead of trusting the extension alone.
function admin_save_apk(string $field): string {
    if (empty($_FILES[$field]) || $_FILES[$field]['error'] !== UPLOAD_ERR_OK) {
        return '';
    }
    $ext = strtolower(pathinfo($_FILES[$field]['name'] ?? '', PATHINFO_EXTENSION));
    if ($ext !== 'apk') return '';
    $fh = @fopen($_FILES[$field]['tmp_name'], 'rb');
    if ($fh === false) return '';
    $magic = fread($fh, 2);
    fclose($fh);
    if ($magic !== 'PK') return ''; // not a valid zip/apk
    // Save at the server root (one level above admin/), matching version.json url.
    $dest = dirname(__DIR__) . '/app-release.apk';
    if (!move_uploaded_file($_FILES[$field]['tmp_name'], $dest)) return '';
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host   = $_SERVER['HTTP_HOST'] ?? 'localhost';
    $dir    = rtrim(dirname(dirname($_SERVER['SCRIPT_NAME'])), '/');
    return "$scheme://$host$dir/app-release.apk";
}

// Path to the version manifest the app checks for updates.
function version_file(): string { return dirname(__DIR__) . '/version.json'; }

// Reads the current version.json (or sensible defaults).
function read_version(): array {
    $raw = @file_get_contents(version_file());
    $v = $raw ? json_decode($raw, true) : null;
    if (!is_array($v)) $v = [];
    return $v + [
        'version'   => '1.0.0',
        'build'     => 1,
        'url'       => '',
        'mandatory' => false,
        'notes'     => '',
    ];
}

// Sends a broadcast push to all app users. Never throws — push failures
// should not block content from being saved. Returns 'ok' on success or a
// short diagnostic string describing what went wrong.
function broadcast_push(string $title, string $body, string $page): string {
    if (!defined('BROADCAST_TOPIC')) {
        return 'config.php قديم: لم يتم العثور على BROADCAST_TOPIC — أعد رفع config.php';
    }
    try {
        [$code, $res] = fcm_send(['topic' => BROADCAST_TOPIC], $title, $body, ['page' => $page]);
        return $code === 200 ? 'ok' : "FCM فشل (رمز $code): $res";
    } catch (Throwable $e) {
        return 'خطأ: ' . $e->getMessage();
    }
}

// Turns a Firestore [code, data] result into a flash message, surfacing the
// real error when a write fails (instead of pretending it succeeded).
function fs_flash(array $res, string $okMsg): string {
    [$code, $data] = $res;
    if ($code === 200) return '✅ ' . $okMsg;
    $err = $data['error']['message'] ?? json_encode($data, JSON_UNESCAPED_UNICODE);
    return "❌ فشلت العملية (رمز $code): $err";
}

// ---- actions (only when logged in) ---------------------------------------
$flash = '';
if ($authed && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    // When an upload is bigger than the server's post_max_size, PHP discards
    // the whole body so $_POST/$_FILES come back empty. Detect that and tell
    // the admin to raise the limit instead of failing silently.
    if ($action === '' && empty($_FILES)
        && (int)($_SERVER['CONTENT_LENGTH'] ?? 0) > 0) {
        $flash = '❌ حجم الملف أكبر من الحد المسموح في الاستضافة. ارفع الحد من '
            . 'لوحة Hostinger ‹ PHP Configuration › upload_max_filesize و '
            . 'post_max_size إلى حجم أكبر من حجم الـ APK، ثم أعد المحاولة.';
    }

    if ($action === 'add_event') {
        $img = admin_save_image('image');
        $dt  = $_POST['date'] ? new DateTime($_POST['date']) : new DateTime();
        $title = trim($_POST['title'] ?? '');
        $res = fs_add('events', [
            'title'       => $title,
            'description' => trim($_POST['description'] ?? ''),
            'location'    => trim($_POST['location'] ?? ''),
            'category'    => $_POST['category'] ?? 'فعالية',
            'imageUrl'    => $img,
            'boosted'     => isset($_POST['boosted']),
            'date'        => $dt,
            'createdAt'   => new DateTime(),
        ]);
        if ($res[0] === 200 && isset($_POST['notify'])) {
            broadcast_push('فعالية جديدة 🗓️', $title, 'events');
        }
        $flash = fs_flash($res, 'تمت إضافة الفعالية');
    }

    if ($action === 'delete_event') {
        fs_delete('events', $_POST['id']);
        $flash = 'تم حذف الفعالية';
    }

    if ($action === 'add_trip') {
        $img = admin_save_image('image');
        $dt  = $_POST['date'] ? new DateTime($_POST['date']) : new DateTime();
        $title = trim($_POST['title'] ?? '');
        $dest  = trim($_POST['destination'] ?? '');
        $res = fs_add('trips', [
            'title'       => $title,
            'description' => trim($_POST['description'] ?? ''),
            'destination' => $dest,
            'cost'        => trim($_POST['cost'] ?? ''),
            'contact'     => trim($_POST['contact'] ?? ''),
            'imageUrl'    => $img,
            'boosted'     => isset($_POST['boosted']),
            'date'        => $dt,
            'createdAt'   => new DateTime(),
        ]);
        if ($res[0] === 200 && isset($_POST['notify'])) {
            $b = $dest !== '' ? "$title — $dest" : $title;
            broadcast_push('رحلة جديدة 🚌', $b, 'trips');
        }
        $flash = fs_flash($res, 'تمت إضافة الرحلة');
    }

    if ($action === 'delete_trip') {
        fs_delete('trips', $_POST['id']);
        $flash = 'تم حذف الرحلة';
    }

    if ($action === 'add_announcement') {
        $img = admin_save_image('image');
        $title = trim($_POST['title'] ?? '');
        $bodyText = trim($_POST['body'] ?? '');
        $res = fs_add('announcements', [
            'title'     => $title,
            'body'      => $bodyText,
            'imageUrl'  => $img,
            'linkUrl'   => trim($_POST['link'] ?? ''),
            'createdAt' => new DateTime(),
        ]);
        if ($res[0] === 200 && isset($_POST['notify'])) {
            broadcast_push(
                $title !== '' ? $title : 'إعلان جديد 📢',
                $bodyText !== '' ? $bodyText : 'تم نشر إعلان جديد',
                'announcements'
            );
        }
        $flash = fs_flash($res, 'تمت إضافة الإعلان');
    }

    if ($action === 'delete_announcement') {
        fs_delete('announcements', $_POST['id']);
        $flash = 'تم حذف الإعلان';
    }

    if ($action === 'send_broadcast') {
        $title = trim($_POST['title'] ?? '');
        $bodyText = trim($_POST['body'] ?? '');
        if ($bodyText !== '' || $title !== '') {
            $result = broadcast_push(
                $title !== '' ? $title : 'مسجد وحسينية أهل البيت',
                $bodyText !== '' ? $bodyText : 'لديك إشعار جديد',
                trim($_POST['page'] ?? 'announcements')
            );
            $flash = $result === 'ok'
                ? '✅ تم إرسال الإشعار بنجاح لجميع المستخدمين'
                : '❌ ' . $result;
        } else {
            $flash = 'يرجى كتابة نص الإشعار';
        }
    }

    if ($action === 'answer_question') {
        $img = admin_save_image('image');
        $fields = [
            'answer'     => trim($_POST['answer'] ?? ''),
            'status'     => 'answered',
            'answeredAt' => new DateTime(),
        ];
        if ($img !== '') $fields['answerImageUrl'] = $img;
        $res = fs_update('questions', $_POST['id'], $fields);

        // Push the answer to the client who asked.
        $token = trim($_POST['clientToken'] ?? '');
        if ($res[0] === 200 && $token !== '') {
            try {
                $a = $fields['answer'];
                fcm_send(['token' => $token], 'تم الرد على سؤالك ✅',
                    mb_strlen($a) > 80 ? mb_substr($a, 0, 80) . '…' : $a,
                    ['page' => 'questions']);
            } catch (Throwable $e) { /* ignore push errors */ }
        }
        $flash = fs_flash($res, 'تم نشر الجواب');
    }

    if ($action === 'delete_question') {
        fs_delete('questions', $_POST['id']);
        $flash = 'تم حذف السؤال';
    }

    if ($action === 'edit_event') {
        $fields = [
            'title'       => trim($_POST['title'] ?? ''),
            'description' => trim($_POST['description'] ?? ''),
            'location'    => trim($_POST['location'] ?? ''),
            'category'    => $_POST['category'] ?? 'فعالية',
            'boosted'     => isset($_POST['boosted']),
            'date'        => $_POST['date'] ? new DateTime($_POST['date']) : new DateTime(),
        ];
        $img = admin_save_image('image');
        if ($img !== '') $fields['imageUrl'] = $img;
        $res = fs_update('events', $_POST['id'], $fields);
        $flash = fs_flash($res, 'تم تعديل الفعالية');
    }

    if ($action === 'edit_trip') {
        $fields = [
            'title'       => trim($_POST['title'] ?? ''),
            'description' => trim($_POST['description'] ?? ''),
            'destination' => trim($_POST['destination'] ?? ''),
            'cost'        => trim($_POST['cost'] ?? ''),
            'contact'     => trim($_POST['contact'] ?? ''),
            'boosted'     => isset($_POST['boosted']),
            'date'        => $_POST['date'] ? new DateTime($_POST['date']) : new DateTime(),
        ];
        $img = admin_save_image('image');
        if ($img !== '') $fields['imageUrl'] = $img;
        $res = fs_update('trips', $_POST['id'], $fields);
        $flash = fs_flash($res, 'تم تعديل الرحلة');
    }

    if ($action === 'edit_announcement') {
        $fields = [
            'title'   => trim($_POST['title'] ?? ''),
            'body'    => trim($_POST['body'] ?? ''),
            'linkUrl' => trim($_POST['link'] ?? ''),
        ];
        $img = admin_save_image('image');
        if ($img !== '') $fields['imageUrl'] = $img;
        $res = fs_update('announcements', $_POST['id'], $fields);
        $flash = fs_flash($res, 'تم تعديل الإعلان');
    }

    if ($action === 'edit_question') {
        $res = fs_update('questions', $_POST['id'],
            ['question' => trim($_POST['question'] ?? '')]);
        $flash = fs_flash($res, 'تم تعديل نص السؤال');
    }

    if ($action === 'set_quran_audio') {
        $num = (int)($_POST['surah'] ?? 0);
        if ($num < 1 || $num > 114) {
            $flash = '❌ رقم السورة يجب أن يكون بين 1 و 114';
        } else {
            $audio = admin_save_audio('audio');
            if ($audio === '') {
                $flash = '❌ تعذّر رفع الملف الصوتي (الصيغة mp3 والحجم أقل من 50 ميجا)';
            } else {
                $res = fs_update('quran_audio', (string)$num,
                    ['url' => $audio, 'updatedAt' => new DateTime()]);
                $flash = fs_flash($res, "تم رفع تلاوة سورة رقم $num");
            }
        }
    }

    if ($action === 'delete_quran_audio') {
        fs_delete('quran_audio', (string)(int)($_POST['surah'] ?? 0));
        $flash = 'تم حذف التلاوة';
    }

    if ($action === 'add_slide') {
        // Use an uploaded file if given, otherwise a pasted image URL.
        $img = admin_save_image('image');
        if ($img === '') $img = trim($_POST['imageUrl'] ?? '');
        if ($img === '') {
            $flash = '❌ ارفع صورة أو ألصق رابط صورة';
        } else {
            $res = fs_add('home_slider', [
                'imageUrl'  => $img,
                'title'     => trim($_POST['title'] ?? ''),
                'order'     => (int)($_POST['order'] ?? 0),
                'createdAt' => new DateTime(),
            ]);
            $flash = fs_flash($res, 'تمت إضافة الصورة إلى السلايدر');
        }
    }

    if ($action === 'delete_slide') {
        fs_delete('home_slider', $_POST['id']);
        $flash = 'تم حذف الصورة من السلايدر';
    }

    if ($action === 'publish_release') {
        $cur = read_version();
        // Keep the old APK url unless a new file was uploaded successfully.
        $url = $cur['url'];
        $uploadErr = '';
        if (!empty($_FILES['apk']['name'])) {
            $saved = admin_save_apk('apk');
            if ($saved === '') {
                $uploadErr = 'تعذّر رفع ملف الـ APK (تأكد أنه ملف .apk صالح وأن '
                    . 'حد الرفع في الاستضافة يكفي لحجمه).';
            } else {
                $url = $saved;
            }
        }
        if ($uploadErr) {
            $flash = '❌ ' . $uploadErr;
        } else {
            $version = trim($_POST['version'] ?? $cur['version']);
            $build   = (int)($_POST['build'] ?? $cur['build']);
            $notes   = trim($_POST['notes'] ?? '');
            $data = [
                'version'   => $version !== '' ? $version : $cur['version'],
                'build'     => $build > 0 ? $build : $cur['build'],
                'url'       => $url,
                'mandatory' => isset($_POST['mandatory']),
                'notes'     => $notes !== '' ? $notes
                    : 'أحدث إصدار من تطبيق مسجد وحسينية أهل البيت',
            ];
            $ok = @file_put_contents(
                version_file(),
                json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)
            );
            if ($ok === false) {
                $flash = '❌ تعذّر حفظ version.json (تحقق من صلاحيات الكتابة على المجلد).';
            } else {
                $flash = '✅ تم نشر الإصدار ' . h($data['version'])
                    . ' (build ' . $data['build'] . ')';
                if (isset($_POST['notify'])) {
                    $r = broadcast_push('تحديث متوفر 🚀',
                        'إصدار جديد من التطبيق متوفر الآن — اضغط للتحديث', 'home');
                    $flash .= $r === 'ok'
                        ? ' — وأُرسل إشعار التحديث'
                        : ' — لكن فشل إرسال الإشعار: ' . h($r);
                }
            }
        }
    }
}

function h($s): string { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

// Converts a stored Firestore ISO timestamp into a value for <input
// type="datetime-local"> (Y-m-d\TH:i), or '' when absent/invalid.
function dt_local($iso): string {
    if (!$iso) return '';
    try { return (new DateTime((string)$iso))->format('Y-m-d\TH:i'); }
    catch (Throwable $e) { return ''; }
}

$tab = $_GET['tab'] ?? 'events';
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>لوحة إدارة مسجد أهل البيت</title>
<style>
  :root { --navy:#1B3D6F; --gold:#C9A843; }
  * { box-sizing:border-box; font-family:'Segoe UI',Tahoma,Arial,sans-serif; }
  body { margin:0; background:#0f2240; color:#fff; }
  header { background:var(--navy); padding:16px 20px; display:flex;
           justify-content:space-between; align-items:center; }
  header h1 { font-size:18px; margin:0; }
  header a { color:#fff; text-decoration:none; opacity:.8; font-size:14px; }
  .tabs { display:flex; gap:8px; padding:14px 20px; background:#15315c; }
  .tabs a { padding:8px 16px; border-radius:10px; text-decoration:none;
            color:#cfe0f5; font-weight:bold; }
  .tabs a.active { background:var(--gold); color:#1a1a1a; }
  .wrap { padding:20px; max-width:900px; margin:auto; }
  .card { background:#fff; color:#1a2540; border-radius:14px; padding:16px;
          margin-bottom:14px; }
  .card img { max-width:100%; border-radius:10px; margin-bottom:8px; }
  input, textarea, select { width:100%; padding:10px; margin:6px 0 12px;
          border:1px solid #ccd; border-radius:10px; font-size:15px; }
  label { font-weight:bold; font-size:14px; }
  button { background:var(--navy); color:#fff; border:0; padding:11px 18px;
           border-radius:10px; font-weight:bold; cursor:pointer; font-size:15px; }
  button.danger { background:#c62828; padding:7px 12px; font-size:13px; }
  a.editbtn { background:var(--gold); color:#1a1a1a; padding:7px 12px;
              border-radius:10px; font-size:13px; font-weight:bold;
              text-decoration:none; display:inline-block; }
  .actions { display:flex; gap:6px; align-items:center; }
  .cancel { color:#5a6b88; text-decoration:none; margin-right:10px; font-size:14px; }
  .flash { background:#1b7a4b; padding:10px 16px; border-radius:10px;
           margin:14px 20px; }
  .muted { color:#5a6b88; font-size:13px; }
  .row { display:flex; gap:10px; align-items:center; justify-content:space-between; }
  .login { max-width:360px; margin:80px auto; background:#fff; color:#1a2540;
           padding:28px; border-radius:16px; }
  .pending { border-right:4px solid var(--gold); }
  .answered { border-right:4px solid #1b7a4b; }
</style>
</head>
<body>
<?php if (!$authed): ?>
  <div class="login">
    <h2 style="margin-top:0;color:var(--navy)">لوحة الإدارة</h2>
    <?php if (!empty($loginError)): ?>
      <p style="color:#c62828"><?= h($loginError) ?></p>
    <?php endif; ?>
    <form method="post">
      <label>كلمة المرور</label>
      <input type="password" name="password" autofocus>
      <button name="login" value="1" style="width:100%">دخول</button>
    </form>
  </div>
<?php else: ?>
  <header>
    <h1>🕌 لوحة إدارة مسجد وحسينية أهل البيت</h1>
    <a href="?logout=1">تسجيل الخروج</a>
  </header>
  <div class="tabs">
    <a href="?tab=events" class="<?= $tab==='events'?'active':'' ?>">الفعاليات</a>
    <a href="?tab=trips" class="<?= $tab==='trips'?'active':'' ?>">الرحلات</a>
    <a href="?tab=announcements" class="<?= $tab==='announcements'?'active':'' ?>">الإعلانات</a>
    <a href="?tab=questions" class="<?= $tab==='questions'?'active':'' ?>">الأسئلة</a>
    <a href="?tab=slider" class="<?= $tab==='slider'?'active':'' ?>">معرض الصور</a>
    <a href="?tab=quran" class="<?= $tab==='quran'?'active':'' ?>">القرآن</a>
    <a href="?tab=notify" class="<?= $tab==='notify'?'active':'' ?>">الإشعارات</a>
    <a href="?tab=release" class="<?= $tab==='release'?'active':'' ?>">إصدار التطبيق</a>
  </div>
  <?php if ($flash): ?><div class="flash"><?= h($flash) ?></div><?php endif; ?>
  <div class="wrap">

  <?php if ($tab === 'events'):
      $cats = ['فعالية','محاضرة','خطبة الجمعة','مناسبة دينية','إعلان عام'];
      $events = fs_list('events');
      usort($events, fn($a,$b) => ($b['date']??'') <=> ($a['date']??''));
      $ed = null;
      if (!empty($_GET['edit'])) {
          foreach ($events as $e) if (($e['_id'] ?? '') === $_GET['edit']) { $ed = $e; break; }
      }
      $isEdit = $ed !== null; ?>
    <div class="card">
      <h3 style="margin-top:0"><?= $isEdit ? '✏️ تعديل الفعالية' : '➕ فعالية جديدة' ?></h3>
      <form method="post" enctype="multipart/form-data">
        <input type="hidden" name="action" value="<?= $isEdit ? 'edit_event' : 'add_event' ?>">
        <?php if ($isEdit): ?><input type="hidden" name="id" value="<?= h($ed['_id']) ?>"><?php endif; ?>
        <label>العنوان</label><input name="title" required value="<?= h($ed['title'] ?? '') ?>">
        <label>النوع</label>
        <select name="category">
          <?php foreach ($cats as $c): ?>
            <option <?= ($ed['category'] ?? '')===$c?'selected':'' ?>><?= h($c) ?></option>
          <?php endforeach; ?>
        </select>
        <label>التاريخ والوقت</label>
        <input type="datetime-local" name="date" required value="<?= h(dt_local($ed['date'] ?? '')) ?>">
        <label>المكان</label><input name="location" value="<?= h($ed['location'] ?? '') ?>">
        <label>الوصف</label><textarea name="description" rows="3"><?= h($ed['description'] ?? '') ?></textarea>
        <label>صورة <?= $isEdit ? '(اتركها فارغة للإبقاء على الصورة الحالية)' : '' ?></label>
        <input type="file" name="image" accept="image/*">
        <label><input type="checkbox" name="boosted" style="width:auto" <?= !empty($ed['boosted'])?'checked':'' ?>> تمييز (مميز)</label><br>
        <?php if (!$isEdit): ?>
        <label><input type="checkbox" name="notify" checked style="width:auto"> 🔔 إرسال إشعار لجميع المستخدمين</label><br>
        <?php endif; ?>
        <br>
        <button><?= $isEdit ? 'حفظ التعديل' : 'نشر الفعالية' ?></button>
        <?php if ($isEdit): ?><a href="?tab=events" class="cancel">إلغاء</a><?php endif; ?>
      </form>
    </div>
    <?php foreach ($events as $e): ?>
      <div class="card">
        <?php if (!empty($e['imageUrl'])): ?><img src="<?= h($e['imageUrl']) ?>"><?php endif; ?>
        <div class="row">
          <strong><?= h($e['title'] ?? '') ?></strong>
          <div class="actions">
            <a class="editbtn" href="?tab=events&edit=<?= h($e['_id']) ?>">تعديل</a>
            <form method="post" onsubmit="return confirm('حذف؟')">
              <input type="hidden" name="action" value="delete_event">
              <input type="hidden" name="id" value="<?= h($e['_id']) ?>">
              <button class="danger">حذف</button>
            </form>
          </div>
        </div>
        <div class="muted"><?= h($e['category'] ?? '') ?> · <?= h($e['date'] ?? '') ?></div>
        <?php if (!empty($e['description'])): ?><p><?= h($e['description']) ?></p><?php endif; ?>
      </div>
    <?php endforeach; ?>

  <?php elseif ($tab === 'trips'):
      $trips = fs_list('trips');
      usort($trips, fn($a,$b) => ($b['date']??'') <=> ($a['date']??''));
      $ed = null;
      if (!empty($_GET['edit'])) {
          foreach ($trips as $t) if (($t['_id'] ?? '') === $_GET['edit']) { $ed = $t; break; }
      }
      $isEdit = $ed !== null; ?>
    <div class="card">
      <h3 style="margin-top:0"><?= $isEdit ? '✏️ تعديل الرحلة' : '➕ رحلة جديدة' ?></h3>
      <form method="post" enctype="multipart/form-data">
        <input type="hidden" name="action" value="<?= $isEdit ? 'edit_trip' : 'add_trip' ?>">
        <?php if ($isEdit): ?><input type="hidden" name="id" value="<?= h($ed['_id']) ?>"><?php endif; ?>
        <label>عنوان الرحلة</label><input name="title" required value="<?= h($ed['title'] ?? '') ?>">
        <label>الوجهة (مثال: كربلاء المقدسة)</label><input name="destination" value="<?= h($ed['destination'] ?? '') ?>">
        <label>موعد الانطلاق</label>
        <input type="datetime-local" name="date" required value="<?= h(dt_local($ed['date'] ?? '')) ?>">
        <label>التكلفة (مثال: 25 ألف دينار)</label><input name="cost" value="<?= h($ed['cost'] ?? '') ?>">
        <label>أرقام الحجز / واتساب — كل جهة في سطر بصيغة: الاسم | الرقم</label>
        <textarea name="contact" rows="3" placeholder="أبو علي | +9647xxxxxxxxx&#10;الحاج حسن | +9647yyyyyyyyy"><?= h($ed['contact'] ?? '') ?></textarea>
        <label>تفاصيل الرحلة</label><textarea name="description" rows="3"><?= h($ed['description'] ?? '') ?></textarea>
        <label>صورة <?= $isEdit ? '(اتركها فارغة للإبقاء على الصورة الحالية)' : '' ?></label>
        <input type="file" name="image" accept="image/*">
        <label><input type="checkbox" name="boosted" style="width:auto" <?= !empty($ed['boosted'])?'checked':'' ?>> تمييز (مميز)</label><br>
        <?php if (!$isEdit): ?>
        <label><input type="checkbox" name="notify" checked style="width:auto"> 🔔 إرسال إشعار لجميع المستخدمين</label><br>
        <?php endif; ?>
        <br>
        <button><?= $isEdit ? 'حفظ التعديل' : 'نشر الرحلة' ?></button>
        <?php if ($isEdit): ?><a href="?tab=trips" class="cancel">إلغاء</a><?php endif; ?>
      </form>
    </div>
    <?php foreach ($trips as $t): ?>
      <div class="card">
        <?php if (!empty($t['imageUrl'])): ?><img src="<?= h($t['imageUrl']) ?>"><?php endif; ?>
        <div class="row">
          <strong><?= h($t['title'] ?? '') ?></strong>
          <div class="actions">
            <a class="editbtn" href="?tab=trips&edit=<?= h($t['_id']) ?>">تعديل</a>
            <form method="post" onsubmit="return confirm('حذف؟')">
              <input type="hidden" name="action" value="delete_trip">
              <input type="hidden" name="id" value="<?= h($t['_id']) ?>">
              <button class="danger">حذف</button>
            </form>
          </div>
        </div>
        <div class="muted">
          <?= h($t['destination'] ?? '') ?>
          <?php if (!empty($t['cost'])): ?> · <?= h($t['cost']) ?><?php endif; ?>
          · <?= h($t['date'] ?? '') ?>
        </div>
        <?php if (!empty($t['description'])): ?><p><?= h($t['description']) ?></p><?php endif; ?>
      </div>
    <?php endforeach; ?>

  <?php elseif ($tab === 'slider'): ?>
    <div class="card">
      <h3 style="margin-top:0">🖼️ إضافة صورة إلى معرض الصور (السلايدر)</h3>
      <form method="post" enctype="multipart/form-data">
        <input type="hidden" name="action" value="add_slide">
        <label>ارفع صورة من جهازك</label>
        <input type="file" name="image" accept="image/*">
        <label>أو ألصق رابط صورة موجودة (نفس الصور التي لديك على الموقع)</label>
        <input name="imageUrl" placeholder="https://ahlulbaytmosque.site/app/server/uploads/...">
        <label>عنوان (اختياري — يظهر فوق الصورة)</label>
        <input name="title">
        <label>الترتيب (رقم أصغر يظهر أولاً)</label>
        <input type="number" name="order" value="0">
        <button>إضافة الصورة</button>
      </form>
      <p class="muted">إذا رفعت صورة ورابطاً معاً، تُستخدم الصورة المرفوعة.</p>
    </div>
    <?php
      $slides = fs_list('home_slider');
      usort($slides, fn($a,$b) => ((int)($a['order']??0)) <=> ((int)($b['order']??0)));
      foreach ($slides as $s): ?>
      <div class="card">
        <?php if (!empty($s['imageUrl'])): ?><img src="<?= h($s['imageUrl']) ?>"><?php endif; ?>
        <div class="row">
          <strong><?= h($s['title'] ?? '') ?: 'بدون عنوان' ?>
            <span class="muted">(ترتيب: <?= h($s['order'] ?? 0) ?>)</span></strong>
          <form method="post" onsubmit="return confirm('حذف الصورة؟')">
            <input type="hidden" name="action" value="delete_slide">
            <input type="hidden" name="id" value="<?= h($s['_id']) ?>">
            <button class="danger">حذف</button>
          </form>
        </div>
      </div>
    <?php endforeach; ?>

  <?php elseif ($tab === 'quran'): ?>
    <div class="card">
      <h3 style="margin-top:0">🎙️ رفع تلاوة لسورة</h3>
      <form method="post" enctype="multipart/form-data">
        <input type="hidden" name="action" value="set_quran_audio">
        <label>رقم السورة (1 - 114)</label>
        <input type="number" name="surah" min="1" max="114" required>
        <label>ملف الصوت (mp3 — أقل من 50 ميجا)</label>
        <input type="file" name="audio" accept="audio/*" required>
        <button>رفع التلاوة</button>
      </form>
      <p class="muted">تظهر هذه التلاوة للمستخدمين بدل التلاوة الافتراضية لنفس
        السورة. من رفع نفس الرقم مرة أخرى يستبدل التلاوة السابقة.</p>
    </div>
    <?php
      $qa = fs_list('quran_audio');
      usort($qa, fn($a,$b) => ((int)($a['_id']??0)) <=> ((int)($b['_id']??0)));
      foreach ($qa as $a): ?>
      <div class="card">
        <div class="row">
          <strong>سورة رقم <?= h($a['_id']) ?></strong>
          <form method="post" onsubmit="return confirm('حذف التلاوة؟')">
            <input type="hidden" name="action" value="delete_quran_audio">
            <input type="hidden" name="surah" value="<?= h($a['_id']) ?>">
            <button class="danger">حذف</button>
          </form>
        </div>
        <?php if (!empty($a['url'])): ?>
          <audio controls src="<?= h($a['url']) ?>"
                 style="width:100%;margin-top:8px"></audio>
        <?php endif; ?>
      </div>
    <?php endforeach; ?>

  <?php elseif ($tab === 'release'):
      $ver = read_version();
      $apkExists = is_file(dirname(__DIR__) . '/app-release.apk');
      $apkSize = $apkExists ? filesize(dirname(__DIR__) . '/app-release.apk') : 0; ?>
    <div class="card">
      <h3 style="margin-top:0">🚀 نشر إصدار جديد للتطبيق</h3>
      <p class="muted">
        لا يمكن <b>بناء</b> ملف APK على الاستضافة — البناء يتم على جهازك بالأمر
        <code>flutter build apk --release</code>. هنا تقوم برفع الملف الناتج
        ونشر رقم الإصدار، فيظهر لكل المستخدمين إشعار «تحديث متوفر» ويحمّلونه من
        الموقع مباشرة.
      </p>
      <div style="background:#eef3fb;padding:10px 12px;border-radius:10px;font-size:14px">
        <b>الإصدار الحالي:</b> <?= h($ver['version']) ?> (build <?= h($ver['build']) ?>)<br>
        <b>ملف APK:</b>
        <?php if ($apkExists): ?>
          موجود (<?= number_format($apkSize / 1048576, 1) ?> ميجا) —
          <a href="../app-release.apk" target="_blank">تحميل</a>
        <?php else: ?>
          <span style="color:#c62828">لا يوجد — ارفع ملفاً أدناه</span>
        <?php endif; ?>
      </div>
      <form method="post" enctype="multipart/form-data" style="margin-top:12px"
            onsubmit="this.querySelector('button').disabled=true;
                      this.querySelector('button').textContent='جارٍ الرفع... قد يستغرق دقائق';">
        <input type="hidden" name="action" value="publish_release">
        <label>ملف التطبيق (app-release.apk)</label>
        <input type="file" name="apk" accept=".apk">
        <label>رقم الإصدار (version) مثال: 1.0.2</label>
        <input name="version" value="<?= h($ver['version']) ?>" required>
        <label>رقم البناء (build) — رقم يزيد مع كل إصدار</label>
        <input type="number" name="build" value="<?= h((int)$ver['build'] + 1) ?>" min="1" required>
        <label>ملاحظات التحديث (تظهر للمستخدم)</label>
        <textarea name="notes" rows="2" placeholder="ما الجديد في هذا الإصدار..."><?= h($ver['notes']) ?></textarea>
        <label><input type="checkbox" name="mandatory" style="width:auto"
               <?= !empty($ver['mandatory']) ? 'checked' : '' ?>> تحديث إجباري (يمنع استخدام النسخة القديمة)</label><br>
        <label><input type="checkbox" name="notify" checked style="width:auto"> 🔔 إرسال إشعار «تحديث متوفر» لكل المستخدمين</label><br><br>
        <button>نشر الإصدار</button>
      </form>
      <p class="muted">
        حد الرفع مرفوع إلى ٢٠٠ ميجا عبر ملف <code>.user.ini</code> المرفق، فيكفي
        لملف بحجم ٦٠ ميجا. إذا بقي الخطأ بعد دقائق، ارفع
        <code>upload_max_filesize</code> و <code>post_max_size</code> من لوحة
        Hostinger ‹ <b>PHP Configuration</b>.
        <br><br>
        لتصغير الحجم: ابنِ نسخاً منفصلة لكل معالج بالأمر
        <code>flutter build apk --split-per-abi</code> وارفع ملف
        <code>app-arm64-v8a-release.apk</code> (حوالي ٢٠ ميجا، يعمل على معظم
        الهواتف الحديثة).
      </p>
    </div>

  <?php elseif ($tab === 'notify'): ?>
    <div class="card">
      <h3 style="margin-top:0">🔔 إرسال إشعار لجميع المستخدمين</h3>
      <p class="muted">يصل هذا الإشعار فوراً إلى كل من ثبّت التطبيق على هاتفه.</p>
      <form method="post">
        <input type="hidden" name="action" value="send_broadcast">
        <label>عنوان الإشعار</label>
        <input name="title" placeholder="مسجد وحسينية أهل البيت" required>
        <label>نص الإشعار</label>
        <textarea name="body" rows="3" placeholder="اكتب نص الرسالة..." required></textarea>
        <label>الصفحة التي تُفتح عند الضغط</label>
        <select name="page">
          <option value="announcements">الإعلانات</option>
          <option value="events">الفعاليات</option>
          <option value="trips">الرحلات</option>
          <option value="home">الرئيسية</option>
          <option value="prayer">أوقات الصلاة</option>
        </select>
        <button>📤 إرسال الإشعار الآن</button>
      </form>
    </div>

  <?php elseif ($tab === 'announcements'):
      $ann = fs_list('announcements');
      usort($ann, fn($a,$b) => ($b['createdAt']??'') <=> ($a['createdAt']??''));
      $ed = null;
      if (!empty($_GET['edit'])) {
          foreach ($ann as $a) if (($a['_id'] ?? '') === $_GET['edit']) { $ed = $a; break; }
      }
      $isEdit = $ed !== null; ?>
    <div class="card">
      <h3 style="margin-top:0"><?= $isEdit ? '✏️ تعديل الإعلان' : '➕ إعلان جديد' ?></h3>
      <form method="post" enctype="multipart/form-data">
        <input type="hidden" name="action" value="<?= $isEdit ? 'edit_announcement' : 'add_announcement' ?>">
        <?php if ($isEdit): ?><input type="hidden" name="id" value="<?= h($ed['_id']) ?>"><?php endif; ?>
        <label>العنوان</label><input name="title" required value="<?= h($ed['title'] ?? '') ?>">
        <label>النص</label><textarea name="body" rows="4"><?= h($ed['body'] ?? '') ?></textarea>
        <label>رابط يوتيوب (اختياري)</label><input name="link" placeholder="https://youtube.com/..." value="<?= h($ed['linkUrl'] ?? '') ?>">
        <label>صورة <?= $isEdit ? '(اتركها فارغة للإبقاء على الصورة الحالية)' : '' ?></label>
        <input type="file" name="image" accept="image/*">
        <?php if (!$isEdit): ?>
        <label><input type="checkbox" name="notify" checked style="width:auto"> 🔔 إرسال إشعار لجميع المستخدمين</label><br>
        <?php endif; ?>
        <br>
        <button><?= $isEdit ? 'حفظ التعديل' : 'نشر الإعلان' ?></button>
        <?php if ($isEdit): ?><a href="?tab=announcements" class="cancel">إلغاء</a><?php endif; ?>
      </form>
    </div>
    <?php foreach ($ann as $a): ?>
      <div class="card">
        <?php if (!empty($a['imageUrl'])): ?><img src="<?= h($a['imageUrl']) ?>"><?php endif; ?>
        <div class="row">
          <strong><?= h($a['title'] ?? '') ?></strong>
          <div class="actions">
            <a class="editbtn" href="?tab=announcements&edit=<?= h($a['_id']) ?>">تعديل</a>
            <form method="post" onsubmit="return confirm('حذف؟')">
              <input type="hidden" name="action" value="delete_announcement">
              <input type="hidden" name="id" value="<?= h($a['_id']) ?>">
              <button class="danger">حذف</button>
            </form>
          </div>
        </div>
        <?php if (!empty($a['body'])): ?><p><?= h($a['body']) ?></p><?php endif; ?>
      </div>
    <?php endforeach; ?>

  <?php elseif ($tab === 'questions'):
      $qs = fs_list('questions');
      usort($qs, fn($a,$b) => ($b['askedAt']??'') <=> ($a['askedAt']??''));
      foreach ($qs as $q):
        $answered = ($q['status'] ?? '') === 'answered'; ?>
      <div class="card <?= $answered?'answered':'pending' ?>">
        <div class="row">
          <strong><?= h($q['question'] ?? '') ?></strong>
          <form method="post" onsubmit="return confirm('حذف؟')">
            <input type="hidden" name="action" value="delete_question">
            <input type="hidden" name="id" value="<?= h($q['_id']) ?>">
            <button class="danger">حذف</button>
          </form>
        </div>
        <div class="muted">— <?= h($q['name'] ?? 'بدون اسم') ?>
          · <?= $answered ? 'تمت الإجابة' : 'بانتظار الرد' ?></div>
        <?php if ($answered): ?>
          <p style="background:#e8f5ee;padding:10px;border-radius:8px">
            <?= h($q['answer'] ?? '') ?></p>
        <?php endif; ?>
        <details style="margin-top:8px">
          <summary style="cursor:pointer;color:#5a6b88;font-size:13px">✏️ تعديل نص السؤال</summary>
          <form method="post" style="margin-top:6px">
            <input type="hidden" name="action" value="edit_question">
            <input type="hidden" name="id" value="<?= h($q['_id']) ?>">
            <textarea name="question" rows="2"><?= h($q['question'] ?? '') ?></textarea>
            <button>حفظ نص السؤال</button>
          </form>
        </details>
        <form method="post" enctype="multipart/form-data" style="margin-top:8px">
          <input type="hidden" name="action" value="answer_question">
          <input type="hidden" name="id" value="<?= h($q['_id']) ?>">
          <input type="hidden" name="clientToken" value="<?= h($q['clientFcmToken'] ?? '') ?>">
          <textarea name="answer" rows="3" placeholder="اكتب الجواب..."><?= h($q['answer'] ?? '') ?></textarea>
          <label>صورة للجواب (اختياري)</label>
          <input type="file" name="image" accept="image/*">
          <button><?= $answered ? 'تعديل الجواب' : 'نشر الجواب' ?></button>
        </form>
      </div>
    <?php endforeach; ?>
  <?php endif; ?>

  </div>
<?php endif; ?>
</body>
</html>
