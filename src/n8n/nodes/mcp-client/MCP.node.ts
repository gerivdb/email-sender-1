import { IExecuteFunctions } from 'n8n-core';
import {
	INodeExecutionData,
	INodeType,
	INodeTypeDescription,
	NodeOperationError
} from 'n8n-workflow';
import axios, { AxiosRequestConfig } from 'axios';

export class MCPClient implements INodeType {
	description: INodeTypeDescription = {
		displayName: 'MCP Client',
		name: 'mcpClient',
		icon: 'file:mcp.svg',
		group: ['transform'],
		version: 1,
		subtitle: '={{$parameter["operation"]}}',
		description: 'Interact with Model Context Protocol (MCP) servers',
		defaults: {
			name: 'MCP Client',
		},
		inputs: ['main'],
		outputs: ['main'],
		credentials: [
			{
				name: 'mcpClientApi',
				required: true,
			},
		],
		properties: [
			{
				displayName: 'Operation',
				name: 'operation',
				type: 'options',
				noDataExpression: true,
				options: [
					{
						name: 'Get Context',
						value: 'getContext',
						description: 'Get context from MCP server',
						action: 'Get context from MCP server',
					},
					{
						name: 'List Tools',
						value: 'listTools',
						description: 'List available tools on MCP server',
						action: 'List available tools on MCP server',
					},
					{
						name: 'Execute Tool',
						value: 'executeTool',
						description: 'Execute a tool on MCP server',
						action: 'Execute a tool on MCP server',
					},
				],
				default: 'getContext',
			},
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
			// Properties for getContext operation
			{
				displayName: 'Prompt',
				name: 'prompt',
				type: 'string',
				default: '',
				required: true,
				displayOptions: {
					show: {
						operation: ['getContext'],
					},
				},
				description: 'The prompt to send to the MCP server',
			},
			{
				displayName: 'Sources',
				name: 'sources',
				type: 'multiOptions',
				options: [
					{
						name: 'Notion',
						value: 'notion',
					},
					{
						name: 'Calendar',
						value: 'calendar',
					},
					{
						name: 'Email',
						value: 'email',
					},
					{
						name: 'Files',
						value: 'files',
					},
					{
						name: 'Memory',
						value: 'memory',
					},
				],
				default: [],
				displayOptions: {
					show: {
						operation: ['getContext'],
					},
				},
				description: 'The sources to use for context',
			},
			// Properties for executeTool operation
			{
				displayName: 'Tool Name',
				name: 'toolName',
				type: 'string',
				default: '',
				required: true,
				displayOptions: {
					show: {
						operation: ['executeTool'],
					},
				},
				description: 'The name of the tool to execute',
			},
			{
				displayName: 'Tool Parameters',
				name: 'toolParameters',
				type: 'json',
				default: '{}',
				displayOptions: {
					show: {
						operation: ['executeTool'],
					},
				},
				description: 'The parameters to pass to the tool',
			},
		],
	};

