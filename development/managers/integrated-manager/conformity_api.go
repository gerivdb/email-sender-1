// filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\integrated-manager\conformity_api.go
package integratedmanager

import (
	"context"
	"context"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	// "encoding/json" // Used by gin's c.JSON and c.ShouldBindJSON
	// "strconv" // Seems unused
	// "strings" // Seems unused
	// "github.com/google/uuid" // Seems unused
)

// ConformityAPIServer provides REST API endpoints for conformity management
type ConformityAPIServer struct {
	manager *IntegratedErrorManager
	router  *gin.Engine
	server  *http.Server
	port    int
}

// NewConformityAPIServer creates a new conformity API server
func NewConformityAPIServer(manager *IntegratedErrorManager, port int) *ConformityAPIServer {
	gin.SetMode(gin.ReleaseMode)
	router := gin.New()

	// Add middleware
	router.Use(gin.Logger())
	router.Use(gin.Recovery())
	router.Use(corsMiddleware())
	router.Use(authMiddleware())

	server := &ConformityAPIServer{
		manager: manager,
		router:  router,
		port:    port,
	}

	server.setupRoutes()

	return server
}

// setupRoutes configures all API routes
func (s *ConformityAPIServer) setupRoutes() {
	// API version group
	v1 := s.router.Group("/api/conformity")
	{
		// Manager-specific conformity endpoints
		v1.GET("/managers/:name", s.getManagerConformity)
		v1.POST("/managers/:name/verify", s.verifyManagerConformity)
		v1.PUT("/managers/:name/status", s.updateManagerStatus)

		// Ecosystem conformity endpoints
		v1.GET("/ecosystem/status", s.getEcosystemStatus)
		v1.POST("/ecosystem/verify", s.verifyEcosystemConformity)

		// Report generation endpoints
		v1.POST("/reports/generate", s.generateConformityReport)
		v1.GET("/reports/formats", s.getReportFormats)

		// Badge generation endpoints
		v1.GET("/badges/:manager/:type", s.generateConformityBadge)
		v1.GET("/badges/ecosystem/:type", s.generateEcosystemBadge)

		// Configuration endpoints
		v1.GET("/config", s.getConformityConfig)
		v1.PUT("/config", s.updateConformityConfig)

		// Health and metrics endpoints
		v1.GET("/health", s.healthCheck)
		v1.GET("/metrics", s.getMetrics)
	}

	// Documentation endpoint
	s.router.GET("/api/docs/conformity", s.getAPIDocumentation)
}

// corsMiddleware adds CORS headers
func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
		c.Header("Access-Control-Allow-Credentials", "true")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}

// authMiddleware provides basic authentication (can be extended with JWT)
func authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// For now, we'll use a simple API key approach
		// In production, this should be replaced with proper JWT authentication
		apiKey := c.GetHeader("X-API-Key")
		if apiKey == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Unauthorized",
				"message": "API key required",
			})
			c.Abort()
			return
		}

		// Simple validation - in production use proper key validation
		if apiKey != "conformity-api-key-2024" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Unauthorized",
				"message": "Invalid API key",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// getManagerConformity returns conformity status for a specific manager
func (s *ConformityAPIServer) getManagerConformity(c *gin.Context) {
	managerName := c.Param("name")
	if managerName == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Manager name is required",
		})
		return
	}

	s.manager.conformityMu.RLock()
	status, exists := s.manager.managerStatuses[managerName]
	s.manager.conformityMu.RUnlock()

	if !exists {
		// Try to verify conformity if not exists
		report, err := s.manager.conformityManager.VerifyManagerConformity(c.Request.Context(), managerName)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{
				"error":   "Not Found",
				"message": fmt.Sprintf("Manager '%s' not found or conformity check failed", managerName),
				"details": err.Error(),
			})
			return
		}

		status = ConformityStatus{
			Level:           report.ComplianceLevel,
			Score:           report.OverallScore,
			LastCheck:       report.Timestamp,
			Issues:          report.Issues,
			Recommendations: report.Recommendations,
			NextCheck:       time.Now().Add(24 * time.Hour),
		}
	}

	response := gin.H{
		"manager":   managerName,
		"status":    status,
		"timestamp": time.Now(),
	}

	c.JSON(http.StatusOK, response)
}

