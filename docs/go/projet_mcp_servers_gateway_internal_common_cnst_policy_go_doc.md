# Package cnst

## Types

### ActionType

ActionType represents the type of action performed on a configuration


### AuthMode

### MCPStartupPolicy

MCPStartupPolicy represents the startup policy for MCP servers


### ProtoType

#### Methods

##### ProtoType.String

```go
func (s ProtoType) String() string
```

## Variables

### ErrDuplicateToolName, ErrDuplicateServerName, ErrDuplicateRouterPrefix, ErrNotReceiver, ErrNotSender

```go
var (
	// ErrDuplicateToolName is returned when a tool name is duplicated
	ErrDuplicateToolName	= errors.New("duplicate tool name")
	// ErrDuplicateServerName is returned when a server name is duplicated
	ErrDuplicateServerName	= errors.New("duplicate server name")
	// ErrDuplicateRouterPrefix is returned when a router prefix is duplicated
	ErrDuplicateRouterPrefix	= errors.New("duplicate router prefix")

	// ErrNotReceiver is returned when a notifier cannot receive updates
	ErrNotReceiver	= errors.New("notifier cannot receive updates")
	// ErrNotSender is returned when a notifier cannot send updates
	ErrNotSender	= errors.New("notifier cannot send updates")
)
```

## Constants

### AppName, CommandName

```go
const (
	AppName		= "mcp-gateway"
	CommandName	= "mcp-gateway"
)
```

### ApiServerYaml, MCPGatewayYaml

```go
const (
	ApiServerYaml	= "apiserver.yaml"
	MCPGatewayYaml	= "mcp-gateway.yaml"
)
```

### RedisClusterTypeSentinel, RedisClusterTypeCluster, RedisClusterTypeSingle

```go
const (
	RedisClusterTypeSentinel	= "sentinel"
	RedisClusterTypeCluster		= "cluster"
	RedisClusterTypeSingle		= "single"
)
```

### LangDefault, LangEN, LangZH, XLang, CtxKeyTranslator

```go
const (
	LangDefault	= LangEN
	LangEN		= "en"
	LangZH		= "zh"

	XLang			= "X-Lang"
	CtxKeyTranslator	= "translator"
)
```

