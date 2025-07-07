package security

import (
	"context"
	"sync"
	"time"
)

// === PHASE 4.2.2: INTERFACES ET STRUCTURES DE VECTORISATION POUR SECURITY MANAGER ===

// VectorizationEngine interface pour le moteur de vectorisation
type VectorizationEngine interface {
	GenerateEmbedding(ctx context.Context, text string) ([]float32, error)
	GeneratePolicyEmbedding(ctx context.Context, policy SecurityPolicy) ([]float32, error)
	GenerateVulnerabilityEmbedding(ctx context.Context, vuln Vulnerability) ([]float32, error)
	FindSimilar(ctx context.Context, embedding []float32, threshold float64) ([]SimilarItem, error)
}

// QdrantInterface interface pour Qdrant
type QdrantInterface interface {
	StoreVector(ctx context.Context, collection string, id string, vector []float32, payload map[string]interface{}) error
	SearchVector(ctx context.Context, collection string, vector []float32, limit int) ([]QdrantSearchResult, error)
	DeleteVector(ctx context.Context, collection string, id string) error
}

// SimilarItem représente un élément similaire
type SimilarItem struct {
	ID         string                 `json:"id"`
	Similarity float64                `json:"similarity"`
	Metadata   map[string]interface{} `json:"metadata"`
}

// QdrantSearchResult résultat de recherche Qdrant
type QdrantSearchResult struct {
	ID      string                 `json:"id"`
	Score   float32                `json:"score"`
	Payload map[string]interface{} `json:"payload"`
}

// PolicyVectorizer gère la vectorisation des politiques de sécurité
type PolicyVectorizer struct {
	vectorizer VectorizationEngine
	qdrant     QdrantInterface
	policies   map[string]*SecurityPolicy
	embeddings map[string][]float32
	mu         sync.RWMutex
	logger     Logger
}

// SecurityPolicy représente une politique de sécurité
type SecurityPolicy struct {
	ID          string            `json:"id"`
	Name        string            `json:"name"`
	Description string            `json:"description"`
	Category    string            `json:"category"` // authentication, authorization, encryption, etc.
	Severity    string            `json:"severity"` // low, medium, high, critical
	Rules       []PolicyRule      `json:"rules"`
	Conditions  []PolicyCondition `json:"conditions"`
	Actions     []PolicyAction    `json:"actions"`
	Tags        []string          `json:"tags"`
	CreatedAt   time.Time         `json:"created_at"`
	UpdatedAt   time.Time         `json:"updated_at"`
	Enabled     bool              `json:"enabled"`
}

// PolicyRule représente une règle de politique
type PolicyRule struct {
	ID         string      `json:"id"`
	Name       string      `json:"name"`
	Expression string      `json:"expression"` // Expression logique de la règle
	Type       string      `json:"type"`       // allow, deny, require, etc.
	Priority   int         `json:"priority"`
	Parameters interface{} `json:"parameters"`
}

// PolicyCondition représente une condition de politique
type PolicyCondition struct {
	Field    string      `json:"field"`    // Champ à évaluer
	Operator string      `json:"operator"` // eq, ne, gt, lt, contains, etc.
	Value    interface{} `json:"value"`    // Valeur de comparaison
}

// PolicyAction représente une action de politique
type PolicyAction struct {
	Type       string                 `json:"type"` // log, alert, block, redirect, etc.
	Parameters map[string]interface{} `json:"parameters"`
}

// AnomalyDetector détecte les anomalies basées sur les embeddings
type AnomalyDetector struct {
	vectorizer      VectorizationEngine
	qdrant          QdrantInterface
	baselineProfile *SecurityProfile
	thresholds      AnomalyThresholds
	recentEvents    []SecurityEvent
	eventsMu        sync.RWMutex
	logger          Logger
}

// SecurityProfile représente un profil de sécurité de référence
type SecurityProfile struct {
	ID                string             `json:"id"`
	Name              string             `json:"name"`
	BaselineEmbedding []float32          `json:"baseline_embedding"`
	NormalPatterns    []PatternEmbedding `json:"normal_patterns"`
	CreatedAt         time.Time          `json:"created_at"`
	UpdatedAt         time.Time          `json:"updated_at"`
	EventCount        int                `json:"event_count"`
}

