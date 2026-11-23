const { initializeApp, cert } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const path = require('path');
const fs = require('fs');
const logger = require('./logger');
const { pool } = require('../config/database');

let fcmInitialized = false;

function initFCM() {
  if (fcmInitialized) return;

  try {
    const keyPath = path.join(__dirname, '../config/serviceAccountKey.json');
    if (fs.existsSync(keyPath)) {
      const serviceAccount = require(keyPath);
      initializeApp({
        credential: cert(serviceAccount)
      });
      fcmInitialized = true;
      logger.info('[FCM] Firebase Admin SDK initialized successfully via serviceAccountKey.json');
    } else if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      initializeApp({
        credential: cert(serviceAccount)
      });
      fcmInitialized = true;
      logger.info('[FCM] Firebase Admin SDK initialized successfully via env variable');
    } else {
      logger.warn('[FCM] serviceAccountKey.json not found in src/config/. Push notifications disabled until key is placed.');
    }
  } catch (err) {
    logger.error('[FCM ERROR] Failed to initialize Firebase Admin SDK:', err.message);
  }
}

// Initialize on module load
initFCM();

/**
 * Sends a high-priority FCM Push Notification when a new order arrives.
 * Directly targets the registered device tokens of the shop to avoid duplicates.
 */
async function sendNewOrderPushNotification(userId, tokenNo, totalAmount) {
  if (!fcmInitialized) {
    initFCM();
    if (!fcmInitialized) return;
  }

  try {
    const title = '🔔 New Order Received!';
    const body = `Token #${tokenNo} • Total: ₹${parseFloat(totalAmount || 0).toFixed(0)}`;

    const notificationPayload = {
      notification: {
        title,
        body
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        shop_id: userId.toString(),
        token_no: tokenNo.toString()
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'high_importance_channel',
          priority: 'high',
          visibility: 'public'
        }
      }
    };

    const messaging = getMessaging();

    // Query active device FCM tokens for this shop
    const [devices] = await pool.query(
      'SELECT fcm_token FROM user_devices WHERE user_id = ? AND fcm_token IS NOT NULL AND fcm_token != ""',
      [userId]
    );

    const tokens = [...new Set(devices.map((d) => d.fcm_token).filter(Boolean))];

    if (tokens.length > 0) {
      // Send single targeted multicast directly to the shop's devices
      const response = await messaging.sendEachForMulticast({
        tokens,
        ...notificationPayload
      });
      logger.info(`[FCM] Targeted notification sent to ${tokens.length} device(s) for shop ${userId} (Success: ${response.successCount})`);
    } else {
      // Fallback to shop topic if no direct device tokens are registered
      await messaging.send({
        ...notificationPayload,
        topic: `orders_${userId}`
      });
      logger.info(`[FCM] Fallback topic notification sent for shop ${userId}, token #${tokenNo}`);
    }
  } catch (error) {
    logger.error(`[FCM ERROR] Failed to send push notification: ${error.message}`);
  }
}

module.exports = {
  sendNewOrderPushNotification
};
