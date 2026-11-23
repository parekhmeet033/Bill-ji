const settingsRepository = require('../repositories/settingsRepository');

class SettingsService {
  async getSettings(userId) {
    return await settingsRepository.getByUserId(userId);
  }

  async updateSettings(userId, settingsData) {
    return await settingsRepository.updateByUserId(userId, settingsData);
  }
}

module.exports = new SettingsService();
