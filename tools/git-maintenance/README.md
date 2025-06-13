# Git Maintenance Tool

Automated maintenance and synchronization tool for Git submodules according to Plan Dev v41 section 2.2.1.

## Features

### Core Functionality

- **Intelligent Submodule Sync**: Automated synchronization with multiple strategies
- **Status Monitoring**: Comprehensive submodule health reporting
- **Cleanup Operations**: Remove orphaned and stale submodule references
- **Timeout Handling**: 30-second timeout for fetch operations
- **Concurrent Processing**: Configurable parallel processing limits

### Sync Strategies

- **auto-ff**: Safe fast-forward updates for remote-ahead scenarios
- **manual-review**: Request manual intervention for complex changes
- **force-sync**: Force synchronization (destroys local changes)

### Safety Features

- **Dry-run Mode**: Test operations without making changes
- **Verbose Logging**: Detailed operation reporting
- **Error Handling**: Graceful failure recovery
- **Divergence Detection**: Identify local vs remote conflicts

## Usage

### Build the Tool

```powershell
cd tools\git-maintenance
go build -o git-maintenance.exe .
```plaintext
### Basic Commands

```powershell
# Check submodule status

.\git-maintenance.exe --action=status --verbose

# Sync with dry-run (safe testing)

.\git-maintenance.exe --action=sync --dry-run --strategy=auto-ff

# Perform actual sync

.\git-maintenance.exe --action=sync --strategy=auto-ff

# Cleanup orphaned submodules

.\git-maintenance.exe --action=cleanup --verbose
```plaintext
### Configuration Options

- `--dry-run`: Show what would be done without making changes
- `--verbose`: Enable detailed logging
- `--strategy`: Sync strategy (auto-ff, manual-review, force-sync)
- `--config`: Path to JSON configuration file
- `--action`: Operation to perform (status, sync, cleanup)

### Configuration File Example

```json
{
  "dryRun": false,
  "verbose": true,
  "syncStrategy": "auto-ff",
  "maxConcurrency": 2,
  "timeoutSeconds": 30
}
```plaintext
## Current Submodules

### Configured Submodules

- **projet/mcp/servers/gcp-mcp**: Google Cloud Platform MCP server
  - URL: https://github.com/eniayomi/gcp-mcp.git
  - Purpose: GCP service integration

- **projet/mcp/servers/gateway**: MCP Gateway server
  - URL: https://github.com/mcp-ecosystem/mcp-gateway.git
  - Purpose: MCP protocol gateway functionality

## Status Icons

- ✅ Up to date
- 🔄 Successfully synced
- ⚠️ Manual review required
- ❌ Error occurred
- 🧪 Dry-run mode

## Implementation Details

### SubmoduleStatus Structure

- Path, URL, and SHA tracking
- Last sync/fetch timestamps
- Divergence and conflict detection
- Strategy determination

### Sync Process

1. Enumerate configured submodules
2. Fetch remote updates with timeout
3. Analyze local vs remote state
4. Apply appropriate sync strategy
5. Report results with summary statistics

### Error Handling

- Graceful timeout management
- Orphaned submodule cleanup
- Git configuration validation
- Detailed error reporting

## Plan Dev v41 Compliance

This tool implements section 2.2.1 requirements:
- ✅ Automated submodule maintenance
- ✅ Intelligent synchronization strategies
- ✅ Comprehensive status reporting
- ✅ Cleanup and validation functions
- ✅ Safe operation modes (dry-run)
- ✅ Concurrent processing capabilities
