const { default: makeWASocket, useMultiFileAuthState, DisconnectReason, fetchLatestBaileysVersion, downloadMediaMessage } = require('@whiskeysockets/baileys');
const { Boom } = require('@hapi/boom');
const express = require('express');
const qrcode = require('qrcode-terminal');
require('dotenv').config();

const app = express();
app.use(express.json({ limit: '50mb' }));

const PORT = process.env.PORT || 3000;
const N8N_WEBHOOK_URL = process.env.N8N_WEBHOOK_URL;
const N8N_EVENTS_WEBHOOK_URL = process.env.N8N_EVENTS_WEBHOOK_URL;
const SERVER_SECRET = process.env.SERVER_SECRET || 'masjid-secret';

// كلمات تشير أن الصورة حدث من الإدارة
const EVENT_KEYWORDS = ['📢', 'حدث', 'إعلان', 'موعد', 'خبر'];

let sock = null;

function checkSecret(req, res, next) {
  if (req.headers['x-secret'] !== SERVER_SECRET) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
}

app.post('/send', checkSecret, async (req, res) => {
  const { number, text } = req.body;
  if (!sock) return res.status(503).json({ error: 'واتساب غير متصل' });
  try {
    const jid = number.includes('@') ? number : `${number}@s.whatsapp.net`;
    await sock.sendMessage(jid, { text });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/status', (req, res) => {
  res.json({ connected: sock !== null });
});

async function sendToWebhook(url, payload) {
  if (!url) return;
  try {
    await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
  } catch (err) {
    console.error('❌ خطأ في الإرسال لـ n8n:', err.message);
  }
}

async function startBot() {
  const { state, saveCreds } = await useMultiFileAuthState('./auth_info');
  const { version } = await fetchLatestBaileysVersion();

  sock = makeWASocket({
    version,
    auth: state,
    browser: ['مسجد بوت', 'Chrome', '1.0']
  });

  sock.ev.on('creds.update', saveCreds);

  sock.ev.on('connection.update', ({ connection, lastDisconnect, qr }) => {
    if (qr) {
      console.log('\n📱 امسح هذا الـ QR Code من واتساب:\n');
      qrcode.generate(qr, { small: true });
    }
    if (connection === 'close') {
      sock = null;
      const code = new Boom(lastDisconnect?.error)?.output?.statusCode;
      if (code !== DisconnectReason.loggedOut) {
        console.log('🔄 إعادة الاتصال...');
        startBot();
      } else {
        console.log('🚪 تم تسجيل الخروج. احذف مجلد auth_info وأعد التشغيل.');
      }
    } else if (connection === 'open') {
      console.log('✅ واتساب متصل وجاهز!');
    }
  });

  sock.ev.on('messages.upsert', async ({ messages, type }) => {
    if (type !== 'notify') return;

    for (const msg of messages) {
      if (msg.key.fromMe) continue;

      const msgContent = msg.message || {};
      let text = '';
      let mediaBase64 = null;
      let mimeType = null;
      let messageType = 'text';

      if (msgContent.conversation) {
        text = msgContent.conversation;

      } else if (msgContent.extendedTextMessage?.text) {
        text = msgContent.extendedTextMessage.text;

      } else if (msgContent.imageMessage) {
        const caption = msgContent.imageMessage.caption || '';
        text = caption;
        mimeType = msgContent.imageMessage.mimetype || 'image/jpeg';
        messageType = 'image';
        try {
          const buffer = await downloadMediaMessage(msg, 'buffer', {}, {
            logger: console,
            reuploadRequest: sock.updateMediaMessage
          });
          mediaBase64 = buffer.toString('base64');
          console.log('🖼️ تم تحميل الصورة');
        } catch (err) {
          console.error('❌ خطأ في تحميل الصورة:', err.message);
        }

      } else if (msgContent.audioMessage || msgContent.pttMessage) {
        const audioMsg = msgContent.audioMessage || msgContent.pttMessage;
        mimeType = audioMsg.mimetype || 'audio/ogg; codecs=opus';
        messageType = 'voice';
        text = 'استمع لهذه الرسالة الصوتية وأجب على طلب المتحدث باللغة العربية.';
        try {
          const buffer = await downloadMediaMessage(msg, 'buffer', {}, {
            logger: console,
            reuploadRequest: sock.updateMediaMessage
          });
          mediaBase64 = buffer.toString('base64');
          console.log('🎙️ تم تحميل الرسالة الصوتية');
        } catch (err) {
          console.error('❌ خطأ في تحميل الصوت:', err.message);
        }
      }

      if (!text && !mediaBase64) continue;

      const senderName = msg.pushName || 'الزائر الكريم';
      const payload = {
        event: 'messages.upsert',
        data: {
          key: msg.key,
          pushName: senderName,
          text,
          messageType,
          mediaBase64,
          mimeType
        }
      };

      // صورة تحتوي على كلمة حدث → إرسال لـ workflow الأحداث
      const isEventImage = messageType === 'image' &&
        EVENT_KEYWORDS.some(kw => text.includes(kw));

      if (isEventImage && N8N_EVENTS_WEBHOOK_URL) {
        console.log(`📢 إعلان/حدث من ${senderName} → يُرسل لـ Workflow الأحداث`);
        await sendToWebhook(N8N_EVENTS_WEBHOOK_URL, payload);
      } else {
        console.log(`📨 [${messageType}] من ${senderName}: ${text.substring(0, 50)}`);
        await sendToWebhook(N8N_WEBHOOK_URL, payload);
      }
    }
  });
}

app.listen(PORT, () => {
  console.log(`🚀 سيرفر Baileys يعمل على المنفذ ${PORT}`);
  startBot();
});
