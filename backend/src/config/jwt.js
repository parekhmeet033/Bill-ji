module = module.exports = {
  secret: process.env.JWT_SECRET || 'lineless_super_secret_jwt_key_2026',
  expiresIn: process.env.JWT_EXPIRES_IN || '30d'
};
