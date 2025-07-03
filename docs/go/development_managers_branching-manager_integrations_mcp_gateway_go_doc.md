# Package integrations

## Types

### MCPBranchRequest

MCPBranchRequest represents a branch creation request


### MCPEventRequest

MCPEventRequest represents an event registration request


### MCPGatewayConfig

MCPGatewayConfig holds MCP Gateway configuration


### MCPGatewayIntegration

MCPGatewayIntegration handles integration with MCP (Model Context Protocol) Gateway


#### Methods

##### MCPGatewayIntegration.Close

Close closes the MCP Gateway integration and cleans up resources


```go
func (m *MCPGatewayIntegration) Close() error
```

##### MCPGatewayIntegration.GetBranches

GetBranches retrieves branches from MCP Gateway


```go
func (m *MCPGatewayIntegration) GetBranches(ctx context.Context, filters map[string]string) ([]*interfaces.Branch, error)
```

##### MCPGatewayIntegration.GetEvents

GetEvents retrieves events from MCP Gateway


```go
func (m *MCPGatewayIntegration) GetEvents(ctx context.Context, filters map[string]string) ([]*interfaces.BranchingEvent, error)
```

##### MCPGatewayIntegration.GetMetrics

GetMetrics retrieves metrics from MCP Gateway


```go
func (m *MCPGatewayIntegration) GetMetrics(ctx context.Context, metricType string, timeRange *interfaces.TimeRange) (map[string]interface{}, error)
```

##### MCPGatewayIntegration.GetSessions

GetSessions retrieves sessions from MCP Gateway


```go
func (m *MCPGatewayIntegration) GetSessions(ctx context.Context, filters map[string]string) ([]*interfaces.Session, error)
```

##### MCPGatewayIntegration.Health

Health checks the MCP Gateway health


```go
func (m *MCPGatewayIntegration) Health(ctx context.Context) error
```

##### MCPGatewayIntegration.NotifyQuantumBranchCreated

NotifyQuantumBranchCreated notifies MCP Gateway of quantum branch creation


```go
func (m *MCPGatewayIntegration) NotifyQuantumBranchCreated(ctx context.Context, quantumBranch *interfaces.QuantumBranch) error
```

##### MCPGatewayIntegration.RegisterBranch

RegisterBranch registers a branch with MCP Gateway


```go
func (m *MCPGatewayIntegration) RegisterBranch(ctx context.Context, branch *interfaces.Branch) error
```

##### MCPGatewayIntegration.RegisterEvent

RegisterEvent registers an event with MCP Gateway


```go
func (m *MCPGatewayIntegration) RegisterEvent(ctx context.Context, event *interfaces.BranchingEvent) error
```

##### MCPGatewayIntegration.RegisterSession

RegisterSession registers a session with MCP Gateway


```go
func (m *MCPGatewayIntegration) RegisterSession(ctx context.Context, session *interfaces.Session) error
```

##### MCPGatewayIntegration.RegisterSnapshot

RegisterSnapshot registers a temporal snapshot with MCP Gateway


```go
func (m *MCPGatewayIntegration) RegisterSnapshot(ctx context.Context, snapshot *interfaces.TemporalSnapshot) error
```

##### MCPGatewayIntegration.UpdateBranchStatus

UpdateBranchStatus updates branch status via MCP Gateway


```go
func (m *MCPGatewayIntegration) UpdateBranchStatus(ctx context.Context, branchID string, status interfaces.BranchStatus) error
```

##### MCPGatewayIntegration.UpdateSessionStatus

UpdateSessionStatus updates session status via MCP Gateway


```go
func (m *MCPGatewayIntegration) UpdateSessionStatus(ctx context.Context, sessionID string, status interfaces.SessionStatus) error
```

### MCPResponse

MCPResponse represents a standard MCP Gateway response


### MCPSessionRequest

MCPSessionRequest represents a session creation request


### MCPSnapshotRequest

MCPSnapshotRequest represents a snapshot creation request


### N8NConfig

N8NConfig holds n8n integration configuration


### N8NIntegration

N8NIntegration handles integration with n8n workflow automation


#### Methods

##### N8NIntegration.GetWorkflowStatus

GetWorkflowStatus gets the status of a workflow execution


```go
func (n *N8NIntegration) GetWorkflowStatus(ctx context.Context, executionID string) (*N8NWorkflowExecution, error)
```

##### N8NIntegration.Health

Health checks the n8n integration health


```go
func (n *N8NIntegration) Health(ctx context.Context) error
```

##### N8NIntegration.ListWorkflows

ListWorkflows lists available workflows


```go
func (n *N8NIntegration) ListWorkflows(ctx context.Context) ([]map[string]interface{}, error)
```

##### N8NIntegration.TriggerApproachCompletedWorkflow

TriggerApproachCompletedWorkflow triggers workflow when a quantum approach is completed


```go
func (n *N8NIntegration) TriggerApproachCompletedWorkflow(ctx context.Context, result *interfaces.ApproachResult) error
```

##### N8NIntegration.TriggerBranchCreatedWorkflow

TriggerBranchCreatedWorkflow triggers workflow when a branch is created


```go
func (n *N8NIntegration) TriggerBranchCreatedWorkflow(ctx context.Context, branch *interfaces.Branch) error
```

##### N8NIntegration.TriggerBranchMergedWorkflow

TriggerBranchMergedWorkflow triggers workflow when a branch is merged


```go
func (n *N8NIntegration) TriggerBranchMergedWorkflow(ctx context.Context, mergeResult *interfaces.GitMergeResult, sourceBranch, targetBranch string) error
```

##### N8NIntegration.TriggerBranchingCodeExecutedWorkflow

TriggerBranchingCodeExecutedWorkflow triggers workflow when branching code is executed


```go
func (n *N8NIntegration) TriggerBranchingCodeExecutedWorkflow(ctx context.Context, result *interfaces.ExecutionResult) error
```

##### N8NIntegration.TriggerQuantumBranchCreatedWorkflow

TriggerQuantumBranchCreatedWorkflow triggers workflow for quantum branch creation


```go
func (n *N8NIntegration) TriggerQuantumBranchCreatedWorkflow(ctx context.Context, quantumBranch *interfaces.QuantumBranch) error
```

##### N8NIntegration.TriggerSessionCreatedWorkflow

TriggerSessionCreatedWorkflow triggers workflow when a session is created


```go
func (n *N8NIntegration) TriggerSessionCreatedWorkflow(ctx context.Context, session *interfaces.Session) error
```

##### N8NIntegration.TriggerSnapshotCreatedWorkflow

TriggerSnapshotCreatedWorkflow triggers workflow when a temporal snapshot is created


```go
func (n *N8NIntegration) TriggerSnapshotCreatedWorkflow(ctx context.Context, snapshot *interfaces.TemporalSnapshot) error
```

### N8NWebhookPayload

N8NWebhookPayload represents webhook payload structure


### N8NWorkflowExecution

N8NWorkflowExecution represents a workflow execution


### RateLimiter

RateLimiter implements simple rate limiting


#### Methods

##### RateLimiter.Wait

Wait waits for a token to become available


```go
func (rl *RateLimiter) Wait(ctx context.Context) error
```

