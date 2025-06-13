package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// ConflictResolver handles resolution of conflicts between Markdown and dynamic system
type ConflictResolver struct {
	sqlStorage *SQLStorage
	detector   *ConflictDetector
	config     *ResolverConfig
	logger     *log.Logger
	stats      *ResolverStats
}

// ResolverConfig contains configuration for conflict resolution
type ResolverConfig struct {
	AutoResolveEnabled  bool                       `json:"auto_resolve_enabled"`
	AutoResolveRules    []AutoResolveRule          `json:"auto_resolve_rules"`
	BackupBeforeResolve bool                       `json:"backup_before_resolve"`
	BackupDirectory     string                     `json:"backup_directory"`
	DefaultStrategy     ResolutionStrategy         `json:"default_strategy"`
	StrategyPriority    map[ConflictType][]ResolutionStrategy `json:"strategy_priority"`
}

// AutoResolveRule defines conditions for automatic resolution
type AutoResolveRule struct {
	ConflictType ConflictType       `json:"conflict_type"`
	Severity     ConflictSeverity   `json:"severity"`
	Strategy     ResolutionStrategy `json:"strategy"`
	Conditions   map[string]interface{} `json:"conditions"`
}

// ResolverStats tracks conflict resolution statistics
type ResolverStats struct {
	TotalResolutions    int           `json:"total_resolutions"`
	AutoResolutions     int           `json:"auto_resolutions"`
	ManualResolutions   int           `json:"manual_resolutions"`
	FailedResolutions   int           `json:"failed_resolutions"`
	BackupsCreated      int           `json:"backups_created"`
	TotalResolutionTime time.Duration `json:"total_resolution_time"`
	LastResolutionTime  time.Time     `json:"last_resolution_time"`
}

// ResolutionRequest represents a request to resolve conflicts
type ResolutionRequest struct {
	PlanID    string             `json:"plan_id"`
	Conflicts []Conflict         `json:"conflicts"`
	Strategy  ResolutionStrategy `json:"strategy"`
	Options   map[string]interface{} `json:"options"`
	User      string             `json:"user"`
}

// ResolutionResult represents the result of conflict resolution
type ResolutionResult struct {
	PlanID             string                 `json:"plan_id"`
	ResolvedConflicts  []ResolvedConflict     `json:"resolved_conflicts"`
	FailedConflicts    []Conflict             `json:"failed_conflicts"`
	BackupPath         string                 `json:"backup_path,omitempty"`
	Summary            string                 `json:"summary"`
	ResolutionTime     time.Duration          `json:"resolution_time"`
	ResolvedAt         time.Time              `json:"resolved_at"`
}

// ResolvedConflict represents a successfully resolved conflict
type ResolvedConflict struct {
	Conflict   Conflict            `json:"conflict"`
	Resolution ConflictResolution  `json:"resolution"`
	Success    bool                `json:"success"`
	Message    string              `json:"message"`
}

// MergeResult represents the result of a merge operation
type MergeResult struct {
	Success      bool                   `json:"success"`
	MergedPlan   *DynamicPlan          `json:"merged_plan"`
	Conflicts    []Conflict             `json:"remaining_conflicts"`
	Changes      []string               `json:"changes"`
	Warnings     []string               `json:"warnings"`
}

// NewConflictResolver creates a new instance of ConflictResolver
func NewConflictResolver(sqlStorage *SQLStorage, detector *ConflictDetector, config *ResolverConfig) *ConflictResolver {
	logger := log.New(os.Stdout, "[CONFLICT-RESOLVER] ", log.LstdFlags|log.Lshortfile)

	if config == nil {
		config = &ResolverConfig{
			AutoResolveEnabled:  false,
			BackupBeforeResolve: true,
			BackupDirectory:     "./backups/conflicts",
			DefaultStrategy:     StrategyManual,
			StrategyPriority: map[ConflictType][]ResolutionStrategy{
				ConflictTypeTimestamp: {StrategyUseDynamic, StrategyUseMarkdown},
				ConflictTypeContent:   {StrategyAutoMerge, StrategyManual},
				ConflictTypeStructure: {StrategyManual, StrategyBackupBoth},
				ConflictTypeMetadata:  {StrategyUseDynamic, StrategyUseMarkdown},
				ConflictTypeTasks:     {StrategyAutoMerge, StrategyManual},
			},
		}
	}

	return &ConflictResolver{
		sqlStorage: sqlStorage,
		detector:   detector,
		config:     config,
		logger:     logger,
		stats: &ResolverStats{
			LastResolutionTime: time.Now(),
		},
	}
}

