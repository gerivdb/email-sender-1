# PyMCPfy Documentation

Welcome to the PyMCPfy documentation! PyMCPfy is a Python library that enables developers to expose their existing web framework APIs via the Model Context Protocol (MCP).

## Table of Contents

1. [Getting Started](getting_started.md)
   - Installation
   - Basic Configuration
   - Your First MCP API

2. Framework Integration Guides
   - [Django Integration](django_integration.md)
   - [Flask Integration](flask_integration.md)
   - [FastAPI Integration](fastapi_integration.md)

3. [Configuration Guide](configuration.md)
   - Configuration File
   - Environment Variables
   - Programmatic Configuration

4. [API Reference](api_reference.md)
   - Core API
   - Framework-specific APIs
   - Transport Protocols

5. Advanced Topics
   - Authentication & Authorization
   - Custom Transport Protocols
   - Schema Generation
   - Error Handling

6. [Examples](../examples/)
   - Django Example
   - Flask Example
   - FastAPI Example

## Architecture Overview

PyMCPfy is built with a modular architecture:

```
┌─────────────────┐
│    Your API     │
└────────┬────────┘
         │
┌────────┴────────┐
│  Framework      │
│  Integration    │
└────────┬────────┘
         │
┌────────┴────────┐
│   PyMCPfy Core  │
└────────┬────────┘
         │
┌────────┴────────┐
│  MCP Protocol   │
└─────────────────┘
```

- **Your API**: Your existing web API endpoints
- **Framework Integration**: Framework-specific adapters (Django, Flask, FastAPI)
- **PyMCPfy Core**: Core protocol implementation and schema generation
- **MCP Protocol**: The underlying Model Context Protocol

## Key Concepts

1. **MCP Functions**: API endpoints exposed via MCP
2. **Schema Generation**: Automatic conversion of Python types to MCP schema
3. **Transport Protocols**: WebSocket and HTTP communication
4. **Context**: Request context and metadata handling

## Getting Help

- [GitHub Issues](https://github.com/nimeshkverma/pymcpfy/issues)
- [Contributing Guide](../CONTRIBUTING.md)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/pymcpfy)
