const fs = require('fs');
const path = require('path');

class PDFDocument {
  constructor() {
    this.pages = [];
    this.pageWidth = 595.28;  // A4
    this.pageHeight = 841.89; // A4
  }

  addPage() {
    const page = {
      stream: []
    };
    this.pages.push(page);
    return page;
  }

  escapeText(str) {
    return str.replace(/\\/g, '\\\\').replace(/\(/g, '\\(').replace(/\)/g, '\\)');
  }

  // Draw rectangle
  drawRect(page, x, y, w, h, fillRGB = null, strokeRGB = null, lineWidth = 1) {
    let s = 'q\n';
    if (strokeRGB) {
      s += `${strokeRGB[0].toFixed(3)} ${strokeRGB[1].toFixed(3)} ${strokeRGB[2].toFixed(3)} RG\n`;
      s += `${lineWidth} w\n`;
    }
    if (fillRGB) {
      s += `${fillRGB[0].toFixed(3)} ${fillRGB[1].toFixed(3)} ${fillRGB[2].toFixed(3)} rg\n`;
    }
    s += `${x.toFixed(2)} ${y.toFixed(2)} ${w.toFixed(2)} ${h.toFixed(2)} re\n`;
    if (fillRGB && strokeRGB) {
      s += 'B\n';
    } else if (fillRGB) {
      s += 'f\n';
    } else if (strokeRGB) {
      s += 's\n';
    }
    s += 'Q\n';
    page.stream.push(s);
  }

  // Draw line
  drawLine(page, x1, y1, x2, y2, strokeRGB = [0.8, 0.8, 0.8], lineWidth = 1) {
    let s = 'q\n';
    s += `${strokeRGB[0].toFixed(3)} ${strokeRGB[1].toFixed(3)} ${strokeRGB[2].toFixed(3)} RG\n`;
    s += `${lineWidth} w\n`;
    s += `${x1.toFixed(2)} ${y1.toFixed(2)} m\n`;
    s += `${x2.toFixed(2)} ${y2.toFixed(2)} l\n`;
    s += 'S\nQ\n';
    page.stream.push(s);
  }

  // Draw Text
  drawText(page, text, x, y, options = {}) {
    const font = options.font || 'F1'; // F1 = Helvetica, F2 = Helvetica-Bold, F3 = Courier, F4 = Courier-Bold
    const size = options.size || 10;
    const color = options.color || [0.1, 0.1, 0.1];

    let s = 'q\nBT\n';
    s += `${color[0].toFixed(3)} ${color[1].toFixed(3)} ${color[2].toFixed(3)} rg\n`;
    s += `/${font} ${size} Tf\n`;
    s += `1 0 0 1 ${x.toFixed(2)} ${y.toFixed(2)} Tm\n`;
    s += `(${this.escapeText(text)}) Tj\n`;
    s += 'ET\nQ\n';
    page.stream.push(s);
  }