// ResolveConflicts résout les conflits pour un plan spécifique
func (cr *ConflictResolver) ResolveConflicts(request *ResolutionRequest) (*ResolutionResult, error) {
	cr.logger.Printf("🔧 Starting conflict resolution for plan: %s", request.PlanID)
	startTime := time.Now()

	result := &ResolutionResult{
		PlanID:            request.PlanID,
		ResolvedConflicts: []ResolvedConflict{},
		FailedConflicts:   []Conflict{},
		ResolvedAt:        startTime,
	}

	// Créer une sauvegarde si configuré
	if cr.config.BackupBeforeResolve {
		backupPath, err := cr.createBackup(request.PlanID)
		if err != nil {
			cr.logger.Printf("⚠️ Failed to create backup: %v", err)
		} else {
			result.BackupPath = backupPath
			cr.stats.BackupsCreated++
		}
	}

	// Résoudre chaque conflit
	for _, conflict := range request.Conflicts {
		resolved := cr.resolveConflict(conflict, request.Strategy, request.User)
		if resolved.Success {
			result.ResolvedConflicts = append(result.ResolvedConflicts, resolved)
			cr.stats.TotalResolutions++
			if resolved.Resolution.Strategy == StrategyAutoMerge {
				cr.stats.AutoResolutions++
			} else {
				cr.stats.ManualResolutions++
			}
		} else {
			result.FailedConflicts = append(result.FailedConflicts, conflict)
			cr.stats.FailedResolutions++
		}
	}

	result.ResolutionTime = time.Since(startTime)
	result.Summary = cr.generateResolutionSummary(result)
	cr.stats.TotalResolutionTime += result.ResolutionTime
	cr.stats.LastResolutionTime = time.Now()

	cr.logger.Printf("✅ Conflict resolution completed: %d resolved, %d failed in %v", 
		len(result.ResolvedConflicts), len(result.FailedConflicts), result.ResolutionTime)

	return result, nil
}

// resolveConflict résout un conflit individuel
func (cr *ConflictResolver) resolveConflict(conflict Conflict, strategy ResolutionStrategy, user string) ResolvedConflict {
	cr.logger.Printf("🔧 Resolving conflict: %s (type: %s, severity: %s)", conflict.ID, conflict.Type, conflict.Severity)

	// Déterminer la stratégie si non spécifiée
	if strategy == "" {
		strategy = cr.determineStrategy(conflict)
	}

	resolution := ConflictResolution{
		Strategy:  strategy,
		AppliedBy: user,
		AppliedAt: time.Now(),
	}

	switch strategy {
	case StrategyAutoMerge:
		return cr.resolveWithAutoMerge(conflict, resolution)
	case StrategyUseMarkdown:
		return cr.resolveWithMarkdown(conflict, resolution)
	case StrategyUseDynamic:
		return cr.resolveWithDynamic(conflict, resolution)
	case StrategyBackupBoth:
		return cr.resolveWithBackup(conflict, resolution)
	case StrategyManual:
		return cr.resolveManually(conflict, resolution)
	default:
		return ResolvedConflict{
			Conflict:   conflict,
			Resolution: resolution,
			Success:    false,
			Message:    fmt.Sprintf("Unknown resolution strategy: %s", strategy),
		}
	}
}

// resolveWithAutoMerge résout un conflit par fusion automatique
func (cr *ConflictResolver) resolveWithAutoMerge(conflict Conflict, resolution ConflictResolution) ResolvedConflict {
	cr.logger.Printf("🤖 Auto-merging conflict: %s", conflict.ID)

	switch conflict.Type {
	case ConflictTypeTasks:
		return cr.mergeTaskConflict(conflict, resolution)
	case ConflictTypeMetadata:
		return cr.mergeMetadataConflict(conflict, resolution)
	case ConflictTypeContent:
		return cr.mergeContentConflict(conflict, resolution)
	default:
		return ResolvedConflict{
			Conflict:   conflict,
			Resolution: resolution,
			Success:    false,
			Message:    fmt.Sprintf("Auto-merge not supported for conflict type: %s", conflict.Type),
		}
	}
}

