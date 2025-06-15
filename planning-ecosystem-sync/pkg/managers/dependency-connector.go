package managers

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
)

// DependencyConnector implémente la synchronisation bidirectionnelle
// entre le Dependency Manager et le Planning Ecosystem Sync
type DependencyConnector struct {
	mu                      sync.RWMutex
	dependencyMetadata      map[string]*DependencyMetadata
	planDependencyMappings  map[string][]string // planID -> []dependencyNames
	conflictDetector        *ConflictDetector
	syncEnabled             bool
	eventChannel            chan DependencyEvent
	logger                  Logger
}

// DependencyMetadata contient les métadonnées enrichies d'une dépendance
type DependencyMetadata struct {
	Name           string            `json:"name"`
	Version        string            `json:"version"`
	AssociatedPlan string            `json:"associated_plan,omitempty"`
	Conflicts      []string          `json:"conflicts,omitempty"`
	LastSync       time.Time         `json:"last_sync"`
	Embedding      []float32         `json:"embedding,omitempty"`
	Tags           map[string]string `json:"tags,omitempty"`
	Usage          UsageMetrics      `json:"usage"`
}

// UsageMetrics contient les métriques d'utilisation d'une dépendance
type UsageMetrics struct {
	ImportCount      int       `json:"import_count"`
	LastUsed         time.Time `json:"last_used"`
	CriticalityScore float64   `json:"criticality_score"`
	Performance      struct {
		BuildTime   time.Duration `json:"build_time"`
		TestCoverage float64      `json:"test_coverage"`
	} `json:"performance"`
}

// DependencyEvent représente un événement de synchronisation
type DependencyEvent struct {
	ID            string    `json:"id"`
	Type          EventType `json:"type"`
	DependencyName string   `json:"dependency_name"`
	PlanID        string    `json:"plan_id,omitempty"`
	Metadata      *DependencyMetadata `json:"metadata"`
	Timestamp     time.Time `json:"timestamp"`
}

// EventType définit les types d'événements de synchronisation
type EventType string

const (
	EventDependencyAdded      EventType = "dependency_added"
	EventDependencyUpdated    EventType = "dependency_updated"
	EventDependencyRemoved    EventType = "dependency_removed"
	EventPlanAssociated       EventType = "plan_associated"
	EventConflictDetected     EventType = "conflict_detected"
	EventConflictResolved     EventType = "conflict_resolved"
)

// ConflictDetector détecte automatiquement les conflits de dépendances
type ConflictDetector struct {
	versionConflicts map[string][]string // dependency -> conflicting versions
	semanticEngine   VectorizationEngine // pour la détection sémantique
}

// Logger interface pour le logging
type Logger interface {
	Info(msg string, fields ...interface{})
	Error(msg string, err error, fields ...interface{})
	Debug(msg string, fields ...interface{})
	Warn(msg string, fields ...interface{})
}

// VectorizationEngine interface pour la vectorisation
type VectorizationEngine interface {
	GenerateEmbedding(ctx context.Context, text string) ([]float32, error)
	FindSimilar(ctx context.Context, embedding []float32, threshold float64) ([]SimilarItem, error)
}

// SimilarItem représente un élément similaire trouvé par vectorisation
type SimilarItem struct {
	Name       string  `json:"name"`
	Similarity float64 `json:"similarity"`
	Metadata   map[string]interface{} `json:"metadata"`
}

// NewDependencyConnector crée une nouvelle instance du connecteur
func NewDependencyConnector(logger Logger, vectorEngine VectorizationEngine) *DependencyConnector {
	dc := &DependencyConnector{
		dependencyMetadata:     make(map[string]*DependencyMetadata),
		planDependencyMappings: make(map[string][]string),
		conflictDetector: &ConflictDetector{
			versionConflicts: make(map[string][]string),
			semanticEngine:   vectorEngine,
		},
		syncEnabled:  true,
		eventChannel: make(chan DependencyEvent, 100),
		logger:       logger,
	}

	// Démarrer le processeur d'événements
	go dc.processEvents()

	return dc
}

