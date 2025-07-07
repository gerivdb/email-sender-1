# GatewayManager

## Purpose

The `GatewayManager` is a Go-based component designed to act as a central request processor. It orchestrates calls to several backend services and managers, including:

*   `CacheManager` (for cache operations)
*   `LWM` (assumed to be a Lifecycle Workflow Manager)
*   `RAG` (assumed to be a Retrieval Augmented Generation service)
*   `MemoryBank` (for data storage and retrieval)

It is intended to be a robust and reliable component, potentially serving as a replacement for the deprecated `MCP-Gateway`.

## Architecture

*   **Language:** Built in Go.
*   **Core Dependencies:** `GatewayManager` relies on the following Go interfaces defined in `internal/core/interfaces.go`:
    *   `core.CacheManagerInterface`
    *   `core.LWMInterface`
    *   `core.RAGInterface`
    *   `core.MemoryBankAPIClient`
    Concrete implementations of these interfaces must be provided (injected) when `GatewayManager` is instantiated via `NewGatewayManager()`.
*   **Discovery Sub-feature:** This manager includes a discovery mechanism (`discovery.go` and `discovery/discovery.go`) accessible via the `cmd/gateway-manager-cli discover` command. This feature currently scans `localhost` for active n8n and "augment" services, labeling them as "MCP Servers." The direct operational use of this discovered information by `GatewayManager`'s request processing logic is not currently implemented; it may be intended for other components or future enhancements.

## Configuration

*   `GatewayManager` itself does not have dedicated configuration files.
*   Configuration is primarily handled at the point of instantiating its dependencies. Each concrete implementation of `CacheManagerInterface`, `LWMInterface`, etc., will have its own configuration requirements.
*   If `GatewayManager` is run as a standalone service in the future (e.g., via an enhanced CLI), that service would likely require configuration for aspects like listen address, port, and how to initialize its dependencies.

## How to Run

*   **As a Library:** Currently, `GatewayManager` is primarily used as an embeddable library.
    *   The `cmd/performance-test-gateway/main.go` tool demonstrates how to instantiate `GatewayManager` and call its `ProcessRequest` method (note: it uses mock dependencies for testing purposes).
*   **CLI (`cmd/gateway-manager-cli`):** The existing command-line interface only provides a `discover` command:
    ```bash
    go run cmd/gateway-manager-cli/main.go discover [output-file.json]
    ```
    This command does not run the main `GatewayManager` request processing logic.
*   **Future Standalone Service:** To run `GatewayManager` as a continuously operating service (e.g., listening for HTTP requests), its CLI (`cmd/gateway-manager-cli`) would need to be enhanced with a `serve` or `start` command. This command would be responsible for:
    1.  Initializing concrete implementations of all dependencies.
    2.  Instantiating `GatewayManager` with these dependencies.
    3.  Starting a server (e.g., HTTP) to expose `GatewayManager.ProcessRequest`.
    This enhancement is pending the availability of concrete dependency implementations.

## Dependencies and Their Roles

`GatewayManager` depends on the following interfaces:

*   **`core.CacheManagerInterface`**:
    *   `Invalidate(ctx context.Context, key string) error`: Invalidates a cache entry.
    *   `Update(ctx context.Context, key string, value interface{}) error`: Updates/sets a cache entry.
*   **`core.LWMInterface`**:
    *   `TriggerWorkflow(ctx context.Context, workflowID string, payload map[string]interface{}) (string, error)`: Triggers a workflow and returns a task/instance ID.
    *   `GetWorkflowStatus(ctx context.Context, taskID string) (string, error)`: Retrieves the status of a triggered workflow.
*   **`core.RAGInterface`**:
    *   `GenerateContent(ctx context.Context, query string, context []string) (string, error)`: Generates content based on a query and provided context.
*   **`core.MemoryBankAPIClient`**:
    *   `Store(ctx context.Context, key string, data map[string]interface{}, ttl string) (string, error)`: Stores data with a given key and TTL.
    *   `Retrieve(ctx context.Context, id string) (map[string]interface{}, error)`: Retrieves data by ID.

**Current Status of Dependencies:** As of the last review, concrete Go implementations for these interfaces were not found within this repository. The existing tests and tools use mock implementations from `internal/core/mocks.go`. For `GatewayManager` to be fully functional in a real environment, these dependencies must be implemented or provided.

## Build and Test

Refer to the CI workflow at `.github/workflows/gateway-manager-ci.yml` for current build and test procedures. This typically involves:

```bash
# Ensure dependencies are tidy
go mod tidy

# Build the GatewayManager package and its CLI
go build ./development/managers/gateway-manager/...
go build ./cmd/gateway-manager-cli/main.go

# Run unit tests
go test ./development/managers/gateway-manager/...

# Run (current) integration tests
go test ./tests/integration/...
```

---
*This README should be updated as `GatewayManager` and its ecosystem evolve, particularly when concrete dependencies are implemented and its operational mode as a service is finalized.*
