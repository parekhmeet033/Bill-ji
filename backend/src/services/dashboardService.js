const userRepository = require('../repositories/userRepository');
const settingsRepository = require('../repositories/settingsRepository');
const orderRepository = require('../repositories/orderRepository');

class DashboardService {
  async getDashboardData(userId) {
    const user = await userRepository.findById(userId);
    const settings = await settingsRepository.getByUserId(userId);
    const orderData = await orderRepository.getDashboardData(userId);

    return {
      user_id: userId,
      user_name: user ? user.name : 'BillJi Restaurant',
      profile_banner: user ? user.profile_banner : null,
      running_token: orderData.running_token,
      today_total_orders: orderData.today_total_orders,
      today_pending_orders: orderData.today_pending_orders,
      today_completed_orders: orderData.today_completed_orders,
      today_dispatched_orders: orderData.today_dispatched_orders,
      generated_code: settings ? settings.generated_code : '',
      slug: user ? user.slug : '',
      opration_mode_status: settings ? settings.opration_mode_status : 'both',
      number_of_tables: settings ? settings.number_of_tables : 10,
      recent_orders: orderData.recent_orders
    };
  }
}

module.exports = new DashboardService();
