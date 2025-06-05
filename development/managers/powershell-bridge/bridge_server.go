// Package bridge implements the PowerShell-Go bridge for ErrorManager integration
// Section 1.4 - Implementation des Recommandations
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"sync"
	"syscall"	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/email-sender/managers/error-manager"
)

// PowerShellError represents an error received from PowerShell
type PowerShellError struct {
	ErrorMessage      string                 `json:"error_message"`
	Component         string                 `json:"component"`
	Context           map[string]interface{} `json:"context"`
	Severity          string                 `json:"severity"`
	Category          string                 `json:"category"`
	ScriptPath        string                 `json:"script_path"`
	Operation         string                 `json:"operation"`
	Timestamp         string                 `json:"timestamp"`
	Source            string                 `json:"source"`
	SessionID         int                    `json:"session_id"`
	User              string                 `json:"user"`
	Machine           string                 `json:"machine"`
}

// PowerShellErrorResponse represents the response sent back to PowerShell
type PowerShellErrorResponse struct {
	Success        bool      `json:"success"`
	ErrorID        string    `json:"error_id"`
	RecoveryAction string    `json:"recovery_action"`
	ProcessedAt    time.Time `json:"processed_at"`
	Message        string    `json:"message"`
}

// BridgeConfig holds configuration for the PowerShell bridge
type BridgeConfig struct {
	Port         int    `json:"port"`
	LogLevel     string `json:"log_level"`
	LogFile      string `json:"log_file"`
	EnableCORS   bool   `json:"enable_cors"`
	ReadTimeout  int    `json:"read_timeout"`
	WriteTimeout int    `json:"write_timeout"`
}

// DefaultBridgeConfig returns default configuration
func DefaultBridgeConfig() BridgeConfig {
	return BridgeConfig{
		Port:         8081,
		LogLevel:     "INFO",
		LogFile:      "./powershell_bridge.log",
		EnableCORS:   true,
		ReadTimeout:  30,
		WriteTimeout: 30,
	}
}

// PowerShellBridge implements the bridge server
type PowerShellBridge struct {
	config       BridgeConfig
	server       *http.Server
	logger       *zap.Logger
	errorManager *ErrorManagerService
	mutex        sync.RWMutex
	stats        BridgeStats
}

// BridgeStats tracks bridge statistics
type BridgeStats struct {
	RequestsProcessed   int64     `json:"requests_processed"`
	ErrorsProcessed     int64     `json:"errors_processed"`
	SuccessfulRequests  int64     `json:"successful_requests"`
	FailedRequests      int64     `json:"failed_requests"`
	StartTime           time.Time `json:"start_time"`
	LastActivityTime    time.Time `json:"last_activity_time"`
}

// ErrorManagerService wraps the ErrorManager for the bridge
type ErrorManagerService struct {
	errorManager *errormanager.ErrorManager
	logger       *zap.Logger
}

// NewErrorManagerService creates a new ErrorManager service
func NewErrorManagerService(logger *zap.Logger) *ErrorManagerService {
	// Initialize a simple ErrorManager for the bridge
	// In a real implementation, this would connect to the actual ErrorManager
	em := &errormanager.ErrorManager{}
	
	return &ErrorManagerService{
		errorManager: em,
		logger:       logger,
	}
}

