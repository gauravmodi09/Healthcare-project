import { Response } from 'express';
import { PaginationMeta } from '../types';

/** Send { data: T } envelope */
export function sendData<T>(res: Response, data: T, status = 200) {
  return res.status(status).json({ data });
}

/** Send paginated { data, meta } envelope */
export function sendPaginated<T>(res: Response, data: T[], meta: PaginationMeta) {
  return res.json({ data, meta });
}

/** Build pagination meta from total + query params */
export function buildPaginationMeta(total: number, page: number, perPage: number): PaginationMeta {
  return {
    total,
    page,
    per_page: perPage,
    total_pages: Math.ceil(total / perPage),
  };
}

/** Parse page & per_page from query with safe defaults */
export function parsePagination(query: Record<string, any>): { page: number; perPage: number; offset: number } {
  const page = Math.max(1, parseInt(query.page) || 1);
  const perPage = Math.min(100, Math.max(1, parseInt(query.per_page) || 20));
  return { page, perPage, offset: (page - 1) * perPage };
}