  build() {
    const totalPages = this.pages.length;
    // Add footers to all pages
    for (let i = 0; i < totalPages; i++) {
      const p = this.pages[i];
      this.drawLine(p, 40, 45, 555, 45, [0.85, 0.87, 0.9], 0.75);
      this.drawText(p, 'LineLess POS — Project Setup & Architecture Manual', 40, 32, { font: 'F1', size: 8, color: [0.5, 0.55, 0.6] });
      this.drawText(p, `Page ${i + 1} of ${totalPages}`, 505, 32, { font: 'F1', size: 8, color: [0.5, 0.55, 0.6] });
    }

    let pdf = '%PDF-1.4\n';
    const offsets = [];

    function addObj(str) {
      offsets.push(Buffer.byteLength(pdf, 'binary'));
      pdf += str + '\n';
    }

    // 1: Catalog
    addObj('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj');

    // 2: Pages root
    const pageObjStart = 3;
    const fontObjStart = pageObjStart + totalPages * 2;
    const kids = [];
    for (let i = 0; i < totalPages; i++) {
      kids.push(`${pageObjStart + (i * 2)} 0 R`);
    }
    addObj(`2 0 obj\n<< /Type /Pages /Kids [${kids.join(' ')}] /Count ${totalPages} >>\nendobj`);

    // Pages and content streams
    for (let i = 0; i < totalPages; i++) {
      const pageObjNum = pageObjStart + (i * 2);
      const contentObjNum = pageObjNum + 1;
      const contentStr = this.pages[i].stream.join('');
      const streamLen = Buffer.byteLength(contentStr, 'utf8');

      addObj(`${pageObjNum} 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595.28 841.89] /Contents ${contentObjNum} 0 R /Resources << /Font << /F1 ${fontObjStart} 0 R /F2 ${fontObjStart + 1} 0 R /F3 ${fontObjStart + 2} 0 R /F4 ${fontObjStart + 3} 0 R >> >> >>\nendobj`);
      addObj(`${contentObjNum} 0 obj\n<< /Length ${streamLen} >>\nstream\n${contentStr}\nendstream\nendobj`);
    }

    // Standard 14 Fonts
    addObj(`${fontObjStart} 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj`);
    addObj(`${fontObjStart + 1} 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\nendobj`);
    addObj(`${fontObjStart + 2} 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>\nendobj`);
    addObj(`${fontObjStart + 3} 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Courier-Bold >>\nendobj`);

    const startxref = Buffer.byteLength(pdf, 'binary');
    pdf += 'xref\n0 ' + (offsets.length + 1) + '\n';
    pdf += '0000000000 65535 f \n';
    for (let i = 0; i < offsets.length; i++) {
      pdf += offsets[i].toString().padStart(10, '0') + ' 00000 n \n';
    }
    pdf += `trailer\n<< /Size ${offsets.length + 1} /Root 1 0 R >>\nstartxref\n${startxref}\n%%EOF\n`;

    return Buffer.from(pdf, 'binary');
  }
}

// Generate the Document
const doc = new PDFDocument();

// ==========================================
// PAGE 1: COVER & ARCHITECTURE OVERVIEW
// ==========================================
const p1 = doc.addPage();

// Header Banner
doc.drawRect(p1, 0, 740, 595.28, 101.89, [0.08, 0.18, 0.36]); // Deep Navy #142E5C
doc.drawRect(p1, 0, 735, 595.28, 5, [0.29, 0.44, 0.95]);     // Royal Blue accent

doc.drawText(p1, 'LINELESS POS SYSTEM', 45, 800, { font: 'F2', size: 24, color: [1, 1, 1] });
doc.drawText(p1, 'Full-Stack Architecture & Environment Setup Guide', 45, 778, { font: 'F1', size: 12, color: [0.85, 0.9, 1.0] });
doc.drawText(p1, 'GoalScripture Technologies  |  November 2026 Release', 45, 755, { font: 'F1', size: 9, color: [0.7, 0.78, 0.9] });

// Section: Executive Summary
let y = 705;
doc.drawText(p1, '1. Executive Overview', 45, y, { font: 'F2', size: 14, color: [0.08, 0.18, 0.36] });
doc.drawLine(p1, 45, y - 5, 550, y - 5, [0.85, 0.87, 0.9], 1);

y -= 22;
doc.drawText(p1, 'LineLess is an enterprise POS & restaurant billing solution designed to replace legacy Laravel systems', 45, y, { font: 'F1', size: 9.5, color: [0.2, 0.2, 0.2] });
y -= 14;
doc.drawText(p1, 'with high-performance Node.js microservices, real-time WebSockets, modern React administration,', 45, y, { font: 'F1', size: 9.5, color: [0.2, 0.2, 0.2] });
y -= 14;
doc.drawText(p1, 'and a multi-platform Flutter client for tablet, mobile, and desktop counters.', 45, y, { font: 'F1', size: 9.5, color: [0.2, 0.2, 0.2] });