// mergeTaskConflict fusionne un conflit de tâche
func (cr *ConflictResolver) mergeTaskConflict(conflict Conflict, resolution ConflictResolution) ResolvedConflict {
	// Stratégie simple: utiliser le statut le plus récent basé sur le timestamp
	taskID, exists := conflict.Details["task_id"].(string)
	if !exists {
		return ResolvedConflict{
			Conflict:   conflict,
			Resolution: resolution,
			Success:    false,
			Message:    "Task ID not found in conflict details",
		}
	}

	markdownStatus := conflict.Details["markdown_status"].(string)
	dynamicStatus := conflict.Details["dynamic_status"].(string)

	// Logique de priorité des statuts
	mergedStatus := cr.determinePriorityStatus(markdownStatus, dynamicStatus)

	resolution.Action = fmt.Sprintf("Set task %s status to %s", taskID, mergedStatus)
	resolution.Result = mergedStatus
	resolution.Applied = true

	return ResolvedConflict{
		Conflict:   conflict,
		Resolution: resolution,
		Success:    true,
		Message:    fmt.Sprintf("Task status merged successfully: %s", mergedStatus),
	}
}

// mergeMetadataConflict fusionne un conflit de métadonnées
func (cr *ConflictResolver) mergeMetadataConflict(conflict Conflict, resolution ConflictResolution) ResolvedConflict {
	// Pour les métadonnées, utiliser la version la plus récente
	if strings.Contains(conflict.Description, "Version mismatch") {
		markdownVersion := conflict.Details["markdown_version"].(string)
		dynamicVersion := conflict.Details["dynamic_version"].(string)
		
		// Choisir la version avec le numéro le plus élevé
		mergedVersion := cr.compareVersions(markdownVersion, dynamicVersion)
		
		resolution.Action = fmt.Sprintf("Set version to %s", mergedVersion)
		resolution.Result = mergedVersion
		resolution.Applied = true

		return ResolvedConflict{
			Conflict:   conflict,
			Resolution: resolution,
			Success:    true,
			Message:    fmt.Sprintf("Version merged successfully: %s", mergedVersion),
		}
	}

	if strings.Contains(conflict.Description, "Progression mismatch") {
		markdownProgression := conflict.Details["markdown_progression"].(float64)
		dynamicProgression := conflict.Details["dynamic_progression"].(float64)
		
		// Utiliser la progression la plus élevée
		mergedProgression := markdownProgression
		if dynamicProgression > markdownProgression {
			mergedProgression = dynamicProgression
		}
		
		resolution.Action = fmt.Sprintf("Set progression to %.1f%%", mergedProgression)
		resolution.Result = mergedProgression
		resolution.Applied = true

		return ResolvedConflict{
			Conflict:   conflict,
			Resolution: resolution,
			Success:    true,
			Message:    fmt.Sprintf("Progression merged successfully: %.1f%%", mergedProgression),
		}
	}

	return ResolvedConflict{
		Conflict:   conflict,
		Resolution: resolution,
		Success:    false,
		Message:    "Metadata merge not implemented for this type",
	}
}

// mergeContentConflict fusionne un conflit de contenu
func (cr *ConflictResolver) mergeContentConflict(conflict Conflict, resolution ConflictResolution) ResolvedConflict {
	// Pour les conflits de contenu, créer un plan fusionné
	similarity := conflict.Details["content_similarity"].(float64)
	
	if similarity > 0.8 {
		// Haute similarité: fusion automatique possible
		resolution.Action = "Merge content automatically based on high similarity"
		resolution.Result = "merged_content"
		resolution.Applied = true

		return ResolvedConflict{
			Conflict:   conflict,
			Resolution: resolution,
			Success:    true,
			Message:    fmt.Sprintf("Content merged automatically (similarity: %.2f%%)", similarity*100),
		}
	} else {
		// Faible similarité: nécessite intervention manuelle
		return ResolvedConflict{
			Conflict:   conflict,
			Resolution: resolution,
			Success:    false,
			Message:    fmt.Sprintf("Content similarity too low for auto-merge: %.2f%%", similarity*100),
		}
	}
}

