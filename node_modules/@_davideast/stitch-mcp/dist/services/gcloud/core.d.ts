import { type ShellResult } from '../../platform/shell.js';
export declare class GcloudExecutor {
    platform: import("../../platform/detector.js").Platform;
    private gcloudPath;
    private useSystemGcloud;
    constructor();
    setGcloudPath(path: string, isSystem: boolean): void;
    getGcloudPath(): string | null;
    isSystemGcloud(): boolean;
    private setupEnvironment;
    getEnvironment(useSystem?: boolean): Record<string, string>;
    getGcloudCommand(): Promise<string>;
    exec(args: string[], options?: {
        timeout?: number;
        env?: Record<string, string>;
    }): Promise<ShellResult>;
    execRaw(command: string[], options?: {
        timeout?: number;
        env?: Record<string, string>;
    }): Promise<ShellResult>;
}
