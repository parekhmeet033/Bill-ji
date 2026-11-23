const bcrypt = require('bcryptjs');
const userRepository = require('../repositories/userRepository');
const orderRepository = require('../repositories/orderRepository');
const { emitDashboardUpdate } = require('../config/socket');
const { generateToken } = require('../utils/tokenGenerator');

class AuthService {
  async login(email, password, deviceId, deviceType, fcmToken) {
    const user = await userRepository.findByEmail(email);
    if (!user) {
      throw new Error('Invalid email or password');
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      // Also allow plain text match fallback for legacy compatibility
      if (password !== user.password) {
        throw new Error('Invalid email or password');
      }
    }

    // Update device_id and fcm_token if provided
    await userRepository.updateDeviceAndFcmToken(user.id, deviceId, deviceType, fcmToken);

    const token = generateToken(user);

    return {
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone || null,
        role: user.role || 'user',
        profile_image: user.profile_image || null
      }
    };
  }

  async logout(userId, deviceId) {
    await userRepository.updateDeviceAndFcmToken(userId, null, null, null);
    try {
      await orderRepository.clearDraftPosOrder(userId);
    } catch (_) {}
    emitDashboardUpdate(userId);
    return true;
  }

  async forgotPin(userId, oldPin, newPin) {
    const user = await userRepository.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    // Laravel stores user_pin as a bcrypt hash — verify the old PIN with bcrypt
    // (plaintext fallback for legacy data).
    if (user.user_pin) {
      let ok = false;
      try {
        ok = await bcrypt.compare(String(oldPin || ''), user.user_pin);
      } catch (_) {
        ok = false;
      }
      if (!ok && String(oldPin) !== String(user.user_pin)) {
        throw new Error('Incorrect old PIN');
      }
    }

    // Store the new PIN hashed, to stay compatible with the Laravel schema.
    const hashedPin = await bcrypt.hash(String(newPin), 10);
    await userRepository.updatePin(userId, hashedPin);
    return true;
  }
}

module.exports = new AuthService();
