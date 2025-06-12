package dashboard

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

// SyncEngine defines the interface for the synchronization engine
type SyncEngine interface {
	GetLastSyncTime() time.Time
	GetActiveSyncs() []string
	GetConflictCount() int
	GetHealthStatus() string
	GetMetrics() *PerformanceMetrics
	GetDivergences() []DivergenceInfo
	GetActiveConflicts() []ConflictInfo
	ResolveConflict(conflictID, resolution, customMerge string) error
	GetSyncHistory(limit int) []SyncHistoryEntry
}

// ConflictInfo represents conflict information from the sync engine
type ConflictInfo struct {
	ID            string
	FilePath      string
	Severity      string
	SourceContent string
	TargetContent string
	Timestamp     time.Time
	Status        string
}

// SyncHistoryEntry represents a sync history entry
type SyncHistoryEntry struct {
	Timestamp time.Time
	Operation string
	Status    string
	Duration  string
	Details   string
}

// SyncDashboard represents the web dashboard for synchronization monitoring
type SyncDashboard struct {
	syncEngine    SyncEngine
	webServer     *gin.Engine
	wsConnections map[string]*websocket.Conn
	logger        *log.Logger
}

// SyncStatus represents the current synchronization status
type SyncStatus struct {
	LastSync           time.Time           `json:"lastSync"`
	ActiveSyncs        []string            `json:"activeSyncs"`
	ConflictCount      int                 `json:"conflictCount"`
	HealthStatus       string              `json:"healthStatus"`
	PerformanceMetrics *PerformanceMetrics `json:"performanceMetrics"`
	Divergences        []DivergenceInfo    `json:"divergences"`
}

// DivergenceInfo represents a detected divergence
type DivergenceInfo struct {
	ID            string    `json:"id"`
	FilePath      string    `json:"filePath"`
	Severity      string    `json:"severity"`
	SourceContent string    `json:"sourceContent"`
	TargetContent string    `json:"targetContent"`
	Timestamp     time.Time `json:"timestamp"`
	Status        string    `json:"status"` // pending, resolved, ignored
}

// PerformanceMetrics represents sync performance data
type PerformanceMetrics struct {
	TotalSyncs  int           `json:"totalSyncs"`
	SuccessRate float64       `json:"successRate"`
	AverageTime time.Duration `json:"averageTime"`
	ErrorCount  int           `json:"errorCount"`
	LastError   string        `json:"lastError"`
}

// ConflictResolutionRequest represents a conflict resolution request
type ConflictResolutionRequest struct {
	ConflictID  string `json:"conflictId"`
	Resolution  string `json:"resolution"` // accept_source, accept_target, merge, custom
	CustomMerge string `json:"customMerge,omitempty"`
}

// WebSocket upgrader
var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins for development
	},
}

// NewSyncDashboard creates a new sync dashboard instance
func NewSyncDashboard(syncEngine SyncEngine, logger *log.Logger) *SyncDashboard {
	gin.SetMode(gin.ReleaseMode)

	dashboard := &SyncDashboard{
		syncEngine:    syncEngine,
		webServer:     gin.New(),
		wsConnections: make(map[string]*websocket.Conn),
		logger:        logger,
	}

	dashboard.setupRoutes()
	dashboard.setupMiddleware()

	return dashboard
}

// setupMiddleware configures the web server middleware
func (sd *SyncDashboard) setupMiddleware() {
	sd.webServer.Use(gin.Recovery())
	sd.webServer.Use(gin.Logger())

	// CORS middleware
	sd.webServer.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})
}

// setupRoutes configures the web server routes
func (sd *SyncDashboard) setupRoutes() {
	// Static files
	sd.webServer.Static("/static", "./web/static")
	sd.webServer.LoadHTMLGlob("web/templates/*")

	// Dashboard routes
	sd.webServer.GET("/", sd.handleDashboard)
	sd.webServer.GET("/api/sync/status", sd.handleSyncStatus)
	sd.webServer.GET("/api/sync/conflicts", sd.handleConflicts)
	sd.webServer.POST("/api/sync/resolve", sd.handleResolveConflict)
	sd.webServer.GET("/api/sync/history", sd.handleSyncHistory)
	sd.webServer.GET("/ws", sd.handleWebSocket)

	// Health check
	sd.webServer.GET("/health", sd.handleHealthCheck)
}

// handleDashboard serves the main dashboard page
func (sd *SyncDashboard) handleDashboard(c *gin.Context) {
	status, err := sd.getCurrentStatus()
	if err != nil {
		sd.logger.Printf("Error getting dashboard status: %v", err)
		c.HTML(http.StatusInternalServerError, "error.html", gin.H{
			"error": "Failed to load dashboard data",
		})
		return
	}

	c.HTML(http.StatusOK, "dashboard.html", gin.H{
		"status":      status,
		"pageTitle":   "Sync Dashboard",
		"currentTime": time.Now().Format("2006-01-02 15:04:05"),
	})
}