// === IMPLÉMENTATION PHASE 4.1.2.1.1: CONNECTEUR BIDIRECTIONNEL ===

// SyncDependencyFromManager synchronise une dépendance depuis le Dependency Manager
func (dc *DependencyConnector) SyncDependencyFromManager(ctx context.Context, dep *DependencyInput) error {
	dc.mu.Lock()
	defer dc.mu.Unlock()

	if !dc.syncEnabled {
		return fmt.Errorf("synchronization is disabled")
	}

	// Créer ou mettre à jour les métadonnées
	metadata := &DependencyMetadata{
		Name:     dep.Name,
		Version:  dep.Version,
		LastSync: time.Now(),
		Tags:     make(map[string]string),
		Usage: UsageMetrics{
			ImportCount: 1,
			LastUsed:    time.Now(),
			CriticalityScore: dc.calculateCriticality(dep),
		},
	}

	// Générer l'embedding pour la recherche sémantique
	if dc.conflictDetector.semanticEngine != nil {
		description := fmt.Sprintf("%s %s", dep.Name, dep.Version)
		embedding, err := dc.conflictDetector.semanticEngine.GenerateEmbedding(ctx, description)
		if err != nil {
			dc.logger.Warn("Failed to generate embedding", "dependency", dep.Name, "error", err)
		} else {
			metadata.Embedding = embedding
		}
	}

	dc.dependencyMetadata[dep.Name] = metadata

	// Envoyer événement de synchronisation
	event := DependencyEvent{
		ID:             uuid.New().String(),
		Type:           EventDependencyAdded,
		DependencyName: dep.Name,
		Metadata:       metadata,
		Timestamp:      time.Now(),
	}

	select {
	case dc.eventChannel <- event:
		dc.logger.Info("Dependency synced from manager", "name", dep.Name, "version", dep.Version)
	default:
		dc.logger.Error("Event channel full, sync event dropped", nil, "dependency", dep.Name)
	}

	return nil
}

// SyncDependencyToPlan associe une dépendance à un plan
func (dc *DependencyConnector) SyncDependencyToPlan(ctx context.Context, dependencyName, planID string) error {
	dc.mu.Lock()
	defer dc.mu.Unlock()

	// Vérifier que la dépendance existe
	metadata, exists := dc.dependencyMetadata[dependencyName]
	if !exists {
		return fmt.Errorf("dependency %s not found in metadata", dependencyName)
	}

	// Mettre à jour l'association
	metadata.AssociatedPlan = planID
	metadata.LastSync = time.Now()

	// Mettre à jour les mappings
	if dc.planDependencyMappings[planID] == nil {
		dc.planDependencyMappings[planID] = make([]string, 0)
	}
	dc.planDependencyMappings[planID] = append(dc.planDependencyMappings[planID], dependencyName)

	// Envoyer événement d'association
	event := DependencyEvent{
		ID:             uuid.New().String(),
		Type:           EventPlanAssociated,
		DependencyName: dependencyName,
		PlanID:         planID,
		Metadata:       metadata,
		Timestamp:      time.Now(),
	}

	select {
	case dc.eventChannel <- event:
		dc.logger.Info("Dependency associated with plan", "dependency", dependencyName, "plan", planID)
	default:
		dc.logger.Error("Event channel full, association event dropped", nil)
	}

	return nil
}

// === IMPLÉMENTATION PHASE 4.1.2.1.2: SYNCHRONISATION MÉTADONNÉES ===

// GetDependencyMetadata récupère les métadonnées d'une dépendance
func (dc *DependencyConnector) GetDependencyMetadata(dependencyName string) (*DependencyMetadata, error) {
	dc.mu.RLock()
	defer dc.mu.RUnlock()

	metadata, exists := dc.dependencyMetadata[dependencyName]
	if !exists {
		return nil, fmt.Errorf("metadata not found for dependency: %s", dependencyName)
	}

	return metadata, nil
}

