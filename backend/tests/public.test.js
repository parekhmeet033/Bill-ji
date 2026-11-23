const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/database');

describe('Public QR Menu & Shop Data APIs', () => {
  afterAll(async () => {
    await pool.end();
  });

  it('GET /public-api/shop/nonexistent-shop should return 404', async () => {
    const res = await request(app).get('/public-api/shop/nonexistent-shop-slug-123');
    expect(res.statusCode).toEqual(404);
    expect(res.body.status).toEqual(false);
  });
});
