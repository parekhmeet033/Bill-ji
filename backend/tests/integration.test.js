const request = require('supertest');
const bcrypt = require('bcryptjs');
const app = require('../src/app');
const { pool, initDatabase } = require('../src/config/database');
const { io: ClientIO } = require('socket.io-client');
const http = require('http');
const { initSocket, emitDashboardUpdate } = require('../src/config/socket');

describe('End-To-End Node.js Backend Integration Test', () => {
  let server;
  let serverPort;
  let testUser;
  let token;
  let clientSocket;

  beforeAll(async () => {
    // 1. Initialize Database Schema
    await initDatabase();

    // 2. Start HTTP & Socket.IO server on dynamic port
    server = http.createServer(app);
    initSocket(server);
    await new Promise((resolve) => server.listen(0, resolve));
    serverPort = server.address().port;

    // 3. Ensure a test user exists in MySQL DB without altering production users
    const [existing] = await pool.query('SELECT * FROM users WHERE email = ? LIMIT 1', ['test_integration@lineless.com']);

    if (existing.length > 0) {
      testUser = existing[0];
    } else {
      const hashedPassword = await bcrypt.hash('Password123!', 10);
      const [res] = await pool.query(
        'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
        ['Test Integration User', 'test_integration@lineless.com', hashedPassword, 'admin']
      );
      const [inserted] = await pool.query('SELECT * FROM users WHERE id = ?', [res.insertId]);
      testUser = inserted[0];
    }
  }, 30000);

  afterAll(async () => {
    if (clientSocket && clientSocket.connected) {
      clientSocket.disconnect();
    }
    if (server) {
      await new Promise((resolve) => server.close(resolve));
    }
    await pool.end();
  }, 30000);

  it('1. Verify /health Endpoint', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual(true);
    expect(res.body.message).toEqual('LineLess Backend is Healthy');
  });

  it('2. Authenticate Test User via /api/login', async () => {
    const res = await request(app).post('/api/login').send({
      email: testUser.email,
      password: 'Password123!'
    });

    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual(true);
    expect(res.body.token).toBeDefined();
    expect(res.body.data.id).toEqual(testUser.id);
    token = res.body.token;
  });

  it('3. Test GET /health with authenticated user header', async () => {
    const res = await request(app)
      .get('/health')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toEqual(200);
  });

  it('4. Test POST /api/dashboard', async () => {
    const res = await request(app)
      .post('/api/dashboard')
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual(true);
    expect(res.body.data).toHaveProperty('user_id');
    expect(res.body.data).toHaveProperty('running_token');
    expect(res.body.data).toHaveProperty('today_total_orders');
    expect(res.body.data).toHaveProperty('today_pending_orders');
    expect(res.body.data).toHaveProperty('today_completed_orders');
    expect(res.body.data).toHaveProperty('today_dispatched_orders');
    expect(res.body.data).toHaveProperty('recent_orders');
  });

  it('5. Test POST /api/menu-list', async () => {
    const res = await request(app)
      .post('/api/menu-list')
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual(true);
    expect(Array.isArray(res.body.product)).toEqual(true);
  });

  it('6. Test POST /api/category-list', async () => {
    const res = await request(app)
      .post('/api/category-list')
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual(true);
    expect(Array.isArray(res.body.data)).toEqual(true);
  });

  it('7. Test POST /api/orders-list', async () => {
    const res = await request(app)
      .post('/api/orders-list')
      .set('Authorization', `Bearer ${token}`)
      .send({
        status: 'All',
        order_type: 'All',
        search: '',
        start_date: '',
        end_date: '',
        page: 1
      });

    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual(true);
    expect(Array.isArray(res.body.data)).toEqual(true);
    expect(res.body.pagination).toBeDefined();
    expect(res.body.pagination).toHaveProperty('current_page');
    expect(res.body.pagination).toHaveProperty('last_page');
  });

  it('8. Test POST /api/settings (Get)', async () => {
    const res = await request(app)
      .post('/api/settings')
      .set('Authorization', `Bearer ${token}`)
      .send({ type: 'get' });

    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual(true);
    expect(res.body.data).toHaveProperty('user_id');
    expect(res.body.data).toHaveProperty('shop_open');
    expect(res.body.data).toHaveProperty('morning_start');
  });

  it('9. Test POST /api/pending-tables', async () => {
    const res = await request(app)
      .post('/api/pending-tables')
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual(true);
    expect(Array.isArray(res.body.data)).toEqual(true);
  });

  it('10. Test POST /api/reports-analytics', async () => {
    const res = await request(app)
      .post('/api/reports-analytics')
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual(true);
    expect(res.body.data).toHaveProperty('today_revenue');
    expect(res.body.data).toHaveProperty('total_sales');
    expect(res.body.data).toHaveProperty('total_orders');
  });

  it('11. Test Socket.IO / Reverb Realtime Connection & Event Broadcast', async () => {
    clientSocket = ClientIO(`http://localhost:${serverPort}`, {
      transports: ['websocket']
    });

    await new Promise((resolve) => clientSocket.on('connect', resolve));
    expect(clientSocket.connected).toEqual(true);

    // Subscribe to shop room and Pusher/Reverb channel
    clientSocket.emit('join_shop', testUser.id);
    clientSocket.emit('pusher:subscribe', { data: { channel: 'dashboard' } });

    // Wait for dashboard.updated event
    const eventPromise = new Promise((resolve) => {
      clientSocket.on('dashboard.updated', (payload) => {
        resolve(payload);
      });
      clientSocket.on('message', (msgStr) => {
        try {
          const parsed = JSON.parse(msgStr);
          if (parsed.event === 'dashboard.updated') {
            resolve(parsed);
          }
        } catch (_) {}
      });
    });

    // Emit dashboard update
    emitDashboardUpdate(testUser.id);

    const receivedEvent = await eventPromise;
    expect(receivedEvent).toBeDefined();
    expect(receivedEvent.event).toEqual('dashboard.updated');
    expect(receivedEvent.data.user_id).toEqual(testUser.id.toString());
  }, 10000);
});
