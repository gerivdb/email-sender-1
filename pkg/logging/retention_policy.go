package logging

import (
	"context"
	"fmt"
	"sync"
	"time"

	"go.uber.org/zap"
)

// RetentionPolicy définit une politique de rétention des logs
type RetentionPolicy struct {
	ID            string        `json:"id"`
	Name          string        `json:"name"`
	LogLevel      string        `json:"log_level"`
	Component     string        `json:"component"`
	RetentionDays int           `json:"retention_days"`
	MaxSizeMB     int64         `json:"max_size_mb"`
	ArchiveAfter  time.Duration `json:"archive_after"`
	DeleteAfter   time.Duration `json:"delete_after"`
	Enabled       bool          `json:"enabled"`
	CreatedAt     time.Time     `json:"created_at"`
	UpdatedAt     time.Time     `json:"updated_at"`
}

// RetentionPolicyManager gère les politiques de rétention des logs
type RetentionPolicyManager struct {
	mu       sync.RWMutex
	policies map[string]*RetentionPolicy
	logger   *zap.Logger
	storage  RetentionStorage
	ticker   *time.Ticker
	ctx      context.Context
	cancel   context.CancelFunc
}

// RetentionStorage interface pour le stockage des politiques
type RetentionStorage interface {
	SavePolicy(policy *RetentionPolicy) error
	LoadPolicies() ([]*RetentionPolicy, error)
	DeletePolicy(policyID string) error
	ArchiveLogs(policyID string, before time.Time) error
	DeleteLogs(policyID string, before time.Time) error
	GetLogStats(policyID string) (*LogStats, error)
}

// LogStats statistiques des logs pour une politique
type LogStats struct {
	TotalSize    int64     `json:"total_size"`
	TotalCount   int64     `json:"total_count"`
	OldestLog    time.Time `json:"oldest_log"`
	NewestLog    time.Time `json:"newest_log"`
	ArchiveSize  int64     `json:"archive_size"`
	ArchiveCount int64     `json:"archive_count"`
	LastCleanup  time.Time `json:"last_cleanup"`
}

// RetentionAction représente une action de rétention
type RetentionAction struct {
	Type      string        `json:"type"`
	PolicyID  string        `json:"policy_id"`
	Timestamp time.Time     `json:"timestamp"`
	LogsCount int64         `json:"logs_count"`
	SizeBytes int64         `json:"size_bytes"`
	Success   bool          `json:"success"`
	Error     string        `json:"error,omitempty"`
	Duration  time.Duration `json:"duration"`
}

