package core

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"log"
	"os"
	"strings"
	"time"
)

// ConflictDetector handles detection of conflicts between Markdown and dynamic system
type ConflictDetector struct {
	sqlStorage *SQLStorage
	config     *ConflictConfig
	logger     *log.Logger
	stats      *ConflictStats
}

// ConflictConfig contains configuration for conflict detection
type ConflictConfig struct {
	TimestampTolerance time.Duration `json:"timestamp_tolerance"`
	ContentThreshold   float64       `json:"content_threshold"`
	EnableAutoResolve  bool          `json:"enable_auto_resolve"`
	BackupConflicts    bool          `json:"backup_conflicts"`
}

// ConflictStats tracks conflict detection statistics
type ConflictStats struct {
	ConflictsDetected  int           `json:"conflicts_detected"`
	ConflictsResolved  int           `json:"conflicts_resolved"`
	AutoResolutions    int           `json:"auto_resolutions"`
	ManualResolutions  int           `json:"manual_resolutions"`
	TotalDetectionTime time.Duration `json:"total_detection_time"`
	LastDetectionTime  time.Time     `json:"last_detection_time"`
}

// Conflict represents a conflict between Markdown and dynamic versions
type Conflict struct {
	ID           string                 `json:"id"`
	PlanID       string                 `json:"plan_id"`
	Type         ConflictType           `json:"type"`
	MarkdownHash string                 `json:"markdown_hash"`
	DynamicHash  string                 `json:"dynamic_hash"`
	Description  string                 `json:"description"`
	Severity     ConflictSeverity       `json:"severity"`
	Details      map[string]interface{} `json:"details"`
	DetectedAt   time.Time              `json:"detected_at"`
	Resolution   *ConflictResolution    `json:"resolution,omitempty"`
}

// ConflictType represents the type of conflict
type ConflictType string

const (
	ConflictTypeTimestamp ConflictType = "timestamp"
	ConflictTypeContent   ConflictType = "content"
	ConflictTypeStructure ConflictType = "structure"
	ConflictTypeMetadata  ConflictType = "metadata"
	ConflictTypeTasks     ConflictType = "tasks"
)

// ConflictSeverity represents the severity level of a conflict
type ConflictSeverity string

const (
	SeverityLow      ConflictSeverity = "low"
	SeverityMedium   ConflictSeverity = "medium"
	SeverityHigh     ConflictSeverity = "high"
	SeverityCritical ConflictSeverity = "critical"
)

// ConflictResolution represents the resolution of a conflict
type ConflictResolution struct {
	Strategy  ResolutionStrategy `json:"strategy"`
	Action    string             `json:"action"`
	Result    interface{}        `json:"result"`
	Applied   bool               `json:"applied"`
	AppliedAt time.Time          `json:"applied_at"`
	AppliedBy string             `json:"applied_by"`
	Backup    string             `json:"backup,omitempty"`
}

// ResolutionStrategy represents different resolution strategies
type ResolutionStrategy string

const (
	StrategyManual      ResolutionStrategy = "manual"
	StrategyAutoMerge   ResolutionStrategy = "auto_merge"
	StrategyUseMarkdown ResolutionStrategy = "use_markdown"
	StrategyUseDynamic  ResolutionStrategy = "use_dynamic"
	StrategyBackupBoth  ResolutionStrategy = "backup_both"
)

// ConflictDetectionResult represents the result of conflict detection
type ConflictDetectionResult struct {
	PlanID        string        `json:"plan_id"`
	Conflicts     []Conflict    `json:"conflicts"`
	Summary       string        `json:"summary"`
	DetectedAt    time.Time     `json:"detected_at"`
	DetectionTime time.Duration `json:"detection_time"`
}

// NewConflictDetector creates a new instance of ConflictDetector
func NewConflictDetector(sqlStorage *SQLStorage, config *ConflictConfig) *ConflictDetector {
	logger := log.New(os.Stdout, "[CONFLICT-DETECTOR] ", log.LstdFlags|log.Lshortfile)

	if config == nil {
		config = &ConflictConfig{
			TimestampTolerance: 5 * time.Minute,
			ContentThreshold:   0.95,
			EnableAutoResolve:  false,
			BackupConflicts:    true,
		}
	}

	return &ConflictDetector{
		sqlStorage: sqlStorage,
		config:     config,
		logger:     logger,
		stats: &ConflictStats{
			LastDetectionTime: time.Now(),
		},
	}
}

