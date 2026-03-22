import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { JwtPayload } from '../types';

// ============================================================
// WebSocket Server — Socket.IO based real-time layer
// ============================================================

let io: Server;

/** Authenticated socket with user payload attached */
interface AuthenticatedSocket extends Socket {
  user: JwtPayload;
}

// ============================================================
// Connection authentication middleware
// ============================================================
function authenticateSocket(socket: Socket, next: (err?: Error) => void) {
  const token =
    socket.handshake.auth?.token ||
    socket.handshake.headers?.authorization?.replace('Bearer ', '');

  if (!token) {
    return next(new Error('Authentication required'));
  }

  try {
    const payload = jwt.verify(token, env.JWT_SECRET) as JwtPayload;
    (socket as AuthenticatedSocket).user = payload;
    next();
  } catch {
    next(new Error('Invalid or expired token'));
  }
}

// ============================================================
// Heartbeat — ping/pong for connection health
// ============================================================
const HEARTBEAT_INTERVAL = 25_000; // 25s
const HEARTBEAT_TIMEOUT = 10_000;  // 10s to respond

function setupHeartbeat(socket: AuthenticatedSocket) {
  let alive = true;

  const interval = setInterval(() => {
    if (!alive) {
      console.warn(`[WS] Client ${socket.id} failed heartbeat — disconnecting`);
      socket.disconnect(true);
      return;
    }
    alive = false;
    socket.emit('ping');
  }, HEARTBEAT_INTERVAL);

  socket.on('pong', () => {
    alive = true;
  });

  socket.on('disconnect', () => {
    clearInterval(interval);
  });
}

// ============================================================
// Room management
// ============================================================
function joinUserRooms(socket: AuthenticatedSocket) {
  const { sub, role } = socket.user;

  if (role === 'patient') {
    socket.join(`user:${sub}`);
    console.log(`[WS] Patient ${sub} joined room user:${sub}`);
  } else if (role === 'doctor') {
    socket.join(`doctor:${sub}`);
    console.log(`[WS] Doctor ${sub} joined room doctor:${sub}`);
  }
}

// ============================================================
// Event handlers
// ============================================================
function registerEventHandlers(socket: AuthenticatedSocket) {
  // Client can join a hospital queue room
  socket.on('queue:join', (data: { hospitalId: string }) => {
    if (data.hospitalId) {
      socket.join(`queue:${data.hospitalId}`);
      console.log(`[WS] ${socket.user.sub} joined queue:${data.hospitalId}`);
    }
  });

  socket.on('queue:leave', (data: { hospitalId: string }) => {
    if (data.hospitalId) {
      socket.leave(`queue:${data.hospitalId}`);
    }
  });

  // Typing indicator for messages
  socket.on('message:typing', (data: { receiverId: string }) => {
    const receiverRoom =
      socket.user.role === 'patient'
        ? `doctor:${data.receiverId}`
        : `user:${data.receiverId}`;
    io.to(receiverRoom).emit('message:typing', {
      senderId: socket.user.sub,
      senderRole: socket.user.role,
    });
  });

  // Acknowledge message read
  socket.on('message:read', (data: { messageId: string; senderId: string }) => {
    const senderRoom =
      socket.user.role === 'patient'
        ? `doctor:${data.senderId}`
        : `user:${data.senderId}`;
    io.to(senderRoom).emit('message:read', {
      messageId: data.messageId,
      readBy: socket.user.sub,
    });
  });
}

// ============================================================
// Graceful disconnect
// ============================================================
function handleDisconnect(socket: AuthenticatedSocket) {
  socket.on('disconnect', (reason) => {
    console.log(`[WS] Client ${socket.id} (${socket.user.sub}) disconnected: ${reason}`);
  });

  socket.on('error', (err) => {
    console.error(`[WS] Socket error for ${socket.user.sub}:`, err.message);
  });
}

// ============================================================
// Initialization
// ============================================================
export function initWebSocket(server: HttpServer): Server {
  io = new Server(server, {
    cors: {
      origin:
        env.NODE_ENV === 'production'
          ? ['https://medcare.app']
          : ['http://localhost:3000', 'http://localhost:3001'],
      credentials: true,
    },
    pingInterval: HEARTBEAT_INTERVAL,
    pingTimeout: HEARTBEAT_TIMEOUT,
    transports: ['websocket', 'polling'],
  });

  // Auth middleware
  io.use(authenticateSocket);

  io.on('connection', (rawSocket: Socket) => {
    const socket = rawSocket as AuthenticatedSocket;
    console.log(`[WS] Client connected: ${socket.id} (${socket.user.sub}, ${socket.user.role})`);

    joinUserRooms(socket);
    setupHeartbeat(socket);
    registerEventHandlers(socket);
    handleDisconnect(socket);
  });

  console.log('[WS] WebSocket server initialized');
  return io;
}

// ============================================================
// Emitters — called from REST routes / services / jobs
// ============================================================

/** Deliver a new message in real-time */
export function emitNewMessage(
  receiverId: string,
  receiverRole: 'patient' | 'doctor',
  payload: {
    messageId: string;
    senderId: string;
    senderName: string;
    content: string;
    messageType: string;
    createdAt: string;
  }
) {
  const room = receiverRole === 'patient' ? `user:${receiverId}` : `doctor:${receiverId}`;
  io?.to(room).emit('message:new', payload);
}

/** Notify queue position changes */
export function emitQueueUpdate(
  hospitalId: string,
  payload: {
    queueId: string;
    position: number;
    estimatedWait: number; // minutes
    patientId?: string;
  }
) {
  io?.to(`queue:${hospitalId}`).emit('queue:update', payload);
}

/** Alert doctor when patient vital breaches threshold */
export function emitVitalAlert(
  doctorId: string,
  payload: {
    patientId: string;
    patientName: string;
    vitalType: string;
    value: any;
    threshold: { min?: number; max?: number };
    recordedAt: string;
  }
) {
  io?.to(`doctor:${doctorId}`).emit('vital:alert', payload);
}

/** Notify caregiver when dose is taken or missed */
export function emitDoseTaken(
  caregiverUserId: string,
  payload: {
    patientName: string;
    medicineName: string;
    status: 'taken' | 'missed' | 'skipped';
    scheduledTime: string;
    actualTime?: string;
  }
) {
  io?.to(`user:${caregiverUserId}`).emit('dose:taken', payload);
}

/** Send appointment reminder via WebSocket */
export function emitAppointmentReminder(
  userId: string,
  userRole: 'patient' | 'doctor',
  payload: {
    appointmentId: string;
    doctorName?: string;
    patientName?: string;
    scheduledAt: string;
    type: string;
    minutesBefore: number;
  }
) {
  const room = userRole === 'patient' ? `user:${userId}` : `doctor:${userId}`;
  io?.to(room).emit('appointment:reminder', payload);
}

/** Get the Socket.IO server instance */
export function getIO(): Server {
  if (!io) throw new Error('WebSocket server not initialized');
  return io;
}

/** Get connected client count */
export async function getConnectedCount(): Promise<number> {
  if (!io) return 0;
  const sockets = await io.fetchSockets();
  return sockets.length;
}