// RetentionEvent événement de rétention
type RetentionEvent struct {
	Type      string                 `json:"type"`
	PolicyID  string                 `json:"policy_id"`
	Action    *RetentionAction       `json:"action,omitempty"`
	Stats     *LogStats              `json:"stats,omitempty"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
	Timestamp time.Time              `json:"timestamp"`
}

// RetentionNotifier interface pour les notifications
type RetentionNotifier interface {
	NotifyRetentionAction(event *RetentionEvent) error
}

// NewRetentionPolicyManager crée un nouveau gestionnaire de politiques
func NewRetentionPolicyManager(
	logger *zap.Logger,
	storage RetentionStorage,
	notifier RetentionNotifier,
) *RetentionPolicyManager {
	ctx, cancel := context.WithCancel(context.Background())

	return &RetentionPolicyManager{
		policies: make(map[string]*RetentionPolicy),
		logger:   logger,
		storage:  storage,
		ctx:      ctx,
		cancel:   cancel,
	}
}

// Start démarre le gestionnaire de rétention
func (rpm *RetentionPolicyManager) Start() error {
	rpm.mu.Lock()
	defer rpm.mu.Unlock()

	// Charge les politiques existantes
	policies, err := rpm.storage.LoadPolicies()
	if err != nil {
		return fmt.Errorf("failed to load retention policies: %w", err)
	}

	for _, policy := range policies {
		rpm.policies[policy.ID] = policy
	}

	// Démarre le nettoyage automatique (toutes les heures)
	rpm.ticker = time.NewTicker(time.Hour)
	go rpm.cleanupLoop()

	rpm.logger.Info("Retention policy manager started",
		zap.Int("policies_loaded", len(policies)),
	)

	return nil
}

// Stop arrête le gestionnaire
func (rpm *RetentionPolicyManager) Stop() error {
	rpm.mu.Lock()
	defer rpm.mu.Unlock()

	if rpm.ticker != nil {
		rpm.ticker.Stop()
		rpm.ticker = nil
	}

	rpm.cancel()
	rpm.logger.Info("Retention policy manager stopped")
	return nil
}

// CreatePolicy crée une nouvelle politique de rétention
func (rpm *RetentionPolicyManager) CreatePolicy(policy *RetentionPolicy) error {
	rpm.mu.Lock()
	defer rpm.mu.Unlock()

	if policy.ID == "" {
		policy.ID = fmt.Sprintf("policy_%d", time.Now().Unix())
	}

	now := time.Now()
	policy.CreatedAt = now
	policy.UpdatedAt = now

	// Valide la politique
	if err := rpm.validatePolicy(policy); err != nil {
		return fmt.Errorf("invalid retention policy: %w", err)
	}

	// Sauvegarde
	if err := rpm.storage.SavePolicy(policy); err != nil {
		return fmt.Errorf("failed to save retention policy: %w", err)
	}

	rpm.policies[policy.ID] = policy

	rpm.logger.Info("Retention policy created",
		zap.String("policy_id", policy.ID),
		zap.String("name", policy.Name),
		zap.Int("retention_days", policy.RetentionDays),
	)

	return nil
}

// UpdatePolicy met à jour une politique existante
func (rpm *RetentionPolicyManager) UpdatePolicy(policy *RetentionPolicy) error {
	rpm.mu.Lock()
	defer rpm.mu.Unlock()

	existing, exists := rpm.policies[policy.ID]
	if !exists {
		return fmt.Errorf("retention policy %s not found", policy.ID)
	}

	// Conserve la date de création
	policy.CreatedAt = existing.CreatedAt
	policy.UpdatedAt = time.Now()

	// Valide la politique
	if err := rpm.validatePolicy(policy); err != nil {
		return fmt.Errorf("invalid retention policy: %w", err)
	}

	// Sauvegarde
	if err := rpm.storage.SavePolicy(policy); err != nil {
		return fmt.Errorf("failed to update retention policy: %w", err)
	}

	rpm.policies[policy.ID] = policy

	rpm.logger.Info("Retention policy updated",
		zap.String("policy_id", policy.ID),
		zap.String("name", policy.Name),
	)

	return nil
}

// DeletePolicy supprime une politique
func (rpm *RetentionPolicyManager) DeletePolicy(policyID string) error {
	rpm.mu.Lock()
	defer rpm.mu.Unlock()

	if _, exists := rpm.policies[policyID]; !exists {
		return fmt.Errorf("retention policy %s not found", policyID)
	}

	if err := rpm.storage.DeletePolicy(policyID); err != nil {
		return fmt.Errorf("failed to delete retention policy: %w", err)
	}

	delete(rpm.policies, policyID)

	rpm.logger.Info("Retention policy deleted",
		zap.String("policy_id", policyID),
	)

	return nil
}

// GetPolicy retourne une politique par son ID
func (rpm *RetentionPolicyManager) GetPolicy(policyID string) (*RetentionPolicy, error) {
	rpm.mu.RLock()
	defer rpm.mu.RUnlock()

	policy, exists := rpm.policies[policyID]
	if !exists {
		return nil, fmt.Errorf("retention policy %s not found", policyID)
	}

	return policy, nil
}

// ListPolicies retourne toutes les politiques
func (rpm *RetentionPolicyManager) ListPolicies() []*RetentionPolicy {
	rpm.mu.RLock()
	defer rpm.mu.RUnlock()

	policies := make([]*RetentionPolicy, 0, len(rpm.policies))
	for _, policy := range rpm.policies {
		policies = append(policies, policy)
	}

	return policies
}

// ApplyRetention applique manuellement les politiques de rétention
func (rpm *RetentionPolicyManager) ApplyRetention(policyID string) (*RetentionAction, error) {
	rpm.mu.RLock()
	policy, exists := rpm.policies[policyID]
	rpm.mu.RUnlock()

	if !exists {
		return nil, fmt.Errorf("retention policy %s not found", policyID)
	}

	if !policy.Enabled {
		return nil, fmt.Errorf("retention policy %s is disabled", policyID)
	}

	return rpm.applyPolicy(policy)
}

// GetLogStats retourne les statistiques des logs pour une politique
func (rpm *RetentionPolicyManager) GetLogStats(policyID string) (*LogStats, error) {
	rpm.mu.RLock()
	defer rpm.mu.RUnlock()

	if _, exists := rpm.policies[policyID]; !exists {
		return nil, fmt.Errorf("retention policy %s not found", policyID)
	}

	return rpm.storage.GetLogStats(policyID)
}

// cleanupLoop boucle de nettoyage automatique
func (rpm *RetentionPolicyManager) cleanupLoop() {
	for {
		select {
		case <-rpm.ctx.Done():
			return
		case <-rpm.ticker.C:
			rpm.runCleanup()
		}
	}
}

// runCleanup exécute le nettoyage pour toutes les politiques actives
func (rpm *RetentionPolicyManager) runCleanup() {
	rpm.mu.RLock()
	policies := make([]*RetentionPolicy, 0, len(rpm.policies))
	for _, policy := range rpm.policies {
		if policy.Enabled {
			policies = append(policies, policy)
		}
	}
	rpm.mu.RUnlock()

	for _, policy := range policies {
		action, err := rpm.applyPolicy(policy)
		if err != nil {
			rpm.logger.Error("Failed to apply retention policy",
				zap.String("policy_id", policy.ID),
				zap.Error(err),
			)
		} else if action != nil {
			rpm.logger.Info("Retention policy applied",
				zap.String("policy_id", policy.ID),
				zap.String("action_type", action.Type),
				zap.Int64("logs_count", action.LogsCount),
				zap.Int64("size_bytes", action.SizeBytes),
			)
		}
	}
}

// applyPolicy applique une politique de rétention
func (rpm *RetentionPolicyManager) applyPolicy(policy *RetentionPolicy) (*RetentionAction, error) {
	start := time.Now()

	action := &RetentionAction{
		PolicyID:  policy.ID,
		Timestamp: start,
		Success:   false,
	}

	// Calcule les dates limites
	archiveDate := time.Now().Add(-policy.ArchiveAfter)
	deleteDate := time.Now().Add(-policy.DeleteAfter)

	var totalLogsProcessed int64
	var totalSizeProcessed int64

	// Archive les anciens logs
	if policy.ArchiveAfter > 0 {
		err := rpm.storage.ArchiveLogs(policy.ID, archiveDate)
		if err != nil {
			action.Error = fmt.Sprintf("archive failed: %v", err)
			return action, err
		}
		action.Type = "archive"
	}

	// Supprime les très anciens logs
	if policy.DeleteAfter > 0 {
		err := rpm.storage.DeleteLogs(policy.ID, deleteDate)
		if err != nil {
			action.Error = fmt.Sprintf("delete failed: %v", err)
			return action, err
		}
		if action.Type == "" {
			action.Type = "delete"
		} else {
			action.Type = "archive_and_delete"
		}
	}

	action.LogsCount = totalLogsProcessed
	action.SizeBytes = totalSizeProcessed
	action.Duration = time.Since(start)
	action.Success = true

	return action, nil
}

// validatePolicy valide une politique de rétention
func (rpm *RetentionPolicyManager) validatePolicy(policy *RetentionPolicy) error {
	if policy.Name == "" {
		return fmt.Errorf("policy name is required")
	}

	if policy.RetentionDays <= 0 {
		return fmt.Errorf("retention days must be positive")
	}

	if policy.MaxSizeMB <= 0 {
		return fmt.Errorf("max size must be positive")
	}

	if policy.DeleteAfter > 0 && policy.ArchiveAfter > 0 {
		if policy.DeleteAfter <= policy.ArchiveAfter {
			return fmt.Errorf("delete_after must be greater than archive_after")
		}
	}

	return nil
}

// Health retourne l'état de santé du gestionnaire
func (rpm *RetentionPolicyManager) Health() map[string]interface{} {
	rpm.mu.RLock()
	defer rpm.mu.RUnlock()

	enabledPolicies := 0
	for _, policy := range rpm.policies {
		if policy.Enabled {
			enabledPolicies++
		}
	}

	return map[string]interface{}{
		"status":           "healthy",
		"total_policies":   len(rpm.policies),
		"enabled_policies": enabledPolicies,
		"auto_cleanup":     rpm.ticker != nil,
	}
}

// DefaultRetentionPolicies retourne des politiques par défaut
func DefaultRetentionPolicies() []*RetentionPolicy {
	return []*RetentionPolicy{
		{
			ID:            "default_error_logs",
			Name:          "Error Logs Retention",
			LogLevel:      "error",
			Component:     "*",
			RetentionDays: 30,
			MaxSizeMB:     1024,                // 1GB
			ArchiveAfter:  7 * 24 * time.Hour,  // 7 jours
			DeleteAfter:   30 * 24 * time.Hour, // 30 jours
			Enabled:       true,
		},
		{
			ID:            "default_info_logs",
			Name:          "Info Logs Retention",
			LogLevel:      "info",
			Component:     "*",
			RetentionDays: 7,
			MaxSizeMB:     512,                // 512MB
			ArchiveAfter:  24 * time.Hour,     // 1 jour
			DeleteAfter:   7 * 24 * time.Hour, // 7 jours
			Enabled:       true,
		},
		{
			ID:            "default_debug_logs",
			Name:          "Debug Logs Retention",
			LogLevel:      "debug",
			Component:     "*",
			RetentionDays: 3,
			MaxSizeMB:     256,                // 256MB
			ArchiveAfter:  6 * time.Hour,      // 6 heures
			DeleteAfter:   3 * 24 * time.Hour, // 3 jours
			Enabled:       true,
		},
	}
}
