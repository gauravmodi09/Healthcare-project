import { z } from 'zod';
export declare const ViewOptionsSchema: z.ZodObject<{
    projects: z.ZodDefault<z.ZodBoolean>;
    name: z.ZodOptional<z.ZodString>;
    sourceScreen: z.ZodOptional<z.ZodString>;
    project: z.ZodOptional<z.ZodString>;
    screen: z.ZodOptional<z.ZodString>;
    serve: z.ZodDefault<z.ZodBoolean>;
}, "strip", z.ZodTypeAny, {
    projects: boolean;
    serve: boolean;
    name?: string | undefined;
    project?: string | undefined;
    screen?: string | undefined;
    sourceScreen?: string | undefined;
}, {
    name?: string | undefined;
    projects?: boolean | undefined;
    project?: string | undefined;
    serve?: boolean | undefined;
    screen?: string | undefined;
    sourceScreen?: string | undefined;
}>;
export type ViewOptions = z.infer<typeof ViewOptionsSchema>;