// ProcessPowerShellError processes an error from PowerShell
func (ems *ErrorManagerService) ProcessPowerShellError(ctx context.Context, psError PowerShellError) (*PowerShellErrorResponse, error) {
	// Create Go error from PowerShell error
	goErr := fmt.Errorf("PowerShell error: %s", psError.ErrorMessage)
	
	// Add PowerShell context to Go context
	ctx = context.WithValue(ctx, "component", psError.Component)
	ctx = context.WithValue(ctx, "powershell_context", psError.Context)
	ctx = context.WithValue(ctx, "severity", psError.Severity)
	ctx = context.WithValue(ctx, "category", psError.Category)
	ctx = context.WithValue(ctx, "script_path", psError.ScriptPath)
	ctx = context.WithValue(ctx, "operation", psError.Operation)
	ctx = context.WithValue(ctx, "source", psError.Source)
	ctx = context.WithValue(ctx, "session_id", psError.SessionID)
	ctx = context.WithValue(ctx, "user", psError.User)
	ctx = context.WithValue(ctx, "machine", psError.Machine)

	// Create error entry for validation and cataloging
	errorEntry := errormanager.ErrorEntry{
		ID:          uuid.New().String(),
		Timestamp:   time.Now(),
		Level:       mapSeverityToLevel(psError.Severity),
		Component:   psError.Component,
		Message:     psError.ErrorMessage,
		Context:     psError.Context,
		Source:      psError.Source,
		Category:    psError.Category,
		Operation:   psError.Operation,
		ScriptPath:  psError.ScriptPath,
		SessionID:   strconv.Itoa(psError.SessionID),
		User:        psError.User,
		Machine:     psError.Machine,
	}

	// Validate error entry
	if err := errormanager.ValidateErrorEntry(errorEntry); err != nil {
		ems.logger.Error("Invalid error entry from PowerShell",
			zap.Error(err),
			zap.String("component", psError.Component),
			zap.String("error_message", psError.ErrorMessage))
		return nil, fmt.Errorf("invalid error entry: %v", err)
	}

	// Catalog the error
	if err := errormanager.CatalogError(errorEntry); err != nil {
		ems.logger.Error("Failed to catalog PowerShell error",
			zap.Error(err),
			zap.String("error_id", errorEntry.ID))
		return nil, fmt.Errorf("failed to catalog error: %v", err)
	}

	// Determine recovery action based on error characteristics
	recoveryAction := determineRecoveryAction(psError)

	// Log successful processing
	ems.logger.Info("Successfully processed PowerShell error",
		zap.String("error_id", errorEntry.ID),
		zap.String("component", psError.Component),
		zap.String("severity", psError.Severity),
		zap.String("recovery_action", recoveryAction))

	return &PowerShellErrorResponse{
		Success:        true,
		ErrorID:        errorEntry.ID,
		RecoveryAction: recoveryAction,
		ProcessedAt:    time.Now(),
		Message:        "Error processed successfully by ErrorManager bridge",
	}, nil
}

// NewPowerShellBridge creates a new PowerShell bridge
func NewPowerShellBridge(config BridgeConfig) (*PowerShellBridge, error) {
	// Setup logger
	logConfig := zap.NewProductionConfig()
	logConfig.Level = zap.NewAtomicLevelAt(parseLogLevel(config.LogLevel))
	logConfig.OutputPaths = []string{"stdout", config.LogFile}
	
	logger, err := logConfig.Build()
	if err != nil {
		return nil, fmt.Errorf("failed to create logger: %v", err)
	}

	// Create ErrorManager service
	errorManagerService := NewErrorManagerService(logger)

	bridge := &PowerShellBridge{
		config:       config,
		logger:       logger,
		errorManager: errorManagerService,
		stats: BridgeStats{
			StartTime: time.Now(),
		},
	}

	// Setup HTTP server
	bridge.setupHTTPServer()

	return bridge, nil
}

// setupHTTPServer configures the HTTP server
func (pb *PowerShellBridge) setupHTTPServer() {
	mux := http.NewServeMux()

	// Error processing endpoint
	mux.HandleFunc("/api/v1/errors", pb.handleErrors)

	// Health check endpoint
	mux.HandleFunc("/api/v1/health", pb.handleHealth)

	// Statistics endpoint
	mux.HandleFunc("/api/v1/stats", pb.handleStats)

	// Add CORS middleware if enabled
	var handler http.Handler = mux
	if pb.config.EnableCORS {
		handler = pb.corsMiddleware(mux)
	}

	// Add logging middleware
	handler = pb.loggingMiddleware(handler)

	pb.server = &http.Server{
		Addr:         fmt.Sprintf(":%d", pb.config.Port),
		Handler:      handler,
		ReadTimeout:  time.Duration(pb.config.ReadTimeout) * time.Second,
		WriteTimeout: time.Duration(pb.config.WriteTimeout) * time.Second,
	}
}

// handleErrors processes PowerShell error requests
func (pb *PowerShellBridge) handleErrors(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	pb.updateStats(func(stats *BridgeStats) {
		stats.RequestsProcessed++
		stats.LastActivityTime = time.Now()
	})

	var psError PowerShellError
	if err := json.NewDecoder(r.Body).Decode(&psError); err != nil {
		pb.logger.Error("Invalid JSON in request",
			zap.Error(err),
			zap.String("remote_addr", r.RemoteAddr))
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		pb.updateStats(func(stats *BridgeStats) { stats.FailedRequests++ })
		return
	}

	// Process the error
	response, err := pb.errorManager.ProcessPowerShellError(r.Context(), psError)
	if err != nil {
		pb.logger.Error("Failed to process PowerShell error",
			zap.Error(err),
			zap.String("component", psError.Component))
		http.Error(w, fmt.Sprintf("Error processing: %v", err), http.StatusInternalServerError)
		pb.updateStats(func(stats *BridgeStats) { stats.FailedRequests++ })
		return
	}

	pb.updateStats(func(stats *BridgeStats) {
		stats.ErrorsProcessed++
		stats.SuccessfulRequests++
	})

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(response); err != nil {
		pb.logger.Error("Failed to encode response", zap.Error(err))
	}
}

