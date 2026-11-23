const path = require('path');
const userRepository = require('../repositories/userRepository');
const menuRepository = require('../repositories/menuRepository');
const orderRepository = require('../repositories/orderRepository');
const { emitDashboardUpdate } = require('../config/socket');

const viewsDir = path.join(__dirname, '../views/public');

function toMinutes(timeStr) {
  if (!timeStr) return null;
  const m = /^(\d{1,2}):(\d{2})(?::\d{2})?$/.exec(String(timeStr).trim());
  if (!m) return null;
  const h = parseInt(m[1], 10), min = parseInt(m[2], 10);
  if (h > 23 || min > 59) return null;
  return h * 60 + min;
}

function cleanTime(timeStr) {
  if (!timeStr) return '';
  const m = /^(\d{1,2}:\d{2})/.exec(String(timeStr).trim());
  return m ? m[1] : String(timeStr);
}

function getLocalCurrentMinutes() {
  const now = new Date();
  const utcTotalMinutes = now.getUTCHours() * 60 + now.getUTCMinutes();
  const istTotalMinutes = (utcTotalMinutes + 330) % 1440;
  return istTotalMinutes;
}

function isShopOpenNow(settings = {}) {
  if (String(settings.shop_open) === '1' || settings.shop_open === true) {
    return false;
  }

  const cur = getLocalCurrentMinutes();

  const windows = [
    [settings.morning_start, settings.morning_end],
    [settings.afternoon_start, settings.afternoon_end],
    [settings.evening_start, settings.evening_end]
  ];

  let validWindowFound = false;

  for (const [start, end] of windows) {
    const s = toMinutes(start);
    const e = toMinutes(end);

    if (s == null || e == null) continue;
    if (s === e) continue;

    validWindowFound = true;

    if (s < e) {
      if (cur >= s && cur <= e) return true;
    } else {
      if (cur >= s || cur <= e) return true;
    }
  }

  if (!validWindowFound) {
    return String(settings.shop_open) === '0' || settings.shop_open === 0 || settings.shop_open === false;
  }

  return false;
}

class PublicController {
  // ---- Pages ----
  menuPage(req, res) {
    res.sendFile(path.join(viewsDir, 'menu.html'));
  }

  posPage(req, res) {
    res.sendFile(path.join(viewsDir, 'pos.html'));
  }

  privacyPage(req, res) {
    res.sendFile(path.join(viewsDir, 'privacy.html'));
  }

  // ---- Data ----
  async shopData(req, res) {
    try {
      const shop = await userRepository.getShopBySlug(req.params.slug);
      if (!shop) {
        return res.status(404).json({ status: false, success: false, message: 'Shop not found' });
      }
      const categories = await menuRepository.getTableProducts(shop.id);
      const runningToken = await orderRepository.getRunningToken(shop.id);
      res.json({
        status: true,
        success: true,
        data: {
          shop: {
            id: shop.id,
            name: shop.name,
            slug: shop.slug,
            status: shop.status,
            running_token: runningToken,
            shop_open: shop.settings.shop_open,
            is_open: isShopOpenNow(shop.settings),
            hours: {
              morning: [cleanTime(shop.settings.morning_start), cleanTime(shop.settings.morning_end)],
              afternoon: [cleanTime(shop.settings.afternoon_start), cleanTime(shop.settings.afternoon_end)],
              evening: [cleanTime(shop.settings.evening_start), cleanTime(shop.settings.evening_end)]
            },
            mode: shop.settings.opration_mode_status || 'both',
            number_of_tables: shop.settings.number_of_tables || 0,
            generated_code: shop.settings.generated_code || null,
            category_display: shop.settings.category_display != null ? String(shop.settings.category_display) : '1',
            gst_enabled: shop.settings.gst_enabled == 1 || shop.settings.gst_enabled == '1' ? 1 : 0,
            gstin: shop.settings.gstin || '',
            legal_business_name: shop.settings.legal_business_name || '',
            business_address: shop.settings.business_address || '',
            state: shop.settings.state || '',
            state_code: shop.settings.state_code || ''
          },
          categories
        }
      });
    } catch (err) {
      res.status(500).json({ status: false, success: false, message: err.message });
    }
  }

