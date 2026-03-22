export class ApiError extends Error {
  constructor(
    public statusCode: number,
    public code: string,
    message: string,
    public details?: Array<{ field: string; message: string; code: string }>
  ) {
    super(message);
    Object.setPrototypeOf(this, ApiError.prototype);
  }

  static badRequest(message: string, details?: ApiError['details']) {
    return new ApiError(400, 'bad_request', message, details);
  }

  static unauthorized(message = 'Unauthorized') {
    return new ApiError(401, 'unauthorized', message);
  }

  static forbidden(message = 'Forbidden') {
    return new ApiError(403, 'forbidden', message);
  }

  static notFound(resource = 'Resource') {
    return new ApiError(404, 'not_found', `${resource} not found`);
  }

  static conflict(message: string) {
    return new ApiError(409, 'conflict', message);
  }

  static internal(message = 'Internal server error') {
    return new ApiError(500, 'internal_error', message);
  }
}
