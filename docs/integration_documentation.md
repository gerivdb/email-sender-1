# Package integration

## Types

### DocManager

DocManager implements the IDocManagerInterface.


#### Methods

##### DocManager.SyncDocs

SyncDocs synchronizes documentation.


```go
func (d *DocManager) SyncDocs() error
```

##### DocManager.TriggerUpdate

TriggerUpdate triggers an update in the document manager.


```go
func (d *DocManager) TriggerUpdate() error
```

### Exporter

Exporter implements the IExporter interface.


#### Methods

##### Exporter.ExportGraphviz

ExportGraphviz exports data to Graphviz DOT format.


```go
func (e *Exporter) ExportGraphviz(data interface{}) (string, error)
```

##### Exporter.ExportMermaid

ExportMermaid exports data to Mermaid format.


```go
func (e *Exporter) ExportMermaid(data interface{}) (string, error)
```

##### Exporter.ExportPlantUML

ExportPlantUML exports data to PlantUML format.


```go
func (e *Exporter) ExportPlantUML(data interface{}) (string, error)
```

### IDocManagerInterface

IDocManagerInterface defines the interface for interacting with the document manager.


### IExporter

IExporter defines the interface for exporting data to various standard formats.


### IIntegrationObjectives

IIntegrationObjectives defines the interface for managing integration objectives and listing dependencies.


### IMultiLangCompat

IMultiLangCompat defines the interface for checking multi-language compatibility.


### MultiLangCompat

MultiLangCompat implements the IMultiLangCompat interface.


#### Methods

##### MultiLangCompat.CheckCompatibility

CheckCompatibility checks the compatibility across different languages and folders.


```go
func (m *MultiLangCompat) CheckCompatibility() error
```

### ObjectivesManager

ObjectivesManager is an implementation of the IIntegrationObjectives interface.


#### Methods

##### ObjectivesManager.DefineObjectives

```go
func (o *ObjectivesManager) DefineObjectives(ctx context.Context) error
```

##### ObjectivesManager.ListDependencies

```go
func (o *ObjectivesManager) ListDependencies() ([]string, error)
```

