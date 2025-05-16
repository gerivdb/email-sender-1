import {
	ICredentialType,
	INodeProperties,
} from 'n8n-workflow';

export class MCPClientApi implements ICredentialType {
	name = 'mcpClientApi';
	displayName = 'MCP Client API';
	documentationUrl = 'https://docs.example.com/mcp';
	properties: INodeProperties[] = [
		// Common Properties
		{
			displayName: 'Connection Type',
			name: 'connectionType',
			type: 'options',
			options: [
				{
					name: 'HTTP',
					value: 'http',
					description: 'Connect via HTTP/HTTPS',
				},
				{
					name: 'Command Line',
					value: 'cmd',
					description: 'Connect via command line interface',
				},
			],
			default: 'http',
			description: 'Type of connection to use',
		},
		// HTTP Connection Properties
		{
			displayName: 'Base URL',
			name: 'baseUrl',
			type: 'string',
			default: 'http://localhost:3000',
			description: 'The base URL of the MCP server',
			displayOptions: {
				show: {
					connectionType: ['http'],
				},
			},
		},
		{
			displayName: 'API Key',
			name: 'apiKey',
			type: 'string',
			typeOptions: {
				password: true,
			},
			default: '',
			description: 'The API key for the MCP server',
			displayOptions: {
				show: {
					connectionType: ['http'],
				},
			},
		},
		// Command Line Connection Properties
		{
			displayName: 'Command',
			name: 'command',
			type: 'string',
			default: '',
			description: 'The command to execute for the MCP client',
			displayOptions: {
				show: {
					connectionType: ['cmd'],
				},
			},
		},
		{
			displayName: 'Arguments',
			name: 'args',
			type: 'string',
			default: '',
			description: 'The arguments to pass to the command',
			displayOptions: {
				show: {
					connectionType: ['cmd'],
				},
			},
		},
		{
			displayName: 'Environment Variables',
			name: 'environments',
			type: 'string',
			default: '',
			description: 'Environment variables to set for the command (format: KEY1=value1,KEY2=value2)',
			displayOptions: {
				show: {
					connectionType: ['cmd'],
				},
			},
		},
	];
}
