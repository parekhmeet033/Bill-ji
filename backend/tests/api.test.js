const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/database');

describe('LineLess API Health & Endpoints', () => {
  afterAll(async () => {
    await pool.end();
  });

  it('GET /health should return 200 and healthy status', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('status', true);
    expect(res.body).toHaveProperty('message', 'LineLess Backend is Healthy');
  });

  it('GET /privacy-policy should return 200 and privacy policy page', async () => {
    const res = await request(app).get('/privacy-policy');
    expect(res.statusCode).toEqual(200);
    expect(res.text).toContain('Privacy Policy');
  });

  it('POST /api/login without body should return 400 error', async () => {
    const res = await request(app).post('/api/login').send({});
    expect(res.statusCode).toEqual(400);
    expect(res.body).toHaveProperty('status', false);
  });

  it('Protected route /api/dashboard without token should return 401', async () => {
    const res = await request(app).post('/api/dashboard').send({});
    expect(res.statusCode).toEqual(401);
    expect(res.body).toHaveProperty('status', false);
  });

  it('Protected route /api/orders-list without token should return 401', async () => {
    const res = await request(app).post('/api/orders-list').send({});
    expect(res.statusCode).toEqual(401);
    expect(res.body).toHaveProperty('status', false);
  });
});