// verifyManagerConformity performs a new conformity check for a manager
func (s *ConformityAPIServer) verifyManagerConformity(c *gin.Context) {
	managerName := c.Param("name")
	if managerName == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Manager name is required",
		})
		return
	}

	// Perform conformity verification
	report, err := s.manager.conformityManager.VerifyManagerConformity(c.Request.Context(), managerName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to verify manager conformity",
			"details": err.Error(),
		})
		return
	}

	// Update status in manager
	// Assuming local ConformityStatus struct has a field `Level` of type ComplianceLevel
	parsedStatus := ConformityStatus{
		Level:           report.ComplianceLevel,
		Score:           report.OverallScore,
		LastCheck:       report.Timestamp,
		Issues:          report.Issues,
		Recommendations: report.Recommendations,
		NextCheck:       time.Now().Add(24 * time.Hour),
	}

	err = s.manager.conformityManager.UpdateConformityStatus(c.Request.Context(), managerName, parsedStatus.Level)
	if err != nil {
		log.Printf("Failed to update conformity status for manager %s: %v", managerName, err)
	}

	response := gin.H{
		"manager":    managerName,
		"report":     report,
		"status":     parsedStatus,
		"timestamp":  time.Now(),
		"verified":   true,
	}

	c.JSON(http.StatusOK, response)
}

// updateManagerStatus updates the conformity status for a manager
// Note: The ConformityStatus struct bound from JSON here is local to conformity_api.go
// It likely has a 'Level' field of type ComplianceLevel.
func (s *ConformityAPIServer) updateManagerStatus(c *gin.Context) {
	managerName := c.Param("name")
	if managerName == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Manager name is required",
		})
		return
	}

	var status ConformityStatus
	if err := c.ShouldBindJSON(&status); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Invalid status format",
			"details": err.Error(),
		})
		return
	}

	// The manager's UpdateConformityStatus expects a ComplianceLevel, not the whole status struct.
	err := s.manager.conformityManager.UpdateConformityStatus(c.Request.Context(), managerName, status.Level)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to update conformity status",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":   "Status updated successfully",
		"manager":   managerName,
		"status":    status, // Send back the originally parsed status
		"timestamp": time.Now(),
	})
}

// determineComplianceLevelForApi is a helper to get ComplianceLevel from score
// This is needed because EcosystemConformityReport doesn't directly store OverallLevel
func (s *ConformityAPIServer) determineComplianceLevelForAPI(score float64) ComplianceLevel {
	// Attempt to get thresholds from the manager's config
	config := s.manager.conformityManager.GetConformityConfig()
	if config != nil && config.MinimumScores.Platinum > 0 { // Check if config is populated
		thresholds := config.MinimumScores
		if score >= thresholds.Platinum {
			return ComplianceLevelPlatinum
		} else if score >= thresholds.Gold {
			return ComplianceLevelGold
		} else if score >= thresholds.Silver {
			return ComplianceLevelSilver
		} else if score >= thresholds.Bronze {
			return ComplianceLevelBronze
		}
		return ComplianceLevelFailed
	}
	// Fallback to default thresholds if config not available or not set
	if score >= 90 { return ComplianceLevelPlatinum }
	if score >= 80 { return ComplianceLevelGold }
	if score >= 70 { return ComplianceLevelSilver }
	if score >= 60 { return ComplianceLevelBronze }
	return ComplianceLevelFailed
}

// getEcosystemStatus returns overall ecosystem conformity status
func (s *ConformityAPIServer) getEcosystemStatus(c *gin.Context) {
	report, err := s.manager.conformityManager.VerifyEcosystemConformity(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to get ecosystem conformity status",
			"details": err.Error(),
		})
		return
	}

	response := gin.H{
		"ecosystem": report, // report itself
		"timestamp": time.Now(),
		"health":    s.calculateEcosystemHealth(report), // derived health summary
	}

	c.JSON(http.StatusOK, response)
}

// verifyEcosystemConformity performs a new ecosystem conformity check
func (s *ConformityAPIServer) verifyEcosystemConformity(c *gin.Context) {
	report, err := s.manager.conformityManager.VerifyEcosystemConformity(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to verify ecosystem conformity",
			"details": err.Error(),
		})
		return
	}

	// Update last ecosystem check time
	s.manager.conformityMu.Lock()
	s.manager.lastEcosystemCheck = time.Now()
	s.manager.conformityMu.Unlock()

	response := gin.H{
		"ecosystem": report, // report itself
		"timestamp": time.Now(),
		"verified":  true,
		"health":    s.calculateEcosystemHealth(report), // derived health summary
	}

	c.JSON(http.StatusOK, response)
}

