const { Server } = require('socket.io');
const { WebSocketServer } = require('ws');
const logger = require('../utils/logger');
const { verifyToken } = require('../utils/tokenGenerator');
const { sendNewOrderPushNotification } = require('../utils/fcmService');
let io = null;

// Raw WebSocket (Pusher/Reverb-compatible) clients. The Flutter app's
// ReverbService connects with a plain WebSocket at the root path, which the
// Socket.IO server (served only at /socket.io/) cannot accept. We run a small
// raw-WS endpoint here so real-time works against the Node backend too.
const rawClients = new Set();

// Must be attached BEFORE Socket.IO so engine.io preserves and delegates
// non-/socket.io upgrade requests to our handler.
function setupRawWebSocket(server) {
  const wss = new WebSocketServer({ noServer: true });

  server.on('upgrade', (req, socket, head) => {
    if ((req.url || '').startsWith('/socket.io/')) return; // Socket.IO handles its own path
    wss.handleUpgrade(req, socket, head, (ws) => wss.emit('connection', ws, req));
  });

  wss.on('connection', (ws) => {
    rawClients.add(ws);
    logger.info(`[RAW-WS] Client connected (total ${rawClients.size})`);

    // Pusher-style handshake expected by the Flutter ReverbService.
    ws.send(JSON.stringify({
      event: 'pusher:connection_established',
      data: JSON.stringify({ socket_id: Math.random().toString(36).slice(2), activity_timeout: 120 })
    }));

    ws.on('message', (buf) => {
      let msg;
      try { msg = JSON.parse(buf.toString()); } catch (_) { return; }
      if (msg.event === 'pusher:subscribe') {
        const channel = msg.data && msg.data.channel;
        ws.send(JSON.stringify({ event: 'pusher_internal:subscription_succeeded', channel, data: {} }));
      } else if (msg.event === 'pusher:ping') {
        ws.send(JSON.stringify({ event: 'pusher:pong' }));
      }
    });

    ws.on('close', () => { rawClients.delete(ws); });
    ws.on('error', () => { rawClients.delete(ws); });
  });

  // Keepalive: ping clients so dead connections are pruned.
  setInterval(() => {
    for (const ws of rawClients) {
      if (ws.readyState === 1) {
        try { ws.send(JSON.stringify({ event: 'pusher:ping' })); } catch (_) {}
      }
    }
  }, 25000);
}

function initSocket(server) {
  // Raw WS first (see note above), then Socket.IO.
  setupRawWebSocket(server);

  io = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST']
    },
    transports: ['websocket', 'polling']
  });

  // Handle connection for native Socket.IO & raw WS channels
  io.on('connection', (socket) => {
    logger.info(`[SOCKET.IO] New client connected: ${socket.id}`);

    // Send connection established payload immediately for Reverb/Pusher clients
    const connectionMsg = JSON.stringify({
      event: 'pusher:connection_established',
      data: JSON.stringify({ socket_id: socket.id, activity_timeout: 120 })
    });
    socket.emit('message', connectionMsg);
    socket.send(connectionMsg);

    // Allow socket authentication / joining room
    socket.on('authenticate', (data) => {
      if (data && data.token) {
        const decoded = verifyToken(data.token);
        if (decoded && decoded.id) {
          socket.userId = decoded.id;
          const shopRoom = `shop_${decoded.id}`;
          socket.join(shopRoom);
          logger.info(`[SOCKET.IO] Socket ${socket.id} authenticated & joined room ${shopRoom}`);
          socket.emit('authenticated', { success: true, room: shopRoom });
        }
      }
    });

    // Support Pusher / Reverb style subscription requests for compatibility
    socket.on('pusher:subscribe', (data) => {
      let channelName = null;
      if (typeof data === 'string') {
        try {
          const parsed = JSON.parse(data);
          channelName = parsed.data?.channel;
        } catch (_) {}
      } else if (data && data.data && data.data.channel) {
        channelName = data.data.channel;
      }

      if (channelName) {
        socket.join(channelName);
        logger.info(`[SOCKET.IO] Socket ${socket.id} subscribed to channel: ${channelName}`);
      }
    });

    socket.on('join_shop', (shopId) => {
      if (shopId) {
        const shopRoom = `shop_${shopId}`;
        socket.join(shopRoom);
        logger.info(`[SOCKET.IO] Socket ${socket.id} joined ${shopRoom}`);
      }
    });

    socket.on('disconnect', () => {
      logger.info(`[SOCKET.IO] Client disconnected: ${socket.id}`);
    });
  });

  return io;
}

function getIO() {
  if (!io) {
    logger.warn('[SOCKET.IO] IO instance requested before initialization.');
  }
  return io;
}

/**
 * Emits real-time dashboard / order update event to connected clients
 */
function emitDashboardUpdate(shopId, tokenNo = '') {
  // ૧. Laravel Reverb મુજબ exact payload
  const innerData = {
    status: true,
    data: {
      message: 'New Order',
      token_no: tokenNo ? String(tokenNo) : '',
      user_id: Number(shopId)
    }
  };

  // ૨. Reverb / Pusher WebSocket ફોર્મેટ (data must be JSON string)
  const pusherPayload = JSON.stringify({
    channel: 'dashboard',
    event: 'dashboard.updated',
    data: JSON.stringify(innerData)
  });

  // Raw WebSocket ક્લાયન્ટ્સ (Flutter Reverb Client)
  for (const ws of rawClients) {
    if (ws.readyState === 1) {
      try {
        ws.send(pusherPayload);
      } catch (err) {
        logger.error('[WS SEND ERROR]', err.message);
      }
    }
  }

  // Socket.IO ક્લાયન્ટ્સ
  if (io) {
    io.to(`shop_${shopId}`).to('dashboard').emit('dashboard.updated', innerData);
    io.to(`shop_${shopId}`).to('dashboard').emit('message', pusherPayload);
    io.emit('dashboard.updated', innerData);
  }

  logger.info(`[SOCKET] Broadcasted 'New Order' (Token #${tokenNo}) for shop_${shopId} to ${rawClients.size} raw clients`);
}

module.exports = {
  initSocket,
  getIO,
  emitDashboardUpdate
};
