import { type EnsureGcloudInput, type GcloudResult } from './spec.js';
import { GcloudExecutor } from './core.js';
export declare class GcloudInstallService {
    private executor;
    constructor(executor: GcloudExecutor);
    /**
     * Ensure gcloud is installed and available
     */
    ensureInstalled(input: EnsureGcloudInput): Promise<GcloudResult>;
    /**
     * Install beta components
     */
    installBetaComponents(): Promise<{
        success: boolean;
        error?: {
            message: string;
        };
    }>;
    private findGlobalGcloud;
    private getVersionFromPath;
    private isVersionValid;
    private installLocal;
}
