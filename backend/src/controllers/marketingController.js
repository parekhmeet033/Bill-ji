// Marketing-site lead endpoints (Book Demo / Contact) used by the BillJi website.
// Mirrors the website's own server validation so the forms work when they POST to
// /api/* on this backend. No DB writes (matches existing behavior).

function isEmail(v) {
  return typeof v === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v.trim());
}
function digits(v) {
  return String(v || '').replace(/\D/g, '');
}
function req(v) {
  return typeof v === 'string' && v.trim().length > 0;
}
function notPastDate(v) {
  if (!v) return true;
  const d = new Date(v);
  if (isNaN(d)) return false;
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return d >= today;
}

class MarketingController {
  async bookDemo(req_, res) {
    const b = req_.body || {};
    const errors = {};
    if (!req(b.name)) errors.name = 'Your name is required';
    if (!isEmail(b.email)) errors.email = 'A valid email is required';
    if (digits(b.phone || b.mobile).length < 10) errors.phone = 'A valid mobile number is required';
    if (!req(b.restaurantName)) errors.restaurantName = 'Restaurant name is required';
    if (!notPastDate(b.preferredDate)) errors.preferredDate = 'Preferred date cannot be in the past';

    if (Object.keys(errors).length > 0) {
      return res.status(400).json({ status: false, success: false, message: 'Backend Validation Failed', errors });
    }
    return res.status(200).json({
      status: true,
      success: true,
      message: 'Demo booked successfully!',
      data: {
        name: b.name.trim(),
        email: b.email.trim(),
        phone: (b.phone || b.mobile).trim(),
        restaurantName: b.restaurantName.trim(),
        type: b.type || 'Cloud Kitchen',
        preferredDate: (b.preferredDate || '').trim()
      }
    });
  }

  async contact(req_, res) {
    const b = req_.body || {};
    const errors = {};
    if (!req(b.name)) errors.name = 'Full name is required';
    if (!req(b.businessName)) errors.businessName = 'Business name is required';
    if (!isEmail(b.email)) errors.email = 'A valid email is required';
    if (digits(b.mobile || b.phone).length < 10) errors.mobile = 'A valid mobile number is required';
    if (!req(b.city)) errors.city = 'City is required';
    if (!req(b.message)) errors.message = 'Message is required';
    if (b.preferredDate && !notPastDate(b.preferredDate)) errors.preferredDate = 'Preferred date cannot be in the past';

    if (Object.keys(errors).length > 0) {
      return res.status(400).json({ status: false, success: false, message: 'Backend Validation Failed', errors });
    }
    return res.status(200).json({
      status: true,
      success: true,
      message: 'Contact request received successfully!',
      data: {
        name: b.name.trim(),
        email: b.email.trim(),
        mobile: (b.mobile || b.phone).trim(),
        businessName: b.businessName.trim(),
        city: b.city.trim()
      }
    });
  }
}

module.exports = new MarketingController();
