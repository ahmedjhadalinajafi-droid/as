// Masjid WhatsApp Bridge (Baileys <-> n8n)
// جسر يربط واتساب (عبر Baileys) بـ n8n:
//   1) يستقبل رسائل المصلّين ويرسلها إلى n8n (Webhook).
//   2) يوفّر مسار /send لكي يرسل n8n الإجابة إلى المصلّي.
require('dotenv').config();

const {
  default: makeWASocket,
  useMultiFileAuthState,
  fetchLatestBaileysVersion,
  DisconnectReason,
} = require('@whiskeysockets/baileys');
const qrcode = require('qrcode-terminal');
const express = require('express');
const axios = require('axios');
const pino = require('pino');

const N8N_WEBHOOK_URL = process.env.N8N_WEBHOOK_URL || 'http://localhost:5678/webhook/masjid-bot';
const PORT = parseInt(process.env.PORT || '3000', 10);
const API_TOKEN = process.env.API_TOKEN || ''; // سرّ اختياري لحماية مسار /send
const AUTH_DIR = process.env.AUTH_DIR || 'auth_info';

const logger = pino({ level: process.env.LOG_LEVEL || 'silent' });
let sock; // يُعاد إنشاؤه عند إعادة الاتصال

async function startSock() {
  const { state, saveCreds } = await useMultiFileAuthState(AUTH_DIR);
  const { version } = await fetchLatestBaileysVersion();

  sock = makeWASocket({
    version,
    auth: state,
    logger,
    browser: ['Masjid Bot', 'Chrome', '1.0.0'],
    markOnlineOnConnect: false,
  });

  sock.ev.on('creds.update', saveCreds);

  sock.ev.on('connection.update', (update) => {
    const { connection, lastDisconnect, qr } = update;
    if (qr) {
      console.log('\n📲  امسح رمز QR من تطبيق واتساب (الإعدادات ← الأجهزة المرتبطة ← ربط جهاز):\n');
      qrcode.generate(qr, { small: true });
    }
    if (connection === 'open') {
      console.log('✅  تم الاتصال بواتساب بنجاح / Connected to WhatsApp');
    }
    if (connection === 'close') {
      const code = lastDisconnect?.error?.output?.statusCode;
      const loggedOut = code === DisconnectReason.loggedOut;
      console.log(
        `⚠️  انقطع الاتصال (code=${code}). ` +
          (loggedOut
            ? 'تم تسجيل الخروج: احذف مجلد auth_info وأعد مسح رمز QR.'
            : 'إعادة المحاولة...'),
      );
      if (!loggedOut) startSock();
    }
  });

  sock.ev.on('messages.upsert', async ({ messages, type }) => {
    if (type !== 'notify') return;
    for (const msg of messages) {
      try {
        await handleIncoming(msg);
      } catch (e) {
        console.error('خطأ في معالجة الرسالة / message error:', e.message);
      }
    }
  });
}

async function handleIncoming(msg) {
  if (!msg.message || msg.key.fromMe) return;
  const from = msg.key.remoteJid;
  // تجاهل المجموعات والحالات والقنوات
  if (!from || from.endsWith('@g.us') || from === 'status@broadcast' || from.endsWith('@newsletter')) {
    return;
  }

  const text = (
    msg.message.conversation ||
    msg.message.extendedTextMessage?.text ||
    msg.message.imageMessage?.caption ||
    ''
  ).trim();
  if (!text) return; // نتعامل مع الأسئلة النصّية فقط

  const name = msg.pushName || '';
  console.log(`📩  ${name} <${from}>: ${text}`);

  // أظهر مؤشّر "يكتب..." بينما يعالج n8n السؤال
  try {
    await sock.readMessages([msg.key]);
    await sock.sendPresenceUpdate('composing', from);
  } catch (_) {}

  await axios.post(
    N8N_WEBHOOK_URL,
    {
      from,
      name,
      text,
      messageId: msg.key.id,
      timestamp: Number(msg.messageTimestamp) || Date.now(),
    },
    { timeout: 20000 },
  );
}

// ----- خادم HTTP: يستدعيه n8n لإرسال الإجابة إلى المصلّي -----
const app = express();
app.use(express.json({ limit: '1mb' }));

app.get('/health', (_req, res) => res.json({ ok: true, connected: !!sock?.user }));

app.post('/send', async (req, res) => {
  if (API_TOKEN && req.headers['x-api-token'] !== API_TOKEN) {
    return res.status(401).json({ ok: false, error: 'unauthorized' });
  }
  const { to, text } = req.body || {};
  if (!to || !text) return res.status(400).json({ ok: false, error: 'missing "to" or "text"' });
  try {
    await sock.sendPresenceUpdate('paused', to);
    await sock.sendMessage(to, { text: String(text) });
    console.log(`📤  → ${to}: ${String(text).slice(0, 80)}`);
    res.json({ ok: true });
  } catch (e) {
    console.error('فشل الإرسال / send failed:', e.message);
    res.status(500).json({ ok: false, error: e.message });
  }
});

app.listen(PORT, () =>
  console.log(`🌐  خادم HTTP جاهز على المنفذ :${PORT}  (POST /send, GET /health)`),
);

startSock().catch((e) => {
  console.error('فشل بدء التشغيل / startup failed:', e);
  process.exit(1);
});