// GetPlanDependencies récupère toutes les dépendances associées à un plan
func (dc *DependencyConnector) GetPlanDependencies(planID string) ([]string, error) {
	dc.mu.RLock()
	defer dc.mu.RUnlock()

	dependencies, exists := dc.planDependencyMappings[planID]
	if !exists {
		return []string{}, nil
	}

	return dependencies, nil
}

// UpdateDependencyMetadata met à jour les métadonnées d'une dépendance
func (dc *DependencyConnector) UpdateDependencyMetadata(dependencyName string, updates map[string]interface{}) error {
	dc.mu.Lock()
	defer dc.mu.Unlock()

	metadata, exists := dc.dependencyMetadata[dependencyName]
	if !exists {
		return fmt.Errorf("dependency %s not found", dependencyName)
	}

	// Appliquer les mises à jour
	for key, value := range updates {
		switch key {
		case "version":
			if v, ok := value.(string); ok {
				metadata.Version = v
			}
		case "associated_plan":
			if v, ok := value.(string); ok {
				metadata.AssociatedPlan = v
			}
		case "criticality_score":
			if v, ok := value.(float64); ok {
				metadata.Usage.CriticalityScore = v
			}
		}
	}

	metadata.LastSync = time.Now()

	// Envoyer événement de mise à jour
	event := DependencyEvent{
		ID:             uuid.New().String(),
		Type:           EventDependencyUpdated,
		DependencyName: dependencyName,
		Metadata:       metadata,
		Timestamp:      time.Now(),
	}

	select {
	case dc.eventChannel <- event:
		dc.logger.Info("Dependency metadata updated", "name", dependencyName)
	default:
		dc.logger.Error("Event channel full, update event dropped", nil)
	}

	return nil
}

// === IMPLÉMENTATION PHASE 4.1.2.1.3: DÉTECTION AUTOMATIQUE DE CONFLITS ===

// DetectConflicts détecte automatiquement les conflits de dépendances
func (dc *DependencyConnector) DetectConflicts(ctx context.Context, dependencyName string) ([]ConflictReport, error) {
	dc.mu.RLock()
	defer dc.mu.RUnlock()

	var conflicts []ConflictReport

	// 1. Détection des conflits de version
	versionConflicts := dc.detectVersionConflicts(dependencyName)
	conflicts = append(conflicts, versionConflicts...)

	// 2. Détection des conflits sémantiques via vectorisation
	if dc.conflictDetector.semanticEngine != nil {
		semanticConflicts, err := dc.detectSemanticConflicts(ctx, dependencyName)
		if err != nil {
			dc.logger.Warn("Failed to detect semantic conflicts", "dependency", dependencyName, "error", err)
		} else {
			conflicts = append(conflicts, semanticConflicts...)
		}
	}

	// 3. Détection des conflits de plan
	planConflicts := dc.detectPlanConflicts(dependencyName)
	conflicts = append(conflicts, planConflicts...)

	// Envoyer événements de conflit détectés
	for _, conflict := range conflicts {
		event := DependencyEvent{
			ID:             uuid.New().String(),
			Type:           EventConflictDetected,
			DependencyName: dependencyName,
			Metadata:       dc.dependencyMetadata[dependencyName],
			Timestamp:      time.Now(),
		}

		select {
		case dc.eventChannel <- event:
		default:
			dc.logger.Error("Event channel full, conflict event dropped", nil)
		}
	}

	return conflicts, nil
}

// ConflictReport représente un rapport de conflit
type ConflictReport struct {
	Type              ConflictType `json:"type"`
	DependencyName    string       `json:"dependency_name"`
	ConflictingEntity string       `json:"conflicting_entity"`
	Description       string       `json:"description"`
	Severity          Severity     `json:"severity"`
	Resolution        string       `json:"resolution,omitempty"`
	AutoResolvable    bool         `json:"auto_resolvable"`
}

// ConflictType définit les types de conflits
type ConflictType string

const (
	ConflictVersion   ConflictType = "version"
	ConflictSemantic  ConflictType = "semantic"
	ConflictPlan      ConflictType = "plan"
	ConflictUsage     ConflictType = "usage"
)

