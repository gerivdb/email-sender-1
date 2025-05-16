# Augment Client Node for n8n

This node allows you to interact with Augment Code directly from n8n workflows.

## Prerequisites

- n8n installed and running
- Augment Code installed and configured
- AugmentIntegration PowerShell module installed

## Installation

1. Copy the `augment-client` directory to your n8n custom nodes directory
2. Restart n8n

## Features

The Augment Client node provides the following operations:

### Execute Mode

Execute an Augment operational mode on a specific file or task.

**Parameters:**
- **Mode**: The Augment operational mode to execute (GRAN, DEV-R, ARCHI, etc.)
- **File Path**: Path to the file to process
- **Task Identifier**: Identifier of the task to process (e.g., "1.2.3")
- **Update Memories**: Whether to update Augment memories after execution

### Update Memories

Update Augment memories with new content.

**Parameters:**
- **Memory Content**: Content to add to Augment memories
- **Memory Category**: Category for the memory

### Get Mode Description

Get a description of an Augment operational mode.

**Parameters:**
- **Mode**: The Augment operational mode to get description for

## Operational Modes

Augment Code supports the following operational modes:

| Mode | Description |
|------|-------------|
| GRAN | Decompose complex tasks into smaller ones |
| DEV-R | Implement roadmap tasks sequentially |
| ARCHI | Design and model system architecture |
| DEBUG | Isolate and fix bugs |
| TEST | Create and run automated tests |
| OPTI | Optimize performance and reduce complexity |
| REVIEW | Verify code quality against standards |
| PREDIC | Anticipate performance and detect anomalies |
| C-BREAK | Detect and resolve circular dependencies |
| CHECK | Verify task implementation status |

## Example Workflows

### Task Decomposition and Implementation

This workflow demonstrates how to use the Augment Client node to decompose a complex task and then implement the resulting sub-tasks.

1. Use the Augment Client node with the "Execute Mode" operation and the "GRAN" mode to decompose a task
2. Use a Split node to separate the sub-tasks
3. Use the Augment Client node with the "Execute Mode" operation and the "DEV-R" mode to implement each sub-task

### Automated Testing

This workflow demonstrates how to use the Augment Client node to run tests on a codebase.

1. Use the Augment Client node with the "Execute Mode" operation and the "TEST" mode to run tests
2. Use a Function node to parse the test results
3. Use a Slack node to send notifications about test results

## Troubleshooting

### Common Issues

- **Error: "Import-Module AugmentIntegration" failed**: Make sure the AugmentIntegration PowerShell module is installed and available in the PowerShell module path
- **Error: "Augment mode execution failed"**: Check that the file path and task identifier are correct
- **No output from the node**: Check that the PowerShell execution policy allows running scripts

### Logs

Check the n8n logs for more detailed error messages.

## License

This node is licensed under the MIT License.
