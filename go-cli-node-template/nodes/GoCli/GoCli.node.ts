import {
	IExecuteFunctions,
	INodeExecutionData,
	INodeType,
	INodeTypeDescription,
	NodeOperationError,
} from 'n8n-workflow';

import { spawn } from 'child_process';
import { promisify } from 'util';

export class GoCli implements INodeType {
	description: INodeTypeDescription = {
		displayName: 'Go CLI',
		name: 'goCli',
		icon: 'file:gocli.svg',
		group: ['transform'],
		version: 1,
		subtitle: '={{$parameter["operation"] + ": " + $parameter["command"]}}',
		description: 'Execute Go CLI commands and process results',
		defaults: {
			name: 'Go CLI',
		},
		inputs: ['main'],
		outputs: ['main'],
		credentials: [
			{
				name: 'goCliApi',
				required: false,
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
						name: 'Execute',
						value: 'execute',
						description: 'Execute Go CLI command with data processing',
						action: 'Execute a Go CLI command',
					},
					{
						name: 'Validate',
						value: 'validate',
						description: 'Validate input data using Go CLI',
						action: 'Validate input data',
					},
					{
						name: 'Status',
						value: 'status',
						description: 'Get status from Go CLI process',
						action: 'Get status information',
					},
					{
						name: 'Health Check',
						value: 'health',
						description: 'Check Go CLI health and availability',
						action: 'Perform health check',
					},
				],
				default: 'execute',
			},
			{
				displayName: 'CLI Binary Path',
				name: 'binaryPath',
				type: 'string',
				default: '/usr/local/bin/n8n-go-cli',
				placeholder: '/path/to/go-cli-binary',
				description: 'Full path to the Go CLI binary executable',
				required: true,
			},
			{
				displayName: 'Command',
				name: 'command',
				type: 'string',
				default: '',
				placeholder: 'email-process',
				description: 'The Go CLI command to execute',
				displayOptions: {
					show: {
						operation: ['execute'],
					},
				},
				required: true,
			},
			{
				displayName: 'Arguments',
				name: 'arguments',
				type: 'collection',
				placeholder: 'Add Argument',
				default: {},
				description: 'Arguments to pass to the Go CLI command',
				options: [
					{
						displayName: 'Argument Name',
						name: 'name',
						type: 'string',
						default: '',
						description: 'Name of the argument',
					},
					{
						displayName: 'Argument Value',
						name: 'value',
						type: 'string',
						default: '',
						description: 'Value of the argument',
					},
					{
						displayName: 'Type',
						name: 'type',
						type: 'options',
						options: [
							{
								name: 'String',
								value: 'string',
							},
							{
								name: 'Number',
								value: 'number',
							},
							{
								name: 'Boolean',
								value: 'boolean',
							},
							{
								name: 'File',
								value: 'file',
							},
						],
						default: 'string',
						description: 'Type of the argument for proper handling',
					},
				],
			},
			{
				displayName: 'Input Data Processing',
				name: 'inputProcessing',
				type: 'options',
				options: [
					{
						name: 'Pass as JSON',
						value: 'json',
						description: 'Pass input data as JSON to stdin',
					},
					{
						name: 'Pass as Arguments',
						value: 'args',
						description: 'Convert input data to command line arguments',
					},
					{
						name: 'No Input',
						value: 'none',
						description: 'Do not pass input data',
					},
				],
				default: 'json',
				description: 'How to handle input data from previous nodes',
			},
			{
				displayName: 'Output Format',
				name: 'outputFormat',
				type: 'options',
				options: [
					{
						name: 'JSON',
						value: 'json',
						description: 'Parse output as JSON',
					},
					{
						name: 'Raw Text',
						value: 'text',
						description: 'Return raw text output',
					},
					{
						name: 'Lines Array',
						value: 'lines',
						description: 'Split output into array of lines',
					},
				],
				default: 'json',
				description: 'How to process the output from Go CLI',
			},
			{
				displayName: 'Timeout (seconds)',
				name: 'timeout',
				type: 'number',
				default: 30,
				description: 'Timeout for CLI execution in seconds',
				typeOptions: {
					minValue: 1,
					maxValue: 300,
				},
			},
			{
				displayName: 'Environment Variables',
				name: 'environmentVariables',
				type: 'fixedCollection',
				typeOptions: {
					multipleValues: true,
				},
				placeholder: 'Add Environment Variable',
				default: {},
				description: 'Environment variables to set for the CLI execution',
				options: [
					{
						name: 'variable',
						displayName: 'Variable',
						values: [
							{
								displayName: 'Name',
								name: 'name',
								type: 'string',
								default: '',
								description: 'Environment variable name',
							},
							{
								displayName: 'Value',
								name: 'value',
								type: 'string',
								default: '',
								description: 'Environment variable value',
							},
						],
					},
				],
			},
			{
				displayName: 'Advanced Options',
				name: 'advancedOptions',
				type: 'collection',
				placeholder: 'Add Option',
				default: {},
				options: [
					{
						displayName: 'Working Directory',
						name: 'workingDirectory',
						type: 'string',
						default: '',
						description: 'Working directory for CLI execution',
					},
					{
						displayName: 'Error Handling',
						name: 'errorHandling',
						type: 'options',
						options: [
							{
								name: 'Stop on Error',
								value: 'stop',
								description: 'Stop execution if CLI returns error',
							},
							{
								name: 'Continue on Error',
								value: 'continue',
								description: 'Continue execution and include error in output',
							},
							{
								name: 'Retry on Error',
								value: 'retry',
								description: 'Retry execution on error',
							},
						],
						default: 'stop',
						description: 'How to handle CLI execution errors',
					},
					{
						displayName: 'Retry Count',
						name: 'retryCount',
						type: 'number',
						default: 3,
						description: 'Number of retry attempts on error',
						displayOptions: {
							show: {
								errorHandling: ['retry'],
							},
						},
						typeOptions: {
							minValue: 1,
							maxValue: 10,
						},
					},
					{
						displayName: 'Enable Tracing',
						name: 'enableTracing',
						type: 'boolean',
						default: false,
						description: 'Enable execution tracing for debugging',
					},
				],
			},
		],
	};

	async execute(this: IExecuteFunctions): Promise<INodeExecutionData[][]> {
		const items = this.getInputData();
		const returnData: INodeExecutionData[] = [];

		for (let i = 0; i < items.length; i++) {
			try {
				const operation = this.getNodeParameter('operation', i) as string;
				const binaryPath = this.getNodeParameter('binaryPath', i) as string;
				const timeout = this.getNodeParameter('timeout', i) as number;
				const outputFormat = this.getNodeParameter('outputFormat', i) as string;
				const inputProcessing = this.getNodeParameter('inputProcessing', i) as string;
				const advancedOptions = this.getNodeParameter('advancedOptions', i) as any;

				let result: any;

				switch (operation) {
					case 'execute':
						result = await this.executeCommand(i, binaryPath, timeout, outputFormat, inputProcessing, advancedOptions);
						break;
					case 'validate':
						result = await this.validateData(i, binaryPath, timeout);
						break;
					case 'status':
						result = await this.getStatus(i, binaryPath, timeout);
						break;
					case 'health':
						result = await this.healthCheck(i, binaryPath, timeout);
						break;
					default:
						throw new NodeOperationError(this.getNode(), `Unknown operation: ${operation}`, {
							itemIndex: i,
						});
				}

				returnData.push({
					json: result,
					pairedItem: { item: i },
				});

			} catch (error) {
				const errorHandling = this.getNodeParameter('advancedOptions.errorHandling', i, 'stop') as string;
				
				if (errorHandling === 'continue') {
					returnData.push({
						json: {
							error: error.message,
							success: false,
							timestamp: new Date().toISOString(),
						},
						pairedItem: { item: i },
					});
					continue;
				} else if (errorHandling === 'retry') {
					const retryCount = this.getNodeParameter('advancedOptions.retryCount', i, 3) as number;
					// Implement retry logic here
					throw new NodeOperationError(this.getNode(), `CLI execution failed after ${retryCount} retries: ${error.message}`, {
						itemIndex: i,
					});
				} else {
					throw new NodeOperationError(this.getNode(), `CLI execution failed: ${error.message}`, {
						itemIndex: i,
					});
				}
			}
		}

		return [returnData];
	}

	private async executeCommand(
		itemIndex: number,
		binaryPath: string,
		timeout: number,
		outputFormat: string,
		inputProcessing: string,
		advancedOptions: any,
	): Promise<any> {
		const command = this.getNodeParameter('command', itemIndex) as string;
		const arguments = this.getNodeParameter('arguments', itemIndex) as any;
		const environmentVariables = this.getNodeParameter('environmentVariables', itemIndex) as any;
		const inputData = this.getInputData()[itemIndex];

		// Build command arguments
		const args = ['execute', command];
		
		// Add arguments from parameters
		if (arguments && Array.isArray(arguments)) {
			for (const arg of arguments) {
				if (arg.name && arg.value) {
					args.push(`--${arg.name}`, this.formatArgumentValue(arg.value, arg.type));
				}
			}
		}

		// Handle input data processing
		let stdinData: string | undefined;
		if (inputProcessing === 'json' && inputData?.json) {
			stdinData = JSON.stringify(inputData.json);
			args.push('--input-format', 'json');
		} else if (inputProcessing === 'args' && inputData?.json) {
			// Convert JSON to arguments
			for (const [key, value] of Object.entries(inputData.json)) {
				args.push(`--${key}`, String(value));
			}
		}

		// Add output format
		args.push('--output-format', outputFormat);

		// Set up environment
		const env = { ...process.env };
		if (environmentVariables?.variable) {
			for (const envVar of environmentVariables.variable) {
				if (envVar.name && envVar.value) {
					env[envVar.name] = envVar.value;
				}
			}
		}

		// Execute CLI command
		const result = await this.executeCLI(binaryPath, args, {
			timeout: timeout * 1000,
			cwd: advancedOptions?.workingDirectory || process.cwd(),
			env,
			input: stdinData,
		});

		// Process output based on format
		return this.processOutput(result.stdout, outputFormat, result);
	}

	private async validateData(itemIndex: number, binaryPath: string, timeout: number): Promise<any> {
		const inputData = this.getInputData()[itemIndex];
		const args = ['validate'];

		const result = await this.executeCLI(binaryPath, args, {
			timeout: timeout * 1000,
			input: JSON.stringify(inputData.json),
		});

		return this.processOutput(result.stdout, 'json', result);
	}

	private async getStatus(itemIndex: number, binaryPath: string, timeout: number): Promise<any> {
		const args = ['status'];
		
		const result = await this.executeCLI(binaryPath, args, {
			timeout: timeout * 1000,
		});

		return this.processOutput(result.stdout, 'json', result);
	}

	private async healthCheck(itemIndex: number, binaryPath: string, timeout: number): Promise<any> {
		const args = ['health'];
		
		const result = await this.executeCLI(binaryPath, args, {
			timeout: timeout * 1000,
		});

		return this.processOutput(result.stdout, 'json', result);
	}

	private formatArgumentValue(value: any, type: string): string {
		switch (type) {
			case 'number':
				return String(Number(value));
			case 'boolean':
				return String(Boolean(value));
			case 'file':
				return String(value); // File path
			default:
				return String(value);
		}
	}

	private processOutput(stdout: string, format: string, result: any): any {
		try {
			switch (format) {
				case 'json':
					return JSON.parse(stdout);
				case 'lines':
					return {
						lines: stdout.split('\n').filter(line => line.trim() !== ''),
						success: result.code === 0,
						exitCode: result.code,
					};
				case 'text':
				default:
					return {
						output: stdout,
						success: result.code === 0,
						exitCode: result.code,
					};
			}
		} catch (error) {
			return {
				output: stdout,
				error: `Failed to parse output: ${error.message}`,
				success: false,
				exitCode: result.code,
			};
		}
	}

	private async executeCLI(
		binaryPath: string,
		args: string[],
		options: {
			timeout?: number;
			cwd?: string;
			env?: NodeJS.ProcessEnv;
			input?: string;
		} = {},
	): Promise<{ stdout: string; stderr: string; code: number }> {
		return new Promise((resolve, reject) => {
			const child = spawn(binaryPath, args, {
				cwd: options.cwd,
				env: options.env,
				stdio: ['pipe', 'pipe', 'pipe'],
			});

			let stdout = '';
			let stderr = '';
			let timeoutId: NodeJS.Timeout | undefined;

			// Set up timeout
			if (options.timeout) {
				timeoutId = setTimeout(() => {
					child.kill('SIGTERM');
					reject(new Error(`CLI execution timed out after ${options.timeout}ms`));
				}, options.timeout);
			}

			// Collect output
			child.stdout.on('data', (data) => {
				stdout += data.toString();
			});

			child.stderr.on('data', (data) => {
				stderr += data.toString();
			});

			// Handle process completion
			child.on('close', (code) => {
				if (timeoutId) {
					clearTimeout(timeoutId);
				}

				if (code === 0) {
					resolve({ stdout, stderr, code });
				} else {
					reject(new Error(`CLI exited with code ${code}: ${stderr}`));
				}
			});

			child.on('error', (error) => {
				if (timeoutId) {
					clearTimeout(timeoutId);
				}
				reject(new Error(`Failed to execute CLI: ${error.message}`));
			});

			// Send input data if provided
			if (options.input) {
				child.stdin.write(options.input);
				child.stdin.end();
			} else {
				child.stdin.end();
			}
		});
	}
}
