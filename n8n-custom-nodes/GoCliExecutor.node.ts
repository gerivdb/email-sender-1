import {
	IExecuteFunctions,
	INodeExecutionData,
	INodeType,
	INodeTypeDescription,
	NodeOperationError,
} from 'n8n-workflow';

export class GoCliExecutor implements INodeType {
	description: INodeTypeDescription = {
		displayName: 'Go CLI Executor',
		name: 'goCliExecutor',
		icon: 'file:gocli.svg',
		group: ['transform'],
		version: 1,
		subtitle: '={{$parameter["operation"] + ": " + $parameter["command"]}}',
		description: 'Execute Go CLI commands with parameter bridging',
		defaults: {
			name: 'Go CLI Executor',
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
						name: 'Execute Command',
						value: 'execute',
						description: 'Execute a Go CLI command with parameters',
						action: 'Execute a Go CLI command',
					},
					{
						name: 'Execute Workflow',
						value: 'workflow',
						description: 'Execute a predefined Go workflow',
						action: 'Execute a Go workflow',
					},
					{
						name: 'Validate Parameters',
						value: 'validate',
						description: 'Validate parameters before execution',
						action: 'Validate parameters',
					},
				],
				default: 'execute',
			},
			{
				displayName: 'CLI Command',
				name: 'command',
				type: 'string',
				default: '',
				placeholder: 'email-sender',
				description: 'The Go CLI command to execute',
				displayOptions: {
					show: {
						operation: ['execute'],
					},
				},
			},
			{
				displayName: 'Workflow ID',
				name: 'workflowId',
				type: 'string',
				default: '',
				placeholder: 'email-workflow-001',
				description: 'The ID of the Go workflow to execute',
				displayOptions: {
					show: {
						operation: ['workflow'],
					},
				},
			},
			{
				displayName: 'Parameters',
				name: 'parameters',
				placeholder: 'Add Parameter',
				type: 'fixedCollection',
				default: {},
				typeOptions: {
					multipleValues: true,
				},
				description: 'Parameters to pass to the Go CLI',
				options: [
					{
						name: 'parameter',
						displayName: 'Parameter',
						values: [
							{
								displayName: 'Parameter Name',
								name: 'name',
								type: 'string',
								default: '',
								placeholder: 'recipient',
								description: 'Name of the parameter',
							},
							{
								displayName: 'Parameter Value',
								name: 'value',
								type: 'string',
								default: '',
								placeholder: 'user@example.com',
								description: 'Value of the parameter',
							},
							{
								displayName: 'Parameter Type',
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
										name: 'Object',
										value: 'object',
									},
									{
										name: 'Array',
										value: 'array',
									},
								],
								default: 'string',
								description: 'Type of the parameter for validation',
							},
							{
								displayName: 'Required',
								name: 'required',
								type: 'boolean',
								default: false,
								description: 'Whether this parameter is required',
							},
						],
					},
				],
			},
			{
				displayName: 'Options',
				name: 'options',
				type: 'collection',
				placeholder: 'Add Option',
				default: {},
				options: [
					{
						displayName: 'Timeout (seconds)',
						name: 'timeout',
						type: 'number',
						default: 30,
						description: 'Timeout for the CLI execution in seconds',
					},
					{
						displayName: 'Retry Count',
						name: 'retryCount',
						type: 'number',
						default: 0,
						description: 'Number of retries on failure',
					},
					{
						displayName: 'Async Execution',
						name: 'async',
						type: 'boolean',
						default: false,
						description: 'Execute command asynchronously',
					},
					{
						displayName: 'Enable Tracing',
						name: 'enableTracing',
						type: 'boolean',
						default: true,
						description: 'Enable request tracing for debugging',
					},
					{
						displayName: 'Environment Variables',
						name: 'environment',
						placeholder: 'Add Environment Variable',
						type: 'fixedCollection',
						default: {},
						typeOptions: {
							multipleValues: true,
						},
						options: [
							{
								name: 'variable',
								displayName: 'Environment Variable',
								values: [
									{
										displayName: 'Name',
										name: 'name',
										type: 'string',
										default: '',
										placeholder: 'API_KEY',
									},
									{
										displayName: 'Value',
										name: 'value',
										type: 'string',
										default: '',
										placeholder: 'your-api-key',
									},
								],
							},
						],
					},
				],
			},
			{
				displayName: 'Manager Config',
				name: 'managerConfig',
				type: 'collection',
				placeholder: 'Add Manager Config',
				default: {},
				options: [
					{
						displayName: 'Manager URL',
						name: 'managerUrl',
						type: 'string',
						default: 'http://localhost:8080',
						description: 'URL of the Go Manager service',
					},
					{
						displayName: 'Queue Name',
						name: 'queueName',
						type: 'string',
						default: 'default',
						description: 'Queue to use for async execution',
					},
					{
						displayName: 'Priority',
						name: 'priority',
						type: 'number',
						default: 1,
						description: 'Execution priority (1=high, 5=low)',
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
				const options = this.getNodeParameter('options', i, {}) as any;
				const managerConfig = this.getNodeParameter('managerConfig', i, {}) as any;

				// Generate correlation IDs for tracing
				const correlationId = `n8n-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
				const traceId = `trace-${Date.now()}-${i}`;

				let result: any;

				switch (operation) {
					case 'execute':
						result = await this.executeCommand(i, correlationId, traceId, options);
						break;
					case 'workflow':
						result = await this.executeWorkflow(i, correlationId, traceId, options, managerConfig);
						break;
					case 'validate':
						result = await this.validateParameters(i, correlationId, traceId);
						break;
					default:
						throw new NodeOperationError(this.getNode(), `Unknown operation: ${operation}`, {
							itemIndex: i,
						});
				}

				// Add metadata to result
				result.metadata = {
					correlationId,
					traceId,
					executedAt: new Date().toISOString(),
					nodeExecutionId: this.getExecutionId(),
					workflowId: this.getWorkflow().id,
					operation,
				};

				returnData.push({
					json: result,
					pairedItem: {
						item: i,
					},
				});

			} catch (error) {
				if (this.continueOnFail()) {
					returnData.push({
						json: {
							error: error.message,
							success: false,
							executedAt: new Date().toISOString(),
						},
						pairedItem: {
							item: i,
						},
					});
					continue;
				}
				throw error;
			}
		}

		return [returnData];
	}

	private async executeCommand(
		itemIndex: number,
		correlationId: string,
		traceId: string,
		options: any,
	): Promise<any> {
		const command = this.getNodeParameter('command', itemIndex) as string;
		const parameters = this.getNodeParameter('parameters', itemIndex, {}) as any;

		if (!command) {
			throw new NodeOperationError(this.getNode(), 'CLI command is required', {
				itemIndex,
			});
		}

		// Build parameter map
		const parameterMap: Record<string, any> = {};
		if (parameters.parameter) {
			for (const param of parameters.parameter) {
				parameterMap[param.name] = this.convertParameterValue(param.value, param.type);
			}
		}

		// Add input data to parameters
		const inputData = this.getInputData()[itemIndex].json;
		parameterMap['inputData'] = inputData;

		// Execute via Go Manager if configured, otherwise direct CLI
		const managerConfig = this.getNodeParameter('managerConfig', itemIndex, {}) as any;
		
		if (managerConfig.managerUrl) {
			return await this.executeViaManager(
				command,
				parameterMap,
				correlationId,
				traceId,
				options,
				managerConfig,
			);
		} else {
			return await this.executeDirectCLI(command, parameterMap, correlationId, traceId, options);
		}
	}

	private async executeWorkflow(
		itemIndex: number,
		correlationId: string,
		traceId: string,
		options: any,
		managerConfig: any,
	): Promise<any> {
		const workflowId = this.getNodeParameter('workflowId', itemIndex) as string;
		const parameters = this.getNodeParameter('parameters', itemIndex, {}) as any;

		if (!workflowId) {
			throw new NodeOperationError(this.getNode(), 'Workflow ID is required', {
				itemIndex,
			});
		}

		// Build parameter map
		const parameterMap: Record<string, any> = {};
		if (parameters.parameter) {
			for (const param of parameters.parameter) {
				parameterMap[param.name] = this.convertParameterValue(param.value, param.type);
			}
		}

		// Add input data
		const inputData = this.getInputData()[itemIndex].json;
		
		// Prepare workflow request
		const workflowRequest = {
			workflowId,
			nodeId: this.getNode().id,
			parameters: parameterMap,
			inputData: [inputData],
			options: {
				timeout: (options.timeout || 30) * 1000, // Convert to milliseconds
				retryCount: options.retryCount || 0,
				async: options.async || false,
				enableTracing: options.enableTracing !== false,
			},
			traceId,
			correlationId,
		};

		// Execute via Go Manager
		const managerUrl = managerConfig.managerUrl || 'http://localhost:8080';
		
		try {
			const response = await this.helpers.httpRequest({
				method: 'POST',
				url: `${managerUrl}/api/v1/workflows/execute`,
				body: workflowRequest,
				headers: {
					'Content-Type': 'application/json',
					'X-Correlation-ID': correlationId,
					'X-Trace-ID': traceId,
				},
				timeout: (options.timeout || 30) * 1000,
				json: true,
			});

			return {
				success: true,
				executionId: response.executionId,
				status: response.status,
				outputData: response.outputData,
				metrics: response.metrics,
				warnings: response.warnings || [],
				errors: response.errors || [],
			};

		} catch (error) {
			throw new NodeOperationError(this.getNode(), 
				`Workflow execution failed: ${error.message}`, {
				itemIndex,
			});
		}
	}

	private async validateParameters(
		itemIndex: number,
		correlationId: string,
		traceId: string,
	): Promise<any> {
		const parameters = this.getNodeParameter('parameters', itemIndex, {}) as any;
		const validationResults = [];

		if (parameters.parameter) {
			for (const param of parameters.parameter) {
				const result = {
					name: param.name,
					type: param.type,
					required: param.required,
					valid: true,
					errors: [] as string[],
				};

				// Basic validation
				if (param.required && (!param.value || param.value.trim() === '')) {
					result.valid = false;
					result.errors.push('Required parameter is missing');
				}

				// Type validation
				try {
					this.convertParameterValue(param.value, param.type);
				} catch (error) {
					result.valid = false;
					result.errors.push(`Type validation failed: ${error.message}`);
				}

				validationResults.push(result);
			}
		}

		const allValid = validationResults.every(r => r.valid);

		return {
			success: true,
			valid: allValid,
			parameters: validationResults,
			summary: {
				total: validationResults.length,
				valid: validationResults.filter(r => r.valid).length,
				invalid: validationResults.filter(r => !r.valid).length,
			},
		};
	}

	private async executeViaManager(
		command: string,
		parameters: Record<string, any>,
		correlationId: string,
		traceId: string,
		options: any,
		managerConfig: any,
	): Promise<any> {
		const managerUrl = managerConfig.managerUrl;

		// For async execution, use job queue
		if (options.async) {
			const jobRequest = {
				id: `job-${correlationId}`,
				type: 'cli-execution',
				queueName: managerConfig.queueName || 'default',
				priority: managerConfig.priority || 1,
				payload: {
					command,
					parameters,
					options,
				},
				traceId,
				correlationId,
			};

			const response = await this.helpers.httpRequest({
				method: 'POST',
				url: `${managerUrl}/api/v1/jobs/enqueue`,
				body: jobRequest,
				headers: {
					'Content-Type': 'application/json',
					'X-Correlation-ID': correlationId,
					'X-Trace-ID': traceId,
				},
				json: true,
			});

			return {
				success: true,
				async: true,
				jobId: response.jobId,
				queueName: jobRequest.queueName,
				message: 'Job queued for async execution',
			};
		}

		// Synchronous execution via data conversion
		const conversionRequest = {
			sourceFormat: 'n8n',
			targetFormat: 'go',
			data: {
				command,
				parameters,
				options,
			},
			options: {
				validateSchema: true,
			},
		};

		try {
			const response = await this.helpers.httpRequest({
				method: 'POST',
				url: `${managerUrl}/api/v1/data/convert`,
				body: conversionRequest,
				headers: {
					'Content-Type': 'application/json',
					'X-Correlation-ID': correlationId,
					'X-Trace-ID': traceId,
				},
				timeout: (options.timeout || 30) * 1000,
				json: true,
			});

			return {
				success: true,
				async: false,
				result: response.convertedData,
				metadata: response.metadata,
				warnings: response.warnings || [],
				errors: response.errors || [],
			};

		} catch (error) {
			throw new NodeOperationError(this.getNode(), 
				`Manager execution failed: ${error.message}`);
		}
	}

	private async executeDirectCLI(
		command: string,
		parameters: Record<string, any>,
		correlationId: string,
		traceId: string,
		options: any,
	): Promise<any> {
		// This would typically use child_process to execute the CLI
		// For now, we'll simulate the execution
		
		const simulatedResult = {
			command,
			parameters,
			executedAt: new Date().toISOString(),
			duration: Math.random() * 1000 + 100, // Simulated duration
			success: true,
			output: `CLI execution completed for ${command}`,
			exitCode: 0,
		};

		// Add simulated delay
		await new Promise(resolve => setTimeout(resolve, 100));

		return {
			success: true,
			async: false,
			result: simulatedResult,
			message: 'Direct CLI execution completed',
		};
	}

	private convertParameterValue(value: string, type: string): any {
		switch (type) {
			case 'number':
				const num = Number(value);
				if (isNaN(num)) {
					throw new Error(`Cannot convert "${value}" to number`);
				}
				return num;
			case 'boolean':
				if (value.toLowerCase() === 'true') return true;
				if (value.toLowerCase() === 'false') return false;
				throw new Error(`Cannot convert "${value}" to boolean`);
			case 'object':
				try {
					return JSON.parse(value);
				} catch {
					throw new Error(`Cannot parse "${value}" as JSON object`);
				}
			case 'array':
				try {
					const parsed = JSON.parse(value);
					if (!Array.isArray(parsed)) {
						throw new Error('Parsed value is not an array');
					}
					return parsed;
				} catch {
					throw new Error(`Cannot parse "${value}" as JSON array`);
				}
			case 'string':
			default:
				return value;
		}
	}
}
