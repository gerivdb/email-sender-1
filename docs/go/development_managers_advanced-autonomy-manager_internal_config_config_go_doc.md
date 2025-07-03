# Package config

Package config provides configuration structures for the AdvancedAutonomyManager

Package config provides configuration loading and management for the AdvancedAutonomyManager


## Types

### AutonomyConfig

AutonomyConfig contient la configuration complète du manager autonome


### Config

Config represents the main configuration for the AdvancedAutonomyManager


### CoordinationConfig

CoordinationConfig configure la couche de coordination maître


### DecisionEngineConfig

DecisionEngineConfig configure le moteur de décision neural


### DependencyResolutionConfig

DependencyResolutionConfig defines configuration for dependency resolution


### HealingConfig

HealingConfig configure le système d'auto-réparation


### InfrastructureConfig

InfrastructureConfig defines the configuration for infrastructure orchestration


### MonitoringConfig

MonitoringConfig configure le dashboard de monitoring


### PredictiveConfig

PredictiveConfig configure le système de maintenance prédictive


### ServiceConfig

ServiceConfig defines configuration for an individual service


### ServiceDiscoveryConfig

ServiceDiscoveryConfig defines service discovery configuration


## Functions

### SaveConfigToFile

SaveConfigToFile sauvegarde la configuration dans un fichier YAML


```go
func SaveConfigToFile(config *AutonomyConfig, filePath string) error
```