// Severity définit la sévérité des conflits
type Severity string

const (
	SeverityLow      Severity = "low"
	SeverityMedium   Severity = "medium"
	SeverityHigh     Severity = "high"
	SeverityCritical Severity = "critical"
)

// DependencyInput représente l'entrée d'une dépendance
type DependencyInput struct {
	Name        string            `json:"name"`
	Version     string            `json:"version"`
	Repository  string            `json:"repository,omitempty"`
	License     string            `json:"license,omitempty"`
	Tags        map[string]string `json:"tags,omitempty"`
}

// MetricsReport contient les métriques du connecteur
type MetricsReport struct {
	TotalDependencies int                    `json:"total_dependencies"`
	TotalPlans        int                    `json:"total_plans"`
	SyncEnabled       bool                   `json:"sync_enabled"`
	LastSync          time.Time              `json:"last_sync"`
	PlanMetrics       map[string]PlanMetrics `json:"plan_metrics"`
}

// PlanMetrics contient les métriques d'un plan
type PlanMetrics struct {
	DependencyCount int       `json:"dependency_count"`
	LastUpdate      time.Time `json:"last_update"`
}

// detectVersionConflicts détecte les conflits de version
func (dc *DependencyConnector) detectVersionConflicts(dependencyName string) []ConflictReport {
	var conflicts []ConflictReport

	metadata, exists := dc.dependencyMetadata[dependencyName]
	if !exists {
		return conflicts
	}

	// Rechercher d'autres versions de la même dépendance
	for name, otherMetadata := range dc.dependencyMetadata {
		if name != dependencyName && dc.isSameDependency(dependencyName, name) {
			if metadata.Version != otherMetadata.Version {
				conflict := ConflictReport{
					Type:              ConflictVersion,
					DependencyName:    dependencyName,
					ConflictingEntity: name,
					Description:       fmt.Sprintf("Version mismatch: %s vs %s", metadata.Version, otherMetadata.Version),
					Severity:          SeverityMedium,
					Resolution:        "Upgrade to the latest compatible version",
					AutoResolvable:    true,
				}
				conflicts = append(conflicts, conflict)
			}
		}
	}

	return conflicts
}

// detectSemanticConflicts détecte les conflits sémantiques via vectorisation
func (dc *DependencyConnector) detectSemanticConflicts(ctx context.Context, dependencyName string) ([]ConflictReport, error) {
	var conflicts []ConflictReport

	metadata, exists := dc.dependencyMetadata[dependencyName]
	if !exists || len(metadata.Embedding) == 0 {
		return conflicts, nil
	}

	// Rechercher des dépendances similaires
	similar, err := dc.conflictDetector.semanticEngine.FindSimilar(ctx, metadata.Embedding, 0.85)
	if err != nil {
		return nil, err
	}

	for _, item := range similar {
		if item.Name != dependencyName && item.Similarity > 0.9 {
			conflict := ConflictReport{
				Type:              ConflictSemantic,
				DependencyName:    dependencyName,
				ConflictingEntity: item.Name,
				Description:       fmt.Sprintf("Potentially duplicate functionality (similarity: %.2f)", item.Similarity),
				Severity:          SeverityLow,
				Resolution:        "Review if both dependencies are necessary",
				AutoResolvable:    false,
			}
			conflicts = append(conflicts, conflict)
		}
	}

	return conflicts, nil
}

// detectPlanConflicts détecte les conflits de plan
func (dc *DependencyConnector) detectPlanConflicts(dependencyName string) []ConflictReport {
	var conflicts []ConflictReport

	metadata, exists := dc.dependencyMetadata[dependencyName]
	if !exists || metadata.AssociatedPlan == "" {
		return conflicts
	}

	// Vérifier si la dépendance est associée à plusieurs plans
	planCount := 0
	for _, dependencies := range dc.planDependencyMappings {
		for _, dep := range dependencies {
			if dep == dependencyName {
				planCount++
			}
		}
	}

	if planCount > 1 {
		conflict := ConflictReport{
			Type:              ConflictPlan,
			DependencyName:    dependencyName,
			ConflictingEntity: "multiple_plans",
			Description:       fmt.Sprintf("Dependency associated with %d plans", planCount),
			Severity:          SeverityMedium,
			Resolution:        "Clarify plan ownership or create shared dependency plan",
			AutoResolvable:    false,
		}
		conflicts = append(conflicts, conflict)
	}

	return conflicts
}