// Section: Architecture Breakdown Cards
y -= 30;
doc.drawText(p1, '2. Repository & System Components', 45, y, { font: 'F2', size: 14, color: [0.08, 0.18, 0.36] });
doc.drawLine(p1, 45, y - 5, 550, y - 5, [0.85, 0.87, 0.9], 1);

// Card 1: Backend
y -= 60;
doc.drawRect(p1, 45, y, 505, 50, [0.96, 0.97, 0.99], [0.8, 0.85, 0.92], 1);
doc.drawRect(p1, 45, y, 4, 50, [0.2, 0.45, 0.85]);
doc.drawText(p1, 'A. Backend API & Real-time Server (/backend)', 58, y + 33, { font: 'F2', size: 11, color: [0.1, 0.2, 0.4] });
doc.drawText(p1, 'Technology: Node.js (v20+), Express.js, MySQL (mysql2 pool), Socket.IO, JWT, Helmet', 58, y + 19, { font: 'F1', size: 8.5, color: [0.25, 0.25, 0.25] });
doc.drawText(p1, 'Purpose: Handles POS APIs, tokens, order items, GST calculation, live dining tables, and real-time alerts.', 58, y + 7, { font: 'F1', size: 8.5, color: [0.4, 0.4, 0.4] });

// Card 2: Web App
y -= 60;
doc.drawRect(p1, 45, y, 505, 50, [0.96, 0.98, 0.97], [0.8, 0.9, 0.85], 1);
doc.drawRect(p1, 45, y, 4, 50, [0.1, 0.65, 0.5]);
doc.drawText(p1, 'B. Web Admin Dashboard (/LineLess Web)', 58, y + 33, { font: 'F2', size: 11, color: [0.05, 0.35, 0.25] });
doc.drawText(p1, 'Technology: React 19, Vite, Tailwind CSS 3.4, Framer Motion, Lucide Icons', 58, y + 19, { font: 'F1', size: 8.5, color: [0.25, 0.25, 0.25] });
doc.drawText(p1, 'Purpose: Cloud portal for restaurant owners to manage menus, GST settings, reports, staff, and live billing.', 58, y + 7, { font: 'F1', size: 8.5, color: [0.4, 0.4, 0.4] });

// Card 3: Flutter App
y -= 60;
doc.drawRect(p1, 45, y, 505, 50, [0.99, 0.97, 0.96], [0.92, 0.85, 0.8], 1);
doc.drawRect(p1, 45, y, 4, 50, [0.85, 0.4, 0.15]);
doc.drawText(p1, 'C. POS Terminal Client (Repository Root)', 58, y + 33, { font: 'F2', size: 11, color: [0.45, 0.2, 0.05] });
doc.drawText(p1, 'Technology: Flutter / Dart, Material Design, Local Offline Caching, Thermal Printing Driver', 58, y + 19, { font: 'F1', size: 8.5, color: [0.25, 0.25, 0.25] });
doc.drawText(p1, 'Purpose: High-speed cashier billing terminal supporting token generation, table management, and Bluetooth printing.', 58, y + 7, { font: 'F1', size: 8.5, color: [0.4, 0.4, 0.4] });

// Card 4: Production Infrastructure
y -= 60;
doc.drawRect(p1, 45, y, 505, 50, [0.97, 0.97, 0.98], [0.86, 0.86, 0.9], 1);
doc.drawRect(p1, 45, y, 4, 50, [0.4, 0.35, 0.65]);
doc.drawText(p1, 'D. Production Hosting & Remote Server', 58, y + 33, { font: 'F2', size: 11, color: [0.25, 0.15, 0.4] });
doc.drawText(p1, 'Public Domain: https://lineless.goalscripture.in  |  Server IP: 66.116.241.221 (Port 3009)', 58, y + 19, { font: 'F1', size: 8.5, color: [0.25, 0.25, 0.25] });
doc.drawText(p1, 'Stack: Ubuntu Linux, Nginx Reverse Proxy, PM2 Process Manager, MySQL Database Server', 58, y + 7, { font: 'F1', size: 8.5, color: [0.4, 0.4, 0.4] });

