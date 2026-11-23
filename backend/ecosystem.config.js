module.exports = {
  apps: [
    {
      name: 'lineless-backend',
      script: 'src/server.js',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'development',
        PORT: 3009
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3009
      }
    }
  ]
};
