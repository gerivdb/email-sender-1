# Package analytics

Package analytics provides configuration for the performance metrics engine


## Types

### Config

Config holds configuration for the performance metrics engine


### DataExporter

DataExporter - Interface export données


### MetricsAggregator

MetricsAggregator - Interface agrégation métriques


### MetricsQuery

MetricsQuery - Requête métriques


### MetricsStore

MetricsStore - Interface stockage métriques


## Functions

### NewMetricsCollector

NewMetricsCollector creates a new performance metrics engine with the given configuration


```go
func NewMetricsCollector(config Config) (interfaces.PerformanceMetricsEngine, error)
```

### NewMetricsCollectorEngine

NewMetricsCollectorEngine - Constructeur


```go
func NewMetricsCollectorEngine(
	store MetricsStore,
	aggregator MetricsAggregator,
	exporter DataExporter,
	config *Config,
	logger *logrus.Logger,
) interfaces.PerformanceMetricsEngine
```

