import { type ListProjectsInput, type SetProjectInput, type ProjectListResult, type ProjectSetResult } from './spec.js';
import { GcloudExecutor } from './core.js';
export declare class GcloudProjectService {
    private executor;
    constructor(executor: GcloudExecutor);
    /**
     * List projects
     */
    listProjects(input: ListProjectsInput): Promise<ProjectListResult>;
    /**
     * Set active project
     */
    setProject(input: SetProjectInput): Promise<ProjectSetResult>;
    getProjectId(): Promise<string | null>;
}
