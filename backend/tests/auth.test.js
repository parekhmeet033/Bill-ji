const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/database');

describe('Auth & Settings APIs', () => {
  afterAll(async () => {
    await pool.end();
  });

  it('POST /api/login with invalid credentials should return 400', async () => {
    const res = await request(app).post('/api/login').send({
      email: 'nonexistent@example.com',
      password: 'wrongpassword'
    });

    expect(res.statusCode).toEqual(400);
    expect(res.body.status).toEqual(false);
    expect(res.body.message).toBeDefined();
  });

  it('POST /api/login missing email or password should return 400', async () => {
    const res = await request(app).post('/api/login').send({
      email: 'test@example.com'
    });

    expect(res.statusCode).toEqual(400);
    expect(res.body.status).toEqual(false);
  });
});