  async submitOrder(req, res) {
    try {
      const shop = await userRepository.getShopBySlug(req.params.slug);
      if (!shop) {
        return res.status(404).json({ status: false, success: false, message: 'Shop not found' });
      }
      const { customer_name, customer_mobile, special_note, order_type, payment_type, items } = req.body;
      if (!Array.isArray(items) || items.length === 0) {
        return res.status(400).json({ status: false, success: false, message: 'Cart is empty' });
      }
      const result = await orderRepository.createDirectOrder(shop.id, {
        customer_name, customer_mobile, special_note, order_type, payment_type, items
      });
      emitDashboardUpdate(shop.id, result.tokenNo);
      res.json({ status: true, success: true, message: 'Order placed', data: result });
    } catch (err) {
      res.status(500).json({ status: false, success: false, message: err.message });
    }
  }

  async submitMenuOrder(req, res) {
    try {
      const shop = await userRepository.getShopBySlug(req.params.slug);
      if (!shop) {
        return res.status(404).json({ status: false, success: false, message: 'Shop not found' });
      }
      if (!isShopOpenNow(shop.settings)) {
        return res.status(400).json({ status: false, success: false, message: 'Sorry, the shop is currently closed' });
      }
      const { customer_name, customer_mobile, special_note, items } = req.body;
      if (!customer_name || !customer_name.trim()) {
        return res.status(400).json({ status: false, success: false, message: 'Please enter your name' });
      }
      const mobileDigits = String(customer_mobile || '').replace(/\D/g, '');
      if (mobileDigits.length !== 10) {
        return res.status(400).json({ status: false, success: false, message: 'Mobile number must be exactly 10 digits' });
      }
      if (!Array.isArray(items) || items.length === 0) {
        return res.status(400).json({ status: false, success: false, message: 'Your cart is empty' });
      }
      const result = await orderRepository.createDirectOrder(shop.id, {
        customer_name, customer_mobile, special_note,
        order_type: 'qr',
        order_status: 'pending',
        items
      });
      emitDashboardUpdate(shop.id, result.tokenNo);
      res.json({ status: true, success: true, message: 'Order placed', data: result });
    } catch (err) {
      res.status(500).json({ status: false, success: false, message: err.message });
    }
  }

  async getOrderStatus(req, res) {
    try {
      const order = await orderRepository.getPublicOrderById(req.params.orderId);
      if (!order) {
        return res.status(404).json({ status: false, success: false, message: 'Order not found' });
      }
      res.json({ status: true, success: true, data: order });
    } catch (err) {
      res.status(500).json({ status: false, success: false, message: err.message });
    }
  }

  async cancelOrder(req, res) {
    try {
      const order = await orderRepository.cancelPublicOrder(req.params.orderId);
      if (!order) {
        return res.status(404).json({ status: false, success: false, message: 'Order not found' });
      }
      emitDashboardUpdate(order.user_id, order.token_no);
      res.json({ status: true, success: true, message: 'Order cancelled successfully', data: order });
    } catch (err) {
      res.status(400).json({ status: false, success: false, message: err.message });
    }
  }

  async editOrder(req, res) {
    try {
      const { customer_name, customer_mobile, special_note, items } = req.body;
      const order = await orderRepository.editPublicOrder(req.params.orderId, {
        customer_name, customer_mobile, special_note, items
      });
      if (!order) {
        return res.status(404).json({ status: false, success: false, message: 'Order not found' });
      }
      emitDashboardUpdate(order.user_id, order.token_no);
      res.json({ status: true, success: true, message: 'Order updated successfully', data: order });
    } catch (err) {
      res.status(400).json({ status: false, success: false, message: err.message });
    }
  }
}

module.exports = new PublicController();
