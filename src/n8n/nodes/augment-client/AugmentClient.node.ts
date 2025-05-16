import { IExecuteFunctions } from 'n8n-core';
import {
	INodeExecutionData,
	INodeType,
	INodeTypeDescription,
	NodeOperationError,
} from 'n8n-workflow';
import { spawn } from 'child_process';

export class AugmentClient implements INodeType {
	description: INodeTypeDescription = {
		displayName: 'Augment Client',
		name: 'augmentClient',
		icon: 'file:augment.svg',
		group: ['transform'],
		version: 1,
		subtitle: '={{$parameter["operation"]}}',
		description: 'Interact with Augment Code via operational modes',
		defaults: {
			name: 'Augment Client',
		},
		inputs: ['main'],
		outputs: ['main'],
		credentials: [
			{
				name: 'augmentClientApi',
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
						name: 'Execute Mode',
						value: 'executeMode',
						description: 'Execute an Augment operational mode',
						action: 'Execute an Augment operational mode',
					},
					{
						name: 'Update Memories',
						value: 'updateMemories',
						description: 'Update Augment memories',
						action: 'Update Augment memories',
					},
					{
						name: 'Get Mode Description',
						value: 'getModeDescription',
						description: 'Get description of an Augment mode',
						action: 'Get description of an Augment mode',
					},
				],
				default: 'executeMode',
			},
			// Properties for executeMode operation
			{
				displayName: 'Mode',
				name: 'mode',
				type: 'options',
				options: [
					{
						name: 'GRAN - Granularization',
						value: 'GRAN',
						description: 'Decompose complex tasks into smaller ones',
					},
					{
						name: 'DEV-R - Roadmap Development',
						value: 'DEV-R',
						description: 'Implement roadmap tasks sequentially',
					},
					{
						name: 'ARCHI - Architecture',
						value: 'ARCHI',
						description: 'Design and model system architecture',
					},
					{
						name: 'DEBUG - Debugging',
						value: 'DEBUG',
						description: 'Isolate and fix bugs',
					},
					{
						name: 'TEST - Testing',
						value: 'TEST',
						description: 'Create and run automated tests',
					},
					{
						name: 'OPTI - Optimization',
						value: 'OPTI',
						description: 'Optimize performance and reduce complexity',
					},
					{
						name: 'REVIEW - Code Review',
						value: 'REVIEW',
						description: 'Verify code quality against standards',
					},
					{
						name: 'PREDIC - Predictive Analysis',
						value: 'PREDIC',
						description: 'Anticipate performance and detect anomalies',
					},
					{
						name: 'C-BREAK - Circular Dependency Resolution',
						value: 'C-BREAK',
						description: 'Detect and resolve circular dependencies',
					},
					{
						name: 'CHECK - Verification',
						value: 'CHECK',
						description: 'Verify task implementation status',
					},
				],
				default: 'GRAN',
				required: true,
				displayOptions: {
					show: {
						operation: ['executeMode'],
					},
				},
				description: 'The Augment operational mode to execute',
			},
			{
				displayName: 'File Path',
				name: 'filePath',
				type: 'string',
				default: '',
				required: true,
				displayOptions: {
					show: {
						operation: ['executeMode'],
					},
				},
				description: 'Path to the file to process',
			},
			{
				displayName: 'Task Identifier',
				name: 'taskIdentifier',
				type: 'string',
				default: '',
				displayOptions: {
					show: {
						operation: ['executeMode'],
					},
				},
				description: 'Identifier of the task to process (e.g., "1.2.3")',
			},
			{
				displayName: 'Update Memories',
				name: 'updateMemories',
				type: 'boolean',
				default: true,
				displayOptions: {
					show: {
						operation: ['executeMode'],
					},
				},
				description: 'Whether to update Augment memories after execution',
			},
			// Properties for updateMemories operation
			{
				displayName: 'Memory Content',
				name: 'memoryContent',
				type: 'string',
				typeOptions: {
					rows: 4,
				},
				default: '',
				required: true,
				displayOptions: {
					show: {
						operation: ['updateMemories'],
					},
				},
				description: 'Content to add to Augment memories',
			},
			{
				displayName: 'Memory Category',
				name: 'memoryCategory',
				type: 'string',
				default: 'n8n',
				displayOptions: {
					show: {
						operation: ['updateMemories'],
					},
				},
				description: 'Category for the memory',
			},
			// Properties for getModeDescription operation
			{
				displayName: 'Mode',
				name: 'descriptionMode',
				type: 'options',
				options: [
					{
						name: 'GRAN - Granularization',
						value: 'GRAN',
					},
					{
						name: 'DEV-R - Roadmap Development',
						value: 'DEV-R',
					},
					{
						name: 'ARCHI - Architecture',
						value: 'ARCHI',
					},
					{
						name: 'DEBUG - Debugging',
						value: 'DEBUG',
					},
					{
						name: 'TEST - Testing',
						value: 'TEST',
					},
					{
						name: 'OPTI - Optimization',
						value: 'OPTI',
					},
					{
						name: 'REVIEW - Code Review',
						value: 'REVIEW',
					},
					{
						name: 'PREDIC - Predictive Analysis',
						value: 'PREDIC',
					},
					{
						name: 'C-BREAK - Circular Dependency Resolution',
						value: 'C-BREAK',
					},
					{
						name: 'CHECK - Verification',
						value: 'CHECK',
					},
				],
				default: 'GRAN',
				required: true,
				displayOptions: {
					show: {
						operation: ['getModeDescription'],
					},
				},
				description: 'The Augment operational mode to get description for',
			},
		],
	};

	async execute(this: IExecuteFunctions): Promise<INodeExecutionData[][]> {
		const items = this.getInputData();
		const returnData: INodeExecutionData[] = [];
		const operation = this.getNodeParameter('operation', 0) as string;

		for (let i = 0; i < items.length; i++) {
			try {
				let responseData;

				if (operation === 'executeMode') {
					// Execute Augment mode
					const mode = this.getNodeParameter('mode', i) as string;
					const filePath = this.getNodeParameter('filePath', i) as string;
					const taskIdentifier = this.getNodeParameter('taskIdentifier', i) as string;
					const updateMemories = this.getNodeParameter('updateMemories', i) as boolean;

					responseData = await this.executeAugmentMode(mode, filePath, taskIdentifier, updateMemories);
				} else if (operation === 'updateMemories') {
					// Update Augment memories
					const memoryContent = this.getNodeParameter('memoryContent', i) as string;
					const memoryCategory = this.getNodeParameter('memoryCategory', i) as string;

					responseData = await this.updateAugmentMemories(memoryContent, memoryCategory);
				} else if (operation === 'getModeDescription') {
					// Get mode description
					const mode = this.getNodeParameter('descriptionMode', i) as string;

					responseData = await this.getAugmentModeDescription(mode);
				}

				const executionData = this.helpers.constructExecutionMetaData(
					this.helpers.returnJsonArray(responseData),
					{ itemData: { item: i } },
				);

				returnData.push(...executionData);
			} catch (error) {
				if (this.continueOnFail()) {
					returnData.push({ json: { error: error.message } });
					continue;
				}
				throw new NodeOperationError(this.getNode(), error, {
					itemIndex: i,
				});
			}
		}

		return [returnData];
	}

	/**
	 * Execute an Augment operational mode
	 */
	private async executeAugmentMode(
		mode: string,
		filePath: string,
		taskIdentifier: string,
		updateMemories: boolean,
	): Promise<any> {
		return new Promise((resolve, reject) => {
			// Construct the PowerShell command
			let command = `powershell -ExecutionPolicy Bypass -Command "Import-Module AugmentIntegration; Invoke-AugmentMode -Mode '${mode}' -FilePath '${filePath}'`;

			if (taskIdentifier) {
				command += ` -TaskIdentifier '${taskIdentifier}'`;
			}

			if (updateMemories) {
				command += ' -UpdateMemories';
			}

			command += '"';

			// Execute the command
			const process = spawn(command, [], { shell: true });

			let stdout = '';
			let stderr = '';

			process.stdout.on('data', (data) => {
				stdout += data.toString();
			});

			process.stderr.on('data', (data) => {
				stderr += data.toString();
			});

			process.on('close', (code) => {
				if (code !== 0) {
					reject(new Error(`Augment mode execution failed with code ${code}: ${stderr}`));
					return;
				}

				resolve({
					success: true,
					mode,
					filePath,
					taskIdentifier,
					output: stdout,
					timestamp: new Date().toISOString(),
				});
			});

			process.on('error', (error) => {
				reject(error);
			});
		});
	}

	/**
	 * Update Augment memories
	 */
	private async updateAugmentMemories(content: string, category: string): Promise<any> {
		return new Promise((resolve, reject) => {
			// Construct the PowerShell command
			const command = `powershell -ExecutionPolicy Bypass -Command "Import-Module AugmentIntegration; Update-AugmentMemoriesForMode -Content '${content.replace(/'/g, "''")}' -Category '${category}'"`;

			// Execute the command
			const process = spawn(command, [], { shell: true });

			let stdout = '';
			let stderr = '';

			process.stdout.on('data', (data) => {
				stdout += data.toString();
			});

			process.stderr.on('data', (data) => {
				stderr += data.toString();
			});

			process.on('close', (code) => {
				if (code !== 0) {
					reject(new Error(`Augment memories update failed with code ${code}: ${stderr}`));
					return;
				}

				resolve({
					success: true,
					category,
					output: stdout,
					timestamp: new Date().toISOString(),
				});
			});

			process.on('error', (error) => {
				reject(error);
			});
		});
	}

	/**
	 * Get Augment mode description
	 */
	private async getAugmentModeDescription(mode: string): Promise<any> {
		return new Promise((resolve, reject) => {
			// Construct the PowerShell command
			const command = `powershell -ExecutionPolicy Bypass -Command "Import-Module AugmentIntegration; Get-AugmentModeDescription -Mode '${mode}'"`;

			// Execute the command
			const process = spawn(command, [], { shell: true });

			let stdout = '';
			let stderr = '';

			process.stdout.on('data', (data) => {
				stdout += data.toString();
			});

			process.stderr.on('data', (data) => {
				stderr += data.toString();
			});

			process.on('close', (code) => {
				if (code !== 0) {
					reject(new Error(`Get Augment mode description failed with code ${code}: ${stderr}`));
					return;
				}

				resolve({
					mode,
					description: stdout.trim(),
					timestamp: new Date().toISOString(),
				});
			});

			process.on('error', (error) => {
				reject(error);
			});
		});
	}
}
