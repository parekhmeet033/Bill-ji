const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/database');

describe('Orders & Table APIs', () => {
  afterAll(async () => {
    await pool.end();
  });

  it('POST /api/orders-list without token should return 401', async () => {
    const res = await request(app).post('/api/orders-list').send({});
    expect(res.statusCode).toEqual(401);
  });

  it('POST /api/orders-status without token should return 401', async () => {
    const res = await request(app).post('/api/orders-status').send({});
    expect(res.statusCode).toEqual(401);
  });

  it('POST /api/pending-tables without token should return 401', async () => {
    const res = await request(app).post('/api/pending-tables').send({});
    expect(res.statusCode).toEqual(401);
  });

  it('POST /api/save-table-order without token should return 401', async () => {
    const res = await request(app).post('/api/save-table-order').send({});
    expect(res.statusCode).toEqual(401);
  });
});
