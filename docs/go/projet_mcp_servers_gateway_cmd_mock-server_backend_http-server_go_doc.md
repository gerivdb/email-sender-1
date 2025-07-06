# Package backend

## Types

### HTTPServer

HTTPServer implements the Server interface


#### Methods

##### HTTPServer.Start

```go
func (s *HTTPServer) Start(addr string) error
```

##### HTTPServer.Stop

```go
func (s *HTTPServer) Stop() error
```

### Notification

Notification represents a user's notification preference


### PromptName

### ToolName

### User

## Functions

### NewMCPServer

```go
func NewMCPServer() *server.MCPServer
```

## Variables

### MCPTinyImage

```go
var MCPTinyImage string
```