// DetectConflicts detects conflicts for a specific plan
func (cd *ConflictDetector) DetectConflicts(planID string) (*ConflictDetectionResult, error) {
	cd.logger.Printf("🔍 Starting conflict detection for plan: %s", planID)
	startTime := time.Now()

	result := &ConflictDetectionResult{
		PlanID:     planID,
		Conflicts:  []Conflict{},
		DetectedAt: startTime,
	}

	// Récupérer le plan depuis le système dynamique
	dynamicPlan, err := cd.sqlStorage.GetPlan(planID)
	if err != nil {
		cd.logger.Printf("❌ Failed to get dynamic plan: %v", err)
		return nil, fmt.Errorf("failed to get dynamic plan: %w", err)
	}

	// Charger le plan Markdown (simulé pour ce test)
	markdownPlan, err := cd.loadMarkdownPlan(planID)
	if err != nil {
		cd.logger.Printf("❌ Failed to load markdown plan: %v", err)
		return nil, fmt.Errorf("failed to load markdown plan: %w", err)
	}

	// Détecter les différents types de conflits
	conflicts := []Conflict{}

	// 1. Détecter conflits de timestamp
	timestampConflicts := cd.detectTimestampConflicts(planID, markdownPlan, dynamicPlan)
	conflicts = append(conflicts, timestampConflicts...)

	// 2. Détecter conflits de contenu
	contentConflicts := cd.detectContentConflicts(planID, markdownPlan, dynamicPlan)
	conflicts = append(conflicts, contentConflicts...)

	// 3. Détecter conflits de structure
	structureConflicts := cd.detectStructureConflicts(planID, markdownPlan, dynamicPlan)
	conflicts = append(conflicts, structureConflicts...)

	// 4. Détecter conflits de métadonnées
	metadataConflicts := cd.detectMetadataConflicts(planID, markdownPlan, dynamicPlan)
	conflicts = append(conflicts, metadataConflicts...)

	// 5. Détecter conflits de tâches
	taskConflicts := cd.detectTaskConflicts(planID, markdownPlan, dynamicPlan)
	conflicts = append(conflicts, taskConflicts...)

	result.Conflicts = conflicts
	result.DetectionTime = time.Since(startTime)
	result.Summary = cd.generateSummary(conflicts)

	// Mettre à jour les statistiques
	cd.stats.ConflictsDetected += len(conflicts)
	cd.stats.TotalDetectionTime += result.DetectionTime
	cd.stats.LastDetectionTime = time.Now()

	cd.logger.Printf("✅ Conflict detection completed: %d conflicts found in %v", len(conflicts), result.DetectionTime)
	return result, nil
}

// detectTimestampConflicts détecte les conflits basés sur les timestamps
func (cd *ConflictDetector) detectTimestampConflicts(planID string, markdownPlan, dynamicPlan *DynamicPlan) []Conflict {
	conflicts := []Conflict{}

	// Comparer les timestamps de mise à jour
	timeDiff := markdownPlan.UpdatedAt.Sub(dynamicPlan.UpdatedAt)
	if timeDiff.Abs() > cd.config.TimestampTolerance {
		severity := SeverityMedium
		if timeDiff.Abs() > 24*time.Hour {
			severity = SeverityHigh
		}

		conflict := Conflict{
			ID:          cd.generateConflictID(planID, ConflictTypeTimestamp),
			PlanID:      planID,
			Type:        ConflictTypeTimestamp,
			Description: fmt.Sprintf("Timestamp difference: %v", timeDiff),
			Severity:    severity,
			Details: map[string]interface{}{
				"markdown_updated_at": markdownPlan.UpdatedAt,
				"dynamic_updated_at":  dynamicPlan.UpdatedAt,
				"time_difference":     timeDiff.String(),
			},
			DetectedAt: time.Now(),
		}
		conflicts = append(conflicts, conflict)
	}

	return conflicts
}

// detectContentConflicts détecte les conflits de contenu
func (cd *ConflictDetector) detectContentConflicts(planID string, markdownPlan, dynamicPlan *DynamicPlan) []Conflict {
	conflicts := []Conflict{}

	markdownHash := cd.calculatePlanHash(markdownPlan)
	dynamicHash := cd.calculatePlanHash(dynamicPlan)

	if markdownHash != dynamicHash {
		// Calculer la similarité du contenu
		similarity := cd.calculateContentSimilarity(markdownPlan, dynamicPlan)
		severity := cd.determineSeverityFromSimilarity(similarity)

		conflict := Conflict{
			ID:           cd.generateConflictID(planID, ConflictTypeContent),
			PlanID:       planID,
			Type:         ConflictTypeContent,
			MarkdownHash: markdownHash,
			DynamicHash:  dynamicHash,
			Description:  fmt.Sprintf("Content differs (similarity: %.2f%%)", similarity*100),
			Severity:     severity,
			Details: map[string]interface{}{
				"content_similarity": similarity,
				"markdown_tasks":     len(markdownPlan.Tasks),
				"dynamic_tasks":      len(dynamicPlan.Tasks),
			},
			DetectedAt: time.Now(),
		}
		conflicts = append(conflicts, conflict)
	}

	return conflicts
}