// handleSyncStatus returns the current synchronization status as JSON
func (sd *SyncDashboard) handleSyncStatus(c *gin.Context) {
	status, err := sd.getCurrentStatus()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": fmt.Sprintf("Failed to get sync status: %v", err),
		})
		return
	}

	c.JSON(http.StatusOK, status)
}

// handleConflicts returns current conflicts
func (sd *SyncDashboard) handleConflicts(c *gin.Context) {
	conflicts := sd.syncEngine.GetActiveConflicts()

	divergences := make([]DivergenceInfo, len(conflicts))
	for i, conflict := range conflicts {
		divergences[i] = DivergenceInfo{
			ID:            conflict.ID,
			FilePath:      conflict.FilePath,
			Severity:      conflict.Severity,
			SourceContent: conflict.SourceContent,
			TargetContent: conflict.TargetContent,
			Timestamp:     conflict.Timestamp,
			Status:        conflict.Status,
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"conflicts": divergences,
		"count":     len(divergences),
	})
}

// handleResolveConflict processes conflict resolution requests
func (sd *SyncDashboard) handleResolveConflict(c *gin.Context) {
	var request ConflictResolutionRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid request format",
		})
		return
	}

	err := sd.syncEngine.ResolveConflict(request.ConflictID, request.Resolution, request.CustomMerge)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": fmt.Sprintf("Failed to resolve conflict: %v", err),
		})
		return
	}

	// Broadcast update to WebSocket clients
	sd.broadcastUpdate("conflict_resolved", map[string]string{
		"conflictId": request.ConflictID,
		"resolution": request.Resolution,
	})

	c.JSON(http.StatusOK, gin.H{
		"message": "Conflict resolved successfully",
	})
}

// handleSyncHistory returns synchronization history
func (sd *SyncDashboard) handleSyncHistory(c *gin.Context) {
	limit := 50 // Default limit
	if limitParam := c.Query("limit"); limitParam != "" {
		// Parse limit parameter if provided
	}

	history := sd.syncEngine.GetSyncHistory(limit)

	c.JSON(http.StatusOK, gin.H{
		"history": history,
		"count":   len(history),
	})
}

// handleWebSocket handles WebSocket connections for real-time updates
func (sd *SyncDashboard) handleWebSocket(c *gin.Context) {
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		sd.logger.Printf("WebSocket upgrade failed: %v", err)
		return
	}
	defer conn.Close()

	clientID := fmt.Sprintf("client_%d", time.Now().UnixNano())
	sd.wsConnections[clientID] = conn

	sd.logger.Printf("WebSocket client connected: %s", clientID)

	// Send initial status
	status, _ := sd.getCurrentStatus()
	conn.WriteJSON(map[string]interface{}{
		"type": "initial_status",
		"data": status,
	})

	// Keep connection alive and handle messages
	for {
		_, _, err := conn.ReadMessage()
		if err != nil {
			delete(sd.wsConnections, clientID)
			sd.logger.Printf("WebSocket client disconnected: %s", clientID)
			break
		}
	}
}

// handleHealthCheck returns dashboard health status
func (sd *SyncDashboard) handleHealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "healthy",
		"timestamp": time.Now(),
		"uptime":    time.Since(time.Now()), // This would be actual uptime in real implementation
	})
}

// getCurrentStatus retrieves the current synchronization status
func (sd *SyncDashboard) getCurrentStatus() (*SyncStatus, error) {
	return &SyncStatus{
		LastSync:           sd.syncEngine.GetLastSyncTime(),
		ActiveSyncs:        sd.syncEngine.GetActiveSyncs(),
		ConflictCount:      sd.syncEngine.GetConflictCount(),
		HealthStatus:       sd.syncEngine.GetHealthStatus(),
		PerformanceMetrics: sd.syncEngine.GetMetrics(),
		Divergences:        sd.syncEngine.GetDivergences(),
	}, nil
}

// broadcastUpdate sends updates to all connected WebSocket clients
func (sd *SyncDashboard) broadcastUpdate(eventType string, data interface{}) {
	message := map[string]interface{}{
		"type":      eventType,
		"data":      data,
		"timestamp": time.Now(),
	}

	for clientID, conn := range sd.wsConnections {
		err := conn.WriteJSON(message)
		if err != nil {
			sd.logger.Printf("Failed to send WebSocket message to %s: %v", clientID, err)
			delete(sd.wsConnections, clientID)
		}
	}
}

// Start starts the dashboard web server
func (sd *SyncDashboard) Start(port string) error {
	sd.logger.Printf("Starting Sync Dashboard on port %s", port)
	return sd.webServer.Run(":" + port)
}

// Stop gracefully stops the dashboard
func (sd *SyncDashboard) Stop(ctx context.Context) error {
	// Close all WebSocket connections
	for clientID, conn := range sd.wsConnections {
		conn.Close()
		delete(sd.wsConnections, clientID)
	}

	sd.logger.Println("Sync Dashboard stopped")
	return nil
}
