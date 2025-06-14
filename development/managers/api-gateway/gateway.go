package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"go.uber.org/zap"
	"golang.org/x/time/rate"
)

// ManagerInterface définit l'interface commune pour tous les managers
type ManagerInterface interface {
	Initialize(ctx context.Context, config interface{}) error
	Start(ctx context.Context) error
	Stop(ctx context.Context) error
	GetStatus() map[string]interface{}
	GetMetrics() map[string]interface{}
	ValidateConfig(config interface{}) error
	GetID() string
	GetName() string
	GetVersion() string
	Health(ctx context.Context) error
}

// APIGateway centralise tous les endpoints de l'écosystème
type APIGateway struct {
	managers    map[string]ManagerInterface
	router      *gin.Engine
	logger      *zap.Logger
	rateLimiter *rate.Limiter
	server      *http.Server
}

// NewAPIGateway crée une nouvelle instance de la gateway API
func NewAPIGateway(logger *zap.Logger) *APIGateway {
	gin.SetMode(gin.ReleaseMode)
	router := gin.New()
	router.Use(gin.Recovery())

	return &APIGateway{
		managers:    make(map[string]ManagerInterface),
		router:      router,
		logger:      logger,
		rateLimiter: rate.NewLimiter(1000, 100), // 1000 req/s, burst 100
	}
}

// RegisterManager enregistre un manager dans la gateway
func (ag *APIGateway) RegisterManager(name string, manager ManagerInterface) {
	ag.managers[name] = manager
	ag.logger.Info("Manager registered", zap.String("name", name))
}

// SetupRoutes configure tous les endpoints de l'API
func (ag *APIGateway) SetupRoutes() {
	// Middleware global
	ag.router.Use(ag.corsMiddleware())
	ag.router.Use(ag.rateLimitMiddleware())
	ag.router.Use(ag.loggingMiddleware())
	ag.router.Use(ag.authMiddleware())

	// Routes de santé
	ag.router.GET("/health", ag.healthCheck)
	ag.router.GET("/ready", ag.readinessCheck)

	// Documentation Swagger
	ag.router.GET("/docs/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// API v1
	v1 := ag.router.Group("/api/v1")
	{
		// Gestion des managers
		v1.GET("/managers", ag.listManagers)
		v1.GET("/managers/:name/status", ag.getManagerStatus)
		v1.POST("/managers/:name/action", ag.executeManagerAction)
		v1.GET("/managers/:name/metrics", ag.getManagerMetrics)

		// Routes spécialisées pour les vecteurs
		vectors := v1.Group("/vectors")
		{
			vectors.POST("/search", ag.searchVectors)
			vectors.POST("/upsert", ag.upsertVectors)
			vectors.GET("/list", ag.listVectors)
			vectors.DELETE("/:id", ag.deleteVector)
		}

		// Routes de configuration
		config := v1.Group("/config")
		{
			config.GET("/:key", ag.getConfig)
			config.POST("/:key", ag.setConfig)
			config.GET("/", ag.getAllConfigs)
		}

		// Routes d'événements
		events := v1.Group("/events")
		{
			events.GET("/", ag.getEvents)
			events.POST("/", ag.publishEvent)
			events.GET("/subscribe/:topic", ag.subscribeToEvents)
		}

		// Routes de monitoring
		monitoring := v1.Group("/monitoring")
		{
			monitoring.GET("/status", ag.getSystemStatus)
			monitoring.GET("/metrics", ag.getSystemMetrics)
			monitoring.GET("/performance", ag.getPerformanceMetrics)
		}
	}
}

// Start démarre le serveur API Gateway
func (ag *APIGateway) Start(ctx context.Context, port int) error {
	ag.SetupRoutes()

	ag.server = &http.Server{
		Addr:    ":" + strconv.Itoa(port),
		Handler: ag.router,
	}

	ag.logger.Info("Starting API Gateway", zap.Int("port", port))

	go func() {
		if err := ag.server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			ag.logger.Error("API Gateway server error", zap.Error(err))
		}
	}()

	return nil
}

// Stop arrête le serveur API Gateway
func (ag *APIGateway) Stop(ctx context.Context) error {
	if ag.server != nil {
		ag.logger.Info("Stopping API Gateway")
		return ag.server.Shutdown(ctx)
	}
	return nil
}

// Middleware CORS
func (ag *APIGateway) corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Accept, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}

// Middleware de limitation de taux
func (ag *APIGateway) rateLimitMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !ag.rateLimiter.Allow() {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":   "Rate limit exceeded",
				"message": "Too many requests, please try again later",
			})
			c.Abort()
			return
		}
		c.Next()
	}
}

// Middleware de logging
func (ag *APIGateway) loggingMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		raw := c.Request.URL.RawQuery

		c.Next()

		latency := time.Since(start)
		clientIP := c.ClientIP()
		method := c.Request.Method
		statusCode := c.Writer.Status()

		if raw != "" {
			path = path + "?" + raw
		}

		ag.logger.Info("API Request",
			zap.Int("status", statusCode),
			zap.String("method", method),
			zap.String("path", path),
			zap.String("ip", clientIP),
			zap.Duration("latency", latency),
		)
	}
}

// Middleware d'authentification (basique pour le moment)
func (ag *APIGateway) authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Pour l'instant, authentification simple par header
		authHeader := c.GetHeader("Authorization")

		// Skip auth pour les endpoints publics
		if c.Request.URL.Path == "/health" ||
			c.Request.URL.Path == "/ready" ||
			c.Request.URL.Path == "/docs" {
			c.Next()
			return
		}

		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Authorization header required",
			})
			c.Abort()
			return
		}

		// Validation simple du token (à améliorer en production)
		if authHeader != "Bearer valid-token" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Invalid authorization token",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

func main() {
	logger, _ := zap.NewProduction()
	defer logger.Sync()

	gateway := NewAPIGateway(logger)

	// Start the server
	logger.Info("Starting API Gateway on :8080")
	if err := gateway.Start(context.Background(), 8080); err != nil {
		logger.Fatal("Failed to start API Gateway", zap.Error(err))
	}

	// Wait for interrupt signal to gracefully shutdown the server
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
	<-sigChan

	logger.Info("Shutting down API Gateway")
	if err := gateway.Stop(context.Background()); err != nil {
		logger.Fatal("Failed to stop API Gateway", zap.Error(err))
	}

	logger.Info("API Gateway stopped")
}