	async execute(this: IExecuteFunctions): Promise<INodeExecutionData[][]> {
		const items = this.getInputData();
		const returnData: INodeExecutionData[] = [];
		const operation = this.getNodeParameter('operation', 0) as string;
		const connectionType = this.getNodeParameter('connectionType', 0) as string;
		const credentials = await this.getCredentials('mcpClientApi');

		for (let i = 0; i < items.length; i++) {
			try {
				let responseData;

				if (connectionType === 'http') {
					// HTTP connection
					const baseUrl = credentials.baseUrl as string || 'http://localhost:3000';

					if (operation === 'getContext') {
						const prompt = this.getNodeParameter('prompt', i) as string;
						const sources = this.getNodeParameter('sources', i) as string[];

						const requestOptions: AxiosRequestConfig = {
							method: 'POST',
							url: `${baseUrl}/api/context`,
							headers: {
								'Content-Type': 'application/json',
								'Authorization': `Bearer ${credentials.apiKey}`,
							},
							data: {
								prompt,
								sources,
							},
						};

						const response = await axios(requestOptions);
						responseData = response.data;
					}
					else if (operation === 'listTools') {
						const requestOptions: AxiosRequestConfig = {
							method: 'GET',
							url: `${baseUrl}/api/tools`,
							headers: {
								'Authorization': `Bearer ${credentials.apiKey}`,
							},
						};

						const response = await axios(requestOptions);
						responseData = response.data;
					}
					else if (operation === 'executeTool') {
						const toolName = this.getNodeParameter('toolName', i) as string;
						let toolParameters;
						try {
							toolParameters = JSON.parse(this.getNodeParameter('toolParameters', i) as string);
						} catch (error) {
							throw new Error(`Invalid JSON in Tool Parameters: ${error.message}`);
						}

						const requestOptions: AxiosRequestConfig = {
							method: 'POST',
							url: `${baseUrl}/api/tools/${toolName}`,
							headers: {
								'Content-Type': 'application/json',
								'Authorization': `Bearer ${credentials.apiKey}`,
							},
							data: toolParameters,
						};

						const response = await axios(requestOptions);
						responseData = response.data;
					}
				}
				else if (connectionType === 'cmd') {
					// Command line connection
					const { spawn } = require('child_process');
					const command = credentials.command as string;
					const args = (credentials.args as string || '').split(' ').filter(arg => arg !== '');

					// Parse environment variables
					const envVars = {};
					const envString = credentials.environments as string || '';
					if (envString) {
						envString.split(',').forEach(envVar => {
							const [key, value] = envVar.split('=');
							if (key && value) {
								envVars[key.trim()] = value.trim();
							}
						});
					}

					// Prepare the input data based on the operation
					let inputData = {};
					if (operation === 'getContext') {
						const prompt = this.getNodeParameter('prompt', i) as string;
						const sources = this.getNodeParameter('sources', i) as string[];
						inputData = {
							operation: 'getContext',
							prompt,
							sources,
						};
					}
					else if (operation === 'listTools') {
						inputData = {
							operation: 'listTools',
						};
					}
					else if (operation === 'executeTool') {
						const toolName = this.getNodeParameter('toolName', i) as string;
						const toolParameters = JSON.parse(this.getNodeParameter('toolParameters', i) as string);
						inputData = {
							operation: 'executeTool',
							toolName,
							parameters: toolParameters,
						};
					}

					// Execute the command
					const childProcess = spawn(command, args, {
						env: { ...process.env, ...envVars },
					});

					// Send the input data to the process
					childProcess.stdin.write(JSON.stringify(inputData) + '\n');
					childProcess.stdin.end();

					// Collect the output
					let stdout = '';
					let stderr = '';

					childProcess.stdout.on('data', (data) => {
						stdout += data.toString();
					});

					childProcess.stderr.on('data', (data) => {
						stderr += data.toString();
					});

					// Wait for the process to complete
					const exitCode = await new Promise((resolve) => {
						childProcess.on('close', resolve);
					});

					if (exitCode !== 0) {
						throw new Error(`Command failed with exit code ${exitCode}: ${stderr}`);
					}

					try {
						responseData = JSON.parse(stdout);
					} catch (error) {
						throw new Error(`Failed to parse command output as JSON: ${stdout}`);
					}
				}

				const executionData = this.helpers.constructExecutionMetaData(
					this.helpers.returnJsonArray(responseData),
					{ itemData: { item: i } },
				);

				returnData.push(...executionData);
			} catch (error) {
				// Enhance error handling with more specific error messages
				let errorMessage = error.message;
				let errorDescription = '';

				// Handle specific error types
				if (error.name === 'AxiosError') {
					if (error.code === 'ECONNREFUSED') {
						errorMessage = 'Connection refused';
						errorDescription = `Could not connect to MCP server at ${credentials.baseUrl || 'http://localhost:3000'}. Please check if the server is running and accessible.`;
					} else if (error.code === 'ETIMEDOUT') {
						errorMessage = 'Connection timed out';
						errorDescription = 'The request to the MCP server timed out. Please check your network connection or increase the timeout.';
					} else if (error.response) {
						// Server responded with an error status code
						const status = error.response.status;
						errorMessage = `Server error: ${status}`;

						if (status === 401 || status === 403) {
							errorDescription = 'Authentication failed. Please check your API key.';
						} else if (status === 404) {
							errorDescription = 'The requested resource was not found on the MCP server.';
						} else if (status >= 500) {
							errorDescription = 'The MCP server encountered an internal error. Please check the server logs.';
						} else {
							errorDescription = error.response.data?.message || 'Unknown server error';
						}
					}
				} else if (error.message.includes('JSON')) {
					errorMessage = 'JSON parsing error';
					errorDescription = 'Failed to parse the response from the MCP server. Please check the server output format.';
				} else if (error.message.includes('spawn')) {
					errorMessage = 'Command execution error';
					errorDescription = 'Failed to execute the command. Please check if the command exists and is executable.';
				}

				if (this.continueOnFail()) {
					returnData.push({
						json: {
							error: errorMessage,
							description: errorDescription,
							details: error.message,
							operation: operation,
							timestamp: new Date().toISOString(),
						}
					});
					continue;
				}

				throw new NodeOperationError(
					this.getNode(),
					`${errorMessage}: ${errorDescription || error.message}`,
					{
						itemIndex: i,
						description: errorDescription,
					}
				);
			}
		}

		return [returnData];
	}
}
