# Package config

## Types

### APIConfig

APIConfig represents the configuration for API-based notifier


### APIServerConfig

### APIStorageConfig

### ArgConfig

### Auth

Auth represents authentication configuration


### AuthConfig

AuthConfig defines the authentication configuration


### CORSConfig

### DatabaseConfig

#### Methods

##### DatabaseConfig.GetDSN

GetDSN returns the database connection string


```go
func (c *DatabaseConfig) GetDSN() string
```

### DiskStorageConfig

### I18nConfig

I18nConfig represents the internationalization configuration


### ItemsConfig

### JWTConfig

### Location

Location represents a configuration location


### LoggerConfig

LoggerConfig represents the logger configuration


### MCPConfig

### MCPConfigVersion

MCPConfigVersion represents a version of an MCP configuration


### MCPGatewayConfig

MCPGatewayConfig represents the MCP gateway configuration


### MCPServer

MCPServer represents the MCP server data structure


### MCPServerConfig

### NotifierConfig

NotifierConfig represents the configuration for notifier


### NotifierRole

NotifierRole represents the role of a notifier


### OAuth2Config

### OAuth2RedisConfig

### OAuth2StorageConfig

### OpenAIConfig

### PromptArgument

### PromptConfig

#### Methods

##### PromptConfig.ToPromptSchema

ToPromptSchema converts a PromptConfig to a PromptSchema


```go
func (t *PromptConfig) ToPromptSchema() mcp.PromptSchema
```

### PromptResponse

### PromptResponseContent

### ProxyConfig

### RedisConfig

RedisConfig represents the configuration for Redis-based notifier


### RouterConfig

### ServerConfig

### SessionConfig

SessionConfig represents the session storage configuration


### SessionRedisConfig

SessionRedisConfig represents the Redis configuration for session storage


### SignalConfig

SignalConfig represents the configuration for signal-based notifier


### StorageConfig

### SuperAdminConfig

SuperAdminConfig represents the super admin configuration


### ToolConfig

#### Methods

##### ToolConfig.ToToolSchema

ToToolSchema converts a ToolConfig to a ToolSchema


```go
func (t *ToolConfig) ToToolSchema() mcp.ToolSchema
```

### Type

### ValidationError

ValidationError represents a configuration validation error


#### Methods

##### ValidationError.Error

```go
func (e *ValidationError) Error() string
```

## Functions

### LoadConfig

LoadConfig loads configuration from a YAML file with environment variable support


```go
func LoadConfig[T Type](filename string) (*T, string, error)
```

### ValidateMCPConfig

ValidateMCPConfig validates a single MCP configuration


```go
func ValidateMCPConfig(cfg *MCPConfig) error
```

### ValidateMCPConfigs

ValidateMCPConfigs validates a list of MCP configurations


```go
func ValidateMCPConfigs(configs []*MCPConfig) error
```

