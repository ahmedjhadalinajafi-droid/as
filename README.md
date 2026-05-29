# بوت واتساب للمسجد

بوت ذكاء اصطناعي يجيب على أسئلة المصلين والزوار عبر واتساب تلقائياً باللغة العربية.

## المعمارية

```
واتساب
  ↕
whatsapp-server.js  (Baileys - Node.js)
  ↕  webhook + /send
n8n workflow
  ↕
Gemini AI (مجاني)
```

---

## المتطلبات

- **Node.js 18+**
- **n8n** (مثبّت محلياً أو على سيرفر)
- **مفتاح Gemini مجاني** من aistudio.google.com

---

## خطوات الإعداد

### 1. احصل على مفتاح Gemini المجاني

1. اذهب إلى [aistudio.google.com](https://aistudio.google.com)
2. سجّل دخول بحساب Google
3. اضغط **Get API Key** ثم **Create API Key**

### 2. أضف معلومات المسجد

افتح `mosque_info.txt` واملأ معلومات مسجدك (الاسم، العنوان، أوقات الصلاة...)

### 3. أنشئ ملف .env

```bash
cp .env.example .env
```

عدّل `.env` وأضف المفاتيح:

```env
GEMINI_API_KEY=AIza...مفتاحك
N8N_WEBHOOK_URL=http://localhost:5678/webhook/masjid-whatsapp
SERVER_SECRET=اختر_كلمة_سر
PORT=3000
```

### 4. ثبّت المكتبات

```bash
npm install
```

### 5. استورد الـ workflow في n8n

1. افتح n8n
2. اضغط **+ New Workflow** ← قائمة (⋮) ← **Import from File**
3. اختر ملف `masjid_bot_workflow.json`

### 6. أضف المتغيرات في n8n

في n8n ← **Settings → Variables**:

| المتغير | القيمة |
|---|---|
| `GEMINI_API_KEY` | مفتاح Gemini |
| `BAILEYS_SERVER_URL` | `http://localhost:3000` |
| `SERVER_SECRET` | نفس الكلمة في `.env` |
| `MOSQUE_SYSTEM_PROMPT` | انسخ محتوى `mosque_info.txt` كاملاً |

### 7. فعّل الـ workflow في n8n

اضغط **Active** في الـ workflow.

### 8. شغّل سيرفر Baileys

```bash
npm start
```

سيظهر **QR Code** — افتح واتساب ← الأجهزة المرتبطة ← امسح الكود.

```
✅ واتساب متصل وجاهز!
```

---

## الملفات

| الملف | الوصف |
|---|---|
| `whatsapp-server.js` | سيرفر Baileys — يستقبل رسائل واتساب ويرسلها لـ n8n |
| `masjid_bot_workflow.json` | workflow n8n جاهز للاستيراد |
| `mosque_info.txt` | معلومات المسجد للذكاء الاصطناعي |
| `bot.js` | نسخة مستقلة بدون n8n (اختياري) |

---

## الحد المجاني لـ Gemini

| | |
|---|---|
| **1,500 طلب/يوم** | مجاناً |
| **15 طلب/دقيقة** | الحد الأقصى |

---

## استكشاف الأخطاء

**البوت لا يرد؟**
- تأكد أن سيرفر Baileys يعمل: `curl http://localhost:3000/status`
- تأكد أن الـ workflow في n8n مفعّل
- راجع **Executions** في n8n

**خطأ في الاتصال بواتساب؟**
- احذف مجلد `auth_info/` وأعد التشغيل لمسح QR جديد
