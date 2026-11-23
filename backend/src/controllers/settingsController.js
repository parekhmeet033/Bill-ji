const settingsService = require('../services/settingsService');
const { successResponse, errorResponse } = require('../utils/responseFormatter');

class SettingsController {
  async handleSettings(req, res, next) {
    try {
      const userId = req.user.id;
      const { type } = req.body;

      if (type === 'get') {
        const settings = await settingsService.getSettings(userId);
        return successResponse(res, 'Settings fetched', settings);
      } else {
        const settings = await settingsService.updateSettings(userId, req.body);
        return successResponse(res, 'Settings updated', settings);
      }
    } catch (err) {
      return errorResponse(res, err.message || 'Settings request failed', 400);
    }
  }
}

module.exports = new SettingsController();
