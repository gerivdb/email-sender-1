// SPDX-License-Identifier: MIT
// Package docmanager : synchronisateur multi-branches (v65B)
package docmanager

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/go-git/go-git/v5"
)

// BranchSynchronizer gère la synchronisation documentaire entre branches
// Ajout gestion repository Git et worktree
// 4.2.1.1.2
// 4.2.1.1.3 (début cache)
type BranchSynchronizer struct {
	SyncRules   map[string]BranchSyncRule
	Conflicts   *ConflictResolver
	BranchDiffs map[string]*BranchDiff

	repo     *git.Repository
	workTree *git.Worktree

	branchStatusCache map[string]*BranchDocStatus
	cacheMutex        sync.RWMutex
	cacheExpiry       time.Duration
}

// BranchSyncRule définit les règles de synchronisation
type BranchSyncRule struct {
	SourceBranch    string
	TargetBranches  []string
	AutoMerge       bool
	SyncInterval    time.Duration
	IncludePatterns []string
	ExcludePatterns []string
}

// BranchDiff représente les différences entre branches
type BranchDiff struct {
	FilesChanged []string
	Conflicts    []string
}

// ConflictResolver à implémenter selon besoins

// detectDocumentationConflicts analyse les modifications concurrentes sur les fichiers documentaires
// et retourne la liste des conflits détectés avec un score de gravité.
func (bs *BranchSynchronizer) detectDocumentationConflicts(branchDiffs map[string]*DiffResult) ([]DetectedConflict, error) {
	// On suppose que bs.Conflicts est un ConflictDetector
	conflictDetector, ok := interface{}(bs.Conflicts).(*ConflictDetector)
	if !ok || conflictDetector == nil {
		return nil, fmt.Errorf("ConflictDetector non initialisé dans BranchSynchronizer")
	}

	var allConflicts []DetectedConflict
	branches := []string{}
	for branch := range branchDiffs {
		branches = append(branches, branch)
	}
	// Comparer chaque paire de branches pour détecter les conflits documentaires
	for i := 0; i < len(branches); i++ {
		for j := i + 1; j < len(branches); j++ {
			b1, b2 := branches[i], branches[j]
			files1 := branchDiffs[b1].ModifiedFiles
			files2 := branchDiffs[b2].ModifiedFiles
			// Intersection des fichiers modifiés
			fileSet := map[string]struct{}{}
			for _, f := range files1 {
				fileSet[f] = struct{}{}
			}
			for _, f := range files2 {
				if _, exists := fileSet[f]; exists {
					// Conflit potentiel sur ce fichier documentaire
					conflicts, err := conflictDetector.DetectConflicts(b1, b2, []string{f})
					if err != nil {
						continue // log possible
					}
					allConflicts = append(allConflicts, conflicts...)
				}
			}
		}
	}
	// Scoring de gravité (ajouté dans DetectedConflict.Severity par le detector)
	return allConflicts, nil
}

// NewBranchSynchronizer crée un nouveau synchronisateur de branches
func NewBranchSynchronizer() *BranchSynchronizer {
	return &BranchSynchronizer{
		SyncRules:         make(map[string]BranchSyncRule),
		BranchDiffs:       make(map[string]*BranchDiff),
		branchStatusCache: make(map[string]*BranchDocStatus),
		cacheExpiry:       10 * time.Minute,
	}
}

// AddSyncRule ajoute une règle de synchronisation
// SRP: Responsabilité synchronisation pure - pas de persistence
func (bs *BranchSynchronizer) AddSyncRule(branchName string, rule BranchSyncRule) {
	bs.SyncRules[branchName] = rule
}

// SynchronizeBranches synchronise selon les règles définies
// SRP: Synchronisation multi-branches exclusive
func (bs *BranchSynchronizer) SynchronizeBranches() error {
	for branchName, rule := range bs.SyncRules {
		if err := bs.synchronizeBranch(branchName, rule); err != nil {
			return err
		}
	}
	return nil
}

// synchronizeBranch synchronise une branche spécifique
func (bs *BranchSynchronizer) synchronizeBranch(branchName string, rule BranchSyncRule) error {
	// SRP: Logique de synchronisation uniquement, pas de cache/DB
	diff := &BranchDiff{
		FilesChanged: []string{},
		Conflicts:    []string{},
	}

	bs.BranchDiffs[branchName] = diff
	return nil
}

// GetBranchDiff retourne les différences pour une branche
func (bs *BranchSynchronizer) GetBranchDiff(branchName string) (*BranchDiff, bool) {
	diff, exists := bs.BranchDiffs[branchName]
	return diff, exists
}

// ValidateSyncRules valide la cohérence des règles de synchronisation
func (bs *BranchSynchronizer) ValidateSyncRules() []string {
	var errors []string

	for branchName, rule := range bs.SyncRules {
		if rule.SourceBranch == "" {
			errors = append(errors, "SourceBranch manquante pour "+branchName)
		}
		if len(rule.TargetBranches) == 0 {
			errors = append(errors, "TargetBranches vides pour "+branchName)
		}
	}

	return errors
}

// TASK ATOMIQUE 3.1.4.1.1 - Implementation BranchAware Interface

