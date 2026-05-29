const { default: makeWASocket, useMultiFileAuthState, DisconnectReason, fetchLatestBaileysVersion } = require('@whiskeysockets/baileys');
const { Boom } = require('@hapi/boom');
const fs = require('fs');
require('dotenv').config();

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const MOSQUE_INFO = fs.readFileSync('./mosque_info.txt', 'utf8');

if (!GEMINI_API_KEY) {
  console.error('❌ خطأ: أضف GEMINI_API_KEY في ملف .env');
  process.exit(1);
}

async function askGemini(senderName, question) {
  const res = await fetch(
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
    {
      method: 'POST',
      headers: {
        'x-goog-api-key': GEMINI_API_KEY,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        system_instruction: {
          parts: [{ text: MOSQUE_INFO }]
        },
        contents: [{
          role: 'user',
          parts: [{ text: `${senderName} يسأل: ${question}` }]
        }],
        generationConfig: {
          maxOutputTokens: 600,
          temperature: 0.7
        }
      })
    }
  );

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Gemini API error: ${err}`);
  }

  const data = await res.json();
  return data.candidates[0].content.parts[0].text;
}

async function startBot() {
  const { state, saveCreds } = await useMultiFileAuthState('./auth_info');
  const { version } = await fetchLatestBaileysVersion();

  const sock = makeWASocket({
    version,
    auth: state,
    printQRInTerminal: true,
    browser: ['مسجد بوت', 'Chrome', '1.0']
  });

  sock.ev.on('creds.update', saveCreds);

  sock.ev.on('connection.update', ({ connection, lastDisconnect }) => {
    if (connection === 'close') {
      const code = new Boom(lastDisconnect?.error)?.output?.statusCode;
      if (code !== DisconnectReason.loggedOut) {
        console.log('🔄 إعادة الاتصال...');
        startBot();
      } else {
        console.log('🚪 تم تسجيل الخروج. احذف مجلد auth_info وأعد التشغيل.');
      }
    } else if (connection === 'open') {
      console.log('✅ البوت متصل بواتساب وجاهز لاستقبال الأسئلة!');
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

      const senderName = msg.pushName || 'الزائر الكريم';
      const from = msg.key.remoteJid;

      console.log(`\n📨 ${senderName}: ${text}`);

      try {
        await sock.sendPresenceUpdate('composing', from);
        const answer = await askGemini(senderName, text);
        await sock.sendMessage(from, { text: answer });
        console.log(`✅ تم الرد`);
      } catch (error) {
        console.error('❌ خطأ:', error.message);
        await sock.sendMessage(from, {
          text: 'عذراً، حدث خطأ تقني. يرجى المحاولة مرة أخرى أو التواصل مع المسجد مباشرة.'
        });
      }
    }
  });
}

startBot();
