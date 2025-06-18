package bridge

import (
	"context"
	"fmt"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// WorkflowStatus représente le statut d'un workflow
type WorkflowStatus struct {
	WorkflowID  string                 `json:"workflow_id"`
	ExecutionID string                 `json:"execution_id"`
	Status      string                 `json:"status"`
	Progress    float64                `json:"progress"`
	StartTime   time.Time              `json:"start_time"`
	LastUpdate  time.Time              `json:"last_update"`
	EndTime     *time.Time             `json:"end_time,omitempty"`
	Data        map[string]interface{} `json:"data"`
	Error       string                 `json:"error,omitempty"`
	Steps       []WorkflowStep         `json:"steps,omitempty"`
	TTL         time.Time              `json:"ttl"`
}

// WorkflowStep représente une étape dans un workflow
type WorkflowStep struct {
	StepID    string                 `json:"step_id"`
	Name      string                 `json:"name"`
	Status    string                 `json:"status"`
	StartTime time.Time              `json:"start_time"`
	EndTime   *time.Time             `json:"end_time,omitempty"`
	Duration  time.Duration          `json:"duration"`
	Data      map[string]interface{} `json:"data,omitempty"`
	Error     string                 `json:"error,omitempty"`
}

// StatusTracker interface pour le suivi des statuts
type StatusTracker interface {
	CreateStatus(workflowID, executionID string) (*WorkflowStatus, error)
	UpdateStatus(workflowID string, updates StatusUpdate) error
	GetStatus(workflowID string) (*WorkflowStatus, error)
	DeleteStatus(workflowID string) error
	ListStatuses() (map[string]*WorkflowStatus, error)
	StartCleanup() error
	StopCleanup() error
	SetupRoutes(router *gin.Engine)
	GetStats() StatusTrackerStats
}

// StatusUpdate structure pour mettre à jour un statut
type StatusUpdate struct {
	Status     *string                `json:"status,omitempty"`
	Progress   *float64               `json:"progress,omitempty"`
	Data       map[string]interface{} `json:"data,omitempty"`
	Error      *string                `json:"error,omitempty"`
	AddStep    *WorkflowStep          `json:"add_step,omitempty"`
	UpdateStep *WorkflowStep          `json:"update_step,omitempty"`
}

// StatusTrackerStats statistiques du tracker
type StatusTrackerStats struct {
	TotalStatuses     int           `json:"total_statuses"`
	ActiveStatuses    int           `json:"active_statuses"`
	CompletedStatuses int           `json:"completed_statuses"`
	FailedStatuses    int           `json:"failed_statuses"`
	AverageLifetime   time.Duration `json:"average_lifetime"`
	LastCleanup       time.Time     `json:"last_cleanup"`
	CleanedUp         int64         `json:"cleaned_up"`
}

// MemoryStatusTracker implémentation en mémoire du tracker
type MemoryStatusTracker struct {
	statuses    map[string]*WorkflowStatus
	statusesMux sync.RWMutex
	ctx         context.Context
	cancel      context.CancelFunc
	cleanupTTL  time.Duration
	stats       StatusTrackerStats
	statsMux    sync.RWMutex
}

// StatusTrackerConfig configuration du tracker
type StatusTrackerConfig struct {
	CleanupInterval time.Duration `json:"cleanup_interval"`
	DefaultTTL      time.Duration `json:"default_ttl"`
}

// NewMemoryStatusTracker crée un nouveau tracker en mémoire
func NewMemoryStatusTracker(config StatusTrackerConfig) *MemoryStatusTracker {
	ctx, cancel := context.WithCancel(context.Background())

	defaultTTL := config.DefaultTTL
	if defaultTTL == 0 {
		defaultTTL = 24 * time.Hour // TTL par défaut 24h
	}

	return &MemoryStatusTracker{
		statuses:   make(map[string]*WorkflowStatus),
		ctx:        ctx,
		cancel:     cancel,
		cleanupTTL: defaultTTL,
		stats: StatusTrackerStats{
			LastCleanup: time.Now(),
		},
	}
}

// CreateStatus crée un nouveau statut de workflow
func (t *MemoryStatusTracker) CreateStatus(workflowID, executionID string) (*WorkflowStatus, error) {
	if workflowID == "" {
		return nil, fmt.Errorf("workflow ID cannot be empty")
	}

	if executionID == "" {
		executionID = uuid.New().String()
	}

	now := time.Now()
	status := &WorkflowStatus{
		WorkflowID:  workflowID,
		ExecutionID: executionID,
		Status:      "started",
		Progress:    0.0,
		StartTime:   now,
		LastUpdate:  now,
		Data:        make(map[string]interface{}),
		Steps:       make([]WorkflowStep, 0),
		TTL:         now.Add(t.cleanupTTL),
	}

	t.statusesMux.Lock()
	t.statuses[workflowID] = status
	t.statusesMux.Unlock()

	t.updateStats()
	return status, nil
}

// UpdateStatus met à jour un statut existant
func (t *MemoryStatusTracker) UpdateStatus(workflowID string, updates StatusUpdate) error {
	t.statusesMux.Lock()
	defer t.statusesMux.Unlock()

	status, exists := t.statuses[workflowID]
	if !exists {
		return fmt.Errorf("workflow status not found: %s", workflowID)
	}

	now := time.Now()
	status.LastUpdate = now

	// Mettre à jour les champs modifiés
	if updates.Status != nil {
		status.Status = *updates.Status

		// Si le workflow est terminé, définir EndTime
		if *updates.Status == "completed" || *updates.Status == "failed" || *updates.Status == "cancelled" {
			status.EndTime = &now
		}
	}

	if updates.Progress != nil {
		status.Progress = *updates.Progress
	}

	if updates.Error != nil {
		status.Error = *updates.Error
	}

	if updates.Data != nil {
		// Fusionner les données
		for key, value := range updates.Data {
			status.Data[key] = value
		}
	}

	// Gestion des étapes
	if updates.AddStep != nil {
		step := *updates.AddStep
		if step.StepID == "" {
			step.StepID = uuid.New().String()
		}
		if step.StartTime.IsZero() {
			step.StartTime = now
		}
		status.Steps = append(status.Steps, step)
	}

	if updates.UpdateStep != nil {
		stepUpdate := *updates.UpdateStep
		for i, step := range status.Steps {
			if step.StepID == stepUpdate.StepID {
				// Mettre à jour l'étape existante
				if stepUpdate.Status != "" {
					status.Steps[i].Status = stepUpdate.Status
				}
				if stepUpdate.EndTime != nil {
					status.Steps[i].EndTime = stepUpdate.EndTime
					status.Steps[i].Duration = stepUpdate.EndTime.Sub(step.StartTime)
				}
				if stepUpdate.Error != "" {
					status.Steps[i].Error = stepUpdate.Error
				}
				if stepUpdate.Data != nil {
					status.Steps[i].Data = stepUpdate.Data
				}
				break
			}
		}
	}

	t.updateStats()
	return nil
}

// GetStatus récupère un statut par workflow ID
func (t *MemoryStatusTracker) GetStatus(workflowID string) (*WorkflowStatus, error) {
	t.statusesMux.RLock()
	defer t.statusesMux.RUnlock()

	status, exists := t.statuses[workflowID]
	if !exists {
		return nil, fmt.Errorf("workflow status not found: %s", workflowID)
	}

	// Créer une copie pour éviter les modifications concurrentes
	statusCopy := *status
	statusCopy.Steps = make([]WorkflowStep, len(status.Steps))
	copy(statusCopy.Steps, status.Steps)

	return &statusCopy, nil
}

// DeleteStatus supprime un statut
func (t *MemoryStatusTracker) DeleteStatus(workflowID string) error {
	t.statusesMux.Lock()
	defer t.statusesMux.Unlock()

	delete(t.statuses, workflowID)
	t.updateStats()
	return nil
}

// ListStatuses retourne tous les statuts
func (t *MemoryStatusTracker) ListStatuses() (map[string]*WorkflowStatus, error) {
	t.statusesMux.RLock()
	defer t.statusesMux.RUnlock()

	result := make(map[string]*WorkflowStatus)
	for id, status := range t.statuses {
		statusCopy := *status
		statusCopy.Steps = make([]WorkflowStep, len(status.Steps))
		copy(statusCopy.Steps, status.Steps)
		result[id] = &statusCopy
	}

	return result, nil
}

// StartCleanup démarre le nettoyage automatique
func (t *MemoryStatusTracker) StartCleanup() error {
	go t.cleanupExpiredStatuses()
	return nil
}

// StopCleanup arrête le nettoyage automatique
func (t *MemoryStatusTracker) StopCleanup() error {
	t.cancel()
	return nil
}

// SetupRoutes configure les routes HTTP
func (t *MemoryStatusTracker) SetupRoutes(router *gin.Engine) {
	statusGroup := router.Group("/api/v1/status")
	{
		statusGroup.GET("/:workflow_id", t.getStatusHandler)
		statusGroup.PUT("/:workflow_id", t.updateStatusHandler)
		statusGroup.DELETE("/:workflow_id", t.deleteStatusHandler)
		statusGroup.GET("", t.listStatusesHandler)
		statusGroup.GET("/stats", t.getStatsHandler)
	}
}

// GetStats retourne les statistiques
func (t *MemoryStatusTracker) GetStats() StatusTrackerStats {
	t.statsMux.RLock()
	defer t.statsMux.RUnlock()
	return t.stats
}

// Handlers HTTP

func (t *MemoryStatusTracker) getStatusHandler(c *gin.Context) {
	workflowID := c.Param("workflow_id")

	status, err := t.GetStatus(workflowID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "Status not found",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, status)
}

func (t *MemoryStatusTracker) updateStatusHandler(c *gin.Context) {
	workflowID := c.Param("workflow_id")

	var updates StatusUpdate
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request format",
			"message": err.Error(),
		})
		return
	}

	if err := t.UpdateStatus(workflowID, updates); err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "Failed to update status",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Status updated successfully",
	})
}

