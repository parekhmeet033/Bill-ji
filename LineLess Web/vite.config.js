import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    {
      name: 'diagnostics-logger',
      configureServer(server) {
        server.middlewares.use((req, res, next) => {
          if (req.url && !req.url.startsWith('/@') && !req.url.includes('node_modules')) {
            console.log(`[REQ] ${req.method} ${req.url}`);
          }
          if (req.url && req.url.startsWith('/_diagnostics/error')) {
            let body = '';
            req.on('data', c => body += c);
            req.on('end', () => {
              console.error('\n🔴 [CLIENT BROWSER ERROR]:', body, '\n');
              res.setHeader('Content-Type', 'application/json');
              res.end(JSON.stringify({ ok: true }));
            });
            return;
          }
          if (req.url && req.url.startsWith('/_diagnostics/ping')) {
            let body = '';
            req.on('data', c => body += c);
            req.on('end', () => {
              console.log('\n🟢 [CLIENT BROWSER PING]:', body, '\n');
              res.setHeader('Content-Type', 'application/json');
              res.end(JSON.stringify({ ok: true }));
            });
            return;
          }
          next();
        });
      }
    }
  ],
  server: {
    host: '0.0.0.0',
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:3009',
        changeOrigin: true,
        secure: false,
      },
    },
  },
  preview: {
    host: '0.0.0.0',
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:3009',
        changeOrigin: true,
        secure: false,
      },
    },
  },
})
