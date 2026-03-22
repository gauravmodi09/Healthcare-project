import { Request, Response, NextFunction } from 'express';
import { AnyZodObject, ZodError } from 'zod';

/**
 * Zod validation middleware.
 * Validates req.body, req.query, and req.params against a schema.
 *
 * Usage:
 *   validate(z.object({ body: z.object({ name: z.string() }) }))
 */
export function validate(schema: AnyZodObject) {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      schema.parse({
        body: req.body,
        query: req.query,
        params: req.params,
      });
      next();
    } catch (err) {
      if (err instanceof ZodError) {
        return res.status(422).json({
          error: {
            code: 'validation_error',
            message: 'Request validation failed',
            details: err.issues.map((issue) => ({
              field: issue.path.join('.'),
              message: issue.message,
              code: issue.code,
            })),
          },
        });
      }
      next(err);
    }
  };
}