// handleHealth provides health check information
func (pb *PowerShellBridge) handleHealth(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	health := map[string]interface{}{
		"status":    "ok",
		"service":   "powershell-errormanager-bridge",
		"version":   "1.0.0",
		"timestamp": time.Now().Format(time.RFC3339),
		"uptime":    time.Since(pb.stats.StartTime).String(),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(health)
}

// handleStats provides bridge statistics
func (pb *PowerShellBridge) handleStats(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	pb.mutex.RLock()
	stats := pb.stats
	pb.mutex.RUnlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(stats)
}

// corsMiddleware adds CORS headers
func (pb *PowerShellBridge) corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// loggingMiddleware logs HTTP requests
func (pb *PowerShellBridge) loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		
		// Create a response writer that captures status code
		rw := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}
		
		next.ServeHTTP(rw, r)
		
		duration := time.Since(start)
		
		pb.logger.Info("HTTP request",
			zap.String("method", r.Method),
			zap.String("path", r.URL.Path),
			zap.String("remote_addr", r.RemoteAddr),
			zap.Int("status_code", rw.statusCode),
			zap.Duration("duration", duration))
	})
}

// responseWriter wraps http.ResponseWriter to capture status code
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// updateStats safely updates bridge statistics
func (pb *PowerShellBridge) updateStats(updateFunc func(*BridgeStats)) {
	pb.mutex.Lock()
	defer pb.mutex.Unlock()
	updateFunc(&pb.stats)
}

// Start starts the PowerShell bridge server
func (pb *PowerShellBridge) Start() error {
	pb.logger.Info("Starting PowerShell ErrorManager bridge",
		zap.Int("port", pb.config.Port),
		zap.String("log_level", pb.config.LogLevel))

	return pb.server.ListenAndServe()
}

// Stop gracefully stops the PowerShell bridge server
func (pb *PowerShellBridge) Stop(ctx context.Context) error {
	pb.logger.Info("Stopping PowerShell ErrorManager bridge")
	return pb.server.Shutdown(ctx)
}

// Helper functions

func mapSeverityToLevel(severity string) string {
	switch severity {
	case "LOW":
		return "INFO"
	case "MEDIUM":
		return "WARN"
	case "HIGH":
		return "ERROR"
	case "CRITICAL":
		return "FATAL"
	default:
		return "INFO"
	}
}

func parseLogLevel(level string) zap.AtomicLevel {
	switch level {
	case "DEBUG":
		return zap.NewAtomicLevelAt(zap.DebugLevel)
	case "INFO":
		return zap.NewAtomicLevelAt(zap.InfoLevel)
	case "WARN":
		return zap.NewAtomicLevelAt(zap.WarnLevel)
	case "ERROR":
		return zap.NewAtomicLevelAt(zap.ErrorLevel)
	default:
		return zap.NewAtomicLevelAt(zap.InfoLevel)
	}
}

func determineRecoveryAction(psError PowerShellError) string {
	// Simple recovery action determination based on error characteristics
	switch psError.Category {
	case "DATABASE":
		return "retry_with_backoff"
	case "NETWORK":
		return "check_connectivity"
	case "FILE_SYSTEM":
		return "verify_permissions"
	case "AUTHENTICATION":
		return "refresh_credentials"
	case "CONFIGURATION":
		return "validate_config"
	default:
		if psError.Severity == "CRITICAL" {
			return "escalate_to_admin"
		}
		return "manual_investigation"
	}
}

// Main function
func main() {
	// Load configuration (from environment variables or config file)
	config := DefaultBridgeConfig()
	
	// Override with environment variables if present
	if port := os.Getenv("BRIDGE_PORT"); port != "" {
		if p, err := strconv.Atoi(port); err == nil {
			config.Port = p
		}
	}
	
	if logLevel := os.Getenv("BRIDGE_LOG_LEVEL"); logLevel != "" {
		config.LogLevel = logLevel
	}
	
	if logFile := os.Getenv("BRIDGE_LOG_FILE"); logFile != "" {
		config.LogFile = logFile
	}

	// Create and start bridge
	bridge, err := NewPowerShellBridge(config)
	if err != nil {
		log.Fatalf("Failed to create PowerShell bridge: %v", err)
	}

	// Setup graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		if err := bridge.Start(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start bridge server: %v", err)
		}
	}()

	// Wait for shutdown signal
	<-sigChan
	
	// Graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	
	if err := bridge.Stop(ctx); err != nil {
		log.Printf("Error during shutdown: %v", err)
	}
	
	log.Println("PowerShell ErrorManager bridge stopped")
}
