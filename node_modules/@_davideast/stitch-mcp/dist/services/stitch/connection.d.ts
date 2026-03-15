import { type ConnectionTestResult, type TestConnectionInput, type TestConnectionWithApiKeyInput } from './spec.js';
export declare class StitchConnectionService {
    testConnectionWithApiKey(input: TestConnectionWithApiKeyInput): Promise<ConnectionTestResult>;
    testConnection(input: TestConnectionInput): Promise<ConnectionTestResult>;
}
