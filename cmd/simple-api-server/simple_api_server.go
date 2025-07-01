package simple_api_server

import (
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// Simple health response
type HealthResponse struct {
	Status		string		`json:"status"`
	Timestamp	time.Time	`json:"timestamp"`
	Service		string		`json:"service"`
	Version		string		`json:"version"`
}

// Status response
type StatusResponse struct {
	APIServer	string			`json:"api_server"`
	Services	map[string]string	`json:"services"`
	Uptime		string			`json:"uptime"`
	Timestamp	time.Time		`json:"timestamp"`
}

// ServiceInfo represents service information
type ServiceInfo struct {
	Status	string	`json:"status"`
	Health	string	`json:"health"`
}

// InfrastructureStatusResponse for infrastructure status
type InfrastructureStatusResponse struct {
	Overall			string			`json:"overall"`
	Active			bool			`json:"active"`
	AutoHealingEnabled	bool			`json:"auto_healing_enabled"`
	ServicesMonitored	int			`json:"services_monitored"`
	Services		map[string]ServiceInfo	`json:"services"`
	Timestamp		time.Time		`json:"timestamp"`
}

// MonitoringStatusResponse for monitoring status
type MonitoringStatusResponse struct {
	Overall			string		`json:"overall"`
	Active			bool		`json:"active"`
	AutoHealingEnabled	bool		`json:"auto_healing_enabled"`
	ServicesMonitored	int		`json:"services_monitored"`
	Timestamp		time.Time	`json:"timestamp"`
}

// AutoHealingResponse for auto-healing operations
type AutoHealingResponse struct {
	Status		string		`json:"status"`
	Enabled		bool		`json:"enabled"`
	Message		string		`json:"message"`
	Timestamp	time.Time	`json:"timestamp"`
}

var startTime = time.Now()

func main() {
	log.Println("🚀 Starting Simple Smart Infrastructure API Server...")

	// Set Gin to release mode for production
	gin.SetMode(gin.ReleaseMode)

	// Create Gin router
	router := gin.New()

	// Add basic middleware
	router.Use(gin.Logger())
	router.Use(gin.Recovery())

	// CORS middleware
	router.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// Health endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, HealthResponse{
			Status:		"healthy",
			Timestamp:	time.Now(),
			Service:	"smart-infrastructure-api",
			Version:	"1.0.0-simple",
		})
	})

	// Status endpoint
	router.GET("/status", func(c *gin.Context) {
		uptime := time.Since(startTime)

		// Simple service checks
		services := map[string]string{
			"api_server":	"running",
			"database":	"unknown",
			"redis":	"unknown",
			"qdrant":	"unknown",
		}

		c.JSON(http.StatusOK, StatusResponse{
			APIServer:	"running",
			Services:	services,
			Uptime:		uptime.String(),
			Timestamp:	time.Now(),
		})
	})

	// Root endpoint
	router.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message":	"Smart Infrastructure API Server",
			"version":	"1.0.0-simple",
			"status":	"running",
			"endpoints": []string{
				"/health",
				"/status",
				"/api/v1/infrastructure",
			},
		})
	})
	// API v1 routes
	v1 := router.Group("/api/v1")
	{
		v1.GET("/infrastructure", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"infrastructure": map[string]interface{}{
					"status":	"operational",
					"services":	[]string{"api", "database", "cache"},
					"uptime":	time.Since(startTime).String(),
					"timestamp":	time.Now(),
				},
			})
		})

		// Endpoint pour l'extension VSCode
		v1.GET("/infrastructure/status", func(c *gin.Context) {
			services := map[string]ServiceInfo{
				"api_server":	{Status: "running", Health: "healthy"},
				"database":	{Status: "unknown", Health: "unknown"},
				"redis":	{Status: "unknown", Health: "unknown"},
				"qdrant":	{Status: "unknown", Health: "unknown"},
			}

			c.JSON(http.StatusOK, InfrastructureStatusResponse{
				Overall:		"healthy",
				Active:			true,
				AutoHealingEnabled:	false,
				ServicesMonitored:	len(services),
				Services:		services,
				Timestamp:		time.Now(),
			})
		})

		// Endpoint monitoring status pour l'extension
		v1.GET("/monitoring/status", func(c *gin.Context) {
			c.JSON(http.StatusOK, MonitoringStatusResponse{
				Overall:		"healthy",
				Active:			true,
				AutoHealingEnabled:	false,
				ServicesMonitored:	4,
				Timestamp:		time.Now(),
			})
		})

		// Endpoints auto-healing pour l'extension
		v1.POST("/auto-healing/enable", func(c *gin.Context) {
			c.JSON(http.StatusOK, AutoHealingResponse{
				Status:		"success",
				Enabled:	true,
				Message:	"Auto-healing enabled",
				Timestamp:	time.Now(),
			})
		})

		v1.POST("/auto-healing/disable", func(c *gin.Context) {
			c.JSON(http.StatusOK, AutoHealingResponse{
				Status:		"success",
				Enabled:	false,
				Message:	"Auto-healing disabled",
				Timestamp:	time.Now(),
			})
		})

		v1.GET("/infrastructure/health", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"overall_health":	"healthy",
				"components": map[string]string{
					"api_server":	"healthy",
					"monitoring":	"healthy",
				},
				"timestamp":	time.Now(),
			})
		})
	}

	// Server configuration
	port := "8080"
	log.Printf("✅ Simple API Server starting on port %s", port)
	log.Printf("📋 Available endpoints:")
	log.Printf("   - http://localhost:%s/health", port)
	log.Printf("   - http://localhost:%s/status", port)
	log.Printf("   - http://localhost:%s/api/v1/infrastructure", port)

	// Start server
	if err := router.Run(":" + port); err != nil {
		log.Fatalf("❌ Failed to start server: %v", err)
	}
}
