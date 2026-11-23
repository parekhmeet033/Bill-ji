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
}

module.exports = new TableService();
