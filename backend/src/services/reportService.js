const bcrypt = require('bcryptjs');
const orderRepository = require('../repositories/orderRepository');
const userRepository = require('../repositories/userRepository');

class ReportService {
  async getReportsAnalytics(userId, userPin, filters = {}) {
    const user = await userRepository.findById(userId);

    // If user has a PIN configured, verify it. Laravel stores the PIN as a bcrypt
    // hash, so compare with bcrypt (with a plaintext fallback for legacy data).
    if (user && user.user_pin) {
      if (!userPin) {
        throw new Error('Invalid PIN provided');
      }
      let ok = false;
      try {
        ok = await bcrypt.compare(String(userPin), user.user_pin);
      } catch (_) {
        ok = false;
      }
      if (!ok && String(userPin) !== String(user.user_pin)) {
        throw new Error('Invalid PIN provided');
      }
    }

    return await orderRepository.getReportsAnalytics(userId, filters);
  }
}

module.exports = new ReportService();
