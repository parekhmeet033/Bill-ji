const http = require('http');
const {
  validateEmail,
  validateMobile,
  validateBookingDate,
  validateRequired
} = require('./utils/validation');

const PORT = process.env.PORT || 5000;

function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Accept');
}

const server = http.createServer((req, res) => {
  setCorsHeaders(res);

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Parse JSON Body
  let body = '';
  req.on('data', chunk => {
    body += chunk.toString();
  });

  req.on('end', () => {
    let payload = {};
    try {
      if (body) {
        payload = JSON.parse(body);
      }
    } catch (e) {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: false, message: 'Invalid JSON body' }));
      return;
    }

    const url = req.url;

    // POST /api/book-demo
    if (req.method === 'POST' && url === '/api/book-demo') {
      const errors = {};

      const nameErr = validateRequired(payload.name, 'Your name');
      if (nameErr) errors.name = nameErr;

      const emailErr = validateEmail(payload.email);
      if (emailErr) errors.email = emailErr;

      const phoneErr = validateMobile(payload.phone || payload.mobile);
      if (phoneErr) errors.phone = phoneErr;

      const restaurantErr = validateRequired(payload.restaurantName, 'Restaurant name');
      if (restaurantErr) errors.restaurantName = restaurantErr;

      const dateErr = validateBookingDate(payload.preferredDate);
      if (dateErr) errors.preferredDate = dateErr;

      if (Object.keys(errors).length > 0) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: false,
          message: 'Backend Validation Failed',
          errors
        }));
        return;
      }

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        success: true,
        message: 'Demo booked successfully!',
        data: {
          name: payload.name.trim(),
          email: payload.email.trim(),
          phone: (payload.phone || payload.mobile).trim(),
          restaurantName: payload.restaurantName.trim(),
          type: payload.type || 'Cloud Kitchen',
          preferredDate: payload.preferredDate.trim()
        }
      }));
      return;
    }

    // POST /api/contact
    if (req.method === 'POST' && url === '/api/contact') {
      const errors = {};

      const nameErr = validateRequired(payload.name, 'Full name');
      if (nameErr) errors.name = nameErr;

      const businessErr = validateRequired(payload.businessName, 'Business name');
      if (businessErr) errors.businessName = businessErr;

      const emailErr = validateEmail(payload.email);
      if (emailErr) errors.email = emailErr;

      const mobileErr = validateMobile(payload.mobile || payload.phone);
      if (mobileErr) errors.mobile = mobileErr;

      const cityErr = validateRequired(payload.city, 'City');
      if (cityErr) errors.city = cityErr;

      const messageErr = validateRequired(payload.message, 'Message');
      if (messageErr) errors.message = messageErr;

      if (payload.preferredDate) {
        const dateErr = validateBookingDate(payload.preferredDate);
        if (dateErr) errors.preferredDate = dateErr;
      }

      if (Object.keys(errors).length > 0) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: false,
          message: 'Backend Validation Failed',
          errors
        }));
        return;
      }

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        success: true,
        message: 'Contact request received successfully!',
        data: {
          name: payload.name.trim(),
          email: payload.email.trim(),
          mobile: (payload.mobile || payload.phone).trim(),
          businessName: payload.businessName.trim(),
          city: payload.city.trim()
        }
      }));
      return;
    }

    // Health check endpoint
    if (req.method === 'GET' && url === '/api/health') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'ok', serverTime: new Date().toISOString() }));
      return;
    }

    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ success: false, message: 'Route not found' }));
  });
});

server.listen(PORT, () => {
  console.log(`Lineless Backend Validation API Server running on port ${PORT}`);
});