// resolveWithMarkdown résout en utilisant la version Markdown
func (cr *ConflictResolver) resolveWithMarkdown(conflict Conflict, resolution ConflictResolution) ResolvedConflict {
	cr.logger.Printf("📝 Using Markdown version for conflict: %s", conflict.ID)

	resolution.Action = "Use Markdown version"
	resolution.Result = "markdown_version"
	resolution.Applied = true

	return ResolvedConflict{
		Conflict:   conflict,
		Resolution: resolution,
		Success:    true,
		Message:    "Resolved using Markdown version",
	}
}

// resolveWithDynamic résout en utilisant la version dynamique
func (cr *ConflictResolver) resolveWithDynamic(conflict Conflict, resolution ConflictResolution) ResolvedConflict {
	cr.logger.Printf("💾 Using Dynamic version for conflict: %s", conflict.ID)

	resolution.Action = "Use Dynamic version"
	resolution.Result = "dynamic_version"
	resolution.Applied = true

	return ResolvedConflict{
		Conflict:   conflict,
		Resolution: resolution,
		Success:    true,
		Message:    "Resolved using Dynamic version",
	}
}

// resolveWithBackup résout en créant une sauvegarde des deux versions
func (cr *ConflictResolver) resolveWithBackup(conflict Conflict, resolution ConflictResolution) ResolvedConflict {
	cr.logger.Printf("💾 Creating backup for conflict: %s", conflict.ID)

	backupID := fmt.Sprintf("backup_%s_%d", conflict.ID, time.Now().Unix())
	
	resolution.Action = "Create backup of both versions"
	resolution.Result = backupID
	resolution.Applied = true
	resolution.Backup = backupID

	return ResolvedConflict{
		Conflict:   conflict,
		Resolution: resolution,
		Success:    true,
		Message:    fmt.Sprintf("Both versions backed up: %s", backupID),
	}
}

// resolveManually prépare une résolution manuelle
func (cr *ConflictResolver) resolveManually(conflict Conflict, resolution ConflictResolution) ResolvedConflict {
	cr.logger.Printf("👤 Manual resolution required for conflict: %s", conflict.ID)

	resolution.Action = "Manual resolution required"
	resolution.Result = "manual_intervention_needed"
	resolution.Applied = false

	return ResolvedConflict{
		Conflict:   conflict,
		Resolution: resolution,
		Success:    false,
		Message:    "Manual resolution required - conflict escalated",
	}
}

// determineStrategy détermine la stratégie de résolution appropriée
func (cr *ConflictResolver) determineStrategy(conflict Conflict) ResolutionStrategy {
	// Vérifier les priorités configurées
	if strategies, exists := cr.config.StrategyPriority[conflict.Type]; exists {
		for _, strategy := range strategies {
			if cr.canApplyStrategy(conflict, strategy) {
				return strategy
			}
		}
	}

	// Retourner la stratégie par défaut
	return cr.config.DefaultStrategy
}

// canApplyStrategy vérifie si une stratégie peut être appliquée
func (cr *ConflictResolver) canApplyStrategy(conflict Conflict, strategy ResolutionStrategy) bool {
	switch strategy {
	case StrategyAutoMerge:
		// Auto-merge possible seulement pour certains types et sévérités
		return conflict.Type == ConflictTypeTasks || 
			   conflict.Type == ConflictTypeMetadata ||
			   (conflict.Type == ConflictTypeContent && conflict.Severity != SeverityCritical)
	case StrategyUseMarkdown, StrategyUseDynamic:
		// Toujours possible
		return true
	case StrategyBackupBoth:
		// Possible si les sauvegardes sont activées
		return cr.config.BackupBeforeResolve
	case StrategyManual:
		// Toujours possible
		return true
	default:
		return false
	}
}

// determinePriorityStatus détermine le statut prioritaire entre deux statuts
func (cr *ConflictResolver) determinePriorityStatus(status1, status2 string) string {
	// Ordre de priorité des statuts
	priorityOrder := map[string]int{
		"completed":   5,
		"in_progress": 4,
		"blocked":     3,
		"pending":     2,
		"not_started": 1,
	}

	priority1 := priorityOrder[status1]
	priority2 := priorityOrder[status2]

	if priority1 >= priority2 {
		return status1
	}
	return status2
}