<<<<<<< HEAD
// SyncAcrossBranches implémente l'interface BranchAware
func (bs *BranchSynchronizer) SyncAcrossBranches(ctx context.Context) error {
	// 4.2.1.2.1 déjà implémenté
=======
// SyncAcrossBranches énumère et filtre les branches actives selon la configuration
func (bs *BranchSynchronizer) SyncAcrossBranches(ctx context.Context) ([]string, error) {
	branchesIter, err := bs.repo.Branches()
	if err != nil {
		return nil, err
	}
	var branches []string
	for {
		ref, err := branchesIter.Next()
		if err != nil {
			break
		}
		branches = append(branches, ref.Name().Short())
	}
	currentBranchRef, err := bs.repo.Head()
	if err != nil {
		return nil, err
	}
	currentBranch := currentBranchRef.Name().Short()
	_ = currentBranch // utilisé pour usage ultérieur, évite l'erreur non utilisé

	// Filtrage selon configuration (exemple: inclure/exclure selon SyncRules)
	filteredBranches := []string{}
	for _, branch := range branches {
		if rule, ok := bs.SyncRules[branch]; ok && rule.SourceBranch != "" {
			filteredBranches = append(filteredBranches, branch)
		}
	}
	if len(filteredBranches) == 0 {
		filteredBranches = branches
	}

	// Retourne la liste filtrée et la branche courante (pour usage ultérieur)
	return filteredBranches, nil
>>>>>>> consolidation-v65B
}

// analyzeBranchDocDiff analyse les différences documentaires pour une branche
func (bs *BranchSynchronizer) analyzeBranchDocDiff(branch string) (*BranchDiff, error) {
	// Exemple simplifié : lister les fichiers modifiés .md, .txt, .adoc
	worktree, err := bs.repo.Worktree()
	if err != nil {
		return nil, err
	}
	status, err := worktree.Status()
	if err != nil {
		return nil, err
	}
	filesChanged := []string{}
	for file, s := range status {
		if (s.Worktree != ' ' || s.Staging != ' ') && (strings.HasSuffix(file, ".md") || strings.HasSuffix(file, ".txt") || strings.HasSuffix(file, ".adoc")) {
			filesChanged = append(filesChanged, file)
		}
	}
	// Score de divergence documentaire : nombre de fichiers modifiés
	score := len(filesChanged)
	_ = score // évite l'erreur variable inutilisée
	// On peut enrichir avec d’autres métriques si besoin
	return &BranchDiff{
		FilesChanged: filesChanged,
		Conflicts:    []string{}, // à remplir dans la tâche suivante
	}, nil
}

// GetBranchStatus implémente l'interface BranchAware
func (bs *BranchSynchronizer) GetBranchStatus(branch string) (BranchDocStatus, error) {
	// Gestion du cache status branches (4.2.1.1.3)
	bs.cacheMutex.RLock()
	cached, found := bs.branchStatusCache[branch]
	bs.cacheMutex.RUnlock()
	if found && time.Since(cached.LastSync) < bs.cacheExpiry {
		return *cached, nil
	}

	status := BranchDocStatus{
		Branch:        branch,
		LastSync:      time.Now(),
		ConflictCount: 0,
		Status:        "active",
	}

	// Vérifie les conflits pour cette branche
	if diff, exists := bs.GetBranchDiff(branch); exists {
		status.ConflictCount = len(diff.Conflicts)
		if status.ConflictCount > 0 {
			status.Status = "conflicts"
		}
	}

	// Mise à jour du cache
	bs.cacheMutex.Lock()
	bs.branchStatusCache[branch] = &status
	bs.cacheMutex.Unlock()

	return status, nil
}

// MergeDocumentation implémente l'interface BranchAware
func (bs *BranchSynchronizer) MergeDocumentation(fromBranch, toBranch string) error {
	// Implémentation du merge entre branches
	rule := BranchSyncRule{
		SourceBranch:   fromBranch,
		TargetBranches: []string{toBranch},
		AutoMerge:      false, // Merge manuel pour sécurité
		SyncInterval:   0,     // Merge immédiat
	}

	return bs.synchronizeBranch(fromBranch, rule)
}

// TASK ATOMIQUE 3.4.1.2 - Règles de synchronisation configurables

// SyncConfiguration configuration avancée pour la synchronisation
type SyncConfiguration struct {
	GlobalRules       GlobalSyncRules           `json:"global_rules" yaml:"global_rules"`
	BranchRules       map[string]BranchSyncRule `json:"branch_rules" yaml:"branch_rules"`
	ConflictPolicies  map[string]ConflictPolicy `json:"conflict_policies" yaml:"conflict_policies"`
	ScheduleRules     []ScheduledSyncRule       `json:"schedule_rules" yaml:"schedule_rules"`
	NotificationRules []NotificationRule        `json:"notification_rules" yaml:"notification_rules"`
}

// GlobalSyncRules règles globales de synchronisation
type GlobalSyncRules struct {
	MaxConcurrentSyncs   int           `json:"max_concurrent_syncs" yaml:"max_concurrent_syncs"`
	DefaultSyncInterval  time.Duration `json:"default_sync_interval" yaml:"default_sync_interval"`
	AutoResolveConflicts bool          `json:"auto_resolve_conflicts" yaml:"auto_resolve_conflicts"`
	BackupBeforeSync     bool          `json:"backup_before_sync" yaml:"backup_before_sync"`
	LogLevel             string        `json:"log_level" yaml:"log_level"`
	Timeout              time.Duration `json:"timeout" yaml:"timeout"`
}

// ConflictPolicy politique de résolution de conflits
type ConflictPolicy struct {
	Strategy         string   `json:"strategy" yaml:"strategy"` // "manual", "source_wins", "target_wins", "merge"
	Priority         int      `json:"priority" yaml:"priority"`
	FilePatterns     []string `json:"file_patterns" yaml:"file_patterns"`
	CustomResolver   string   `json:"custom_resolver" yaml:"custom_resolver"`
	NotifyOnConflict bool     `json:"notify_on_conflict" yaml:"notify_on_conflict"`
	MaxRetries       int      `json:"max_retries" yaml:"max_retries"`
}

// ScheduledSyncRule règle de synchronisation planifiée
type ScheduledSyncRule struct {
	Name         string        `json:"name" yaml:"name"`
	CronExpr     string        `json:"cron_expr" yaml:"cron_expr"`
	SourceBranch string        `json:"source_branch" yaml:"source_branch"`
	TargetBranch string        `json:"target_branch" yaml:"target_branch"`
	Enabled      bool          `json:"enabled" yaml:"enabled"`
	LastRun      time.Time     `json:"last_run" yaml:"last_run"`
	NextRun      time.Time     `json:"next_run" yaml:"next_run"`
	Timeout      time.Duration `json:"timeout" yaml:"timeout"`
}

// NotificationRule règle de notification
type NotificationRule struct {
	Event      string                 `json:"event" yaml:"event"` // "sync_start", "sync_complete", "conflict", "error"
	Recipients []string               `json:"recipients" yaml:"recipients"`
	Template   string                 `json:"template" yaml:"template"`
	Enabled    bool                   `json:"enabled" yaml:"enabled"`
	Conditions map[string]interface{} `json:"conditions" yaml:"conditions"`
}

// ConfigurableSyncRuleManager gestionnaire de règles configurables
type ConfigurableSyncRuleManager struct {
	config     *SyncConfiguration
	validators map[string]RuleValidator
	mu         sync.RWMutex
}

// RuleValidator validateur de règles
type RuleValidator interface {
	ValidateRule(rule interface{}) error
}

// NewConfigurableSyncRuleManager crée un nouveau gestionnaire de règles
func NewConfigurableSyncRuleManager() *ConfigurableSyncRuleManager {
	return &ConfigurableSyncRuleManager{
		config: &SyncConfiguration{
			GlobalRules: GlobalSyncRules{
				MaxConcurrentSyncs:   3,
				DefaultSyncInterval:  30 * time.Minute,
				AutoResolveConflicts: false,
				BackupBeforeSync:     true,
				LogLevel:             "INFO",
				Timeout:              10 * time.Minute,
			},
			BranchRules:       make(map[string]BranchSyncRule),
			ConflictPolicies:  make(map[string]ConflictPolicy),
			ScheduleRules:     []ScheduledSyncRule{},
			NotificationRules: []NotificationRule{},
		},
		validators: make(map[string]RuleValidator),
	}
}

// LoadConfiguration charge la configuration depuis un fichier
func (csrm *ConfigurableSyncRuleManager) LoadConfiguration(configPath string) error {
	csrm.mu.Lock()
	defer csrm.mu.Unlock()

	// Simuler le chargement depuis un fichier
	// Dans une vraie implémentation, utiliser yaml.Unmarshal ou json.Unmarshal
	return nil
}

// SaveConfiguration sauvegarde la configuration
func (csrm *ConfigurableSyncRuleManager) SaveConfiguration(configPath string) error {
	csrm.mu.RLock()
	defer csrm.mu.RUnlock()

	// Simuler la sauvegarde vers un fichier
	// Dans une vraie implémentation, utiliser yaml.Marshal ou json.Marshal
	return nil
}

// AddBranchRule ajoute une règle de branche
func (csrm *ConfigurableSyncRuleManager) AddBranchRule(branchName string, rule BranchSyncRule) error {
	csrm.mu.Lock()
	defer csrm.mu.Unlock()

	// Valider la règle
	if err := csrm.validateBranchRule(rule); err != nil {
		return fmt.Errorf("invalid branch rule: %w", err)
	}

	csrm.config.BranchRules[branchName] = rule
	return nil
}

// AddConflictPolicy ajoute une politique de conflit
func (csrm *ConfigurableSyncRuleManager) AddConflictPolicy(name string, policy ConflictPolicy) error {
	csrm.mu.Lock()
	defer csrm.mu.Unlock()

	// Valider la politique
	if err := csrm.validateConflictPolicy(policy); err != nil {
		return fmt.Errorf("invalid conflict policy: %w", err)
	}

	csrm.config.ConflictPolicies[name] = policy
	return nil
}

// AddScheduledRule ajoute une règle planifiée
func (csrm *ConfigurableSyncRuleManager) AddScheduledRule(rule ScheduledSyncRule) error {
	csrm.mu.Lock()
	defer csrm.mu.Unlock()

	// Valider la règle planifiée
	if err := csrm.validateScheduledRule(rule); err != nil {
		return fmt.Errorf("invalid scheduled rule: %w", err)
	}

	csrm.config.ScheduleRules = append(csrm.config.ScheduleRules, rule)
	return nil
}

// GetEffectiveRuleForBranch retourne la règle effective pour une branche
func (csrm *ConfigurableSyncRuleManager) GetEffectiveRuleForBranch(branchName string) BranchSyncRule {
	csrm.mu.RLock()
	defer csrm.mu.RUnlock()

	if rule, exists := csrm.config.BranchRules[branchName]; exists {
		return rule
	}

	// Retourner une règle par défaut
	return BranchSyncRule{
		SourceBranch:    branchName,
		TargetBranches:  []string{},
		AutoMerge:       false,
		SyncInterval:    csrm.config.GlobalRules.DefaultSyncInterval,
		IncludePatterns: []string{"*"},
		ExcludePatterns: []string{},
	}
}

// GetConflictPolicyForFile retourne la politique de conflit pour un fichier
func (csrm *ConfigurableSyncRuleManager) GetConflictPolicyForFile(fileName string) ConflictPolicy {
	csrm.mu.RLock()
	defer csrm.mu.RUnlock()

	// Chercher la politique avec la priorité la plus élevée qui correspond au fichier
	var bestPolicy ConflictPolicy
	bestPriority := -1

	for _, policy := range csrm.config.ConflictPolicies {
		if csrm.fileMatchesPatterns(fileName, policy.FilePatterns) && policy.Priority > bestPriority {
			bestPolicy = policy
			bestPriority = policy.Priority
		}
	}

	// Politique par défaut si aucune ne correspond
	if bestPriority == -1 {
		return ConflictPolicy{
			Strategy:         "manual",
			Priority:         0,
			FilePatterns:     []string{"*"},
			NotifyOnConflict: true,
			MaxRetries:       3,
		}
	}

	return bestPolicy
}

// validateBranchRule valide une règle de branche
func (csrm *ConfigurableSyncRuleManager) validateBranchRule(rule BranchSyncRule) error {
	if rule.SourceBranch == "" {
		return fmt.Errorf("source branch cannot be empty")
	}

	if len(rule.TargetBranches) == 0 {
		return fmt.Errorf("target branches cannot be empty")
	}

	if rule.SyncInterval < 0 {
		return fmt.Errorf("sync interval cannot be negative")
	}

	// Vérifier que la branche source n'est pas dans les branches cibles
	for _, target := range rule.TargetBranches {
		if target == rule.SourceBranch {
			return fmt.Errorf("source branch cannot be in target branches")
		}
	}

	return nil
}

// validateConflictPolicy valide une politique de conflit
func (csrm *ConfigurableSyncRuleManager) validateConflictPolicy(policy ConflictPolicy) error {
	validStrategies := []string{"manual", "source_wins", "target_wins", "merge"}
	isValid := false
	for _, strategy := range validStrategies {
		if policy.Strategy == strategy {
			isValid = true
			break
		}
	}

	if !isValid {
		return fmt.Errorf("invalid strategy '%s', must be one of: %v", policy.Strategy, validStrategies)
	}

	if policy.Priority < 0 {
		return fmt.Errorf("priority cannot be negative")
	}

	if len(policy.FilePatterns) == 0 {
		return fmt.Errorf("file patterns cannot be empty")
	}

	if policy.MaxRetries < 0 {
		return fmt.Errorf("max retries cannot be negative")
	}

	return nil
}

// validateScheduledRule valide une règle planifiée
func (csrm *ConfigurableSyncRuleManager) validateScheduledRule(rule ScheduledSyncRule) error {
	if rule.Name == "" {
		return fmt.Errorf("scheduled rule name cannot be empty")
	}

	if rule.CronExpr == "" {
		return fmt.Errorf("cron expression cannot be empty")
	}

	if rule.SourceBranch == "" {
		return fmt.Errorf("source branch cannot be empty")
	}

	if rule.TargetBranch == "" {
		return fmt.Errorf("target branch cannot be empty")
	}

	if rule.SourceBranch == rule.TargetBranch {
		return fmt.Errorf("source and target branches cannot be the same")
	}

	if rule.Timeout < 0 {
		return fmt.Errorf("timeout cannot be negative")
	}

	return nil
}

// fileMatchesPatterns vérifie si un fichier correspond aux patterns
func (csrm *ConfigurableSyncRuleManager) fileMatchesPatterns(fileName string, patterns []string) bool {
	for _, pattern := range patterns {
		// Implémentation simplifiée - dans une vraie version, utiliser filepath.Match
		if pattern == "*" || pattern == fileName {
			return true
		}
		// Vérification basique des extensions
		if strings.HasPrefix(pattern, "*.") && strings.HasSuffix(fileName, pattern[1:]) {
			return true
		}
	}
	return false
}

// --- Gestion du cache status branches ---
// SetBranchStatusCache met à jour le cache pour une branche
func (bs *BranchSynchronizer) SetBranchStatusCache(branch string, status *BranchDocStatus) {
	bs.cacheMutex.Lock()
	defer bs.cacheMutex.Unlock()
	bs.branchStatusCache[branch] = status
}

// GetBranchStatusCache récupère le status de cache pour une branche (avec gestion d'expiration)
func (bs *BranchSynchronizer) GetBranchStatusCache(branch string) (*BranchDocStatus, bool) {
	bs.cacheMutex.RLock()
	defer bs.cacheMutex.RUnlock()
	status, exists := bs.branchStatusCache[branch]
	if !exists {
		return nil, false
	}
	if time.Since(status.LastSync) > bs.cacheExpiry {
		return nil, false // Expiré
	}
	return status, true
}

// CleanExpiredBranchStatusCache supprime les entrées expirées du cache
func (bs *BranchSynchronizer) CleanExpiredBranchStatusCache() {
	bs.cacheMutex.Lock()
	defer bs.cacheMutex.Unlock()
	for branch, status := range bs.branchStatusCache {
		if time.Since(status.LastSync) > bs.cacheExpiry {
			delete(bs.branchStatusCache, branch)
		}
	}
}

// TASK ATOMIQUE 3.4.1.3 - Détection automatique des conflits

// ConflictDetector détecteur automatique de conflits
type ConflictDetector struct {
	Rules    []ConflictDetectionRule    `json:"rules" yaml:"rules"`
	Scanners map[string]ConflictScanner `json:"-" yaml:"-"`
	History  []DetectedConflict         `json:"history" yaml:"history"`
	mu       sync.RWMutex               `json:"-" yaml:"-"`
}

// ConflictDetectionRule règle de détection de conflit
type ConflictDetectionRule struct {
	Name           string        `json:"name" yaml:"name"`
	FilePatterns   []string      `json:"file_patterns" yaml:"file_patterns"`
	ConflictTypes  []string      `json:"conflict_types" yaml:"conflict_types"`
	Severity       string        `json:"severity" yaml:"severity"` // "low", "medium", "high", "critical"
	AutoDetect     bool          `json:"auto_detect" yaml:"auto_detect"`
	Enabled        bool          `json:"enabled" yaml:"enabled"`
	ScanInterval   time.Duration `json:"scan_interval" yaml:"scan_interval"`
	NotifyOnDetect bool          `json:"notify_on_detect" yaml:"notify_on_detect"`
}

// DetectedConflict conflit détecté
type DetectedConflict struct {
	ID              string           `json:"id" yaml:"id"`
	Type            string           `json:"type" yaml:"type"`
	Severity        string           `json:"severity" yaml:"severity"`
	SourceBranch    string           `json:"source_branch" yaml:"source_branch"`
	TargetBranch    string           `json:"target_branch" yaml:"target_branch"`
	FilePath        string           `json:"file_path" yaml:"file_path"`
	LineNumber      int              `json:"line_number" yaml:"line_number"`
	Description     string           `json:"description" yaml:"description"`
	DetectedAt      time.Time        `json:"detected_at" yaml:"detected_at"`
	Status          string           `json:"status" yaml:"status"` // "new", "analyzing", "resolved", "ignored"
	Resolution      string           `json:"resolution" yaml:"resolution"`
	SourceContent   string           `json:"source_content" yaml:"source_content"`
	TargetContent   string           `json:"target_content" yaml:"target_content"`
	ConflictMarkers []ConflictMarker `json:"conflict_markers" yaml:"conflict_markers"`
}

// ConflictMarker marqueur de conflit dans le code
type ConflictMarker struct {
	StartLine  int    `json:"start_line" yaml:"start_line"`
	EndLine    int    `json:"end_line" yaml:"end_line"`
	MarkerType string `json:"marker_type" yaml:"marker_type"` // "<<<<<<< HEAD", "=======", ">>>>>>> branch"
	Content    string `json:"content" yaml:"content"`
}

// ConflictScanner interface pour les scanners de conflit
type ConflictScanner interface {
	ScanForConflicts(sourceBranch, targetBranch, filePath string) ([]DetectedConflict, error)
	GetScannerType() string
	IsApplicable(filePath string) bool
}

// GitConflictScanner scanner pour les conflits Git classiques
type GitConflictScanner struct {
	name string
}

// NewConflictDetector crée un nouveau détecteur de conflits
func NewConflictDetector() *ConflictDetector {
	detector := &ConflictDetector{
		Rules:    []ConflictDetectionRule{},
		Scanners: make(map[string]ConflictScanner),
		History:  []DetectedConflict{},
	}

	// Ajouter les scanners par défaut
	detector.RegisterScanner("git", &GitConflictScanner{name: "git"})

	return detector
}

// RegisterScanner enregistre un scanner de conflit
func (cd *ConflictDetector) RegisterScanner(scannerType string, scanner ConflictScanner) {
	cd.mu.Lock()
	defer cd.mu.Unlock()
	cd.Scanners[scannerType] = scanner
}

// AddDetectionRule ajoute une règle de détection
func (cd *ConflictDetector) AddDetectionRule(rule ConflictDetectionRule) error {
	cd.mu.Lock()
	defer cd.mu.Unlock()

	if err := cd.validateDetectionRule(rule); err != nil {
		return fmt.Errorf("invalid detection rule: %w", err)
	}

	cd.Rules = append(cd.Rules, rule)
	return nil
}

// DetectConflicts détecte automatiquement les conflits entre branches
func (cd *ConflictDetector) DetectConflicts(sourceBranch, targetBranch string, filePaths []string) ([]DetectedConflict, error) {
	cd.mu.Lock()
	defer cd.mu.Unlock()

	var allConflicts []DetectedConflict

	for _, filePath := range filePaths {
		// Trouver les règles applicables à ce fichier
		applicableRules := cd.getApplicableRules(filePath)

		for _, rule := range applicableRules {
			if !rule.Enabled || !rule.AutoDetect {
				continue
			}

			// Utiliser les scanners appropriés pour chaque type de conflit
			for _, conflictType := range rule.ConflictTypes {
				if scanner, exists := cd.Scanners[conflictType]; exists && scanner.IsApplicable(filePath) {
					conflicts, err := scanner.ScanForConflicts(sourceBranch, targetBranch, filePath)
					if err != nil {
						continue // Log l'erreur mais continue avec les autres scanners
					} // Enrichir les conflits avec les informations de la règle
					for i := range conflicts {
						conflicts[i].Severity = rule.Severity
						conflicts[i].ID = fmt.Sprintf("conflict_%d_%d", time.Now().UnixNano(), i)
						conflicts[i].DetectedAt = time.Now()
						conflicts[i].Status = "new"

						if rule.NotifyOnDetect {
							// Déclencher une notification (à implémenter)
						}
					}

					allConflicts = append(allConflicts, conflicts...)
				}
			}
		}
	}

	// Ajouter à l'historique
	cd.History = append(cd.History, allConflicts...)

	return allConflicts, nil
}

// ScanForConflicts implémentation pour GitConflictScanner
func (gcs *GitConflictScanner) ScanForConflicts(sourceBranch, targetBranch, filePath string) ([]DetectedConflict, error) {
	conflicts := []DetectedConflict{}

	// Simulation de la détection de conflits Git
	// Dans une vraie implémentation, ceci ferait appel à git diff et analyserait les marqueurs de conflit

	// Exemple de conflit détecté
	if strings.Contains(filePath, ".go") || strings.Contains(filePath, ".md") {
		conflict := DetectedConflict{
			Type:          "merge_conflict",
			SourceBranch:  sourceBranch,
			TargetBranch:  targetBranch,
			FilePath:      filePath,
			LineNumber:    42,
			Description:   fmt.Sprintf("Merge conflict detected between %s and %s in %s", sourceBranch, targetBranch, filePath),
			SourceContent: "// Source version of the code",
			TargetContent: "// Target version of the code",
			ConflictMarkers: []ConflictMarker{
				{
					StartLine:  40,
					EndLine:    42,
					MarkerType: "<<<<<<< HEAD",
					Content:    "// Source version of the code",
				},
				{
					StartLine:  43,
					EndLine:    43,
					MarkerType: "=======",
					Content:    "",
				},
				{
					StartLine:  44,
					EndLine:    46,
					MarkerType: fmt.Sprintf(">>>>>>> %s", targetBranch),
					Content:    "// Target version of the code",
				},
			},
		}
		conflicts = append(conflicts, conflict)
	}

	return conflicts, nil
}

// GetScannerType retourne le type du scanner
func (gcs *GitConflictScanner) GetScannerType() string {
	return gcs.name
}

// IsApplicable vérifie si le scanner est applicable à un fichier
func (gcs *GitConflictScanner) IsApplicable(filePath string) bool {
	// Le scanner Git est applicable à tous les fichiers
	return true
}

// getApplicableRules retourne les règles applicables à un fichier
func (cd *ConflictDetector) getApplicableRules(filePath string) []ConflictDetectionRule {
	var applicableRules []ConflictDetectionRule

	for _, rule := range cd.Rules {
		if cd.fileMatchesRulePatterns(filePath, rule.FilePatterns) {
			applicableRules = append(applicableRules, rule)
		}
	}

	return applicableRules
}

// fileMatchesRulePatterns vérifie si un fichier correspond aux patterns d'une règle
func (cd *ConflictDetector) fileMatchesRulePatterns(filePath string, patterns []string) bool {
	if len(patterns) == 0 {
		return true // Si aucun pattern, applicable à tous
	}

	for _, pattern := range patterns {
		if pattern == "*" || pattern == filePath {
			return true
		}
		// Vérification basique des extensions
		if strings.HasPrefix(pattern, "*.") && strings.HasSuffix(filePath, pattern[1:]) {
			return true
		}
		// Vérification des chemins avec wildcards
		if strings.Contains(pattern, "*") && strings.Contains(filePath, strings.Replace(pattern, "*", "", -1)) {
			return true
		}
	}
	return false
}

// validateDetectionRule valide une règle de détection
func (cd *ConflictDetector) validateDetectionRule(rule ConflictDetectionRule) error {
	if rule.Name == "" {
		return fmt.Errorf("rule name cannot be empty")
	}

	validSeverities := []string{"low", "medium", "high", "critical"}
	isValidSeverity := false
	for _, severity := range validSeverities {
		if rule.Severity == severity {
			isValidSeverity = true
			break
		}
	}

	if !isValidSeverity {
		return fmt.Errorf("invalid severity '%s', must be one of: %v", rule.Severity, validSeverities)
	}

	if len(rule.ConflictTypes) == 0 {
		return fmt.Errorf("conflict types cannot be empty")
	}

	if rule.ScanInterval < 0 {
		return fmt.Errorf("scan interval cannot be negative")
	}

	return nil
}

// TASK ATOMIQUE 3.4.1.4 - Stratégies de merge intelligentes

// IntelligentMergeStrategy stratégie de merge intelligente
type IntelligentMergeStrategy struct {
	Name              string                  `json:"name" yaml:"name"`
	Type              string                  `json:"type" yaml:"type"` // "auto", "semi_auto", "manual", "ml_based"
	Priority          int                     `json:"priority" yaml:"priority"`
	ConflictResolvers []MergeConflictResolver `json:"conflict_resolvers" yaml:"conflict_resolvers"`
	FileTypeHandlers  map[string]FileHandler  `json:"file_type_handlers" yaml:"file_type_handlers"`
	DecisionEngine    DecisionEngine          `json:"decision_engine" yaml:"decision_engine"`
	FallbackStrategy  string                  `json:"fallback_strategy" yaml:"fallback_strategy"`
	SuccessRate       float64                 `json:"success_rate" yaml:"success_rate"`
	Enabled           bool                    `json:"enabled" yaml:"enabled"`
}

// MergeConflictResolver résolveur de conflit pour le merge
type MergeConflictResolver struct {
	Name             string           `json:"name" yaml:"name"`
	Type             string           `json:"type" yaml:"type"` // "line_based", "block_based", "semantic", "ai_assisted"
	FilePatterns     []string         `json:"file_patterns" yaml:"file_patterns"`
	ConflictPatterns []string         `json:"conflict_patterns" yaml:"conflict_patterns"`
	Resolution       ResolutionMethod `json:"resolution" yaml:"resolution"`
	Confidence       float64          `json:"confidence" yaml:"confidence"`
	AutoApply        bool             `json:"auto_apply" yaml:"auto_apply"`
}

// ResolutionMethod méthode de résolution
type ResolutionMethod struct {
	Strategy       string                 `json:"strategy" yaml:"strategy"` // "keep_source", "keep_target", "merge_both", "custom"
	CustomLogic    string                 `json:"custom_logic" yaml:"custom_logic"`
	Parameters     map[string]interface{} `json:"parameters" yaml:"parameters"`
	RequiresReview bool                   `json:"requires_review" yaml:"requires_review"`
}

// FileHandler gestionnaire spécialisé par type de fichier
type FileHandler interface {
	CanHandle(filePath string) bool
	MergeFiles(sourceContent, targetContent, baseContent string) (MergeResult, error)
	GetFileType() string
}

// DecisionEngine moteur de décision pour le merge
type DecisionEngine struct {
	Type                string         `json:"type" yaml:"type"` // "rule_based", "ml_based", "hybrid"
	Rules               []DecisionRule `json:"rules" yaml:"rules"`
	MLModel             string         `json:"ml_model" yaml:"ml_model"`
	ConfidenceThreshold float64        `json:"confidence_threshold" yaml:"confidence_threshold"`
	LearningEnabled     bool           `json:"learning_enabled" yaml:"learning_enabled"`
}

// DecisionRule règle de décision
type DecisionRule struct {
	Condition string  `json:"condition" yaml:"condition"`
	Action    string  `json:"action" yaml:"action"`
	Weight    float64 `json:"weight" yaml:"weight"`
	Priority  int     `json:"priority" yaml:"priority"`
}

// MergeResult résultat d'un merge
type MergeResult struct {
	Success            bool                   `json:"success" yaml:"success"`
	MergedContent      string                 `json:"merged_content" yaml:"merged_content"`
	ConflictsResolved  int                    `json:"conflicts_resolved" yaml:"conflicts_resolved"`
	ConflictsRemaining int                    `json:"conflicts_remaining" yaml:"conflicts_remaining"`
	Strategy           string                 `json:"strategy" yaml:"strategy"`
	Confidence         float64                `json:"confidence" yaml:"confidence"`
	Warnings           []string               `json:"warnings" yaml:"warnings"`
	Metadata           map[string]interface{} `json:"metadata" yaml:"metadata"`
}

// SmartMergeManager gestionnaire de merge intelligent
type SmartMergeManager struct {
	strategies       []IntelligentMergeStrategy `json:"strategies" yaml:"strategies"`
	fileHandlers     map[string]FileHandler     `json:"-" yaml:"-"`
	conflictDetector *ConflictDetector          `json:"-" yaml:"-"`
	decisionEngine   *DecisionEngine            `json:"-" yaml:"-"`
	mergeHistory     []MergeOperation           `json:"merge_history" yaml:"merge_history"`
	mu               sync.RWMutex               `json:"-" yaml:"-"`
}

// MergeOperation opération de merge
type MergeOperation struct {
	ID            string        `json:"id" yaml:"id"`
	SourceBranch  string        `json:"source_branch" yaml:"source_branch"`
	TargetBranch  string        `json:"target_branch" yaml:"target_branch"`
	FilePath      string        `json:"file_path" yaml:"file_path"`
	Strategy      string        `json:"strategy" yaml:"strategy"`
	Result        MergeResult   `json:"result" yaml:"result"`
	Timestamp     time.Time     `json:"timestamp" yaml:"timestamp"`
	Duration      time.Duration `json:"duration" yaml:"duration"`
	UserValidated bool          `json:"user_validated" yaml:"user_validated"`
}

// GoFileHandler gestionnaire spécialisé pour les fichiers Go
type GoFileHandler struct{}

// CanHandle vérifie si ce gestionnaire peut traiter le fichier
func (gh *GoFileHandler) CanHandle(filePath string) bool {
	return strings.HasSuffix(strings.ToLower(filePath), ".go")
}

// MergeFiles fusionne les fichiers Go avec une logique spécialisée
func (gh *GoFileHandler) MergeFiles(sourceContent, targetContent, baseContent string) (MergeResult, error) {
	// Logique de merge spécialisée pour Go (imports, fonctions, etc.)
	result := MergeResult{
		Content:         sourceContent, // Implémentation basique pour le moment
		HasConflicts:    false,
		ConflictMarkers: []ConflictMarker{},
		Success:         true,
	}
	return result, nil
}

// GetFileType retourne le type de fichier
func (gh *GoFileHandler) GetFileType() string {
	return "go"
}

// MarkdownFileHandler gestionnaire spécialisé pour les fichiers Markdown
type MarkdownFileHandler struct{}

// CanHandle vérifie si ce gestionnaire peut traiter le fichier
func (mh *MarkdownFileHandler) CanHandle(filePath string) bool {
	ext := strings.ToLower(filePath)
	return strings.HasSuffix(ext, ".md") || strings.HasSuffix(ext, ".markdown")
}

// MergeFiles fusionne les fichiers Markdown avec une logique spécialisée
func (mh *MarkdownFileHandler) MergeFiles(sourceContent, targetContent, baseContent string) (MergeResult, error) {
	// Logique de merge spécialisée pour Markdown (sections, listes, etc.)
	result := MergeResult{
		Content:         sourceContent, // Implémentation basique pour le moment
		HasConflicts:    false,
		ConflictMarkers: []ConflictMarker{},
		Success:         true,
	}
	return result, nil
}

// GetFileType retourne le type de fichier
func (mh *MarkdownFileHandler) GetFileType() string {
	return "markdown"
}

// TASK ATOMIQUE 3.4.2.1 - Synchronisation cross-branch automatique

// CrossBranchSynchronizer synchronisateur automatique cross-branch
type CrossBranchSynchronizer struct {
	syncManager      *SmartMergeManager           `json:"-" yaml:"-"`
	conflictDetector *ConflictDetector            `json:"-" yaml:"-"`
	ruleManager      *ConfigurableSyncRuleManager `json:"-" yaml:"-"`
	scheduler        *SyncScheduler               `json:"-" yaml:"-"`
	ActiveJobs       map[string]*SyncJob          `json:"active_jobs" yaml:"active_jobs"`
	CompletedJobs    []SyncJob                    `json:"completed_jobs" yaml:"completed_jobs"`
	Config           CrossBranchConfig            `json:"config" yaml:"config"`
	mu               sync.RWMutex                 `json:"-" yaml:"-"`
}

// CrossBranchConfig configuration pour la synchronisation cross-branch
type CrossBranchConfig struct {
	EnableAutoSync      bool          `json:"enable_auto_sync" yaml:"enable_auto_sync"`
	SyncInterval        time.Duration `json:"sync_interval" yaml:"sync_interval"`
	MaxConcurrentSyncs  int           `json:"max_concurrent_syncs" yaml:"max_concurrent_syncs"`
	RetryAttempts       int           `json:"retry_attempts" yaml:"retry_attempts"`
	RetryDelay          time.Duration `json:"retry_delay" yaml:"retry_delay"`
	ConflictThreshold   int           `json:"conflict_threshold" yaml:"conflict_threshold"`
	NotifyOnFailure     bool          `json:"notify_on_failure" yaml:"notify_on_failure"`
	HealthCheckInterval time.Duration `json:"health_check_interval" yaml:"health_check_interval"`
}

// SyncJob tâche de synchronisation
type SyncJob struct {
	ID                string                 `json:"id" yaml:"id"`
	SourceBranch      string                 `json:"source_branch" yaml:"source_branch"`
	TargetBranch      string                 `json:"target_branch" yaml:"target_branch"`
	Status            string                 `json:"status" yaml:"status"` // "pending", "running", "completed", "failed", "cancelled"
	StartTime         time.Time              `json:"start_time" yaml:"start_time"`
	EndTime           time.Time              `json:"end_time" yaml:"end_time"`
	FilesProcessed    int                    `json:"files_processed" yaml:"files_processed"`
	ConflictsFound    int                    `json:"conflicts_found" yaml:"conflicts_found"`
	ConflictsResolved int                    `json:"conflicts_resolved" yaml:"conflicts_resolved"`
	Errors            []string               `json:"errors" yaml:"errors"`
	Progress          float64                `json:"progress" yaml:"progress"`
	RetryCount        int                    `json:"retry_count" yaml:"retry_count"`
	Metadata          map[string]interface{} `json:"metadata" yaml:"metadata"`
}

// SyncScheduler planificateur de synchronisation
type SyncScheduler struct {
	jobs        chan *SyncJob `json:"-" yaml:"-"`
	workers     []*SyncWorker `json:"-" yaml:"-"`
	WorkerCount int           `json:"worker_count" yaml:"worker_count"`
	Running     bool          `json:"running" yaml:"running"`
	mu          sync.RWMutex  `json:"-" yaml:"-"`
}

// SyncWorker worker pour exécuter les synchronisations
type SyncWorker struct {
	ID          int                `json:"id" yaml:"id"`
	syncManager *SmartMergeManager `json:"-" yaml:"-"`
	detector    *ConflictDetector  `json:"-" yaml:"-"`
	jobs        <-chan *SyncJob    `json:"-" yaml:"-"`
	quit        chan bool          `json:"-" yaml:"-"`
	CurrentJob  *SyncJob           `json:"current_job" yaml:"current_job"`
}

// NewCrossBranchSynchronizer crée un nouveau synchronisateur cross-branch
func NewCrossBranchSynchronizer(syncManager *SmartMergeManager, conflictDetector *ConflictDetector, ruleManager *ConfigurableSyncRuleManager) *CrossBranchSynchronizer {
	config := CrossBranchConfig{
		EnableAutoSync:      true,
		SyncInterval:        30 * time.Minute,
		MaxConcurrentSyncs:  3,
		RetryAttempts:       3,
		RetryDelay:          5 * time.Minute,
		ConflictThreshold:   10,
		NotifyOnFailure:     true,
		HealthCheckInterval: 10 * time.Minute,
	}

	scheduler := NewSyncScheduler(config.MaxConcurrentSyncs, syncManager, conflictDetector)
	return &CrossBranchSynchronizer{
		syncManager:      syncManager,
		conflictDetector: conflictDetector,
		ruleManager:      ruleManager,
		scheduler:        scheduler,
		ActiveJobs:       make(map[string]*SyncJob),
		CompletedJobs:    []SyncJob{},
		Config:           config,
	}
}

// NewSyncScheduler crée un nouveau planificateur de synchronisation
func NewSyncScheduler(workerCount int, syncManager *SmartMergeManager, detector *ConflictDetector) *SyncScheduler {
	scheduler := &SyncScheduler{
		jobs:        make(chan *SyncJob, 100),
		workers:     make([]*SyncWorker, workerCount),
		WorkerCount: workerCount,
		Running:     false,
	}

	// Créer les workers
	for i := 0; i < workerCount; i++ {
		scheduler.workers[i] = &SyncWorker{
			ID:          i,
			syncManager: syncManager,
			detector:    detector,
			jobs:        scheduler.jobs,
			quit:        make(chan bool),
		}
	}

	return scheduler
}

// Start démarre la synchronisation automatique
func (cbs *CrossBranchSynchronizer) Start() error {
	cbs.mu.Lock()
	defer cbs.mu.Unlock()

	if !cbs.Config.EnableAutoSync {
		return fmt.Errorf("auto sync is disabled")
	}

	// Démarrer le scheduler
	err := cbs.scheduler.Start()
	if err != nil {
		return fmt.Errorf("failed to start scheduler: %w", err)
	}

	// Démarrer la surveillance périodique
	go cbs.runPeriodicSync()
	go cbs.runHealthCheck()

	return nil
}

// Stop arrête la synchronisation automatique
func (cbs *CrossBranchSynchronizer) Stop() error {
	cbs.mu.Lock()
	defer cbs.mu.Unlock()

	return cbs.scheduler.Stop()
}

// ScheduleSync planifie une synchronisation
func (cbs *CrossBranchSynchronizer) ScheduleSync(sourceBranch, targetBranch string) (string, error) {
	cbs.mu.Lock()
	defer cbs.mu.Unlock()

	job := &SyncJob{
		ID:           fmt.Sprintf("sync_%d", time.Now().UnixNano()),
		SourceBranch: sourceBranch,
		TargetBranch: targetBranch,
		Status:       "pending",
		StartTime:    time.Now(),
		Errors:       []string{},
		Progress:     0.0,
		RetryCount:   0,
		Metadata:     make(map[string]interface{}),
	}

	// Ajouter à la liste des jobs actifs
	cbs.ActiveJobs[job.ID] = job

	// Envoyer au scheduler
	cbs.scheduler.ScheduleJob(job)

	return job.ID, nil
}

// runPeriodicSync exécute la synchronisation périodique
func (cbs *CrossBranchSynchronizer) runPeriodicSync() {
	ticker := time.NewTicker(cbs.Config.SyncInterval)
	defer ticker.Stop()

	for range ticker.C {
		if !cbs.Config.EnableAutoSync {
			continue
		}

		// Obtenir toutes les règles de synchronisation
		cbs.ruleManager.mu.RLock()
		rules := cbs.ruleManager.config.BranchRules
		cbs.ruleManager.mu.RUnlock()

		// Planifier les synchronisations automatiques
		for _, rule := range rules {
			if rule.AutoMerge {
				for _, targetBranch := range rule.TargetBranches {
					_, err := cbs.ScheduleSync(rule.SourceBranch, targetBranch)
					if err != nil {
						// Log l'erreur mais continue
						fmt.Printf("Failed to schedule sync from %s to %s: %v\n", rule.SourceBranch, targetBranch, err)
					}
				}
			}
		}
	}
}

// runHealthCheck exécute les vérifications de santé
func (cbs *CrossBranchSynchronizer) runHealthCheck() {
	ticker := time.NewTicker(cbs.Config.HealthCheckInterval)
	defer ticker.Stop()

	for range ticker.C {
		cbs.performHealthCheck()
	}
}

// performHealthCheck effectue une vérification de santé
func (cbs *CrossBranchSynchronizer) performHealthCheck() {
	cbs.mu.Lock()
	defer cbs.mu.Unlock()

	// Nettoyer les jobs terminés anciens
	cutoff := time.Now().Add(-24 * time.Hour)
	filteredJobs := []SyncJob{}

	for _, job := range cbs.CompletedJobs {
		if job.EndTime.After(cutoff) {
			filteredJobs = append(filteredJobs, job)
		}
	}
	cbs.CompletedJobs = filteredJobs

	// Vérifier les jobs bloqués
	for id, job := range cbs.ActiveJobs {
		if job.Status == "running" && time.Since(job.StartTime) > 30*time.Minute {
			job.Status = "failed"
			job.EndTime = time.Now()
			job.Errors = append(job.Errors, "Job timeout - exceeded 30 minutes")

			cbs.CompletedJobs = append(cbs.CompletedJobs, *job)
			delete(cbs.ActiveJobs, id)
		}
	}
}

// Start démarre le scheduler
func (ss *SyncScheduler) Start() error {
	ss.mu.Lock()
	defer ss.mu.Unlock()

	if ss.Running {
		return fmt.Errorf("scheduler is already running")
	}

	ss.Running = true

	// Démarrer tous les workers
	for _, worker := range ss.workers {
		go worker.Start()
	}

	return nil
}

// Stop arrête le scheduler
func (ss *SyncScheduler) Stop() error {
	ss.mu.Lock()
	defer ss.mu.Unlock()

	if !ss.Running {
		return fmt.Errorf("scheduler is not running")
	}

	ss.Running = false

	// Arrêter tous les workers
	for _, worker := range ss.workers {
		worker.Stop()
	}

	// Fermer le canal des jobs
	close(ss.jobs)

	return nil
}

// ScheduleJob ajoute un job à la queue
func (ss *SyncScheduler) ScheduleJob(job *SyncJob) {
	ss.mu.RLock()
	defer ss.mu.RUnlock()

	if ss.Running {
		ss.jobs <- job
	}
}

// Start démarre le worker
func (sw *SyncWorker) Start() {
	for {
		select {
		case job := <-sw.jobs:
			sw.CurrentJob = job
			sw.processJob(job)
		case <-sw.quit:
			return
		}
	}
}

// Stop arrête le worker
func (sw *SyncWorker) Stop() {
	sw.quit <- true
}

// processJob traite un job de synchronisation
func (sw *SyncWorker) processJob(job *SyncJob) {
	job.Status = "running"
	job.StartTime = time.Now()

	defer func() {
		job.EndTime = time.Now()
		sw.CurrentJob = nil
	}()

	// Simuler les étapes de synchronisation
	steps := []string{"detecting_changes", "analyzing_conflicts", "applying_merge", "validating_result"}

	for i, step := range steps {
		job.Progress = float64(i+1) / float64(len(steps))
		job.Metadata["current_step"] = step

		// Simuler le travail
		time.Sleep(100 * time.Millisecond)

		// Simuler une détection de conflit
		if step == "analyzing_conflicts" {
			conflicts, err := sw.detector.DetectConflicts(job.SourceBranch, job.TargetBranch, []string{"example.go"})
			if err != nil {
				job.Status = "failed"
				job.Errors = append(job.Errors, fmt.Sprintf("Conflict detection failed: %v", err))
				return
			}
			job.ConflictsFound = len(conflicts)
		}

		// Simuler un merge
		if step == "applying_merge" && job.ConflictsFound > 0 {
			result, err := sw.syncManager.PerformIntelligentMerge(
				job.SourceBranch, job.TargetBranch, "example.go",
				"source content", "target content", "base content",
			)
			if err != nil {
				job.Status = "failed"
				job.Errors = append(job.Errors, fmt.Sprintf("Merge failed: %v", err))
				return
			}
			job.ConflictsResolved = result.ConflictsResolved
		}
	}

	job.Status = "completed"
	job.Progress = 1.0
	job.FilesProcessed = 1 // Simulation
}

// GetJobStatus retourne le statut d'un job
func (cbs *CrossBranchSynchronizer) GetJobStatus(jobID string) (*SyncJob, error) {
	cbs.mu.RLock()
	defer cbs.mu.RUnlock()

	if job, exists := cbs.ActiveJobs[jobID]; exists {
		return job, nil
	}

	for _, job := range cbs.CompletedJobs {
		if job.ID == jobID {
			return &job, nil
		}
	}

	return nil, fmt.Errorf("job %s not found", jobID)
}

// GetActiveJobs retourne tous les jobs actifs
func (cbs *CrossBranchSynchronizer) GetActiveJobs() []*SyncJob {
	cbs.mu.RLock()
	defer cbs.mu.RUnlock()

	jobs := make([]*SyncJob, 0, len(cbs.ActiveJobs))
	for _, job := range cbs.ActiveJobs {
		jobs = append(jobs, job)
	}

	return jobs
}

// GetCompletedJobs retourne tous les jobs terminés
func (cbs *CrossBranchSynchronizer) GetCompletedJobs() []SyncJob {
	cbs.mu.RLock()
	defer cbs.mu.RUnlock()

	jobs := make([]SyncJob, len(cbs.CompletedJobs))
	copy(jobs, cbs.CompletedJobs)
	return jobs
}

// CancelJob annule un job en cours
func (cbs *CrossBranchSynchronizer) CancelJob(jobID string) error {
	cbs.mu.Lock()
	defer cbs.mu.Unlock()

	job, exists := cbs.ActiveJobs[jobID]
	if !exists {
		return fmt.Errorf("job %s not found or already completed", jobID)
	}

	job.Status = "cancelled"
	job.EndTime = time.Now()

	cbs.CompletedJobs = append(cbs.CompletedJobs, *job)
	delete(cbs.ActiveJobs, jobID)

	return nil
}

// TASK ATOMIQUE 3.4.2.2 - Historique des synchronisations

// SyncHistoryManager gestionnaire d'historique des synchronisations
type SyncHistoryManager struct {
	history    []SyncHistoryEntry  `json:"history" yaml:"history"`
	maxEntries int                 `json:"max_entries" yaml:"max_entries"`
	storage    SyncHistoryStorage  `json:"-" yaml:"-"`
	indexer    *SyncHistoryIndexer `json:"-" yaml:"-"`
	mu         sync.RWMutex        `json:"-" yaml:"-"`
}

// SyncHistoryEntry entrée d'historique de synchronisation
type SyncHistoryEntry struct {
	ID                string                 `json:"id" yaml:"id"`
	Timestamp         time.Time              `json:"timestamp" yaml:"timestamp"`
	SourceBranch      string                 `json:"source_branch" yaml:"source_branch"`
	TargetBranch      string                 `json:"target_branch" yaml:"target_branch"`
	SyncType          string                 `json:"sync_type" yaml:"sync_type"` // "manual", "automatic", "scheduled"
	Status            string                 `json:"status" yaml:"status"`       // "success", "failed", "partial"
	Duration          time.Duration          `json:"duration" yaml:"duration"`
	FilesModified     []string               `json:"files_modified" yaml:"files_modified"`
	ConflictsDetected int                    `json:"conflicts_detected" yaml:"conflicts_detected"`
	ConflictsResolved int                    `json:"conflicts_resolved" yaml:"conflicts_resolved"`
	Strategy          string                 `json:"strategy" yaml:"strategy"`
	UserID            string                 `json:"user_id" yaml:"user_id"`
	CommitHashes      map[string]string      `json:"commit_hashes" yaml:"commit_hashes"`
	Metrics           SyncMetrics            `json:"metrics" yaml:"metrics"`
	Errors            []string               `json:"errors" yaml:"errors"`
	Warnings          []string               `json:"warnings" yaml:"warnings"`
	Metadata          map[string]interface{} `json:"metadata" yaml:"metadata"`
}

// SyncMetrics métriques de synchronisation
type SyncMetrics struct {
	LinesAdded             int           `json:"lines_added" yaml:"lines_added"`
	LinesDeleted           int           `json:"lines_deleted" yaml:"lines_deleted"`
	LinesModified          int           `json:"lines_modified" yaml:"lines_modified"`
	FilesAdded             int           `json:"files_added" yaml:"files_added"`
	FilesDeleted           int           `json:"files_deleted" yaml:"files_deleted"`
	FilesModified          int           `json:"files_modified" yaml:"files_modified"`
	ConflictResolutionTime time.Duration `json:"conflict_resolution_time" yaml:"conflict_resolution_time"`
	CPUUsage               float64       `json:"cpu_usage" yaml:"cpu_usage"`
	MemoryUsage            int64         `json:"memory_usage" yaml:"memory_usage"`
	NetworkIO              int64         `json:"network_io" yaml:"network_io"`
}

// SyncHistoryStorage interface pour le stockage de l'historique
type SyncHistoryStorage interface {
	Save(entry SyncHistoryEntry) error
	Load(id string) (SyncHistoryEntry, error)
	LoadAll() ([]SyncHistoryEntry, error)
	Delete(id string) error
	Query(filter SyncHistoryFilter) ([]SyncHistoryEntry, error)
}

// SyncHistoryIndexer indexeur pour la recherche rapide
type SyncHistoryIndexer struct {
	branchIndex map[string][]string `json:"branch_index" yaml:"branch_index"`
	dateIndex   map[string][]string `json:"date_index" yaml:"date_index"`
	statusIndex map[string][]string `json:"status_index" yaml:"status_index"`
	userIndex   map[string][]string `json:"user_index" yaml:"user_index"`
	mu          sync.RWMutex        `json:"-" yaml:"-"`
}

// SyncHistoryFilter filtre pour les requêtes d'historique
type SyncHistoryFilter struct {
	SourceBranch string        `json:"source_branch" yaml:"source_branch"`
	TargetBranch string        `json:"target_branch" yaml:"target_branch"`
	Status       string        `json:"status" yaml:"status"`
	SyncType     string        `json:"sync_type" yaml:"sync_type"`
	UserID       string        `json:"user_id" yaml:"user_id"`
	StartDate    time.Time     `json:"start_date" yaml:"start_date"`
	EndDate      time.Time     `json:"end_date" yaml:"end_date"`
	MinDuration  time.Duration `json:"min_duration" yaml:"min_duration"`
	MaxDuration  time.Duration `json:"max_duration" yaml:"max_duration"`
	HasConflicts *bool         `json:"has_conflicts" yaml:"has_conflicts"`
	Limit        int           `json:"limit" yaml:"limit"`
	Offset       int           `json:"offset" yaml:"offset"`
}

// MemorySyncHistoryStorage implémentation en mémoire du stockage
type MemorySyncHistoryStorage struct {
	entries map[string]SyncHistoryEntry `json:"entries" yaml:"entries"`
	mu      sync.RWMutex                `json:"-" yaml:"-"`
}

// NewSyncHistoryManager crée un nouveau gestionnaire d'historique
func NewSyncHistoryManager(maxEntries int, storage SyncHistoryStorage) *SyncHistoryManager {
	if storage == nil {
		storage = &MemorySyncHistoryStorage{
			entries: make(map[string]SyncHistoryEntry),
		}
	}

	indexer := &SyncHistoryIndexer{
		branchIndex: make(map[string][]string),
		dateIndex:   make(map[string][]string),
		statusIndex: make(map[string][]string),
		userIndex:   make(map[string][]string),
	}

	return &SyncHistoryManager{
		history:    []SyncHistoryEntry{},
		maxEntries: maxEntries,
		storage:    storage,
		indexer:    indexer,
	}
}

// RecordSync enregistre une synchronisation dans l'historique
func (shm *SyncHistoryManager) RecordSync(entry SyncHistoryEntry) error {
	shm.mu.Lock()
	defer shm.mu.Unlock()

	// Générer un ID si nécessaire
	if entry.ID == "" {
		entry.ID = fmt.Sprintf("sync_hist_%d", time.Now().UnixNano())
	}

	// Ajouter un timestamp si nécessaire
	if entry.Timestamp.IsZero() {
		entry.Timestamp = time.Now()
	}

	// Sauvegarder dans le storage persistant
	if err := shm.storage.Save(entry); err != nil {
		return fmt.Errorf("failed to save sync history entry: %w", err)
	}

	// Ajouter à l'historique en mémoire
	shm.history = append(shm.history, entry)

	// Maintenir la limite d'entrées
	if len(shm.history) > shm.maxEntries {
		shm.history = shm.history[1:] // Supprimer la plus ancienne
	}

	// Mettre à jour les index
	shm.indexer.AddEntry(entry)

	return nil
}

// GetSyncHistory retourne l'historique avec filtrage optionnel
func (shm *SyncHistoryManager) GetSyncHistory(filter SyncHistoryFilter) ([]SyncHistoryEntry, error) {
	shm.mu.RLock()
	defer shm.mu.RUnlock()

	// Utiliser le storage pour les requêtes complexes
	if shm.needsStorageQuery(filter) {
		return shm.storage.Query(filter)
	}

	// Filtrage en mémoire pour les requêtes simples
	return shm.filterEntries(shm.history, filter), nil
}

// GetSyncStats retourne les statistiques d'historique
func (shm *SyncHistoryManager) GetSyncStats() SyncHistoryStats {
	shm.mu.RLock()
	defer shm.mu.RUnlock()

	stats := SyncHistoryStats{
		TotalSyncs:        len(shm.history),
		SuccessfulSyncs:   0,
		FailedSyncs:       0,
		PartialSyncs:      0,
		TotalConflicts:    0,
		ResolvedConflicts: 0,
		AverageDuration:   0,
		BranchStats:       make(map[string]BranchSyncStats),
		UserStats:         make(map[string]UserSyncStats),
		DailyStats:        make(map[string]DailySyncStats),
	}

	var totalDuration time.Duration

	for _, entry := range shm.history {
		// Statistiques globales
		switch entry.Status {
		case "success":
			stats.SuccessfulSyncs++
		case "failed":
			stats.FailedSyncs++
		case "partial":
			stats.PartialSyncs++
		}

		stats.TotalConflicts += entry.ConflictsDetected
		stats.ResolvedConflicts += entry.ConflictsResolved
		totalDuration += entry.Duration
		// Statistiques par branche
		branchKey := fmt.Sprintf("%s->%s", entry.SourceBranch, entry.TargetBranch)
		if branchStat, exists := stats.BranchStats[branchKey]; exists {
			branchStat.SyncCount++
			branchStat.TotalDuration += entry.Duration
			if entry.Status == "success" {
				branchStat.SuccessCount++
			}
			stats.BranchStats[branchKey] = branchStat
		} else {
			successCount := 0
			if entry.Status == "success" {
				successCount = 1
			}
			stats.BranchStats[branchKey] = BranchSyncStats{
				SourceBranch:  entry.SourceBranch,
				TargetBranch:  entry.TargetBranch,
				SyncCount:     1,
				SuccessCount:  successCount,
				TotalDuration: entry.Duration,
				LastSync:      entry.Timestamp,
			}
		}

		// Statistiques par utilisateur
		if userStat, exists := stats.UserStats[entry.UserID]; exists {
			userStat.SyncCount++
			userStat.TotalDuration += entry.Duration
			stats.UserStats[entry.UserID] = userStat
		} else {
			stats.UserStats[entry.UserID] = UserSyncStats{
				UserID:        entry.UserID,
				SyncCount:     1,
				TotalDuration: entry.Duration,
				LastSync:      entry.Timestamp,
			}
		}

		// Statistiques quotidiennes
		dateKey := entry.Timestamp.Format("2006-01-02")
		if dailyStat, exists := stats.DailyStats[dateKey]; exists {
			dailyStat.SyncCount++
			dailyStat.TotalDuration += entry.Duration
			dailyStat.ConflictCount += entry.ConflictsDetected
			stats.DailyStats[dateKey] = dailyStat
		} else {
			stats.DailyStats[dateKey] = DailySyncStats{
				Date:          entry.Timestamp.Format("2006-01-02"),
				SyncCount:     1,
				TotalDuration: entry.Duration,
				ConflictCount: entry.ConflictsDetected,
			}
		}
	}

	if stats.TotalSyncs > 0 {
		stats.AverageDuration = totalDuration / time.Duration(stats.TotalSyncs)
		stats.SuccessRate = float64(stats.SuccessfulSyncs) / float64(stats.TotalSyncs)
		stats.ConflictResolutionRate = float64(stats.ResolvedConflicts) / float64(stats.TotalConflicts)
	}

	return stats
}

// SyncHistoryStats statistiques d'historique de synchronisation
type SyncHistoryStats struct {
	TotalSyncs             int                        `json:"total_syncs" yaml:"total_syncs"`
	SuccessfulSyncs        int                        `json:"successful_syncs" yaml:"successful_syncs"`
	FailedSyncs            int                        `json:"failed_syncs" yaml:"failed_syncs"`
	PartialSyncs           int                        `json:"partial_syncs" yaml:"partial_syncs"`
	SuccessRate            float64                    `json:"success_rate" yaml:"success_rate"`
	TotalConflicts         int                        `json:"total_conflicts" yaml:"total_conflicts"`
	ResolvedConflicts      int                        `json:"resolved_conflicts" yaml:"resolved_conflicts"`
	ConflictResolutionRate float64                    `json:"conflict_resolution_rate" yaml:"conflict_resolution_rate"`
	AverageDuration        time.Duration              `json:"average_duration" yaml:"average_duration"`
	BranchStats            map[string]BranchSyncStats `json:"branch_stats" yaml:"branch_stats"`
	UserStats              map[string]UserSyncStats   `json:"user_stats" yaml:"user_stats"`
	DailyStats             map[string]DailySyncStats  `json:"daily_stats" yaml:"daily_stats"`
}

// BranchSyncStats statistiques par branche
type BranchSyncStats struct {
	SourceBranch  string        `json:"source_branch" yaml:"source_branch"`
	TargetBranch  string        `json:"target_branch" yaml:"target_branch"`
	SyncCount     int           `json:"sync_count" yaml:"sync_count"`
	SuccessCount  int           `json:"success_count" yaml:"success_count"`
	TotalDuration time.Duration `json:"total_duration" yaml:"total_duration"`
	LastSync      time.Time     `json:"last_sync" yaml:"last_sync"`
}

// UserSyncStats statistiques par utilisateur
type UserSyncStats struct {
	UserID        string        `json:"user_id" yaml:"user_id"`
	SyncCount     int           `json:"sync_count" yaml:"sync_count"`
	TotalDuration time.Duration `json:"total_duration" yaml:"total_duration"`
	LastSync      time.Time     `json:"last_sync" yaml:"last_sync"`
}

// DailySyncStats statistiques quotidiennes
type DailySyncStats struct {
	Date          string        `json:"date" yaml:"date"`
	SyncCount     int           `json:"sync_count" yaml:"sync_count"`
	TotalDuration time.Duration `json:"total_duration" yaml:"total_duration"`
	ConflictCount int           `json:"conflict_count" yaml:"conflict_count"`
}

// Méthodes manquantes pour SyncHistoryIndexer

// AddEntry ajoute une entrée aux index
func (shi *SyncHistoryIndexer) AddEntry(entry SyncHistoryEntry) {
	shi.mu.Lock()
	defer shi.mu.Unlock()

	// Index par branche
	branchKey := fmt.Sprintf("%s->%s", entry.SourceBranch, entry.TargetBranch)
	shi.branchIndex[branchKey] = append(shi.branchIndex[branchKey], entry.ID)

	// Index par date
	dateKey := entry.Timestamp.Format("2006-01-02")
	shi.dateIndex[dateKey] = append(shi.dateIndex[dateKey], entry.ID)

	// Index par statut
	shi.statusIndex[entry.Status] = append(shi.statusIndex[entry.Status], entry.ID)

	// Index par utilisateur
	if entry.UserID != "" {
		shi.userIndex[entry.UserID] = append(shi.userIndex[entry.UserID], entry.ID)
	}
}

// Méthodes manquantes pour SyncHistoryManager

// needsStorageQuery détermine si une requête nécessite le storage
func (shm *SyncHistoryManager) needsStorageQuery(filter SyncHistoryFilter) bool {
	// Utiliser le storage pour les requêtes complexes ou avec pagination
	return filter.Limit > 0 || filter.Offset > 0 ||
		!filter.StartDate.IsZero() || !filter.EndDate.IsZero() ||
		filter.MinDuration > 0 || filter.MaxDuration > 0
}

// filterEntries filtre les entrées en mémoire
func (shm *SyncHistoryManager) filterEntries(entries []SyncHistoryEntry, filter SyncHistoryFilter) []SyncHistoryEntry {
	var filtered []SyncHistoryEntry

	for _, entry := range entries {
		if shm.storage.(*MemorySyncHistoryStorage).matchesFilter(entry, filter) {
			filtered = append(filtered, entry)
		}
	}

	return filtered
}

// Méthode manquante pour ConflictDetector

// GetConflictsByStatus retourne les conflits par statut
func (cd *ConflictDetector) GetConflictsByStatus(status string) []DetectedConflict {
	cd.mu.RLock()
	defer cd.mu.RUnlock()

	var filtered []DetectedConflict
	for _, conflict := range cd.History {
		if conflict.Status == status {
			filtered = append(filtered, conflict)
		}
	}
	return filtered
}

// ResolveConflict résout un conflit par son ID
func (cd *ConflictDetector) ResolveConflict(conflictID, resolution string) error {
	cd.mu.Lock()
	defer cd.mu.Unlock()

	// Trouver le conflit dans l'historique
	for i, conflict := range cd.History {
		if conflict.ID == conflictID {
			cd.History[i].Status = "resolved"
			cd.History[i].Resolution = resolution
			return nil
		}
	}

	return fmt.Errorf("conflict with ID %s not found", conflictID)
}

// Implémentation des méthodes pour MemorySyncHistoryStorage

// Save sauvegarde une entrée
func (mshs *MemorySyncHistoryStorage) Save(entry SyncHistoryEntry) error {
	mshs.mu.Lock()
	defer mshs.mu.Unlock()

	mshs.entries[entry.ID] = entry
	return nil
}

// Load charge une entrée par ID
func (mshs *MemorySyncHistoryStorage) Load(id string) (SyncHistoryEntry, error) {
	mshs.mu.RLock()
	defer mshs.mu.RUnlock()

	entry, exists := mshs.entries[id]
	if !exists {
		return SyncHistoryEntry{}, fmt.Errorf("entry %s not found", id)
	}

	return entry, nil
}

// LoadAll charge toutes les entrées
func (mshs *MemorySyncHistoryStorage) LoadAll() ([]SyncHistoryEntry, error) {
	mshs.mu.RLock()
	defer mshs.mu.RUnlock()

	entries := make([]SyncHistoryEntry, 0, len(mshs.entries))
	for _, entry := range mshs.entries {
		entries = append(entries, entry)
	}

	return entries, nil
}

// Delete supprime une entrée
func (mshs *MemorySyncHistoryStorage) Delete(id string) error {
	mshs.mu.Lock()
	defer mshs.mu.Unlock()

	delete(mshs.entries, id)
	return nil
}

// Query effectue une requête filtrée
func (mshs *MemorySyncHistoryStorage) Query(filter SyncHistoryFilter) ([]SyncHistoryEntry, error) {
	entries, err := mshs.LoadAll()
	if err != nil {
		return nil, err
	}

	// Appliquer les filtres (implémentation simplifiée)
	var filtered []SyncHistoryEntry
	for _, entry := range entries {
		if mshs.matchesFilter(entry, filter) {
			filtered = append(filtered, entry)
		}
	}

	// Appliquer la pagination
	if filter.Offset >= len(filtered) {
		return []SyncHistoryEntry{}, nil
	}

	end := len(filtered)
	if filter.Limit > 0 && filter.Offset+filter.Limit < end {
		end = filter.Offset + filter.Limit
	}

	return filtered[filter.Offset:end], nil
}

// matchesFilter vérifie si une entrée correspond au filtre
func (mshs *MemorySyncHistoryStorage) matchesFilter(entry SyncHistoryEntry, filter SyncHistoryFilter) bool {
	if filter.SourceBranch != "" && entry.SourceBranch != filter.SourceBranch {
		return false
	}

	if filter.TargetBranch != "" && entry.TargetBranch != filter.TargetBranch {
		return false
	}

	if filter.Status != "" && entry.Status != filter.Status {
		return false
	}

	if filter.SyncType != "" && entry.SyncType != filter.SyncType {
		return false
	}

	if filter.UserID != "" && entry.UserID != filter.UserID {
		return false
	}

	if !filter.StartDate.IsZero() && entry.Timestamp.Before(filter.StartDate) {
		return false
	}

	if !filter.EndDate.IsZero() && entry.Timestamp.After(filter.EndDate) {
		return false
	}

	if filter.MinDuration > 0 && entry.Duration < filter.MinDuration {
		return false
	}

	if filter.MaxDuration > 0 && entry.Duration > filter.MaxDuration {
		return false
	}

	if filter.HasConflicts != nil {
		hasConflicts := entry.ConflictsDetected > 0
		if *filter.HasConflicts != hasConflicts {
			return false
		}
	}

	return true
}

// DiffResult contient le résultat d'une analyse documentaire
// pour une branche donnée
// 4.2.1.2.2

type DiffResult struct {
	Branch          string
	ModifiedFiles   []string
	DivergenceScore int
}

// analyzeBranchDocDiff analyse les différences documentaires d'une branche
func (bs *BranchSynchronizer) analyzeBranchDocDiff(branch string) (*DiffResult, error) {
	// Simulation : dans un vrai repo, on comparerait les fichiers entre branches
	// Ici, on simule avec des données fictives ou via un mock pour les tests
	var modified []string
	// Ex : on suppose que BranchDiffs contient la liste des fichiers modifiés
	if diff, ok := bs.BranchDiffs[branch]; ok {
		for _, f := range diff.FilesChanged {
			if hasDocExtension(f) {
				modified = append(modified, f)
			}
		}
	}
	return &DiffResult{
		Branch:          branch,
		ModifiedFiles:   modified,
		DivergenceScore: len(modified),
	}, nil
}

func hasDocExtension(filename string) bool {
	return hasSuffix(filename, ".md") || hasSuffix(filename, ".txt") || hasSuffix(filename, ".adoc")
}

func hasSuffix(s, suffix string) bool {
	if len(s) < len(suffix) {
		return false
	}
	return s[len(s)-len(suffix):] == suffix
}

// Résolution automatique des conflits documentaires
// Filtre les conflits auto-résolvables et applique les stratégies de merge
func (bs *BranchSynchronizer) filterAutoResolvable(conflicts []DetectedConflict) []DetectedConflict {
	var resolvable []DetectedConflict
	for _, c := range conflicts {
		// Stratégie simple : conflits de sévérité "low" ou "medium" sont auto-résolvables
		if c.Severity == "low" || c.Severity == "medium" {
			resolvable = append(resolvable, c)
		}
		// On pourrait ajouter d'autres critères (timestamp, consensus, etc.)
	}
	return resolvable
}

// Applique la résolution automatique sur les conflits auto-résolvables
func (bs *BranchSynchronizer) autoResolveConflicts(conflicts []DetectedConflict) (int, error) {
	conflictDetector, ok := interface{}(bs.Conflicts).(*ConflictDetector)
	if !ok || conflictDetector == nil {
		return 0, fmt.Errorf("ConflictDetector non initialisé dans BranchSynchronizer")
	}
	resolved := 0
	for _, c := range conflicts {
		// Stratégie : on applique la résolution "keep_source" ou "timestamp" (exemple)
		resolution := "auto:keep_source"
		if err := conflictDetector.ResolveConflict(c.ID, resolution); err == nil {
			resolved++
		}
	}
	return resolved, nil
}

// 4.3.1.1.1 Système stratégies pluggables
// Définition de l’interface ResolutionStrategy et des structures associées

type ConflictType string

type Document struct {
	Content  string
	Metadata map[string]interface{}
}

type DocumentConflict struct {
	Type     ConflictType
	Details  map[string]interface{}
	Severity string
}

type ResolutionStrategy interface {
	Resolve(*DocumentConflict) (*Document, error)
	CanHandle(ConflictType) bool
	Priority() int
}

type ConflictResolver struct {
	strategies      map[ConflictType][]ResolutionStrategy
	defaultStrategy ResolutionStrategy
}

// 4.3.1.2.1 Analyse et classification conflit
func (cr *ConflictResolver) classifyConflict(conflict *DocumentConflict) ConflictType {
	// Exemple : classification simple par champ Type
	return conflict.Type
}

func (cr *ConflictResolver) assessConflictSeverity(conflict *DocumentConflict) string {
	// Exemple : retourne la sévérité du conflit
	if conflict.Severity != "" {
		return conflict.Severity
	}
	return "medium"
}

func (cr *ConflictResolver) extractConflictMetadata(conflict *DocumentConflict) map[string]interface{} {
	// Exemple : retourne les métadonnées du conflit
	return conflict.Details
}

// 4.3.1.2.2 Sélection stratégie optimale