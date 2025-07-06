# Package main

Package main implements the vector quality verification CLI tool
Phase 3.2.2.1: Créer planning-ecosystem-sync/cmd/verify-quality/main.go


## Types

### AlertThresholds

AlertThresholds defines thresholds for quality alerts


### DistributionStats

DistributionStats contains vector distribution statistics


### OutlierVector

OutlierVector represents a vector identified as an outlier


### QualityAlert

QualityAlert represents a quality issue alert
Phase 3.2.2.1.3: Ajouter alertes automatiques sur dégradation qualité


### QualityConfig

QualityConfig holds configuration for quality verification


### QualityMetrics

QualityMetrics contains computed quality metrics
Phase 3.2.2.1.1: Migrer les métriques de qualité des embeddings


### QualityReport

QualityReport contains the complete quality assessment


### QualitySummary

QualitySummary provides an overall quality assessment


### QualityVerifier

QualityVerifier performs quality verification


#### Methods

##### QualityVerifier.VerifyQuality

VerifyQuality performs comprehensive quality verification


```go
func (qv *QualityVerifier) VerifyQuality(ctx context.Context) (*QualityReport, error)
```

### SemanticTest

SemanticTest represents a semantic similarity test
Phase 3.2.2.1.2: Implémenter les tests de similarité sémantique


### VectorCluster

VectorCluster represents a cluster of similar vectors


