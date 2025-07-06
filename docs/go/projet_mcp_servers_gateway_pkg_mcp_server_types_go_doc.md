# Package mcp

## Types

### AudioContent

#### Methods

##### AudioContent.GetType

```go
func (i *AudioContent) GetType() string
```

### BaseRequestParams

BaseRequestParams represents the base parameters for all requests


### CallToolParams

CallToolParams represents parameters for a tools/call request


### CallToolRequest

CallToolRequest represents a tools/call request


### CallToolResult

CallToolResult represents the result of a tools/call request


### ClientCapabilitiesSchema

ClientCapabilitiesSchema represents capabilities a client may support


### Content

Content represents a content item in a tool call result


### ExperimentalCapabilitySchema

### ImageContent

#### Methods

##### ImageContent.GetType

```go
func (i *ImageContent) GetType() string
```

### ImplementationSchema

ImplementationSchema describes the name and version of an MCP implementation


### InitializeRequestParams

InitializeRequestParams represents parameters for initialize request


### InitializeRequestSchema

InitializeRequestSchema represents an initialize request


### InitializeResult

InitializeResult represents the result of an initialize request


### InitializedNotification

InitializedNotification represents an initialized notification


### InitializedResult

### JSONRPCBaseResult

#### Methods

##### JSONRPCBaseResult.WithID

```go
func (j JSONRPCBaseResult) WithID(id int) JSONRPCBaseResult
```

### JSONRPCError

JSONRPCError represents an error in a JSON-RPC response


### JSONRPCErrorSchema

### JSONRPCNotification

JSONRPCNotification represents a JSON-RPC notification


### JSONRPCRequest

JSONRPCRequest represents a JSON-RPC request that expects a response


### JSONRPCResponse

JSONRPCResponse represents a JSON-RPC response


### ListToolsResult

ListToolsResult represents the result of a tools/list request


### LoggingCapabilitySchema

### PingRequest

PingRequest represents a ping request


### PromptArgumentSchema

### PromptResponseContentSchema

### PromptResponseSchema

### PromptSchema

### PromptsCapabilitySchema

PromptsCapabilitySchema represents prompts-related capabilities


### RequestMeta

RequestMeta represents the meta information for a request


### ResourcesCapabilitySchema

ResourcesCapabilitySchema represents resources-related capabilities


### RootsCapabilitySchema

RootsCapabilitySchema represents roots-related capabilities


### ServerCapabilitiesSchema

ServerCapabilitiesSchema represents capabilities a server may support


### TextContent

TextContent represents a text content item


#### Methods

##### TextContent.GetType

```go
func (t *TextContent) GetType() string
```

### ToolInputSchema

### ToolSchema

ToolSchema represents a tool definition


### ToolsCapabilitySchema

ToolsCapabilitySchema represents tools-related capabilities


## Constants

### ProtocolVersion20250326, ProtocolVersion20241105, LatestProtocolVersion, JSPNRPCVersion

Protocol versions


```go
const (
	ProtocolVersion20250326	= "2025-03-26"
	ProtocolVersion20241105	= "2024-11-05"
	LatestProtocolVersion	= ProtocolVersion20241105
	JSPNRPCVersion		= "2.0"
)
```

### Initialize, NotificationInitialized, Ping, ToolsList, ToolsCall, PromptsList, PromptsGet

Methods


```go
const (
	Initialize		= "initialize"
	NotificationInitialized	= "notifications/initialized"
	Ping			= "ping"
	ToolsList		= "tools/list"
	ToolsCall		= "tools/call"
	PromptsList		= "prompts/list"
	PromptsGet		= "prompts/get"
)
```

### Accepted, NotificationRootsListChanged, NotificationCancelled, NotificationProgress, NotificationMessage, NotificationResourceUpdated, NotificationResourceListChanged, NotificationToolListChanged, NotificationPromptListChanged, SamplingCreateMessage, LoggingSetLevel, ResourcesList, ResourcesTemplatesList, ResourcesRead

Response


```go
const (
	Accepted	= "Accepted"

	NotificationRootsListChanged	= "notifications/roots/list_changed"
	NotificationCancelled		= "notifications/cancelled"
	NotificationProgress		= "notifications/progress"
	NotificationMessage		= "notifications/message"
	NotificationResourceUpdated	= "notifications/resources/updated"
	NotificationResourceListChanged	= "notifications/resources/list_changed"
	NotificationToolListChanged	= "notifications/tools/list_changed"
	NotificationPromptListChanged	= "notifications/prompts/list_changed"

	SamplingCreateMessage	= "sampling/createMessage"
	LoggingSetLevel		= "logging/setLevel"

	ResourcesList		= "resources/list"
	ResourcesTemplatesList	= "resources/templates/list"
	ResourcesRead		= "resources/read"
)
```

### ErrorCodeParseError, ErrorCodeInvalidRequest, ErrorCodeMethodNotFound, ErrorCodeInvalidParams, ErrorCodeInternalError

Error codes for MCP protocol
Standard JSON-RPC error codes


```go
const (
	ErrorCodeParseError	= -32700
	ErrorCodeInvalidRequest	= -32600
	ErrorCodeMethodNotFound	= -32601
	ErrorCodeInvalidParams	= -32602
	ErrorCodeInternalError	= -32603
)
```

### ErrorCodeConnectionClosed, ErrorCodeRequestTimeout

SDKs and applications error codes


```go
const (
	ErrorCodeConnectionClosed	= -32000
	ErrorCodeRequestTimeout		= -32001
)
```

### TextContentType, ImageContentType, AudioContentType

```go
const (
	TextContentType		= "text"
	ImageContentType	= "image"
	AudioContentType	= "audio"
)
```

### HeaderMcpSessionID

```go
const (
	HeaderMcpSessionID = "Mcp-Session-Id"
)
```

