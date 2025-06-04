// Package bridges implementes the real-time monitoring bridge for Section 8.2
// "Optimisation Surveillance Temps Réel" of plan-dev-v42-error-manager.md
package bridges

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/fsnotify/fsnotify"
)

// RealtimeEvent represents a real-time file system event
type RealtimeEvent struct {
	Type       string                 `json:"type"`        // "file_change", "duplication_alert", "error_detected"
	Source     string                 `json:"source"`      // File path or source identifier
	Timestamp  time.Time              `json:"timestamp"`   // Event timestamp
	Severity   string                 `json:"severity"`    // "low", "medium", "high", "critical"
	Message    string                 `json:"message"`     // Human-readable description
	Metadata   map[string]interface{} `json:"metadata"`    // Additional context
	ScriptType string                 `json:"script_type"` // "powershell", "go", "python", etc.
}

// RealtimeBridgeConfig holds configuration for the real-time bridge
type RealtimeBridgeConfig struct {
	HTTPPort         int      `json:"http_port"`          // Port for HTTP server
	WatchPaths       []string `json:"watch_paths"`        // Paths to monitor
	DebounceMs       int      `json:"debounce_ms"`        // Debounce delay in milliseconds
	MaxEvents        int      `json:"max_events"`         // Maximum events to buffer
	LogFilePath      string   `json:"log_file_path"`      // Path to log file
	EnableFileWatch  bool     `json:"enable_file_watch"`  // Enable file system watching
	EnableHTTPServer bool     `json:"enable_http_server"` // Enable HTTP event receiver
}

// DefaultRealtimeBridgeConfig returns default configuration
func DefaultRealtimeBridgeConfig() RealtimeBridgeConfig {
	return RealtimeBridgeConfig{
		HTTPPort:         8080,
		WatchPaths:       []string{"./development", "./src", "./scripts"},
		DebounceMs:       500,
		MaxEvents:        1000,
		LogFilePath:      "./realtime_bridge.log",
		EnableFileWatch:  true,
		EnableHTTPServer: true,
	}
}

// RealtimeBridge implements real-time monitoring capabilities
type RealtimeBridge struct {
	config      RealtimeBridgeConfig
	watcher     *fsnotify.Watcher
	httpServer  *http.Server
	eventBuffer []RealtimeEvent
	mutex       sync.RWMutex
	ctx         context.Context
	cancel      context.CancelFunc
	logger      *log.Logger
	eventCount  int64
}

// NewRealtimeBridge creates a new real-time bridge instance
func NewRealtimeBridge(config RealtimeBridgeConfig) (*RealtimeBridge, error) {
	ctx, cancel := context.WithCancel(context.Background())

	// Setup logger
	logFile, err := os.OpenFile(config.LogFilePath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		return nil, fmt.Errorf("failed to open log file: %v", err)
	}

	logger := log.New(io.MultiWriter(os.Stdout, logFile), "[RealtimeBridge] ", log.LstdFlags|log.Lshortfile)

	// Initialize file system watcher if enabled
	var watcher *fsnotify.Watcher
	if config.EnableFileWatch {
		watcher, err = fsnotify.NewWatcher()
		if err != nil {
			cancel()
			return nil, fmt.Errorf("failed to create file watcher: %v", err)
		}
	}

	bridge := &RealtimeBridge{
		config:      config,
		watcher:     watcher,
		eventBuffer: make([]RealtimeEvent, 0, config.MaxEvents),
		ctx:         ctx,
		cancel:      cancel,
		logger:      logger,
	}

	// Setup HTTP server if enabled
	if config.EnableHTTPServer {
		bridge.setupHTTPServer()
	}

	return bridge, nil
}

// Start initiates the real-time monitoring
func (rb *RealtimeBridge) Start() error {
	rb.logger.Println("Starting Real-time Bridge...")

	// Start file system watching
	if rb.config.EnableFileWatch && rb.watcher != nil {
		if err := rb.startFileWatching(); err != nil {
			return fmt.Errorf("failed to start file watching: %v", err)
		}
	}

	// Start HTTP server
	if rb.config.EnableHTTPServer && rb.httpServer != nil {
		go func() {
			rb.logger.Printf("Starting HTTP server on port %d...", rb.config.HTTPPort)
			if err := rb.httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
				rb.logger.Printf("HTTP server error: %v", err)
			}
		}()
	}

	// Process events
	go rb.processEvents()

	rb.logger.Println("Real-time Bridge started successfully")
	return nil
}

// Stop gracefully stops the real-time bridge
func (rb *RealtimeBridge) Stop() error {
	rb.logger.Println("Stopping Real-time Bridge...")

	rb.cancel()

	// Close file watcher
	if rb.watcher != nil {
		if err := rb.watcher.Close(); err != nil {
			rb.logger.Printf("Error closing file watcher: %v", err)
		}
	}

	// Shutdown HTTP server
	if rb.httpServer != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := rb.httpServer.Shutdown(ctx); err != nil {
			rb.logger.Printf("Error shutting down HTTP server: %v", err)
		}
	}

	rb.logger.Println("Real-time Bridge stopped")
	return nil
}

