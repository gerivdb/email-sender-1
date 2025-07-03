# Package config

## Types

### AppConfig

### HotReloadConfig

HotReloadConfig supports hot-reload without restart.


#### Methods

##### HotReloadConfig.Get

```go
func (h *HotReloadConfig) Get() *AppConfig
```

##### HotReloadConfig.WatchAndReload

```go
func (h *HotReloadConfig) WatchAndReload()
```

### ProfileConfig

ProfileConfig for environment profiles.


## Functions

### ValidateConfigWithSchema

ValidateConfigWithSchema validates config with JSON Schema.


```go
func ValidateConfigWithSchema(cfg *AppConfig, schemaPath string) (bool, error)
```

