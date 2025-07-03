# Package security

## Types

### Anomaly

Anomaly représente une anomalie détectée


### AnomalyDetector

AnomalyDetector détecte les anomalies basées sur les embeddings


### AnomalyReport

AnomalyReport représente un rapport d'anomalies


### AnomalySummary

AnomalySummary résumé des anomalies


### AnomalyThresholds

AnomalyThresholds définit les seuils de détection d'anomalies


### AuditLogger

AuditLogger gère les logs d'audit


#### Methods

##### AuditLogger.LogEvent

LogEvent sur l'AuditLogger


```go
func (al *AuditLogger) LogEvent(category, action, description string, metadata map[string]interface{}) error
```

##### AuditLogger.LogSecurityEvent

LogSecurityEvent enregistre un événement de sécurité


```go
func (al *AuditLogger) LogSecurityEvent(event interfaces.SecurityEvent) error
```

### Config

Config pour le Security Manager


### ImpactAssessment

ImpactAssessment évaluation d'impact


### Logger

Logger interface simple pour le logging


### Mitigation

Mitigation mesure d'atténuation


### PatternEmbedding

PatternEmbedding représente un pattern avec son embedding


### PolicyAction

PolicyAction représente une action de politique


### PolicyCondition

PolicyCondition représente une condition de politique


### PolicyMatch

PolicyMatch représente une correspondance de politique


### PolicyRule

PolicyRule représente une règle de politique


### PolicyVectorizer

PolicyVectorizer gère la vectorisation des politiques de sécurité


### QdrantInterface

QdrantInterface interface pour Qdrant


### QdrantSearchResult

QdrantSearchResult résultat de recherche Qdrant


### RecommendedAction

RecommendedAction action recommandée


### SecurityEvent

SecurityEvent représente un événement de sécurité


### SecurityManagerImpl

SecurityManagerImpl implémente l'interface SecurityManager


#### Methods

##### SecurityManagerImpl.BuildBaselineProfile

BuildBaselineProfile construit un profil de référence à partir d'événements


```go
func (sm *SecurityManagerImpl) BuildBaselineProfile(ctx context.Context, events []SecurityEvent) error
```

##### SecurityManagerImpl.CheckRateLimit

CheckRateLimit vérifie la limite de taux


```go
func (sm *SecurityManagerImpl) CheckRateLimit(identifier string, limit int) bool
```

##### SecurityManagerImpl.ClassifyVulnerability

ClassifyVulnerability classe une vulnérabilité automatiquement


```go
func (sm *SecurityManagerImpl) ClassifyVulnerability(ctx context.Context, vuln Vulnerability) (*VulnClassification, error)
```

##### SecurityManagerImpl.DecryptData

DecryptData déchiffre des données


```go
func (sm *SecurityManagerImpl) DecryptData(encryptedData []byte) ([]byte, error)
```

##### SecurityManagerImpl.DetectAnomalies

DetectAnomalies détecte les anomalies dans un événement


```go
func (sm *SecurityManagerImpl) DetectAnomalies(ctx context.Context, event SecurityEvent) ([]Anomaly, error)
```

##### SecurityManagerImpl.DisableSecurityVectorization

DisableSecurityVectorization désactive la vectorisation sécurité


```go
func (sm *SecurityManagerImpl) DisableSecurityVectorization() error
```

##### SecurityManagerImpl.EnableSecurityVectorization

EnableSecurityVectorization active la vectorisation sécurité


```go
func (sm *SecurityManagerImpl) EnableSecurityVectorization() error
```

##### SecurityManagerImpl.EncryptData

EncryptData chiffre des données


```go
func (sm *SecurityManagerImpl) EncryptData(data []byte) ([]byte, error)
```

##### SecurityManagerImpl.GenerateSecureToken

generateSecureToken génère un token sécurisé


```go
func (sm *SecurityManagerImpl) GenerateSecureToken(length int) (string, error)
```

##### SecurityManagerImpl.GetAnomalyReport

GetAnomalyReport génère un rapport d'anomalies


```go
func (sm *SecurityManagerImpl) GetAnomalyReport(ctx context.Context, timeRange TimeRange) (*AnomalyReport, error)
```

##### SecurityManagerImpl.GetScanResult

GetScanResult récupère le résultat d'un scan


```go
func (sm *SecurityManagerImpl) GetScanResult(scanID string) (*interfaces.SecurityScanResult, error)
```

##### SecurityManagerImpl.GetSecurityVectorizationMetrics

GetSecurityVectorizationMetrics retourne les métriques de vectorisation


```go
func (sm *SecurityManagerImpl) GetSecurityVectorizationMetrics() SecurityVectorizationMetrics
```

##### SecurityManagerImpl.GetSecurityVectorizationStatus

GetSecurityVectorizationStatus retourne le statut de la vectorisation


```go
func (sm *SecurityManagerImpl) GetSecurityVectorizationStatus() bool
```