// Section: Prerequisites Summary Table
y -= 35;
doc.drawText(p1, '3. Required Environment Runtimes', 45, y, { font: 'F2', size: 14, color: [0.08, 0.18, 0.36] });
doc.drawLine(p1, 45, y - 5, 550, y - 5, [0.85, 0.87, 0.9], 1);

y -= 25;
// Table Header
doc.drawRect(p1, 45, y, 505, 18, [0.15, 0.23, 0.35]);
doc.drawText(p1, 'Runtime / Tool', 55, y + 5, { font: 'F2', size: 8.5, color: [1, 1, 1] });
doc.drawText(p1, 'Required Version', 180, y + 5, { font: 'F2', size: 8.5, color: [1, 1, 1] });
doc.drawText(p1, 'Detected on System', 310, y + 5, { font: 'F2', size: 8.5, color: [1, 1, 1] });
doc.drawText(p1, 'Target Component', 440, y + 5, { font: 'F2', size: 8.5, color: [1, 1, 1] });

const tableRows = [
  ['Node.js', 'v18.x - v22.x LTS', 'v22.12.0 (Ready)', 'Backend & Web Frontend'],
  ['npm / npx', 'v9.x - v10.x', 'v9.8.1 (Ready)', 'Package Management'],
  ['MySQL Server', '8.0+ / MariaDB 10.5+', 'Local (3306) or Remote', 'Relational Database'],
  ['Flutter SDK', '3.19+ / Dart 3.3+', 'Install if building App', 'Mobile & Desktop POS Client'],
  ['PM2 & Nginx', 'Production Daemon', 'Installed on Host', 'Production Deployment']
];

tableRows.forEach((row, idx) => {
  y -= 18;
  const bg = (idx % 2 === 0) ? [0.97, 0.97, 0.98] : [1, 1, 1];
  doc.drawRect(p1, 45, y, 505, 18, bg, [0.9, 0.9, 0.92], 0.5);
  doc.drawText(p1, row[0], 55, y + 5, { font: 'F2', size: 8, color: [0.2, 0.2, 0.2] });
  doc.drawText(p1, row[1], 180, y + 5, { font: 'F1', size: 8, color: [0.3, 0.3, 0.3] });
  doc.drawText(p1, row[2], 310, y + 5, { font: 'F2', size: 8, color: [0.1, 0.5, 0.2] });
  doc.drawText(p1, row[3], 440, y + 5, { font: 'F1', size: 8, color: [0.3, 0.3, 0.3] });
});

// ==========================================
// PAGE 2: BACKEND DEEP DIVE & DATABASE
// ==========================================
const p2 = doc.addPage();

// Mini Header
doc.drawRect(p2, 0, 785, 595.28, 56.89, [0.08, 0.18, 0.36]);
doc.drawRect(p2, 0, 781, 595.28, 4, [0.29, 0.44, 0.95]);
doc.drawText(p2, 'COMPONENT SETUP: NODE.JS BACKEND', 45, 815, { font: 'F2', size: 16, color: [1, 1, 1] });
doc.drawText(p2, 'Configuration, Database Schema Initialization, and Execution Commands', 45, 797, { font: 'F1', size: 9, color: [0.85, 0.9, 1] });

y = 750;
doc.drawText(p2, '1. Environment Configuration (.env)', 45, y, { font: 'F2', size: 13, color: [0.08, 0.18, 0.36] });
doc.drawLine(p2, 45, y - 5, 550, y - 5, [0.85, 0.87, 0.9], 1);

