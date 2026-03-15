import { type GcloudService, type EnsureGcloudInput, type AuthenticateInput, type ListProjectsInput, type SetProjectInput, type GcloudResult, type AuthResult, type ProjectListResult, type ProjectSetResult } from './spec.js';
import { GcloudExecutor } from './core.js';
export declare class GcloudHandler implements GcloudService {
    executor: GcloudExecutor;
    private installService;
    private authService;
    private projectService;
    constructor();
    /**
     * Ensure gcloud is installed and available
     */
    ensureInstalled(input: EnsureGcloudInput): Promise<GcloudResult>;
    /**
     * Authenticate user
     */
    authenticate(input: AuthenticateInput): Promise<AuthResult>;
    /**
     * Authenticate application default credentials
     */
    authenticateADC(input: AuthenticateInput): Promise<AuthResult>;
    /**
     * List projects
     */
    listProjects(input: ListProjectsInput): Promise<ProjectListResult>;
    /**
     * Set active project
     */
    setProject(input: SetProjectInput): Promise<ProjectSetResult>;
    /**
     * Get access token
     */
    getAccessToken(): Promise<string | null>;
    getProjectId(): Promise<string | null>;
    /**
     * Install beta components
     */
    installBetaComponents(): Promise<{
        success: boolean;
        error?: {
            message: string;
        };
    }>;
    getActiveAccount(): Promise<string | null>;
    hasADC(): Promise<boolean>;
}