// PatternEmbedding représente un pattern avec son embedding
type PatternEmbedding struct {
	Pattern   string    `json:"pattern"`
	Embedding []float32 `json:"embedding"`
	Frequency int       `json:"frequency"`
}

// AnomalyThresholds définit les seuils de détection d'anomalies
type AnomalyThresholds struct {
	SimilarityThreshold float64 `json:"similarity_threshold"` // Seuil de similarité (0.0-1.0)
	DeviationThreshold  float64 `json:"deviation_threshold"`  // Seuil de déviation
	FrequencyThreshold  int     `json:"frequency_threshold"`  // Seuil de fréquence
}

// SecurityEvent représente un événement de sécurité
type SecurityEvent struct {
	ID          string                 `json:"id"`
	Type        string                 `json:"type"`
	Source      string                 `json:"source"`
	Target      string                 `json:"target,omitempty"`
	Description string                 `json:"description"`
	Severity    string                 `json:"severity"`
	Timestamp   time.Time              `json:"timestamp"`
	Metadata    map[string]interface{} `json:"metadata"`
	Embedding   []float32              `json:"embedding,omitempty"`
}

// VulnerabilityClassifier classe automatiquement les vulnérabilités
type VulnerabilityClassifier struct {
	vectorizer      VectorizationEngine
	qdrant          QdrantInterface
	knownVulns      map[string]*Vulnerability
	classifications map[string]*VulnClassification
	mu              sync.RWMutex
	logger          Logger
}

// Vulnerability représente une vulnérabilité
type Vulnerability struct {
	ID          string                 `json:"id"`
	CVE         string                 `json:"cve,omitempty"`
	Title       string                 `json:"title"`
	Description string                 `json:"description"`
	Severity    string                 `json:"severity"`
	CVSS        float64                `json:"cvss"`
	Category    string                 `json:"category"`
	Affected    []string               `json:"affected"` // Composants affectés
	References  []string               `json:"references"`
	Tags        []string               `json:"tags"`
	CreatedAt   time.Time              `json:"created_at"`
	UpdatedAt   time.Time              `json:"updated_at"`
	Metadata    map[string]interface{} `json:"metadata"`
}

// VulnClassification représente une classification de vulnérabilité
type VulnClassification struct {
	ID           string    `json:"id"`
	Category     string    `json:"category"`
	Subcategory  string    `json:"subcategory"`
	Confidence   float64   `json:"confidence"`
	Reasoning    string    `json:"reasoning"`
	SuggestedFix string    `json:"suggested_fix"`
	Priority     int       `json:"priority"`
	CreatedAt    time.Time `json:"created_at"`
}

// Logger interface simple pour le logging
type Logger interface {
	Info(msg string, fields ...interface{})
	Error(msg string, err error, fields ...interface{})
	Debug(msg string, fields ...interface{})
	Warn(msg string, fields ...interface{})
}

// SecurityVectorization interface pour les capacités de vectorisation du Security Manager
type SecurityVectorization interface {
	// Phase 4.2.2.1: Vectorisation des politiques de sécurité
	IndexSecurityPolicy(ctx context.Context, policy SecurityPolicy) error
	UpdatePolicyIndex(ctx context.Context, policyID string) error
	RemovePolicyIndex(ctx context.Context, policyID string) error
	SearchSimilarPolicies(ctx context.Context, policyID string, threshold float64) ([]PolicyMatch, error)

	// Phase 4.2.2.2: Détection d'anomalies basée sur embeddings
	BuildBaselineProfile(ctx context.Context, events []SecurityEvent) error
	DetectAnomalies(ctx context.Context, event SecurityEvent) ([]Anomaly, error)
	UpdateBaseline(ctx context.Context, event SecurityEvent) error
	GetAnomalyReport(ctx context.Context, timeRange TimeRange) (*AnomalyReport, error)

	// Phase 4.2.2.3: Classification automatique des vulnérabilités
	ClassifyVulnerability(ctx context.Context, vuln Vulnerability) (*VulnClassification, error)
	TrainClassifier(ctx context.Context, trainData []VulnTrainingData) error
	GetVulnerabilityInsights(ctx context.Context, vulnID string) (*VulnInsights, error)
	SuggestMitigations(ctx context.Context, vulnID string) ([]Mitigation, error)

	// Méthodes de gestion
	EnableSecurityVectorization() error
	DisableSecurityVectorization() error
	GetSecurityVectorizationStatus() bool
	GetSecurityVectorizationMetrics() SecurityVectorizationMetrics
}

