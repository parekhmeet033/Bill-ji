const tableRepository = require('../repositories/tableRepository');
const { emitDashboardUpdate } = require('../config/socket');

class TableService {
  async getPendingTables(userId) {
    return await tableRepository.getPendingTables(userId);
  }

  async saveTableOrder(userId, data) {
    const result = await tableRepository.saveTableOrder(userId, data);
    // Realtime notification to dashboard & kitchen
    emitDashboardUpdate(userId);
    return result;
  }

  async cancelTableOrder(userId, tableNo) {
    const result = await tableRepository.cancelTableOrder(userId, tableNo);
    // Realtime notification to dashboard & kitchen & tables
    emitDashboardUpdate(userId);
    return result;
  }
}

module.exports = new TableService();