y -= 18;
doc.drawText(p2, 'The backend requires a configured .env file located at backend/.env. Use the sample below:', 45, y, { font: 'F1', size: 9, color: [0.25, 0.25, 0.25] });

// Code block: .env
y -= 95;
doc.drawRect(p2, 45, y, 505, 88, [0.12, 0.14, 0.18], [0.2, 0.25, 0.3], 1);
const envLines = [
  'PORT=3009',
  'NODE_ENV=development',
  'DB_HOST=localhost            # Set 127.0.0.1 or remote MySQL host',
  'DB_PORT=3306',
  'DB_USER=root',
  'DB_PASSWORD=your_mysql_password',
  'DB_NAME=lineless_db',
  'JWT_SECRET=lineless_super_secret_jwt_key_2026',
  'APP_URL=http://localhost:3009'
];
envLines.forEach((line, i) => {
  doc.drawText(p2, line, 55, y + 74 - (i * 9), { font: 'F3', size: 7.5, color: [0.75, 0.9, 0.75] });
});

// Section: Safe Database Auto-Initialization
y -= 25;
doc.drawText(p2, '2. Automated Safe Database Schema Initialization', 45, y, { font: 'F2', size: 13, color: [0.08, 0.18, 0.36] });
doc.drawLine(p2, 45, y - 5, 550, y - 5, [0.85, 0.87, 0.9], 1);

y -= 16;
doc.drawText(p2, 'When server starts, backend/src/config/database.js automatically runs non-destructive checks:', 45, y, { font: 'F1', size: 9, color: [0.25, 0.25, 0.25] });

const dbFeatures = [
  ['CREATE DATABASE IF NOT EXISTS', 'Auto-provisions "lineless_db" with utf8mb4 character collation.'],
  ['Auto-Migrations (ensureColumnExists)', 'Safely appends missing GST columns (gst_applicable, gst_rate, note).'],
  ['Core Tables Provisioned', 'users, shop_settings, categories, products, orders, order_items, pending_tables.'],
  ['Zero Data Loss Guarantee', 'Uses IF NOT EXISTS and non-destructive ALTER statements compatible with legacy data.']
];

dbFeatures.forEach(([title, desc]) => {
  y -= 22;
  doc.drawRect(p2, 50, y - 2, 6, 6, [0.2, 0.5, 0.9]);
  doc.drawText(p2, title + ':', 65, y, { font: 'F2', size: 8.5, color: [0.15, 0.2, 0.3] });
  doc.drawText(p2, desc, 240, y, { font: 'F1', size: 8.5, color: [0.35, 0.35, 0.35] });
});

// Section: Execution Commands
y -= 30;
doc.drawText(p2, '3. Backend Installation & Execution Commands', 45, y, { font: 'F2', size: 13, color: [0.08, 0.18, 0.36] });
doc.drawLine(p2, 45, y - 5, 550, y - 5, [0.85, 0.87, 0.9], 1);

y -= 95;
doc.drawRect(p2, 45, y, 505, 88, [0.12, 0.14, 0.18], [0.2, 0.25, 0.3], 1);
const cmdLines = [
  '# 1. Navigate to the backend directory',
  'cd backend',
  '',
  '# 2. Install all dependencies (express, mysql2, socket.io, etc.)',
  'npm install',
  '',
  '# 3. Start development server with live reload (nodemon)',
  'npm run dev',
  '',
  '# 4. Run automated test suite (Jest)',
  'npm test'
];
cmdLines.forEach((line, i) => {
  const isComment = line.startsWith('#');
  doc.drawText(p2, line, 55, y + 74 - (i * 8.5), {
    font: 'F3',
    size: 7.5,
    color: isComment ? [0.5, 0.65, 0.8] : [0.95, 0.95, 0.95]
  });
});

