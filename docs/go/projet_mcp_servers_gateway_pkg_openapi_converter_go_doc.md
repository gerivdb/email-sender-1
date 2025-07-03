# Package openapi

## Types

### Converter

Converter handles the conversion from OpenAPI to MCP configuration


#### Methods

##### Converter.Convert

Convert converts OpenAPI specification to MCP configuration


```go
func (c *Converter) Convert(specData []byte) (*config.MCPConfig, error)
```

##### Converter.ConvertFromJSON

ConvertFromJSON converts JSON OpenAPI specification to MCP configuration


```go
func (c *Converter) ConvertFromJSON(jsonData []byte) (*config.MCPConfig, error)
```

##### Converter.ConvertFromYAML

ConvertFromYAML converts YAML OpenAPI specification to MCP configuration


```go
func (c *Converter) ConvertFromYAML(yamlData []byte) (*config.MCPConfig, error)
```

## Constants

### OpenAPIVersion2, OpenAPIVersion3, OpenAPIVersion31

```go
const (
	// OpenAPIVersion2 openapi 2.0
	OpenAPIVersion2	= "2.0"
	// OpenAPIVersion3 openapi 3.0
	OpenAPIVersion3	= "3.0"
	// OpenAPIVersion31 openapi 3.1
	OpenAPIVersion31	= "3.1"
)
```

