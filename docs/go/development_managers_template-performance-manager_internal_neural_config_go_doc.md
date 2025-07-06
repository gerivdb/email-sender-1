# Package neural

Package neural provides configuration for the neural pattern processor


## Types

### AIEngine

AIEngine - Interface pour le moteur IA


### AnalysisData

AnalysisData - Données pour analyse


### Config

Config holds configuration for the neural pattern processor


### MetricsCollector

MetricsCollector - Interface collecteur métriques


### PatternDatabase

PatternDatabase - Interface base de données patterns


### TemplateData

TemplateData - Données template pour analyse


## Functions

### NewNeuralPatternProcessor

NewNeuralPatternProcessor - Constructeur


```go
func NewNeuralPatternProcessor(
	aiEngine AIEngine,
	patternDB PatternDatabase,
	config *Config,
	logger *logrus.Logger,
) interfaces.NeuralPatternProcessor
```

### NewProcessor

NewProcessor creates a new neural pattern processor with the given configuration


```go
func NewProcessor(config Config) (interfaces.NeuralPatternProcessor, error)
```