// detectStructureConflicts détecte les conflits de structure
func (cd *ConflictDetector) detectStructureConflicts(planID string, markdownPlan, dynamicPlan *DynamicPlan) []Conflict {
	conflicts := []Conflict{}

	// Comparer le nombre de phases
	markdownPhases := cd.extractPhases(markdownPlan)
	dynamicPhases := cd.extractPhases(dynamicPlan)

	if len(markdownPhases) != len(dynamicPhases) {
		conflict := Conflict{
			ID:          cd.generateConflictID(planID, ConflictTypeStructure),
			PlanID:      planID,
			Type:        ConflictTypeStructure,
			Description: fmt.Sprintf("Phase count mismatch: markdown=%d, dynamic=%d", len(markdownPhases), len(dynamicPhases)),
			Severity:    SeverityHigh,
			Details: map[string]interface{}{
				"markdown_phases": markdownPhases,
				"dynamic_phases":  dynamicPhases,
			},
			DetectedAt: time.Now(),
		}
		conflicts = append(conflicts, conflict)
	}

	return conflicts
}

// detectMetadataConflicts détecte les conflits de métadonnées
func (cd *ConflictDetector) detectMetadataConflicts(planID string, markdownPlan, dynamicPlan *DynamicPlan) []Conflict {
	conflicts := []Conflict{}

	// Comparer versions
	if markdownPlan.Metadata.Version != dynamicPlan.Metadata.Version {
		conflict := Conflict{
			ID:          cd.generateConflictID(planID, ConflictTypeMetadata),
			PlanID:      planID,
			Type:        ConflictTypeMetadata,
			Description: fmt.Sprintf("Version mismatch: markdown=%s, dynamic=%s", markdownPlan.Metadata.Version, dynamicPlan.Metadata.Version),
			Severity:    SeverityMedium,
			Details: map[string]interface{}{
				"markdown_version": markdownPlan.Metadata.Version,
				"dynamic_version":  dynamicPlan.Metadata.Version,
			},
			DetectedAt: time.Now(),
		}
		conflicts = append(conflicts, conflict)
	}

	// Comparer progression
	progressDiff := markdownPlan.Metadata.Progression - dynamicPlan.Metadata.Progression
	if progressDiff > 5.0 || progressDiff < -5.0 { // Tolérance de 5%
		severity := SeverityMedium
		if progressDiff > 20.0 || progressDiff < -20.0 {
			severity = SeverityHigh
		}

		conflict := Conflict{
			ID:          cd.generateConflictID(planID, ConflictTypeMetadata),
			PlanID:      planID,
			Type:        ConflictTypeMetadata,
			Description: fmt.Sprintf("Progression mismatch: %.1f%% difference", progressDiff),
			Severity:    severity,
			Details: map[string]interface{}{
				"markdown_progression": markdownPlan.Metadata.Progression,
				"dynamic_progression":  dynamicPlan.Metadata.Progression,
				"difference":           progressDiff,
			},
			DetectedAt: time.Now(),
		}
		conflicts = append(conflicts, conflict)
	}

	return conflicts
}

// detectTaskConflicts détecte les conflits au niveau des tâches
func (cd *ConflictDetector) detectTaskConflicts(planID string, markdownPlan, dynamicPlan *DynamicPlan) []Conflict {
	conflicts := []Conflict{}

	// Créer des maps pour la comparaison rapide
	markdownTasks := make(map[string]Task)
	dynamicTasks := make(map[string]Task)

	for _, task := range markdownPlan.Tasks {
		markdownTasks[task.ID] = task
	}

	for _, task := range dynamicPlan.Tasks {
		dynamicTasks[task.ID] = task
	}

	// Détecter les tâches modifiées
	for taskID, markdownTask := range markdownTasks {
		if dynamicTask, exists := dynamicTasks[taskID]; exists {
			if markdownTask.Status != dynamicTask.Status {
				conflict := Conflict{
					ID:          cd.generateConflictID(planID, ConflictTypeTasks),
					PlanID:      planID,
					Type:        ConflictTypeTasks,
					Description: fmt.Sprintf("Task status conflict for '%s': markdown=%s, dynamic=%s", taskID, markdownTask.Status, dynamicTask.Status),
					Severity:    SeverityMedium,
					Details: map[string]interface{}{
						"task_id":         taskID,
						"task_title":      markdownTask.Title,
						"markdown_status": markdownTask.Status,
						"dynamic_status":  dynamicTask.Status,
					},
					DetectedAt: time.Now(),
				}
				conflicts = append(conflicts, conflict)
			}
		}
	}

	return conflicts
}

