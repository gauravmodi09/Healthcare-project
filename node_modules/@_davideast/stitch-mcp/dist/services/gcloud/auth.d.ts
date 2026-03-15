import { type AuthenticateInput, type AuthResult } from './spec.js';
import { GcloudExecutor } from './core.js';
export declare class GcloudAuthService {
    private executor;
    constructor(executor: GcloudExecutor);
    /**
     * Authenticate user
     */
    authenticate(input: AuthenticateInput): Promise<AuthResult>;
    /**
     * Authenticate application default credentials
     */
    authenticateADC(input: AuthenticateInput): Promise<AuthResult>;
    /**
     * Get access token
     */
    getAccessToken(): Promise<string | null>;
    getActiveAccount(): Promise<string | null>;
    hasADC(): Promise<boolean>;
    /**
     * Run the gcloud authentication flow (URL extraction followed by actual login)
     */
    private runAuthFlow;
    /**
     * Get the correct login command with config prefix if using bundled gcloud
     */
    private getLoginCommand;
}