// Section: Production Deployment with PM2
y -= 25;
doc.drawText(p2, '4. Production Deployment (PM2 + Nginx)', 45, y, { font: 'F2', size: 13, color: [0.08, 0.18, 0.36] });
doc.drawLine(p2, 45, y - 5, 550, y - 5, [0.85, 0.87, 0.9], 1);

y -= 85;
doc.drawRect(p2, 45, y, 505, 78, [0.96, 0.97, 0.99], [0.85, 0.88, 0.94], 1);
const pm2Text = [
  '# Start backend via PM2 using existing ecosystem.config.js:',
  'npm install -g pm2',
  'pm2 start ecosystem.config.js --env production',
  'pm2 save && pm2 startup',
  '',
  '# Nginx reverse proxies incoming traffic to port 3009 with WebSocket upgrade headers:',
  'proxy_pass http://127.0.0.1:3009;  proxy_set_header Upgrade $http_upgrade;'
];
pm2Text.forEach((line, i) => {
  doc.drawText(p2, line, 55, y + 64 - (i * 10), { font: 'F3', size: 7.5, color: [0.2, 0.3, 0.45] });
});

// ==========================================
// PAGE 3: FRONTEND, FLUTTER & SERVER REFERENCE
// ==========================================
const p3 = doc.addPage();

// Mini Header
doc.drawRect(p3, 0, 785, 595.28, 56.89, [0.08, 0.18, 0.36]);
doc.drawRect(p3, 0, 781, 595.28, 4, [0.29, 0.44, 0.95]);
doc.drawText(p3, 'WEB, FLUTTER & PRODUCTION REFERENCE', 45, 815, { font: 'F2', size: 16, color: [1, 1, 1] });
doc.drawText(p3, 'LineLess Web Setup, Flutter App, API Endpoints, and Production Credentials', 45, 797, { font: 'F1', size: 9, color: [0.85, 0.9, 1] });

y = 750;
doc.drawText(p3, '1. LineLess Web Dashboard Setup (/LineLess Web)', 45, y, { font: 'F2', size: 13, color: [0.08, 0.18, 0.36] });
doc.drawLine(p3, 45, y - 5, 550, y - 5, [0.85, 0.87, 0.9], 1);

y -= 60;
doc.drawRect(p3, 45, y, 505, 52, [0.12, 0.14, 0.18], [0.2, 0.25, 0.3], 1);
const webCmds = [
  'cd "LineLess Web"',
  'npm install                      # Installs React 19, Tailwind, Lucide, Framer Motion',
  'npm run dev                      # Starts Vite dev server at http://localhost:5173',
  'npm run build                    # Creates optimized production build in /dist'
];
webCmds.forEach((line, i) => {
  doc.drawText(p3, line, 55, y + 40 - (i * 10), { font: 'F3', size: 7.5, color: [0.85, 0.9, 1] });
});

y -= 25;
doc.drawText(p3, '2. Flutter POS Client Terminal (Root)', 45, y, { font: 'F2', size: 13, color: [0.08, 0.18, 0.36] });
doc.drawLine(p3, 45, y - 5, 550, y - 5, [0.85, 0.87, 0.9], 1);

y -= 60;
doc.drawRect(p3, 45, y, 505, 52, [0.12, 0.14, 0.18], [0.2, 0.25, 0.3], 1);
const flutterCmds = [
  'flutter pub get                  # Resolves dependencies from pubspec.yaml',
  'flutter run                      # Runs app on connected device or emulator',
  'flutter build apk --release      # Builds release APK with credentials in creds/billji.jks',
  'flutter build windows --release  # Builds high-speed desktop counter executable'
];
flutterCmds.forEach((line, i) => {
  doc.drawText(p3, line, 55, y + 40 - (i * 10), { font: 'F3', size: 7.5, color: [0.95, 0.85, 0.7] });
});