// setupHTTPServer configures the HTTP server for receiving PowerShell events
func (rb *RealtimeBridge) setupHTTPServer() {
	mux := http.NewServeMux()

	// Event receiver endpoint
	mux.HandleFunc("/events", rb.handleEvents)

	// Health check endpoint
	mux.HandleFunc("/health", rb.handleHealth)

	// Status endpoint
	mux.HandleFunc("/status", rb.handleStatus)

	rb.httpServer = &http.Server{
		Addr:    fmt.Sprintf(":%d", rb.config.HTTPPort),
		Handler: mux,
	}
}

// handleEvents processes HTTP POST events from PowerShell scripts
func (rb *RealtimeBridge) handleEvents(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var event RealtimeEvent
	if err := json.NewDecoder(r.Body).Decode(&event); err != nil {
		rb.logger.Printf("Error decoding event: %v", err)
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Set timestamp if not provided
	if event.Timestamp.IsZero() {
		event.Timestamp = time.Now()
	}

	// Add to event buffer
	rb.addEvent(event)

	rb.logger.Printf("Received event: Type=%s, Source=%s, Severity=%s",
		event.Type, event.Source, event.Severity)

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "accepted"})
}

// handleHealth provides health check endpoint
func (rb *RealtimeBridge) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":      "healthy",
		"timestamp":   time.Now(),
		"event_count": rb.eventCount,
	})
}

// handleStatus provides detailed status information
func (rb *RealtimeBridge) handleStatus(w http.ResponseWriter, r *http.Request) {
	rb.mutex.RLock()
	defer rb.mutex.RUnlock()

	status := map[string]interface{}{
		"config":          rb.config,
		"event_count":     rb.eventCount,
		"buffer_size":     len(rb.eventBuffer),
		"buffer_capacity": cap(rb.eventBuffer),
		"uptime":          time.Since(time.Now().Add(-time.Duration(rb.eventCount) * time.Second)),
		"file_watching":   rb.config.EnableFileWatch && rb.watcher != nil,
		"http_server":     rb.config.EnableHTTPServer,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(status)
}

// startFileWatching configures and starts file system monitoring
func (rb *RealtimeBridge) startFileWatching() error {
	for _, path := range rb.config.WatchPaths {
		// Check if path exists
		if _, err := os.Stat(path); os.IsNotExist(err) {
			rb.logger.Printf("Warning: Watch path does not exist: %s", path)
			continue
		}

		// Add path to watcher
		if err := rb.addWatchPath(path); err != nil {
			rb.logger.Printf("Error adding watch path %s: %v", path, err)
			continue
		}

		rb.logger.Printf("Added watch path: %s", path)
	}

	// Start watching for events
	go rb.watchFileEvents()

	return nil
}

// addWatchPath recursively adds a path to the file watcher
func (rb *RealtimeBridge) addWatchPath(root string) error {
	return filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Only watch directories and specific file types
		if info.IsDir() {
			return rb.watcher.Add(path)
		}

		// Watch specific file extensions
		ext := filepath.Ext(path)
		watchableExts := []string{".go", ".ps1", ".py", ".js", ".ts", ".md", ".yml", ".yaml", ".json"}
		for _, watchExt := range watchableExts {
			if ext == watchExt {
				return rb.watcher.Add(path)
			}
		}

		return nil
	})
}

// watchFileEvents processes file system events
func (rb *RealtimeBridge) watchFileEvents() {
	debounceTimer := make(map[string]*time.Timer)

	for {
		select {
		case event, ok := <-rb.watcher.Events:
			if !ok {
				return
			}

			// Debounce rapid file changes
			if timer, exists := debounceTimer[event.Name]; exists {
				timer.Stop()
			}

			debounceTimer[event.Name] = time.AfterFunc(
				time.Duration(rb.config.DebounceMs)*time.Millisecond,
				func() {
					rb.handleFileEvent(event)
					delete(debounceTimer, event.Name)
				},
			)

		case err, ok := <-rb.watcher.Errors:
			if !ok {
				return
			}
			rb.logger.Printf("File watcher error: %v", err)

		case <-rb.ctx.Done():
			return
		}
	}
}