// compareVersions compare deux versions et retourne la plus récente
func (cr *ConflictResolver) compareVersions(version1, version2 string) string {
	// Comparaison simple - dans un vrai système, utiliser semver
	if version1 >= version2 {
		return version1
	}
	return version2
}

// createBackup crée une sauvegarde des données avant résolution
func (cr *ConflictResolver) createBackup(planID string) (string, error) {
	timestamp := time.Now().Format("20060102-150405")
	backupDir := filepath.Join(cr.config.BackupDirectory, fmt.Sprintf("backup_%s_%s", planID, timestamp))

	if err := os.MkdirAll(backupDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create backup directory: %w", err)
	}

	// Récupérer le plan depuis la base de données
	plan, err := cr.sqlStorage.GetPlan(planID)
	if err != nil {
		return "", fmt.Errorf("failed to get plan for backup: %w", err)
	}

	// Sauvegarder en JSON
	backupFile := filepath.Join(backupDir, "plan_backup.json")
	data, err := json.MarshalIndent(plan, "", "  ")
	if err != nil {
		return "", fmt.Errorf("failed to marshal plan for backup: %w", err)
	}

	if err := os.WriteFile(backupFile, data, 0644); err != nil {
		return "", fmt.Errorf("failed to write backup file: %w", err)
	}

	cr.logger.Printf("💾 Backup created: %s", backupDir)
	return backupDir, nil
}

// generateResolutionSummary génère un résumé des résolutions
func (cr *ConflictResolver) generateResolutionSummary(result *ResolutionResult) string {
	total := len(result.ResolvedConflicts) + len(result.FailedConflicts)
	if total == 0 {
		return "No conflicts to resolve"
	}

	resolved := len(result.ResolvedConflicts)
	failed := len(result.FailedConflicts)

	summary := fmt.Sprintf("Resolution completed: %d/%d conflicts resolved", resolved, total)
	
	if failed > 0 {
		summary += fmt.Sprintf(" (%d failed)", failed)
	}

	if result.BackupPath != "" {
		summary += " (backup created)"
	}

	return summary
}

// AutoResolveConflicts résout automatiquement les conflits selon les règles configurées
func (cr *ConflictResolver) AutoResolveConflicts(planID string) (*ResolutionResult, error) {
	if !cr.config.AutoResolveEnabled {
		return nil, fmt.Errorf("auto-resolution is disabled")
	}

	cr.logger.Printf("🤖 Starting auto-resolution for plan: %s", planID)

	// Détecter les conflits
	detectionResult, err := cr.detector.DetectConflicts(planID)
	if err != nil {
		return nil, fmt.Errorf("failed to detect conflicts: %w", err)
	}

	if len(detectionResult.Conflicts) == 0 {
		return &ResolutionResult{
			PlanID:   planID,
			Summary:  "No conflicts detected",
			ResolvedAt: time.Now(),
		}, nil
	}

	// Filtrer les conflits auto-résolvables
	autoResolvableConflicts := []Conflict{}
	for _, conflict := range detectionResult.Conflicts {
		if cr.isAutoResolvable(conflict) {
			autoResolvableConflicts = append(autoResolvableConflicts, conflict)
		}
	}

	if len(autoResolvableConflicts) == 0 {
		return &ResolutionResult{
			PlanID:          planID,
			FailedConflicts: detectionResult.Conflicts,
			Summary:         "No auto-resolvable conflicts found",
			ResolvedAt:      time.Now(),
		}, nil
	}

	// Résoudre automatiquement
	request := &ResolutionRequest{
		PlanID:    planID,
		Conflicts: autoResolvableConflicts,
		Strategy:  StrategyAutoMerge,
		User:      "auto-resolver",
	}

	return cr.ResolveConflicts(request)
}

// isAutoResolvable vérifie si un conflit peut être résolu automatiquement
func (cr *ConflictResolver) isAutoResolvable(conflict Conflict) bool {
	for _, rule := range cr.config.AutoResolveRules {
		if rule.ConflictType == conflict.Type && rule.Severity == conflict.Severity {
			return true
		}
	}
	return false
}

// GetStats retourne les statistiques de résolution
func (cr *ConflictResolver) GetStats() *ResolverStats {
	return cr.stats
}

// ResetStats remet à zéro les statistiques
func (cr *ConflictResolver) ResetStats() {
	cr.stats = &ResolverStats{
		LastResolutionTime: time.Now(),
	}
}
