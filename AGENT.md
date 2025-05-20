# Directives pour les agents - Email-Sender-1

## Build/Test Commands
- Run all tests: `node src/n8n/nodes/tests/run-all-tests.js`
- Run specific test: `node src/n8n/nodes/tests/test-mcp-nodes.js` or `node src/n8n/nodes/tests/test-scenarios.js`
- PowerShell tests: `Install-Module -Name Pester -Force -SkipPublisherCheck` then run `./path/to/test.ps1`

## Project Architecture
- **n8n workflows**: Email automation processes in `/src/n8n/workflows/`
- **MCP (Model Context Protocol)**: AI context servers in `/src/mcp/servers/`
- **Integrations**: Notion, Google Calendar, Gmail, OpenRouter/DeepSeek
- **Key workflows**: Email Sender Phases 1-3 (prospection, follow-up, response handling)

## Code Style Guidelines
- **Environment**: PowerShell 7 + Python 3.11, TypeScript for n8n components
- **Encoding**: UTF-8 for all files (with BOM for PowerShell)
- **Naming Conventions**: 
  - PowerShell: PascalCase for functions (Verb-Noun), camelCase for variables
  - JavaScript: camelCase for variables/functions, PascalCase for classes
  - Python: snake_case for functions/variables, PascalCase for classes
- **Documentation**: Min 20% of code, document intention and logic
- **Complexity**: Cyclometric complexity < 10
- **Error Handling**: Use specific exceptions/errors, log with context
- **Organization**: Modular structure with clear separation of concerns
- **Principles**: SOLID, DRY, KISS, YAGNI
- **Limits**: Max 500 lines per file, max 5KB per functional unit

## Development Methodology
- **ANALYZE**: Decompose and estimate tasks
- **LEARN**: Research existing patterns
- **CODE**: Implement in functional units ≤5KB
- **TEST**: Systematic testing with high coverage
- **ADAPT**: Adjust granularity based on complexity

## Dependencies
- n8n-nodes-mcp==0.1.14
- @suekou/mcp-notion-server==1.1.1
- python-dotenv==1.0.0
- requests==2.31.0