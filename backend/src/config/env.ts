import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  PORT: z.string().default('3000').transform(Number),
  DATABASE_URL: z.string().url().default('postgresql://medcare:medcare_dev@localhost:5432/medcare'),
  JWT_SECRET: z.string().min(8).default('dev-jwt-secret-change-me'),
  JWT_REFRESH_SECRET: z.string().min(8).default('dev-refresh-secret-change-me'),
  SMS_API_KEY: z.string().default('mock-sms-key'),
  AWS_S3_BUCKET: z.string().default('medcare-documents'),
  AWS_REGION: z.string().default('ap-south-1'),
  REDIS_URL: z.string().default('redis://localhost:6379'),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('Invalid environment variables:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