// calculatePlanHash calcule un hash du plan pour détecter les changements
func (cd *ConflictDetector) calculatePlanHash(plan *DynamicPlan) string {
	data := fmt.Sprintf("%s-%s-%f-%d", plan.Metadata.Title, plan.Metadata.Version, plan.Metadata.Progression, len(plan.Tasks))

	// Ajouter les hashes des tâches
	for _, task := range plan.Tasks {
		data += fmt.Sprintf("-%s-%s-%s", task.ID, task.Title, task.Status)
	}

	hasher := sha256.New()
	hasher.Write([]byte(data))
	return hex.EncodeToString(hasher.Sum(nil))[:16] // Utiliser les 16 premiers caractères
}

// calculateContentSimilarity calcule la similarité entre deux plans
func (cd *ConflictDetector) calculateContentSimilarity(plan1, plan2 *DynamicPlan) float64 {
	// Comparaison simple basée sur le nombre de tâches communes
	if len(plan1.Tasks) == 0 && len(plan2.Tasks) == 0 {
		return 1.0
	}

	if len(plan1.Tasks) == 0 || len(plan2.Tasks) == 0 {
		return 0.0
	}

	commonTasks := 0
	taskMap := make(map[string]bool)

	for _, task := range plan1.Tasks {
		taskMap[task.ID] = true
	}

	for _, task := range plan2.Tasks {
		if taskMap[task.ID] {
			commonTasks++
		}
	}

	maxTasks := len(plan1.Tasks)
	if len(plan2.Tasks) > maxTasks {
		maxTasks = len(plan2.Tasks)
	}

	return float64(commonTasks) / float64(maxTasks)
}

// determineSeverityFromSimilarity détermine la sévérité basée sur la similarité
func (cd *ConflictDetector) determineSeverityFromSimilarity(similarity float64) ConflictSeverity {
	if similarity >= 0.9 {
		return SeverityLow
	} else if similarity >= 0.7 {
		return SeverityMedium
	} else if similarity >= 0.5 {
		return SeverityHigh
	} else {
		return SeverityCritical
	}
}

// extractPhases extrait les phases d'un plan
func (cd *ConflictDetector) extractPhases(plan *DynamicPlan) []string {
	phaseMap := make(map[string]bool)
	phases := []string{}

	for _, task := range plan.Tasks {
		if task.Phase != "" && !phaseMap[task.Phase] {
			phases = append(phases, task.Phase)
			phaseMap[task.Phase] = true
		}
	}

	return phases
}

// generateConflictID génère un ID unique pour un conflit
func (cd *ConflictDetector) generateConflictID(planID string, conflictType ConflictType) string {
	timestamp := time.Now().Format("20060102-150405")
	return fmt.Sprintf("conflict-%s-%s-%s", planID, conflictType, timestamp)
}

// generateSummary génère un résumé des conflits détectés
func (cd *ConflictDetector) generateSummary(conflicts []Conflict) string {
	if len(conflicts) == 0 {
		return "No conflicts detected"
	}

	typeCount := make(map[ConflictType]int)
	severityCount := make(map[ConflictSeverity]int)

	for _, conflict := range conflicts {
		typeCount[conflict.Type]++
		severityCount[conflict.Severity]++
	}

	summary := fmt.Sprintf("Found %d conflicts: ", len(conflicts))

	var parts []string
	for conflictType, count := range typeCount {
		parts = append(parts, fmt.Sprintf("%s (%d)", conflictType, count))
	}

	summary += strings.Join(parts, ", ")
	return summary
}

// loadMarkdownPlan charge un plan Markdown (simulé pour ce test)
func (cd *ConflictDetector) loadMarkdownPlan(planID string) (*DynamicPlan, error) {
	// Pour ce test, nous créons un plan simulé légèrement différent
	basePlan, err := cd.sqlStorage.GetPlan(planID)
	if err != nil {
		return nil, err
	}

	// Créer une version modifiée pour simuler des différences
	markdownPlan := &DynamicPlan{
		ID:        basePlan.ID + "_markdown",
		Metadata:  basePlan.Metadata,
		Tasks:     make([]Task, len(basePlan.Tasks)),
		UpdatedAt: basePlan.UpdatedAt.Add(-10 * time.Minute), // Version plus ancienne
	}

	copy(markdownPlan.Tasks, basePlan.Tasks)

	// Modifier légèrement pour créer des conflits
	if len(markdownPlan.Tasks) > 0 {
		markdownPlan.Tasks[0].Status = "in_progress" // Différent du statut original
	}

	markdownPlan.Metadata.Version = "2.0"    // Version différente
	markdownPlan.Metadata.Progression = 75.0 // Progression différente

	return markdownPlan, nil
}

// GetStats retourne les statistiques de détection de conflits
func (cd *ConflictDetector) GetStats() *ConflictStats {
	return cd.stats
}

// ResetStats remet à zéro les statistiques
func (cd *ConflictDetector) ResetStats() {
	cd.stats = &ConflictStats{
		LastDetectionTime: time.Now(),
	}
}
