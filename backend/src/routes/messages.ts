import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { v4 as uuid } from 'uuid';
import { query, queryOne } from '../config/db';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { sendData, sendPaginated, parsePagination, buildPaginationMeta } from '../utils/response';
import { ApiError } from '../utils/errors';
import { Message } from '../types';

const router = Router();
router.use(authenticate);

// ============================================================
// POST /api/v1/messages — Send a message
// ============================================================
const createMessageSchema = z.object({
  body: z.object({
    receiver_id: z.string().uuid(),
    thread_id: z.string().uuid().optional(),
    content: z.string().min(1).max(5000).optional(),
    message_type: z.enum(['text', 'image', 'document', 'voice']).default('text'),
    attachment_url: z.string().url().optional(),
    is_urgent: z.boolean().default(false),
  }).refine(
    (data) => data.content || data.attachment_url,
    { message: 'Either content or attachment_url is required' }
  ),
});

router.post(
  '/',
  validate(createMessageSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { receiver_id, thread_id, content, message_type, attachment_url, is_urgent } = req.body;
      const senderId = req.user!.sub;
      const senderType = req.user!.role === 'doctor' ? 'doctor' : 'patient';

      const id = uuid();
      const resolvedThreadId = thread_id ?? uuid();

      const rows = await query<Message>(
        `INSERT INTO messages (id, sender_type, sender_id, receiver_id, thread_id, content, message_type, attachment_url, is_urgent)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
         RETURNING *`,
        [id, senderType, senderId, receiver_id, resolvedThreadId, content ?? null, message_type, attachment_url ?? null, is_urgent]
      );

      sendData(res, rows[0], 201);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/messages/threads — List message threads
// ============================================================
router.get('/threads', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.sub;

    const threads = await query(
      `SELECT DISTINCT ON (m.thread_id)
        m.thread_id,
        m.content,
        m.message_type,
        m.is_urgent,
        m.created_at as last_message_at,
        m.sender_id,
        m.receiver_id,
        m.sender_type,
        (SELECT COUNT(*) FROM messages WHERE thread_id = m.thread_id AND receiver_id = $1 AND is_read = FALSE)::int as unread_count
       FROM messages m
       WHERE m.sender_id = $1 OR m.receiver_id = $1
       ORDER BY m.thread_id, m.created_at DESC`,
      [userId]
    );

    sendData(res, threads);
  } catch (err) {
    next(err);
  }
});

// ============================================================
// GET /api/v1/messages/threads/:threadId — Messages in a thread
// ============================================================
const threadMessagesSchema = z.object({
  query: z.object({
    page: z.string().optional(),
    per_page: z.string().optional(),
  }),
});

router.get(
  '/threads/:threadId',
  validate(threadMessagesSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.user!.sub;
      const threadId = req.params.threadId;
      const { page, perPage, offset } = parsePagination(req.query as any);

      // Verify user is part of this thread
      const access = await queryOne(
        'SELECT id FROM messages WHERE thread_id = $1 AND (sender_id = $2 OR receiver_id = $2) LIMIT 1',
        [threadId, userId]
      );
      if (!access) throw ApiError.forbidden('Not part of this thread');

      const [{ count }] = await query<{ count: string }>(
        'SELECT COUNT(*) as count FROM messages WHERE thread_id = $1',
        [threadId]
      );

      const messages = await query<Message>(
        `SELECT * FROM messages WHERE thread_id = $1
         ORDER BY created_at ASC
         LIMIT $2 OFFSET $3`,
        [threadId, perPage, offset]
      );

      // Mark messages as read
      await query(
        'UPDATE messages SET is_read = TRUE WHERE thread_id = $1 AND receiver_id = $2 AND is_read = FALSE',
        [threadId, userId]
      );

      sendPaginated(res, messages, buildPaginationMeta(parseInt(count), page, perPage));
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// PATCH /api/v1/messages/:id/read — Mark single message as read
// ============================================================
router.patch('/:id/read', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const rows = await query<Message>(
      'UPDATE messages SET is_read = TRUE WHERE id = $1 AND receiver_id = $2 RETURNING *',
      [req.params.id, req.user!.sub]
    );

    if (rows.length === 0) throw ApiError.notFound('Message');
    sendData(res, rows[0]);
  } catch (err) {
    next(err);
  }
});

// ============================================================
// GET /api/v1/messages/unread-count — Total unread count
// ============================================================
router.get('/unread-count', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const [{ count }] = await query<{ count: string }>(
      'SELECT COUNT(*) as count FROM messages WHERE receiver_id = $1 AND is_read = FALSE',
      [req.user!.sub]
    );
    sendData(res, { unread_count: parseInt(count) });
  } catch (err) {
    next(err);
  }
});

export default router;
