import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { type ProxyService, type StartProxyInput, type ProxyResult } from './spec.js';
import { GcloudHandler } from '../gcloud/handler.js';
export declare class ProxyHandler implements ProxyService {
    private gcloud;
    private transportFactory;
    private currentToken;
    private refreshTimer;
    private pendingToolListIds;
    constructor(gcloud?: GcloudHandler, transportFactory?: () => StdioServerTransport);
    start(input: StartProxyInput): Promise<ProxyResult>;
    private refreshToken;
    private startRefreshTimer;
    private stopRefreshTimer;
}
