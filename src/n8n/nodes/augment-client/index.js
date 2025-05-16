module.exports = {
	packageName: 'n8n-nodes-augment-client',
	nodeTypes: [
		require('./dist/nodes/AugmentClient.node.js'),
	],
	credentialTypes: [
		require('./dist/credentials/AugmentClientApi.credentials.js'),
	],
};
