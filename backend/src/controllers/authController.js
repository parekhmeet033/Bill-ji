const authService = require('../services/authService');
const { successResponse, errorResponse } = require('../utils/responseFormatter');

class AuthController {
  async login(req, res, next) {
    try {
      const { email, password, device_id, device_type, fcm_token } = req.body;

      if (!email || !password) {
        return errorResponse(res, 'Email and password are required', 400);
      }

      const result = await authService.login(email, password, device_id, device_type, fcm_token);

      return res.status(200).json({
        status: true,
        success: true,
        message: 'Login successful',
        token: result.token,
        data: result.user
      });
    } catch (err) {
      return errorResponse(res, err.message || 'Login failed', 400);
    }
  }

  async logout(req, res, next) {
    try {
      const userId = req.user.id;
      const { device_id } = req.body;

      await authService.logout(userId, device_id);
      return successResponse(res, 'Successfully logged out');
    } catch (err) {
      return errorResponse(res, err.message || 'Logout failed', 400);
    }
  }

  async forgotPin(req, res, next) {
    try {
      const userId = req.user.id;
      const { old_pin, new_pin } = req.body;

      if (!old_pin || !new_pin) {
        return errorResponse(res, 'Old PIN and new PIN are required', 400);
      }

      await authService.forgotPin(userId, old_pin, new_pin);
      return successResponse(res, 'PIN updated successfully');
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to update PIN', 400);
    }
  }
}

module.exports = new AuthController();