// PolicyMatch représente une correspondance de politique
type PolicyMatch struct {
	PolicyID    string  `json:"policy_id"`
	PolicyName  string  `json:"policy_name"`
	Similarity  float64 `json:"similarity"`
	MatchReason string  `json:"match_reason"`
}

// Anomaly représente une anomalie détectée
type Anomaly struct {
	ID             string                 `json:"id"`
	EventID        string                 `json:"event_id"`
	Type           string                 `json:"type"`
	Severity       string                 `json:"severity"`
	DeviationScore float64                `json:"deviation_score"`
	Description    string                 `json:"description"`
	Recommendation string                 `json:"recommendation"`
	DetectedAt     time.Time              `json:"detected_at"`
	Metadata       map[string]interface{} `json:"metadata"`
}

// TimeRange représente une plage de temps
type TimeRange struct {
	Start time.Time `json:"start"`
	End   time.Time `json:"end"`
}

// AnomalyReport représente un rapport d'anomalies
type AnomalyReport struct {
	TimeRange   TimeRange      `json:"time_range"`
	TotalEvents int            `json:"total_events"`
	Anomalies   []Anomaly      `json:"anomalies"`
	Summary     AnomalySummary `json:"summary"`
	GeneratedAt time.Time      `json:"generated_at"`
}

// AnomalySummary résumé des anomalies
type AnomalySummary struct {
	HighSeverity     int     `json:"high_severity"`
	MediumSeverity   int     `json:"medium_severity"`
	LowSeverity      int     `json:"low_severity"`
	TotalAnomalies   int     `json:"total_anomalies"`
	AverageDeviation float64 `json:"average_deviation"`
}

// VulnTrainingData données d'entraînement pour le classificateur
type VulnTrainingData struct {
	Vulnerability  Vulnerability      `json:"vulnerability"`
	Classification VulnClassification `json:"classification"`
}

// VulnInsights insights sur une vulnérabilité
type VulnInsights struct {
	VulnID             string              `json:"vuln_id"`
	SimilarVulns       []SimilarVuln       `json:"similar_vulns"`
	TrendAnalysis      TrendAnalysis       `json:"trend_analysis"`
	ImpactAssessment   ImpactAssessment    `json:"impact_assessment"`
	RecommendedActions []RecommendedAction `json:"recommended_actions"`
}

// SimilarVuln vulnérabilité similaire
type SimilarVuln struct {
	ID         string  `json:"id"`
	CVE        string  `json:"cve"`
	Similarity float64 `json:"similarity"`
	Category   string  `json:"category"`
}

// TrendAnalysis analyse de tendance
type TrendAnalysis struct {
	Frequency     int     `json:"frequency"`
	Trend         string  `json:"trend"` // increasing, decreasing, stable
	Seasonality   bool    `json:"seasonality"`
	PredictedRisk float64 `json:"predicted_risk"`
}

// ImpactAssessment évaluation d'impact
type ImpactAssessment struct {
	BusinessImpact  string   `json:"business_impact"`
	TechnicalImpact string   `json:"technical_impact"`
	RiskScore       float64  `json:"risk_score"`
	AffectedSystems []string `json:"affected_systems"`
}

// RecommendedAction action recommandée
type RecommendedAction struct {
	Priority    int    `json:"priority"`
	Action      string `json:"action"`
	Description string `json:"description"`
	Effort      string `json:"effort"` // low, medium, high
}

// Mitigation mesure d'atténuation
type Mitigation struct {
	ID             string  `json:"id"`
	Type           string  `json:"type"`
	Description    string  `json:"description"`
	Effectiveness  float64 `json:"effectiveness"`
	Implementation string  `json:"implementation"`
	Cost           string  `json:"cost"`
	Timeline       string  `json:"timeline"`
}

// SecurityVectorizationMetrics métriques de vectorisation sécurité
type SecurityVectorizationMetrics struct {
	IndexedPolicies      int            `json:"indexed_policies"`
	IndexedVulns         int            `json:"indexed_vulns"`
	ProcessedEvents      int            `json:"processed_events"`
	DetectedAnomalies    int            `json:"detected_anomalies"`
	LastUpdate           time.Time      `json:"last_update"`
	VectorizationEnabled bool           `json:"vectorization_enabled"`
	Collections          map[string]int `json:"collections"`
}
