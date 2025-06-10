// development/hooks/commit-interceptor/main.go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/gorilla/mux"
)

type CommitInterceptor struct {
    branchingManager *BranchingManager
    analyzer         *CommitAnalyzer
    router          *BranchRouter
    config          *Config
}

// NewCommitInterceptor creates a new commit interceptor instance
func NewCommitInterceptor() *CommitInterceptor {
    config := LoadConfig()
    
    return &CommitInterceptor{
        branchingManager: NewBranchingManager(config),
        analyzer:         NewCommitAnalyzer(config),
        router:          NewBranchRouter(config),
        config:          config,
    }
}

// HandlePreCommit handles pre-commit webhook events
func (ci *CommitInterceptor) HandlePreCommit(w http.ResponseWriter, r *http.Request) {
    log.Println("Pre-commit hook triggered")
    
    // Parse commit data from request
    commitData, err := ci.parseCommitData(r)
    if err != nil {
        log.Printf("Error parsing commit data: %v", err)
        http.Error(w, "Invalid commit data", http.StatusBadRequest)
        return
    }
    
    // Analyze the commit
    analysis, err := ci.analyzer.AnalyzeCommit(commitData)
    if err != nil {
        log.Printf("Error analyzing commit: %v", err)
        http.Error(w, "Analysis failed", http.StatusInternalServerError)
        return
    }
    
    // Route the commit to appropriate branch
    routingDecision, err := ci.router.RouteCommit(analysis)
    if err != nil {
        log.Printf("Error routing commit: %v", err)
        http.Error(w, "Routing failed", http.StatusInternalServerError)
        return
    }
    
    // Execute the routing decision
    err = ci.branchingManager.ExecuteRouting(routingDecision)
    if err != nil {
        log.Printf("Error executing routing: %v", err)
        http.Error(w, "Execution failed", http.StatusInternalServerError)
        return
    }
    
    log.Printf("Commit successfully routed to: %s", routingDecision.TargetBranch)
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("Commit intercepted and routed successfully"))
}

// HandlePostCommit handles post-commit webhook events
func (ci *CommitInterceptor) HandlePostCommit(w http.ResponseWriter, r *http.Request) {
    log.Println("Post-commit hook triggered")
    
    // Parse commit data
    commitData, err := ci.parseCommitData(r)
    if err != nil {
        log.Printf("Error parsing commit data: %v", err)
        http.Error(w, "Invalid commit data", http.StatusBadRequest)
        return
    }
    
    // Update metrics and logging
    ci.updateMetrics(commitData)
    
    // Send notifications if configured
    if ci.config.NotificationsEnabled {
        go ci.sendNotifications(commitData)
    }
    
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("Post-commit processed"))
}

// parseCommitData extracts commit information from HTTP request
func (ci *CommitInterceptor) parseCommitData(r *http.Request) (*CommitData, error) {
    // Implementation for parsing Git webhook payload
    // This would typically parse JSON payload from Git hooks
    return ParseGitWebhookPayload(r)
}

// updateMetrics updates system metrics with commit data
func (ci *CommitInterceptor) updateMetrics(commitData *CommitData) {
    // Update metrics for monitoring
    log.Printf("Updating metrics for commit: %s", commitData.Hash)
}

// sendNotifications sends notifications about commit processing
func (ci *CommitInterceptor) sendNotifications(commitData *CommitData) {
    // Send notifications to configured channels
    log.Printf("Sending notifications for commit: %s", commitData.Hash)
}

// setupRoutes configures HTTP routes for the interceptor
func (ci *CommitInterceptor) setupRoutes() *mux.Router {
    r := mux.NewRouter()
    
    // Git hook endpoints
    r.HandleFunc("/hooks/pre-commit", ci.HandlePreCommit).Methods("POST")
    r.HandleFunc("/hooks/post-commit", ci.HandlePostCommit).Methods("POST")
    
    // Health check endpoint
    r.HandleFunc("/health", ci.HandleHealth).Methods("GET")
    
    // Metrics endpoint
    r.HandleFunc("/metrics", ci.HandleMetrics).Methods("GET")
    
    return r
}

// HandleHealth provides health check endpoint
func (ci *CommitInterceptor) HandleHealth(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("OK"))
}

// HandleMetrics provides metrics endpoint
func (ci *CommitInterceptor) HandleMetrics(w http.ResponseWriter, r *http.Request) {
    metrics := ci.collectMetrics()
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    w.Write(metrics)
}

// collectMetrics gathers system metrics
func (ci *CommitInterceptor) collectMetrics() []byte {
    // Return JSON metrics
    return []byte(`{"status": "running", "commits_processed": 0}`)
}

func main() {
    log.Println("Starting Commit Interceptor...")
    
    // Initialize interceptor
    interceptor := NewCommitInterceptor()
    
    // Setup HTTP routes
    router := interceptor.setupRoutes()
    
    // Configure server
    srv := &http.Server{
        Addr:         ":8080",
        Handler:      router,
        ReadTimeout:  15 * time.Second,
        WriteTimeout: 15 * time.Second,
    }
    
    // Start server in goroutine
    go func() {
        log.Println("Commit Interceptor démarré sur :8080")
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("Server failed to start: %v", err)
        }
    }()
    
    // Wait for interrupt signal to gracefully shutdown
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit
    
    log.Println("Shutting down server...")
    
    // Graceful shutdown with timeout
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()
    
    if err := srv.Shutdown(ctx); err != nil {
        log.Fatalf("Server forced to shutdown: %v", err)
    }
    
    log.Println("Server stopped")
}