// handleFileEvent processes individual file system events
func (rb *RealtimeBridge) handleFileEvent(event fsnotify.Event) {
	var eventType, severity string

	// Determine event type and severity
	switch {
	case event.Op&fsnotify.Write == fsnotify.Write:
		eventType = "file_change"
		severity = "medium"
	case event.Op&fsnotify.Create == fsnotify.Create:
		eventType = "file_created"
		severity = "low"
	case event.Op&fsnotify.Remove == fsnotify.Remove:
		eventType = "file_deleted"
		severity = "high"
	case event.Op&fsnotify.Rename == fsnotify.Rename:
		eventType = "file_renamed"
		severity = "medium"
	case event.Op&fsnotify.Chmod == fsnotify.Chmod:
		eventType = "file_permissions"
		severity = "low"
	default:
		eventType = "file_unknown"
		severity = "low"
	}

	// Determine script type
	scriptType := "unknown"
	ext := filepath.Ext(event.Name)
	switch ext {
	case ".go":
		scriptType = "go"
	case ".ps1":
		scriptType = "powershell"
	case ".py":
		scriptType = "python"
	case ".js":
		scriptType = "javascript"
	case ".ts":
		scriptType = "typescript"
	}

	realtimeEvent := RealtimeEvent{
		Type:       eventType,
		Source:     event.Name,
		Timestamp:  time.Now(),
		Severity:   severity,
		Message:    fmt.Sprintf("File %s: %s", event.Name, event.Op.String()),
		ScriptType: scriptType,
		Metadata: map[string]interface{}{
			"operation":  event.Op.String(),
			"file_ext":   ext,
			"watch_path": filepath.Dir(event.Name),
		},
	}

	rb.addEvent(realtimeEvent)
}

// addEvent adds an event to the buffer with thread safety
func (rb *RealtimeBridge) addEvent(event RealtimeEvent) {
	rb.mutex.Lock()
	defer rb.mutex.Unlock()

	// Check buffer capacity
	if len(rb.eventBuffer) >= rb.config.MaxEvents {
		// Remove oldest event
		rb.eventBuffer = rb.eventBuffer[1:]
	}

	rb.eventBuffer = append(rb.eventBuffer, event)
	rb.eventCount++
}

// processEvents handles the processing of collected events
func (rb *RealtimeBridge) processEvents() {
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			rb.processEventBatch()
		case <-rb.ctx.Done():
			return
		}
	}
}

// processEventBatch processes accumulated events
func (rb *RealtimeBridge) processEventBatch() {
	rb.mutex.RLock()
	events := make([]RealtimeEvent, len(rb.eventBuffer))
	copy(events, rb.eventBuffer)
	rb.mutex.RUnlock()

	if len(events) == 0 {
		return
	}

	// Analyze events for patterns
	patterns := rb.analyzeEventPatterns(events)

	// Log significant patterns
	for pattern, count := range patterns {
		if count > 3 { // Threshold for significant activity
			rb.logger.Printf("Detected pattern: %s (count: %d)", pattern, count)
		}
	}

	// Integration point for ErrorManager
	// This would typically send events to the main error management system
	rb.integrateWithErrorManager(events)
}

// analyzeEventPatterns identifies patterns in recent events
func (rb *RealtimeBridge) analyzeEventPatterns(events []RealtimeEvent) map[string]int {
	patterns := make(map[string]int)

	for _, event := range events {
		// Pattern: script type + event type
		pattern := fmt.Sprintf("%s_%s", event.ScriptType, event.Type)
		patterns[pattern]++

		// Pattern: severity level
		severityPattern := fmt.Sprintf("severity_%s", event.Severity)
		patterns[severityPattern]++

		// Pattern: directory activity
		dir := filepath.Dir(event.Source)
		dirPattern := fmt.Sprintf("dir_%s", filepath.Base(dir))
		patterns[dirPattern]++
	}

	return patterns
}

// integrateWithErrorManager sends events to the main error management system
func (rb *RealtimeBridge) integrateWithErrorManager(events []RealtimeEvent) {
	// This is the integration point with the main ErrorManager
	// In a full implementation, this would:
	// 1. Transform events to ErrorManager format
	// 2. Send via API or direct function calls
	// 3. Trigger duplicate detection if needed
	// 4. Update monitoring dashboards

	for _, event := range events {
		if event.Severity == "high" || event.Severity == "critical" {
			rb.logger.Printf("High-priority event requiring attention: %s - %s",
				event.Type, event.Message)
		}
	}
}

// GetEvents returns current event buffer (for testing/monitoring)
func (rb *RealtimeBridge) GetEvents() []RealtimeEvent {
	rb.mutex.RLock()
	defer rb.mutex.RUnlock()

	events := make([]RealtimeEvent, len(rb.eventBuffer))
	copy(events, rb.eventBuffer)
	return events
}

// GetEventCount returns total number of events processed
func (rb *RealtimeBridge) GetEventCount() int64 {
	rb.mutex.RLock()
	defer rb.mutex.RUnlock()
	return rb.eventCount
}

// ClearEvents clears the event buffer
func (rb *RealtimeBridge) ClearEvents() {
	rb.mutex.Lock()
	defer rb.mutex.Unlock()
	rb.eventBuffer = rb.eventBuffer[:0]
}
