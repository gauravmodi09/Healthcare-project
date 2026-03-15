import { type IAMConfigResult, type ConfigureIAMInput } from './spec.js';
import type { GcloudExecutor } from '../gcloud/core.js';
export declare class StitchIamService {
    private executor;
    constructor(executor: GcloudExecutor);
    configureIAM(input: ConfigureIAMInput): Promise<IAMConfigResult>;
    checkIAMRole(input: {
        projectId: string;
        userEmail: string;
    }): Promise<boolean>;
}
