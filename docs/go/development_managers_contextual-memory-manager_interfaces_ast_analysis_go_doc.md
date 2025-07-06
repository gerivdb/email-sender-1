# Package interfaces

interfaces/ast_analysis.go

interfaces/hybrid_metrics.go

interfaces/hybrid_mode.go


## Types

### ASTAnalysisManager

ASTAnalysisManager interface pour l'analyse structurelle du code


### ASTAnalysisResult

Types de support AST


### ASTCacheStats

### ASTPerformanceMetrics

### Action

Action reprÃ©sente une action utilisateur capturÃ©e


### AnalysisMode

#### Methods

##### AnalysisMode.String

```go
func (am AnalysisMode) String() string
```

### BaseManager

BaseManager interface de base pour tous les managers


### CodeSuggestion

### CombinedResult

### ComplexityMetrics

### ConfigManager

ConfigManager interface pour la gestion de la configuration


### ConstantInfo

### ContextEvent

### ContextQuery

### ContextResult

ContextResult reprÃ©sente un rÃ©sultat de recherche contextuelle


### ContextUpdate

ContextUpdate reprÃ©sente une mise Ã  jour de contexte


### ContextualMemoryManager

ContextualMemoryManager interface principale


### DependencyEdge

### DependencyGraph

### DependencyNode

### DependencyRelation

Types supplémentaires nécessaires


### DifferenceAnalysis

### EnrichedAction

Nouveaux types pour le mode hybride - PHASE 2.2


### ErrorManager

ErrorManager interface pour la gestion des erreurs


### ErrorRecord

ErrorRecord représente un enregistrement d'erreur


### ExportInfo

### FieldInfo

### FileNode

### FileRelation

### FileSystemGraph

### FunctionInfo

### HybridConfig

### HybridErrorInfo

HybridErrorInfo informations sur une erreur


### HybridMetrics

### HybridMetricsConfig

HybridMetricsConfig configuration pour le système de métriques


### HybridMetricsManager

HybridMetricsManager interface pour la gestion des métriques hybrides


### HybridMode

### HybridModeManager

HybridModeManager interface pour la gestion du mode hybride RAG+AST


### HybridResult

### HybridSearchResult

Types pour les rÃ©sultats hybrides


### HybridStatistics

HybridStatistics structure contenant toutes les métriques


### ImportInfo

### IndexManager

IndexManager interface pour l'indexation


### IntegrationManager

IntegrationManager interface pour les intÃ©grations externes


### ManagerMetrics

ManagerMetrics reprÃ©sente les mÃ©triques du manager


### MetricsAlert

MetricsAlert structure pour les alertes basées sur les métriques


### ModeDecision

### ModeRecommendation

### MonitoringManager

MonitoringManager interface pour le monitoring


### PackageInfo

### PackageRelation

### PackageStructure

### ParameterInfo

### PerformanceMetrics

### PerformanceThresholds

PerformanceThresholds seuils de performance pour les alertes


### QualityMetrics

### QueryFilters

### RAGPerformanceMetrics

### RealTimeContext

### RecommendationFactor

### RetrievalManager

RetrievalManager interface pour la rÃ©cupÃ©ration


### ScopeInfo

### ScoredResult

### SimilarResult

Types de support


### SimilarityAnalysis

### StorageManager

StorageManager interface pour la gestion du stockage


### StructuralContext

### StructuralMatch

### StructuralQuery

### StructuralResult

### SymbolInfo

### TimeRange

TimeRange reprÃ©sente un intervalle de temps


### TraversalFilters

### TypeInfo

### UsagePattern

### VariableInfo

### WeightFactors

### WorkspaceAnalysis

### WorkspaceMetrics

