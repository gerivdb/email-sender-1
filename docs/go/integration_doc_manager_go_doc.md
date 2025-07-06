# Package integration

## Types

### DocManager

DocManager implémente l'IDocManagerInterface.


#### Methods

##### DocManager.Authenticate

Authenticate gère l'authentification auprès du Doc Manager.


```go
func (d *DocManager) Authenticate(username, password string) error
```

##### DocManager.SyncDocs

SyncDocs synchronise la documentation.


```go
func (d *DocManager) SyncDocs(sourcePath string, forceUpdate bool) error
```

##### DocManager.TriggerUpdate

TriggerUpdate déclenche une mise à jour d'un document spécifique dans le doc manager.


```go
func (d *DocManager) TriggerUpdate(docID string, content map[string]interface{}) error
```

### DocManagerClient

DocManagerClient est une interface pour interagir avec l'API du Doc Manager.


### DocManagerClientInterface

DocManagerClientInterface définit l'interface pour interagir avec le client Doc Manager.
C'est une interface distincte pour permettre l'injection de dépendances et faciliter les tests.


### Exporter

Exporter implements the IExporter interface.


#### Methods

##### Exporter.ExportGraphviz

ExportGraphviz exports a list of dependencies to Graphviz DOT format.


```go
func (e *Exporter) ExportGraphviz(dependencies []visualizer.Dependency) (string, error)
```

##### Exporter.ExportMermaid

ExportMermaid exports a list of dependencies to Mermaid graph format.


```go
func (e *Exporter) ExportMermaid(dependencies []visualizer.Dependency, graphType string) (string, error)
```

##### Exporter.ExportPlantUML

ExportPlantUML exports a list of dependencies to PlantUML format.


```go
func (e *Exporter) ExportPlantUML(dependencies []visualizer.Dependency) (string, error)
```

### IDocManagerInterface

IDocManagerInterface définit l'interface pour interagir avec le gestionnaire de documents.


### IExporter

IExporter defines the interface for exporting data to various standard formats.


### IIntegrationObjectives

IIntegrationObjectives defines the interface for managing integration objectives and listing dependencies.


### IMetrics

IMetrics defines the interface for collecting and reporting metrics.


### IMultiLangCompat

IMultiLangCompat defines the interface for checking multi-language compatibility.


### LangScanner

LangScanner est une interface pour scanner les projets multilingues.


### Metrics

Metrics represents a collection of success metrics.


### MetricsManager

MetricsManager implements the IMetrics interface.


#### Methods

##### MetricsManager.Collect

Collect collects the current metrics.


```go
func (m *MetricsManager) Collect() (Metrics, error)
```

##### MetricsManager.Report

Report generates a report of the collected metrics.


```go
func (m *MetricsManager) Report() error
```

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

### Project

Project représente un projet détecté avec son chemin et son type.


### ProjectType

ProjectType représente les types de projets détectés.