// generateConformityReport generates a conformity report in specified format
func (s *ConformityAPIServer) generateConformityReport(c *gin.Context) {
	var request struct {
		Format    string   `json:"format" binding:"required"`
		Managers  []string `json:"managers,omitempty"`
		IncludeDetails bool `json:"include_details,omitempty"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Invalid request format",
			"details": err.Error(),
		})
		return
	}

	// Validate format
	validFormats := []string{"json", "yaml", "html", "pdf", "markdown"}
	isValidFormat := false
	for _, format := range validFormats {
		if request.Format == format {
			isValidFormat = true
			break
		}
	}

	if !isValidFormat {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Invalid format",
			"valid_formats": validFormats,
		})
		return
	}

	var targetManagerName string
	if len(request.Managers) > 0 {
		targetManagerName = request.Managers[0] // Simplification: use the first manager if multiple are provided
	} else {
		// If no specific manager, what should happen?
		// Option 1: Error - manager name is required by current GenerateConformityReport
		// Option 2: Generate ecosystem report (would require a different manager method or logic here)
		// For now, let's assume manager name is required or we use a default/placeholder.
		// This part of API logic might need refinement based on product requirements.
		// If an ecosystem report is desired, we'd fetch EcosystemConformityReport and pass it to reporter.GenerateReport.
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Bad Request",
			"message": "Manager name is required for this report type or use a different endpoint for ecosystem reports.",
		})
		return
	}

	reportData, err := s.manager.conformityManager.GenerateConformityReport(c.Request.Context(), targetManagerName, ReportFormat(request.Format))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to generate conformity report",
			"details": err.Error(),
		})
		return
	}

	// Set appropriate content type based on format
	contentType := s.getContentType(request.Format)
	c.Header("Content-Type", contentType)
	
	// Set filename for download
	filename := fmt.Sprintf("conformity-report-%s.%s", time.Now().Format("2006-01-02"), request.Format)
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%s", filename))

	c.Data(http.StatusOK, contentType, reportData)
}

// getReportFormats returns available report formats
func (s *ConformityAPIServer) getReportFormats(c *gin.Context) {
	formats := []gin.H{
		{"format": "json", "description": "JavaScript Object Notation", "mime_type": "application/json"},
		{"format": "yaml", "description": "YAML Ain't Markup Language", "mime_type": "application/x-yaml"},
		{"format": "html", "description": "HyperText Markup Language", "mime_type": "text/html"},
		{"format": "pdf", "description": "Portable Document Format", "mime_type": "application/pdf"},
		{"format": "markdown", "description": "Markdown Documentation", "mime_type": "text/markdown"},
	}

	c.JSON(http.StatusOK, gin.H{
		"formats":   formats,
		"timestamp": time.Now(),
	})
}

// generateConformityBadge generates a conformity badge for a specific manager
func (s *ConformityAPIServer) generateConformityBadge(c *gin.Context) {
	managerName := c.Param("manager")
	badgeType := c.Param("type")

	if managerName == "" || badgeType == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Manager name and badge type are required",
		})
		return
	}

	// Get manager status
	s.manager.conformityMu.RLock()
	status, exists := s.manager.managerStatuses[managerName]
	s.manager.conformityMu.RUnlock()

	if !exists {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "Not Found",
			"message": fmt.Sprintf("Manager '%s' not found", managerName),
		})
		return
	}

	badge, err := s.generateBadgeContent(managerName, badgeType, status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to generate badge",
			"details": err.Error(),
		})
		return
	}

	// Set SVG content type for badge
	c.Header("Content-Type", "image/svg+xml")
	c.Header("Cache-Control", "max-age=300") // 5 minutes cache
	c.String(http.StatusOK, badge)
}

// generateEcosystemBadge generates a conformity badge for the entire ecosystem
func (s *ConformityAPIServer) generateEcosystemBadge(c *gin.Context) {
	badgeType := c.Param("type")

	if badgeType == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Badge type is required",
		})
		return
	}

	// Get ecosystem status
	report, err := s.manager.conformityManager.VerifyEcosystemConformity(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to get ecosystem status",
			"details": err.Error(),
		})
		return
	}

	// Create a status-like structure for badge generation
	// EcosystemConformityReport does not directly have OverallLevel or OverallScore.
	// We use GlobalMetrics.AverageConformityScore and derive the level.
	averageScore := 0.0
	if report.GlobalMetrics != nil {
		averageScore = report.GlobalMetrics.AverageConformityScore
	}
	derivedLevel := s.determineComplianceLevelForAPI(averageScore)

	status := ConformityStatus{ // This is the local API struct, used for badge generation
		Level: derivedLevel,
		Score: averageScore,
	}

	badge, err := s.generateBadgeContent("ecosystem", badgeType, status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to generate ecosystem badge",
			"details": err.Error(),
		})
		return
	}

	// Set SVG content type for badge
	c.Header("Content-Type", "image/svg+xml")
	c.Header("Cache-Control", "max-age=300") // 5 minutes cache
	c.String(http.StatusOK, badge)
}

// getConformityConfig returns the current conformity configuration
func (s *ConformityAPIServer) getConformityConfig(c *gin.Context) {
	config := s.manager.conformityManager.GetConformityConfig()
	if config == nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "Not Found",
			"message": "Conformity configuration not found",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"config":    config,
		"timestamp": time.Now(),
	})
}

// updateConformityConfig updates the conformity configuration
func (s *ConformityAPIServer) updateConformityConfig(c *gin.Context) {
	var config ConformityConfig
	if err := c.ShouldBindJSON(&config); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Invalid configuration format",
			"details": err.Error(),
		})
		return
	}

	s.manager.conformityManager.SetConformityConfig(&config)

	c.JSON(http.StatusOK, gin.H{
		"message":   "Configuration updated successfully",
		"config":    config,
		"timestamp": time.Now(),
	})
}

// healthCheck provides API health status
func (s *ConformityAPIServer) healthCheck(c *gin.Context) {
	health := gin.H{
		"status":     "healthy",
		"timestamp":  time.Now(),
		"version":    "1.0.0",
		"uptime":     time.Since(time.Now()).String(), // This would be actual uptime in production
		"managers":   len(s.manager.managerStatuses),
	}

	// Check if conformity manager is available
	if s.manager.conformityManager != nil {
		health["conformity_manager"] = "available"
	} else {
		health["conformity_manager"] = "unavailable"
		health["status"] = "degraded"
	}

	c.JSON(http.StatusOK, health)
}

// getMetrics provides conformity metrics
func (s *ConformityAPIServer) getMetrics(c *gin.Context) {
	s.manager.conformityMu.RLock()
	defer s.manager.conformityMu.RUnlock()

	var totalScore float64
	var totalManagers int
	levelCounts := make(map[string]int)
	issuesCounts := make(map[string]int)

	for _, status := range s.manager.managerStatuses {
		totalScore += status.Score
		totalManagers++
		levelCounts[string(status.Level)]++
		
		for _, issue := range status.Issues {
			issuesCounts[issue.Severity]++
		}
	}

	averageScore := 0.0
	if totalManagers > 0 {
		averageScore = totalScore / float64(totalManagers)
	}

	metrics := gin.H{
		"timestamp":      time.Now(),
		"total_managers": totalManagers,
		"average_score":  averageScore,
		"level_distribution": levelCounts,
		"issues_by_severity": issuesCounts,
		"last_ecosystem_check": s.manager.lastEcosystemCheck,
	}

	c.JSON(http.StatusOK, metrics)
}

// getAPIDocumentation provides API documentation
func (s *ConformityAPIServer) getAPIDocumentation(c *gin.Context) {
	docs := gin.H{
		"title":       "Conformity Management API",
		"version":     "1.0.0",
		"description": "REST API for managing conformity in the integrated manager ecosystem",
		"base_url":    fmt.Sprintf("http://localhost:%d/api/conformity", s.port),
		"endpoints": []gin.H{
			{
				"path":        "/managers/{name}",
				"method":      "GET",
				"description": "Get conformity status for a specific manager",
			},
			{
				"path":        "/managers/{name}/verify",
				"method":      "POST",
				"description": "Verify conformity for a specific manager",
			},
			{
				"path":        "/ecosystem/status",
				"method":      "GET",
				"description": "Get overall ecosystem conformity status",
			},
			{
				"path":        "/reports/generate",
				"method":      "POST",
				"description": "Generate conformity report in specified format",
			},
			{
				"path":        "/badges/{manager}/{type}",
				"method":      "GET",
				"description": "Generate conformity badge for a manager",
			},
		},
		"authentication": gin.H{
			"type":        "API Key",
			"header":      "X-API-Key",
			"description": "API key required for all endpoints",
		},
	}

	c.JSON(http.StatusOK, docs)
}

// Helper methods

// calculateEcosystemHealth calculates ecosystem health metrics
func (s *ConformityAPIServer) calculateEcosystemHealth(report *EcosystemConformityReport) gin.H {
	// Use GlobalMetrics for score and derive level
	score := 0.0
	if report.GlobalMetrics != nil {
		score = report.GlobalMetrics.AverageConformityScore
	}
	level := s.determineComplianceLevelForAPI(score)

	healthStatusText := "excellent"
	if score < 95 { healthStatusText = "good" }
	if score < 85 { healthStatusText = "fair" }
	if score < 75 { healthStatusText = "poor" }
	if score < 60 { healthStatusText = "critical" }

	return gin.H{
		"status":      healthStatusText,
		"score":       score,
		"level":       level,
		"managers":    report.TotalManagers, // Corrected from ManagerCount
		"timestamp":   report.Timestamp,
	}
}

// getContentType returns appropriate content type for report format
func (s *ConformityAPIServer) getContentType(format string) string {
	switch format {
	case "json":
		return "application/json"
	case "yaml":
		return "application/x-yaml"
	case "html":
		return "text/html"
	case "pdf":
		return "application/pdf"
	case "markdown":
		return "text/markdown"
	default:
		return "application/octet-stream"
	}
}

// generateBadgeContent generates SVG badge content
func (s *ConformityAPIServer) generateBadgeContent(name, badgeType string, status ConformityStatus) (string, error) {
	var color, label, value string

	switch badgeType {
	case "score":
		label = "conformity"
		value = fmt.Sprintf("%.1f%%", status.Score)
		color = s.getScoreColor(status.Score)
	case "level":
		label = "level"
		value = string(status.Level)
		color = s.getLevelColor(status.Level)
	case "status":
		label = "status"
		if len(status.Issues) == 0 {
			value = "passing"
			color = "brightgreen"
		} else {
			value = fmt.Sprintf("%d issues", len(status.Issues))
			color = "red"
		}
	default:
		return "", fmt.Errorf("unsupported badge type: %s", badgeType)
	}

	// Generate simple SVG badge
	svg := fmt.Sprintf(`<svg xmlns="http://www.w3.org/2000/svg" width="104" height="20">
		<linearGradient id="b" x2="0" y2="100%%">
			<stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
			<stop offset="1" stop-opacity=".1"/>
		</linearGradient>
		<mask id="a">
			<rect width="104" height="20" rx="3" fill="#fff"/>
		</mask>
		<g mask="url(#a)">
			<path fill="#555" d="M0 0h63v20H0z"/>
			<path fill="%s" d="M63 0h41v20H63z"/>
			<path fill="url(#b)" d="M0 0h104v20H0z"/>
		</g>
		<g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
			<text x="31.5" y="15" fill="#010101" fill-opacity=".3">%s</text>
			<text x="31.5" y="14">%s</text>
			<text x="82.5" y="15" fill="#010101" fill-opacity=".3">%s</text>
			<text x="82.5" y="14">%s</text>
		</g>
	</svg>`, s.getColorHex(color), label, label, value, value)

	return svg, nil
}

// getScoreColor returns color based on conformity score
func (s *ConformityAPIServer) getScoreColor(score float64) string {
	if score >= 95 {
		return "brightgreen"
	} else if score >= 85 {
		return "green"
	} else if score >= 75 {
		return "yellow"
	} else if score >= 60 {
		return "orange"
	}
	return "red"
}

// getLevelColor returns color based on conformity level
func (s *ConformityAPIServer) getLevelColor(level ComplianceLevel) string {
	switch level {
	case ComplianceLevelPlatinum:
		return "brightgreen"
	case ComplianceLevelGold:
		return "green"
	case ComplianceLevelSilver:
		return "yellow"
	case ComplianceLevelBronze:
		return "orange"
	default:
		return "red"
	}
}

// getColorHex converts color name to hex value
func (s *ConformityAPIServer) getColorHex(color string) string {
	colors := map[string]string{
		"brightgreen": "#4c1",
		"green":       "#97ca00",
		"yellow":      "#dfb317",
		"orange":      "#fe7d37",
		"red":         "#e05d44",
	}
	
	if hex, exists := colors[color]; exists {
		return hex
	}
	return "#9f9f9f" // default gray
}

// Start starts the conformity API server
func (s *ConformityAPIServer) Start() error {
	s.server = &http.Server{
		Addr:    fmt.Sprintf(":%d", s.port),
		Handler: s.router,
	}

	log.Printf("Starting Conformity API Server on port %d", s.port)
	return s.server.ListenAndServe()
}

// StartBackground starts the API server in background
func (s *ConformityAPIServer) StartBackground() error {
	s.server = &http.Server{
		Addr:    fmt.Sprintf(":%d", s.port),
		Handler: s.router,
	}

	go func() {
		log.Printf("Starting Conformity API Server on port %d", s.port)
		if err := s.server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Printf("Conformity API Server error: %v", err)
		}
	}()

	return nil
}

// Stop gracefully stops the API server
func (s *ConformityAPIServer) Stop() error {
	if s.server != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		
		log.Println("Stopping Conformity API Server...")
		return s.server.Shutdown(ctx)
	}
	return nil
}
