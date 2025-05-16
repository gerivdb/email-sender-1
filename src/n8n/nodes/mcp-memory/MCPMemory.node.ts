import { IExecuteFunctions } from 'n8n-core';
import {
	INodeExecutionData,
	INodeType,
	INodeTypeDescription,
	NodeOperationError
} from 'n8n-workflow';
import axios, { AxiosRequestConfig } from 'axios';

export class MCPMemory implements INodeType {
	description: INodeTypeDescription = {
		displayName: 'MCP Memory',
		name: 'mcpMemory',
		icon: 'file:memory.svg',
		group: ['transform'],
		version: 1,
		subtitle: '={{$parameter["operation"]}}',
		description: 'Manage memories in MCP',
		defaults: {
			name: 'MCP Memory',
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
						name: 'Add Memory',
						value: 'addMemory',
						description: 'Add a new memory to MCP',
						action: 'Add a new memory to MCP',
					},
					{
						name: 'Get Memory',
						value: 'getMemory',
						description: 'Get a memory by ID',
						action: 'Get a memory by ID',
					},
					{
						name: 'Search Memories',
						value: 'searchMemories',
						description: 'Search memories by content or metadata',
						action: 'Search memories by content or metadata',
					},
					{
						name: 'Update Memory',
						value: 'updateMemory',
						description: 'Update an existing memory',
						action: 'Update an existing memory',
					},
					{
						name: 'Delete Memory',
						value: 'deleteMemory',
						description: 'Delete a memory by ID',
						action: 'Delete a memory by ID',
					},
				],
				default: 'addMemory',
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
			// Properties for addMemory operation
			{
				displayName: 'Content',
				name: 'content',
				type: 'string',
				default: '',
				required: true,
				displayOptions: {
					show: {
						operation: ['addMemory'],
					},
				},
				description: 'The content of the memory',
			},
			{
				displayName: 'Metadata',
				name: 'metadata',
				type: 'json',
				default: '{}',
				displayOptions: {
					show: {
						operation: ['addMemory'],
					},
				},
				description: 'The metadata for the memory',
			},
			// Properties for getMemory and deleteMemory operations
			{
				displayName: 'Memory ID',
				name: 'memoryId',
				type: 'string',
				default: '',
				required: true,
				displayOptions: {
					show: {
						operation: ['getMemory', 'deleteMemory', 'updateMemory'],
					},
				},
				description: 'The ID of the memory',
			},
			// Properties for updateMemory operation
			{
				displayName: 'New Content',
				name: 'newContent',
				type: 'string',
				default: '',
				displayOptions: {
					show: {
						operation: ['updateMemory'],
					},
				},
				description: 'The new content for the memory',
			},
			{
				displayName: 'New Metadata',
				name: 'newMetadata',
				type: 'json',
				default: '{}',
				displayOptions: {
					show: {
						operation: ['updateMemory'],
					},
				},
				description: 'The new metadata for the memory',
			},
			// Properties for searchMemories operation
			{
				displayName: 'Query',
				name: 'query',
				type: 'string',
				default: '',
				displayOptions: {
					show: {
						operation: ['searchMemories'],
					},
				},
				description: 'The query to search for in memory content',
			},
			{
				displayName: 'Metadata Filter',
				name: 'metadataFilter',
				type: 'json',
				default: '{}',
				displayOptions: {
					show: {
						operation: ['searchMemories'],
					},
				},
				description: 'Filter memories by metadata',
			},
			{
				displayName: 'Limit',
				name: 'limit',
				type: 'number',
				default: 10,
				displayOptions: {
					show: {
						operation: ['searchMemories'],
					},
				},
				description: 'Maximum number of memories to return',
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

					if (operation === 'addMemory') {
						const content = this.getNodeParameter('content', i) as string;
						let metadata;
						try {
							metadata = JSON.parse(this.getNodeParameter('metadata', i) as string);
						} catch (error) {
							throw new Error(`Invalid JSON in Metadata: ${error.message}`);
						}

						const requestOptions: AxiosRequestConfig = {
							method: 'POST',
							url: `${baseUrl}/api/memory`,
							headers: {
								'Content-Type': 'application/json',
								'Authorization': `Bearer ${credentials.apiKey}`,
							},
							data: {
								content,
								metadata,
							},
						};

						const response = await axios(requestOptions);
						responseData = response.data;
					}
					else if (operation === 'getMemory') {
						const memoryId = this.getNodeParameter('memoryId', i) as string;

						const requestOptions: AxiosRequestConfig = {
							method: 'GET',
							url: `${baseUrl}/api/memory/${memoryId}`,
							headers: {
								'Authorization': `Bearer ${credentials.apiKey}`,
							},
						};

						const response = await axios(requestOptions);
						responseData = response.data;
					}
					else if (operation === 'searchMemories') {
						const query = this.getNodeParameter('query', i) as string;
						let metadataFilter;
						try {
							metadataFilter = JSON.parse(this.getNodeParameter('metadataFilter', i) as string);
						} catch (error) {
							throw new Error(`Invalid JSON in Metadata Filter: ${error.message}`);
						}
						const limit = this.getNodeParameter('limit', i) as number;

						const requestOptions: AxiosRequestConfig = {
							method: 'POST',
							url: `${baseUrl}/api/memory/search`,
							headers: {
								'Content-Type': 'application/json',
								'Authorization': `Bearer ${credentials.apiKey}`,
							},
							data: {
								query,
								metadata: metadataFilter,
								limit,
							},
						};

						const response = await axios(requestOptions);
						responseData = response.data;
					}
					else if (operation === 'updateMemory') {
						const memoryId = this.getNodeParameter('memoryId', i) as string;
						const newContent = this.getNodeParameter('newContent', i) as string;
						let newMetadata;
						try {
							newMetadata = JSON.parse(this.getNodeParameter('newMetadata', i) as string);
						} catch (error) {
							throw new Error(`Invalid JSON in New Metadata: ${error.message}`);
						}

						const requestOptions: AxiosRequestConfig = {
							method: 'PUT',
							url: `${baseUrl}/api/memory/${memoryId}`,
							headers: {
								'Content-Type': 'application/json',
								'Authorization': `Bearer ${credentials.apiKey}`,
							},
							data: {
								content: newContent,
								metadata: newMetadata,
							},
						};

						const response = await axios(requestOptions);
						responseData = response.data;
					}
					else if (operation === 'deleteMemory') {
						const memoryId = this.getNodeParameter('memoryId', i) as string;

						const requestOptions: AxiosRequestConfig = {
							method: 'DELETE',
							url: `${baseUrl}/api/memory/${memoryId}`,
							headers: {
								'Authorization': `Bearer ${credentials.apiKey}`,
							},
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
					if (operation === 'addMemory') {
						const content = this.getNodeParameter('content', i) as string;
						let metadata;
						try {
							metadata = JSON.parse(this.getNodeParameter('metadata', i) as string);
						} catch (error) {
							throw new Error(`Invalid JSON in Metadata: ${error.message}`);
						}
						inputData = {
							operation: 'addMemory',
							content,
							metadata,
						};
					}
					else if (operation === 'getMemory') {
						const memoryId = this.getNodeParameter('memoryId', i) as string;
						inputData = {
							operation: 'getMemory',
							memoryId,
						};
					}
					else if (operation === 'searchMemories') {
						const query = this.getNodeParameter('query', i) as string;
						let metadataFilter;
						try {
							metadataFilter = JSON.parse(this.getNodeParameter('metadataFilter', i) as string);
						} catch (error) {
							throw new Error(`Invalid JSON in Metadata Filter: ${error.message}`);
						}
						const limit = this.getNodeParameter('limit', i) as number;
						inputData = {
							operation: 'searchMemories',
							query,
							metadata: metadataFilter,
							limit,
						};
					}
					else if (operation === 'updateMemory') {
						const memoryId = this.getNodeParameter('memoryId', i) as string;
						const newContent = this.getNodeParameter('newContent', i) as string;
						let newMetadata;
						try {
							newMetadata = JSON.parse(this.getNodeParameter('newMetadata', i) as string);
						} catch (error) {
							throw new Error(`Invalid JSON in New Metadata: ${error.message}`);
						}
						inputData = {
							operation: 'updateMemory',
							memoryId,
							content: newContent,
							metadata: newMetadata,
						};
					}
					else if (operation === 'deleteMemory') {
						const memoryId = this.getNodeParameter('memoryId', i) as string;
						inputData = {
							operation: 'deleteMemory',
							memoryId,
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
							errorDescription = 'The requested memory was not found on the MCP server.';
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
