# دليل إعداد النظام الكامل (نسخة 2)

نظام مكوّن من **workflowين** في n8n:

```
زائر واتساب ──▶ workflow1_bot_v2 ──▶ Gemini ──▶ يقرأ من Google Doc ──▶ يرد بالعربية
                                                        ▲
الأدمن (تيليجرام) ──▶ workflow2_telegram_admin ──▶ Gemini يلخّص ──┘ يكتب في نفس الـ Doc
   (نص / صورة / تسجيل صوتي)
```

- **Google Docs** = قاعدة معرفة المسجد (مصدر واحد للحقيقة).
- **تيليجرام** = قناة الأدمن لإضافة المعلومات (يكتب نص، أو يرسل صورة إعلان، أو يسجّل رسالة صوتية).
- **واتساب** = قناة الزوار للسؤال.

---

## ١) استورد الملفين في n8n

لكل ملف: **+ New Workflow ← (⋮) ← Import from File**

1. `workflow1_bot_v2.json` — بوت واتساب للزوار.
2. `workflow2_telegram_admin.json` — بوت تيليجرام للأدمن.

---

## ٢) القيم التي يجب استبدالها (ابحث واستبدل في كل node)

| الكلمة المؤقتة | استبدلها بـ | أين تجدها |
|---|---|---|
| `YOUR_GEMINI_API_KEY` | مفتاح Gemini | aistudio.google.com ← Get API Key |
| `YOUR_BAILEYS_IP` | IP جهاز لينكس الذي يشغّل Baileys | على لينكس: `hostname -I` (مثال 192.168.68.115) |
| `YOUR_GOOGLE_DOC_ID` | معرّف مستند Google | من رابط المستند: `docs.google.com/document/d/`**`<هذا_الجزء>`**`/edit` |
| `YOUR_TELEGRAM_BOT_TOKEN` | توكن بوت تيليجرام | من @BotFather ← `/newbot` |
| `YOUR_TELEGRAM_ADMIN_ID` | رقم حسابك في تيليجرام | من @userinfobot ← يرسل لك `Id` رقمي |

> **مهم:** `YOUR_TELEGRAM_BOT_TOKEN` موجود في مكانين داخل `workflow2`:
> - داخل كود node **Prepare Content** (لتحميل الصور/الصوت).
> - في رابط node **Confirm to Admin** (لإرسال رسالة التأكيد).
> استبدلهما معاً.

---

## ٣) ربط Google Docs (مرة واحدة فقط)

استخدمنا اعتماد n8n الرسمي لجوجل بدل التوكن اليدوي، **حتى لا تنتهي صلاحيته كل ساعة**.

في كل من node **Fetch Google Doc** (workflow1) و **Append to Google Doc** (workflow2):

1. افتح الـ node ← حقل **Credential to connect with**.
2. اختر **Create New Credential** ← نوعه **Google Docs OAuth2 API**.
3. اتبع زر **Sign in with Google** وامنح الصلاحية.
4. بعد نجاح الربط اختر نفس الاعتماد في الـ node الثاني.

> شارك مستند Google مع نفس حساب جوجل الذي ربطته (أو اجعله "أي شخص لديه الرابط: محرّر").

---

## ٤) ربط بوت تيليجرام (مرة واحدة فقط)

في node **Telegram Trigger** داخل `workflow2`:

1. حقل **Credential to connect with** ← **Create New Credential** ← نوعه **Telegram API**.
2. ألصق `Access Token` الذي أعطاك إياه @BotFather ← **Save**.

> الـ Trigger يعمل بنظام polling، لذلك لا يحتاج عنوان إنترنت عام — يعمل حتى لو كان n8n على شبكة محلية.

---

## ٥) شغّل سيرفر Baileys (على لينكس)

```bash
cd ~/as
git pull
npm install
npm start
```

امسح الـ QR من واتساب ← الأجهزة المرتبطة. تأكد من ظهور `✅ واتساب متصل وجاهز!`.

تأكد أن `.env` على لينكس يحتوي:

```env
N8N_WEBHOOK_URL=http://192.168.68.115:5678/webhook/masjid-whatsapp
SERVER_SECRET=masjid-secret-2024
PORT=3000
```

---

## ٦) فعّل الـ workflowين

اضغط **Active** في أعلى كل workflow.

---

## ٧) جرّب

1. **كأدمن:** أرسل في تيليجرام إلى بوتك:
   - رسالة نصية: «درس التفسير كل يوم خميس بعد المغرب».
   - أو صورة إعلان (سيقرأ النص منها).
   - أو رسالة صوتية (سيفرّغها).
   يجب أن يردّ: «✅ تم حفظ المعلومة...» وتُضاف للـ Doc.

2. **كزائر:** أرسل في واتساب: «متى درس التفسير؟»
   يجب أن يرد البوت بالعربية اعتماداً على ما حفظه الأدمن.

3. **أول رسالة من زائر جديد** يستقبل تحية ترحيب تلقائية أولاً.

---

## استكشاف الأخطاء

| المشكلة | الحل |
|---|---|
| البوت لا يرد في واتساب | تأكد أن سيرفر Baileys يعمل وأن `YOUR_BAILEYS_IP` صحيح |
| تيليجرام لا يستجيب | تأكد أن `YOUR_TELEGRAM_ADMIN_ID` رقمك الصحيح، والـ workflow مفعّل |
| خطأ 401 في Google | أعد ربط اعتماد Google Docs، وشارك المستند مع حسابك |
| الرد ليس بالعربية | النص في system_instruction يفرض العربية — تأكد أنك لم تغيّره |