// calculateCriticality calcule le score de criticité d'une dépendance
func (dc *DependencyConnector) calculateCriticality(dep *DependencyInput) float64 {
	score := 0.0

	// Base score selon le nom (heuristiques)
	if strings.Contains(strings.ToLower(dep.Name), "security") ||
		strings.Contains(strings.ToLower(dep.Name), "crypto") {
		score += 0.4
	}

	if strings.Contains(strings.ToLower(dep.Name), "test") {
		score += 0.1
	} else {
		score += 0.3 // dépendances de production plus critiques
	}

	// Score basé sur la popularité (simulation)
	score += 0.3

	return score
}

// isSameDependency vérifie si deux noms correspondent à la même dépendance
func (dc *DependencyConnector) isSameDependency(dep1, dep2 string) bool {
	// Logique simplifiée - peut être étendue
	base1 := strings.Split(dep1, "/")
	base2 := strings.Split(dep2, "/")

	if len(base1) > 0 && len(base2) > 0 {
		return base1[len(base1)-1] == base2[len(base2)-1]
	}

	return false
}

// processEvents traite les événements de synchronisation en arrière-plan
func (dc *DependencyConnector) processEvents() {
	for event := range dc.eventChannel {
		dc.handleEvent(event)
	}
}

// handleEvent traite un événement spécifique
func (dc *DependencyConnector) handleEvent(event DependencyEvent) {
	switch event.Type {
	case EventDependencyAdded:
		dc.logger.Info("Processing dependency added event", "name", event.DependencyName)
	case EventDependencyUpdated:
		dc.logger.Info("Processing dependency updated event", "name", event.DependencyName)
	case EventConflictDetected:
		dc.logger.Warn("Conflict detected", "dependency", event.DependencyName)
	case EventPlanAssociated:
		dc.logger.Info("Plan associated", "dependency", event.DependencyName, "plan", event.PlanID)
	}
}

// EnableSync active la synchronisation
func (dc *DependencyConnector) EnableSync() {
	dc.mu.Lock()
	defer dc.mu.Unlock()
	dc.syncEnabled = true
	dc.logger.Info("Dependency synchronization enabled")
}

// DisableSync désactive la synchronisation
func (dc *DependencyConnector) DisableSync() {
	dc.mu.Lock()
	defer dc.mu.Unlock()
	dc.syncEnabled = false
	dc.logger.Info("Dependency synchronization disabled")
}

// GetSyncStatus retourne le statut de synchronisation
func (dc *DependencyConnector) GetSyncStatus() bool {
	dc.mu.RLock()
	defer dc.mu.RUnlock()
	return dc.syncEnabled
}

// GetMetricsReport génère un rapport de métriques
func (dc *DependencyConnector) GetMetricsReport() MetricsReport {
	dc.mu.RLock()
	defer dc.mu.RUnlock()

	report := MetricsReport{
		TotalDependencies: len(dc.dependencyMetadata),
		TotalPlans:        len(dc.planDependencyMappings),
		SyncEnabled:       dc.syncEnabled,
		LastSync:          time.Now(),
	}

	// Calculer les métriques par plan
	report.PlanMetrics = make(map[string]PlanMetrics)
	for planID, dependencies := range dc.planDependencyMappings {
		report.PlanMetrics[planID] = PlanMetrics{
			DependencyCount: len(dependencies),
			LastUpdate:      time.Now(),
		}
	}

	return report
}

// Close ferme proprement le connecteur
func (dc *DependencyConnector) Close() error {
	dc.mu.Lock()
	defer dc.mu.Unlock()

	close(dc.eventChannel)
	dc.logger.Info("Dependency connector closed")
	return nil
}
