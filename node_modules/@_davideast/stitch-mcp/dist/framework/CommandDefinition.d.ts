import { type Command } from 'commander';
export interface CommandDefinition<Args = any, Options = any> {
    name: string;
    description: string;
    options?: Array<{
        flags: string;
        description: string;
        defaultValue?: any;
        fn?: (val: string) => any;
    }>;
    requiredOptions?: Array<{
        flags: string;
        description: string;
        defaultValue?: any;
    }>;
    arguments?: string;
    action: (args: Args, options: Options, command: Command) => Promise<void>;
}
