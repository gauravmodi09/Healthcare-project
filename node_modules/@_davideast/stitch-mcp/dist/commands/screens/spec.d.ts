import { z } from 'zod';
export declare const ScreensOptionsSchema: z.ZodObject<{
    project: z.ZodString;
}, "strip", z.ZodTypeAny, {
    project: string;
}, {
    project: string;
}>;
export type ScreensOptions = z.infer<typeof ScreensOptionsSchema>;
