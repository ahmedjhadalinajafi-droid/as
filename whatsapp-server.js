const { default: makeWASocket, useMultiFileAuthState, DisconnectReason, fetchLatestBaileysVersion } = require('@whiskeysockets/baileys');
const { Boom } = require('@hapi/boom');
const express = require('express');
const qrcode = require('qrcode-terminal');
require('dotenv').config();

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const N8N_WEBHOOK_URL = process.env.N8N_WEBHOOK_URL;
const SERVER_SECRET = process.env.SERVER_SECRET || 'masjid-secret';

let sock = null;

// Middleware: verify secret from n8n
function checkSecret(req, res, next) {
  if (req.headers['x-secret'] !== SERVER_SECRET) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
}

// n8n calls this to send a WhatsApp message
app.post('/send', checkSecret, async (req, res) => {
  const { number, text } = req.body;

  if (!sock) {
    return res.status(503).json({ error: 'واتساب غير متصل بعد' });
  }

  try {
    const jid = number.includes('@') ? number : `${number}@s.whatsapp.net`;
    await sock.sendMessage(jid, { text });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Health check
app.get('/status', (req, res) => {
  res.json({ connected: sock !== null });
});

async function forwardToN8n(payload) {
  if (!N8N_WEBHOOK_URL) return;
  try {
    await fetch(N8N_WEBHOOK_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
  } catch (err) {
    console.error('❌ تعذّر الإرسال إلى n8n:', err.message);
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

      const text =
        msg.message?.conversation ||
        msg.message?.extendedTextMessage?.text ||
        msg.message?.imageMessage?.caption ||
        '';

      if (!text.trim()) continue;

      console.log(`📨 رسالة من ${msg.pushName || 'مجهول'}: ${text}`);

      await forwardToN8n({
        event: 'messages.upsert',
        data: {
          key: msg.key,
          message: msg.message,
          pushName: msg.pushName || 'الزائر الكريم'
        }
      });
    }
  });
}

app.listen(PORT, () => {
  console.log(`🚀 سيرفر Baileys يعمل على المنفذ ${PORT}`);
  startBot();
});
