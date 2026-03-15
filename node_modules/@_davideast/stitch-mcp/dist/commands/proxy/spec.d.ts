import { z } from 'zod';
export declare const ProxyOptionsSchema: z.ZodObject<{
    transport: z.ZodDefault<z.ZodEnum<["stdio", "sse"]>>;
    port: z.ZodOptional<z.ZodNumber>;
    debug: z.ZodDefault<z.ZodBoolean>;
}, "strip", z.ZodTypeAny, {
    transport: "stdio" | "sse";
    debug: boolean;
    port?: number | undefined;
}, {
    transport?: "stdio" | "sse" | undefined;
    port?: number | undefined;
    debug?: boolean | undefined;
}>;
export type ProxyOptions = z.infer<typeof ProxyOptionsSchema>;
