import { type APIEnableResult, type EnableAPIInput } from './spec.js';
import type { GcloudExecutor } from '../gcloud/core.js';
export declare class StitchApiService {
    private executor;
    constructor(executor: GcloudExecutor);
    enableAPI(input: EnableAPIInput): Promise<APIEnableResult>;
    checkAPIEnabled(input: {
        projectId: string;
    }): Promise<boolean>;
}