func (t *MemoryStatusTracker) deleteStatusHandler(c *gin.Context) {
	workflowID := c.Param("workflow_id")

	if err := t.DeleteStatus(workflowID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to delete status",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Status deleted successfully",
	})
}

func (t *MemoryStatusTracker) listStatusesHandler(c *gin.Context) {
	statuses, err := t.ListStatuses()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to list statuses",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"statuses": statuses,
		"count":    len(statuses),
	})
}

func (t *MemoryStatusTracker) getStatsHandler(c *gin.Context) {
	stats := t.GetStats()
	c.JSON(http.StatusOK, stats)
}

// Fonctions privées

func (t *MemoryStatusTracker) cleanupExpiredStatuses() {
	ticker := time.NewTicker(5 * time.Minute) // Nettoyage toutes les 5 minutes
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			t.performCleanup()
		case <-t.ctx.Done():
			return
		}
	}
}

func (t *MemoryStatusTracker) performCleanup() {
	now := time.Now()
	var cleanedCount int64

	t.statusesMux.Lock()
	for workflowID, status := range t.statuses {
		if now.After(status.TTL) {
			delete(t.statuses, workflowID)
			cleanedCount++
		}
	}
	t.statusesMux.Unlock()

	t.statsMux.Lock()
	t.stats.LastCleanup = now
	t.stats.CleanedUp += cleanedCount
	t.statsMux.Unlock()

	if cleanedCount > 0 {
		fmt.Printf("Cleaned up %d expired workflow statuses\n", cleanedCount)
	}
}

func (t *MemoryStatusTracker) updateStats() {
	t.statsMux.Lock()
	defer t.statsMux.Unlock()

	t.statusesMux.RLock()
	defer t.statusesMux.RUnlock()

	t.stats.TotalStatuses = len(t.statuses)

	var active, completed, failed int
	var totalLifetime time.Duration

	for _, status := range t.statuses {
		switch status.Status {
		case "started", "running", "pending":
			active++
		case "completed":
			completed++
		case "failed", "error":
			failed++
		}

		if status.EndTime != nil {
			totalLifetime += status.EndTime.Sub(status.StartTime)
		}
	}

	t.stats.ActiveStatuses = active
	t.stats.CompletedStatuses = completed
	t.stats.FailedStatuses = failed

	if completed+failed > 0 {
		t.stats.AverageLifetime = totalLifetime / time.Duration(completed+failed)
	}
}
