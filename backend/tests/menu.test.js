const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/database');

describe('Menu & Category APIs', () => {
  afterAll(async () => {
    await pool.end();
  });

  it('POST /api/category-list without token should return 401', async () => {
    const res = await request(app).post('/api/category-list').send({});
    expect(res.statusCode).toEqual(401);
  });

  it('POST /api/menu-list without token should return 401', async () => {
    const res = await request(app).post('/api/menu-list').send({});
    expect(res.statusCode).toEqual(401);
  });

  it('POST /api/table-product-list without token should return 401', async () => {
    const res = await request(app).post('/api/table-product-list').send({});
    expect(res.statusCode).toEqual(401);
  });
});
