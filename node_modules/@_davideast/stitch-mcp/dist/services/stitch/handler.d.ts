import { type StitchService, type ConfigureIAMInput, type EnableAPIInput, type TestConnectionInput, type TestConnectionWithApiKeyInput, type IAMConfigResult, type APIEnableResult, type ConnectionTestResult } from './spec.js';
export declare class StitchHandler implements StitchService {
    private executor;
    private iamService;
    private apiService;
    private connectionService;
    constructor();
    configureIAM(input: ConfigureIAMInput): Promise<IAMConfigResult>;
    enableAPI(input: EnableAPIInput): Promise<APIEnableResult>;
    checkIAMRole(input: {
        projectId: string;
        userEmail: string;
    }): Promise<boolean>;
    checkAPIEnabled(input: {
        projectId: string;
    }): Promise<boolean>;
    testConnectionWithApiKey(input: TestConnectionWithApiKeyInput): Promise<ConnectionTestResult>;
    testConnection(input: TestConnectionInput): Promise<ConnectionTestResult>;
}
