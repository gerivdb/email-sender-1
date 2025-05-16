import {
	ICredentialType,
	INodeProperties,
} from 'n8n-workflow';

export class AugmentClientApi implements ICredentialType {
	name = 'augmentClientApi';
	displayName = 'Augment Client API';
	documentationUrl = 'https://docs.augmentcode.com/';
	properties: INodeProperties[] = [
		{
			displayName: 'API Key',
			name: 'apiKey',
			type: 'string',
			default: '',
			description: 'API key for Augment Client',
		},
		{
			displayName: 'Base Path',
			name: 'basePath',
			type: 'string',
			default: '',
			description: 'Base path for Augment installation (e.g., D:/path/to/project)',
		},
	];
}
