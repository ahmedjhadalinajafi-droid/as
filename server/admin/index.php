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
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host   = $_SERVER['HTTP_HOST'] ?? 'localhost';
    // admin/ is one level below the server root that holds uploads/
    $dir    = rtrim(dirname(dirname($_SERVER['SCRIPT_NAME'])), '/');
    return "$scheme://$host$dir/uploads/$name";
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

    if ($action === 'edit_question') {
        $res = fs_update('questions', $_POST['id'],
            ['question' => trim($_POST['question'] ?? '')]);
        $flash = fs_flash($res, 'تم تعديل نص السؤال');
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
    <a href="?tab=notify" class="<?= $tab==='notify'?'active':'' ?>">الإشعارات</a>
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
        <label>رقم الحجز / واتساب</label><input name="contact" placeholder="+9647xxxxxxxxx" value="<?= h($ed['contact'] ?? '') ?>">
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

  <?php elseif ($tab === 'announcements'): ?>
    <div class="card">
      <h3 style="margin-top:0">➕ إعلان جديد</h3>
      <form method="post" enctype="multipart/form-data">
        <input type="hidden" name="action" value="add_announcement">
        <label>العنوان</label><input name="title" required>
        <label>النص</label><textarea name="body" rows="4"></textarea>
        <label>رابط يوتيوب (اختياري)</label><input name="link" placeholder="https://youtube.com/...">
        <label>صورة</label><input type="file" name="image" accept="image/*">
        <label><input type="checkbox" name="notify" checked style="width:auto"> 🔔 إرسال إشعار لجميع المستخدمين</label><br><br>
        <button>نشر الإعلان</button>
      </form>
    </div>
    <?php
      $ann = fs_list('announcements');
      usort($ann, fn($a,$b) => ($b['createdAt']??'') <=> ($a['createdAt']??''));
      foreach ($ann as $a): ?>
      <div class="card">
        <?php if (!empty($a['imageUrl'])): ?><img src="<?= h($a['imageUrl']) ?>"><?php endif; ?>
        <div class="row">
          <strong><?= h($a['title'] ?? '') ?></strong>
          <form method="post" onsubmit="return confirm('حذف؟')">
            <input type="hidden" name="action" value="delete_announcement">
            <input type="hidden" name="id" value="<?= h($a['_id']) ?>">
            <button class="danger">حذف</button>
          </form>
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
