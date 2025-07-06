# Package config

## Types

### Config

Config contient toutes les configurations pour l'application RAG


#### Methods

##### Config.SetLogLevel

SetLogLevel change le niveau de log


```go
func (c *Config) SetLogLevel(level LogLevel)
```

##### Config.Validate

Validate vérifie que la configuration est valide


```go
func (c *Config) Validate() error
```

### LogLevel

LogLevel définit les niveaux de log disponibles


### Provider

Provider représente les différents fournisseurs d'embeddings supportés