##### SecurityManagerImpl.GetVulnerabilityInsights

GetVulnerabilityInsights fournit des insights sur une vulnérabilité


```go
func (sm *SecurityManagerImpl) GetVulnerabilityInsights(ctx context.Context, vulnID string) (*VulnInsights, error)
```

##### SecurityManagerImpl.HashData

hashData calcule le hash SHA-256 de données


```go
func (sm *SecurityManagerImpl) HashData(data []byte) string
```

##### SecurityManagerImpl.HashPassword

HashPassword hash un mot de passe


```go
func (sm *SecurityManagerImpl) HashPassword(password string) (string, error)
```

##### SecurityManagerImpl.IndexSecurityPolicy

IndexSecurityPolicy indexe une politique de sécurité


```go
func (sm *SecurityManagerImpl) IndexSecurityPolicy(ctx context.Context, policy SecurityPolicy) error
```

##### SecurityManagerImpl.IsPrivateIP

isPrivateIP vérifie si une adresse IP est privée


```go
func (sm *SecurityManagerImpl) IsPrivateIP(ip string) bool
```

##### SecurityManagerImpl.LogEvent

LogEvent enregistre un événement de sécurité


```go
func (sm *SecurityManagerImpl) LogEvent(event interfaces.SecurityEvent) error
```

##### SecurityManagerImpl.RemovePolicyIndex

RemovePolicyIndex supprime une politique de l'index


```go
func (sm *SecurityManagerImpl) RemovePolicyIndex(ctx context.Context, policyID string) error
```

##### SecurityManagerImpl.SanitizeInput

SanitizeInput nettoie une entrée utilisateur


```go
func (sm *SecurityManagerImpl) SanitizeInput(input string, options interfaces.SanitizationOptions) string
```

##### SecurityManagerImpl.ScanForVulnerabilities

ScanForVulnerabilities scanne les vulnérabilités


```go
func (sm *SecurityManagerImpl) ScanForVulnerabilities(ctx context.Context, target string) (*interfaces.SecurityScanResult, error)
```

##### SecurityManagerImpl.SearchSimilarPolicies

SearchSimilarPolicies recherche des politiques similaires


```go
func (sm *SecurityManagerImpl) SearchSimilarPolicies(ctx context.Context, policyID string, threshold float64) ([]PolicyMatch, error)
```

##### SecurityManagerImpl.SuggestMitigations

SuggestMitigations suggère des mesures d'atténuation


```go
func (sm *SecurityManagerImpl) SuggestMitigations(ctx context.Context, vulnID string) ([]Mitigation, error)
```

##### SecurityManagerImpl.TrainClassifier

TrainClassifier entraîne le classificateur avec des données d'entraînement


```go
func (sm *SecurityManagerImpl) TrainClassifier(ctx context.Context, trainData []VulnTrainingData) error
```

##### SecurityManagerImpl.UpdateBaseline

UpdateBaseline met à jour la baseline avec un nouvel événement


```go
func (sm *SecurityManagerImpl) UpdateBaseline(ctx context.Context, event SecurityEvent) error
```

##### SecurityManagerImpl.UpdatePolicyIndex

UpdatePolicyIndex met à jour l'index d'une politique


```go
func (sm *SecurityManagerImpl) UpdatePolicyIndex(ctx context.Context, policyID string) error
```

##### SecurityManagerImpl.ValidateIPAddress

validateIPAddress valide une adresse IP


```go
func (sm *SecurityManagerImpl) ValidateIPAddress(ip string) bool
```

##### SecurityManagerImpl.ValidateInput

ValidateInput valide une entrée utilisateur


```go
func (sm *SecurityManagerImpl) ValidateInput(input string, rules interfaces.ValidationRules) error
```

##### SecurityManagerImpl.VerifyPassword

VerifyPassword vérifie un mot de passe


```go
func (sm *SecurityManagerImpl) VerifyPassword(password, hash string) bool
```

### SecurityPolicy

SecurityPolicy représente une politique de sécurité


### SecurityProfile

SecurityProfile représente un profil de sécurité de référence


### SecurityVectorization

SecurityVectorization interface pour les capacités de vectorisation du Security Manager


### SecurityVectorizationMetrics

SecurityVectorizationMetrics métriques de vectorisation sécurité


### SimilarItem

SimilarItem représente un élément similaire


### SimilarVuln

SimilarVuln vulnérabilité similaire


### TimeRange

TimeRange représente une plage de temps


### TrendAnalysis

TrendAnalysis analyse de tendance


### VectorizationEngine

VectorizationEngine interface pour le moteur de vectorisation


### VulnClassification

VulnClassification représente une classification de vulnérabilité


### VulnInsights

VulnInsights insights sur une vulnérabilité


### VulnTrainingData

VulnTrainingData données d'entraînement pour le classificateur


### Vulnerability

Vulnerability représente une vulnérabilité


### VulnerabilityClassifier

VulnerabilityClassifier classe automatiquement les vulnérabilités


