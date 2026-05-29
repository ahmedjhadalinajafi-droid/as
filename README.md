# بوت واتساب للمسجد - n8n

بوت ذكاء اصطناعي يجيب على أسئلة المصلين والزوار عبر واتساب تلقائياً.

## كيف يعمل البوت

```
رسالة واتساب → Evolution API → n8n → GPT-4o-mini → رد تلقائي
```

1. شخص يرسل سؤالاً على واتساب
2. Evolution API يرسل الرسالة إلى n8n
3. n8n يرسل السؤال إلى الذكاء الاصطناعي مع معلومات المسجد
4. الذكاء الاصطناعي يولّد إجابة مناسبة
5. n8n يرسل الإجابة تلقائياً عبر واتساب

---

## المتطلبات

- **n8n** (مثبّت على سيرفر أو cloud)
- **Evolution API** (لتوصيل واتساب)
- **OpenAI API Key** (للذكاء الاصطناعي - GPT-4o-mini رخيص جداً)

---

## خطوات الإعداد

### 1. تجهيز معلومات المسجد

افتح ملف `mosque_info.txt` واملأ جميع معلومات مسجدك:
- اسم المسجد والعنوان
- أوقات الصلاة
- الأنشطة والخدمات
- معلومات التواصل

### 2. إضافة المتغيرات في n8n

في n8n اذهب إلى **Settings → Variables** وأضف هذه المتغيرات:

| اسم المتغير | القيمة |
|---|---|
| `OPENAI_API_KEY` | مفتاح OpenAI API الخاص بك |
| `EVOLUTION_API_URL` | رابط سيرفر Evolution API (مثال: `http://localhost:8080`) |
| `EVOLUTION_INSTANCE` | اسم instance الواتساب في Evolution API |
| `EVOLUTION_API_KEY` | مفتاح Evolution API |
| `MOSQUE_SYSTEM_PROMPT` | انسخ المحتوى الكامل من ملف `mosque_info.txt` بعد تعديله |

### 3. استيراد الـ Workflow

1. افتح n8n
2. اضغط **+ New Workflow**
3. اضغط على القائمة (⋮) ثم **Import from File**
4. اختر ملف `masjid_bot_workflow.json`

### 4. ربط Evolution API بـ n8n

في Evolution API أضف webhook يشير إلى:
```
https://YOUR_N8N_URL/webhook/masjid-whatsapp
```

الأحداث المطلوبة: `messages.upsert`

### 5. تفعيل البوت

في n8n فعّل الـ workflow بالضغط على **Active**

---

## الملفات

| الملف | الوصف |
|---|---|
| `masjid_bot_workflow.json` | ملف n8n جاهز للاستيراد |
| `mosque_info.txt` | قالب معلومات المسجد (عدّله بمعلومات مسجدك) |

---

## التكلفة التقديرية

- **GPT-4o-mini**: ~$0.15 لكل مليون كلمة مدخلة — رخيص جداً
- مثال: 1000 سؤال في الشهر ≈ أقل من $1

---

## استكشاف الأخطاء

**البوت لا يرد؟**
- تحقق أن الـ webhook في Evolution API يشير للرابط الصحيح
- تحقق أن الـ workflow في n8n مفعّل (Active)
- راجع **Executions** في n8n لترى سبب الخطأ

**الإجابات غير دقيقة؟**
- عدّل ملف `mosque_info.txt` وأضف تفاصيل أكثر
- أعد نسخ المحتوى في متغير `MOSQUE_SYSTEM_PROMPT`