// Section: Real-time & API Routing Architecture
y -= 28;
doc.drawText(p3, '3. Key API Endpoints & Socket Events', 45, y, { font: 'F2', size: 13, color: [0.08, 0.18, 0.36] });
doc.drawLine(p3, 45, y - 5, 550, y - 5, [0.85, 0.87, 0.9], 1);

y -= 20;
doc.drawRect(p3, 45, y, 505, 16, [0.15, 0.23, 0.35]);
doc.drawText(p3, 'Method / Scope', 55, y + 4, { font: 'F2', size: 8, color: [1, 1, 1] });
doc.drawText(p3, 'Endpoint / Event', 155, y + 4, { font: 'F2', size: 8, color: [1, 1, 1] });
doc.drawText(p3, 'Payload & Purpose', 320, y + 4, { font: 'F2', size: 8, color: [1, 1, 1] });

const apiRows = [
  ['POST', '/api/auth/login', 'Admin & Cashier email/password JWT login'],
  ['POST', '/api/auth/pin-login', 'Fast 4-digit quick pin cashier access'],
  ['GET / POST', '/api/products', 'Item catalogue, GST rates, category mappings'],
  ['POST', '/api/orders', 'Place orders, print tokens, dine-in & takeaway totals'],
  ['GET / POST', '/api/orders/pending-table', 'Manage running tables, KOT items & running bills'],
  ['SOCKET (IN)', 'join-shop', 'Clients join shop-specific isolated real-time rooms'],
  ['SOCKET (OUT)', 'order-status-update', 'Broadcasts instant table & kitchen ticket updates']
];

apiRows.forEach((row, idx) => {
  y -= 15;
  const bg = (idx % 2 === 0) ? [0.97, 0.97, 0.98] : [1, 1, 1];
  doc.drawRect(p3, 45, y, 505, 15, bg, [0.9, 0.9, 0.92], 0.5);
  doc.drawText(p3, row[0], 55, y + 4, { font: 'F2', size: 7.5, color: [0.1, 0.35, 0.6] });
  doc.drawText(p3, row[1], 155, y + 4, { font: 'F3', size: 7.5, color: [0.2, 0.2, 0.2] });
  doc.drawText(p3, row[2], 320, y + 4, { font: 'F1', size: 7.5, color: [0.35, 0.35, 0.35] });
});

// Section: Production Credentials Reference
y -= 30;
doc.drawText(p3, '4. Production Server Reference & Credentials', 45, y, { font: 'F2', size: 13, color: [0.08, 0.18, 0.36] });
doc.drawLine(p3, 45, y - 5, 550, y - 5, [0.85, 0.87, 0.9], 1);

y -= 90;
doc.drawRect(p3, 45, y, 505, 84, [0.98, 0.98, 0.99], [0.85, 0.88, 0.94], 1);
const credsInfo = [
  ['Remote Server SSH:', 'ssh root@66.116.241.221  (Legacy IP: 66.116.243.31)'],
  ['Remote Directory:', '/var/www/lineless-node'],
  ['Production URL:', 'https://lineless.goalscripture.in'],
  ['Admin Portal Login:', 'https://lineless.goalscripture.in/admin/login'],
  ['Default Admin User:', 'admin@gmail.com  /  Admin@123'],
  ['Keystore Signing:', 'lineless/creds/billji.jks (alias: billji)']
];

credsInfo.forEach(([label, value], i) => {
  doc.drawText(p3, label, 55, y + 68 - (i * 12), { font: 'F2', size: 8, color: [0.2, 0.25, 0.35] });
  doc.drawText(p3, value, 180, y + 68 - (i * 12), { font: 'F3', size: 8, color: [0.1, 0.45, 0.25] });
});

// Write to PDF file
const pdfBuffer = doc.build();
const outputPath = path.join(__dirname, 'LineLess_Project_Setup_Guide.pdf');
fs.writeFileSync(outputPath, pdfBuffer);

console.log('Successfully generated PDF at:', outputPath);
console.log('File size:', pdfBuffer.length, 'bytes');
