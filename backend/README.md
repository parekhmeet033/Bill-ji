# LineLess Node.js + Express + MySQL + Socket.IO Backend

Production-ready, high-performance Node.js backend replacing the legacy Laravel backend for the **LineLess POS** Flutter application.

---

## 🚀 Features

- **Express.js API Engine**: Fully compatible with existing Flutter `ApiResponse` and `ApiConstants`.
- **MySQL Data Layer**: Uses existing production database safely with zero data destruction.
- **Socket.IO Real-time Engine**: Isolated per-shop real-time room events replacing Laravel Reverb.
- **JWT Authentication**: Secure Bearer Token authentication.
- **Multipart Uploads**: Serves `/storage/products` and `/uploads/categories` static assets natively.
- **Production Security**: Helmet, CORS, Rate Limiting, Input Sanitization, SQL Injection prevention.

---

## 🛠️ Requirements & Setup

### Prerequisites
- Node.js LTS (v18.x or v20.x+)
- MySQL Server 8.x+
- PM2 (for production)
- Nginx (for production reverse proxy)

### 1. Installation
Navigate to the `/backend` folder:
```bash
cd backend
npm install
```

### 2. Environment Configuration
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Edit `.env` with your MySQL database credentials and secrets:
```env
PORT=3009
NODE_ENV=production

DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=lineless_db

JWT_SECRET=your_super_secret_jwt_key
JWT_EXPIRES_IN=30d

APP_URL=https://lineless.goalscripture.in
```

### 3. Development Mode
Run using `nodemon`:
```bash
npm run dev
```

### 4. Running Tests
Run automated test suite:
```bash
npm test
```

---

## 📦 Production Deployment (PM2 + Nginx)

### Start with PM2
```bash
npm install -g pm2
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup
```

### Nginx Configuration Sample (`/etc/nginx/sites-available/lineless`)
```nginx
server {
    server_name lineless.goalscripture.in;

    location / {
        proxy_pass http://127.0.0.1:3009;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Static uploads caching
    location /storage/products/ {
        alias /var/www/lineless/backend/uploads/products/;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    location /uploads/categories/ {
        alias /var/www/lineless/backend/uploads/categories/;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }
}
```

---

## 📜 Documentation
- Complete API Specifications: `../docs/API.md`
- Database Mappings: `../docs/DATABASE.md`
- Real-time / Socket.IO Specifications: `../docs/REALTIME.md`
- Flutter Backend Analysis: `../docs/FLUTTER_BACKEND_ANALYSIS.md`
