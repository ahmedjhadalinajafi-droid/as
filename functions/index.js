const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

admin.initializeApp();

exports.processNotificationQueue = onDocumentCreated(
  'notification_queue/{docId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();

    // Delete trigger doc immediately
    await snap.ref.delete();

    if (data.type === 'new_question') {
      // Notify admin device
      const adminDoc = await admin.firestore()
        .collection('config').doc('admin_device').get();
      const token = adminDoc.data()?.fcmToken;
      if (!token) return;

      await admin.messaging().send({
        token,
        notification: {
          title: 'سؤال جديد 📩',
          body: data.questionPreview || 'وصل سؤال جديد بانتظار الرد',
        },
        data: { page: 'questions' },
        android: { notification: { channelId: 'announcements' } },
      }).catch(e => console.error('Notify admin failed:', e));

    } else if (data.type === 'answered') {
      // Notify client that their question was answered
      const token = data.clientToken;
      if (!token) return;

      await admin.messaging().send({
        token,
        notification: {
          title: 'تم الرد على سؤالك ✅',
          body: data.answerPreview || 'افتح التطبيق لمشاهدة الجواب',
        },
        data: { page: 'questions' },
        android: { notification: { channelId: 'announcements' } },
      }).catch(e => console.error('Notify client failed:', e));
    }
  }
);
