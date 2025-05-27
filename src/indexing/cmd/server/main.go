package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"email_sender/src/indexing"

	"github.com/gorilla/mux"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// IndexingServer handles the web interface and API
type IndexingServer struct {
	config  *indexing.IndexingConfig
	indexer *indexing.BatchIndexer
	metrics *indexing.Metrics
}

// IndexRequest represents an indexing request
type IndexRequest struct {
	Source     string   `json:"source"`
	Files      []string `json:"files,omitempty"`
	Recursive  bool     `json:"recursive"`
	BatchSize  int      `json:"batchSize,omitempty"`
	Concurrent int      `json:"concurrent,omitempty"`
}

// IndexResponse represents the response to an indexing request
type IndexResponse struct {
	JobID     string    `json:"jobId"`
	Status    string    `json:"status"`
	Started   time.Time `json:"started"`
	Files     int       `json:"files"`
	Processed int       `json:"processed"`
	Errors    int       `json:"errors,omitempty"`
}

// ValidationResponse represents the response to a validation request
type ValidationResponse struct {
	Valid        bool     `json:"valid"`
	TotalPoints  int      `json:"totalPoints"`
	Inconsistent []string `json:"inconsistentFiles,omitempty"`
	Errors       []string `json:"errors,omitempty"`
}

// NewIndexingServer creates a new IndexingServer instance
func NewIndexingServer(config *indexing.IndexingConfig) (*IndexingServer, error) {
	metrics := indexing.NewMetrics("indexing")

	if config == nil {
		config = indexing.DefaultConfig()
	}
	indexDir := filepath.Join(config.DataDir, "index")
	if err := os.MkdirAll(indexDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create index directory: %v", err)
	}

	indexer, err := indexing.NewBatchIndexer(indexing.BatchIndexerConfig{
		BatchSize: config.Batch.Size,
		IndexDir:  indexDir,
		Metrics:   metrics,
	})
	if err != nil {
		return nil, err
	}

	return &IndexingServer{
		config:  config,
		indexer: indexer,
		metrics: metrics,
	}, nil
}

// Start starts the HTTP server
func (s *IndexingServer) Start(addr string) error {
	r := mux.NewRouter()

	// API routes
	api := r.PathPrefix("/api").Subrouter()
	api.HandleFunc("/index", s.handleIndex).Methods("POST")
	api.HandleFunc("/jobs/{jobId}", s.handleGetJob).Methods("GET")
	api.HandleFunc("/jobs/{jobId}/cancel", s.handleCancelJob).Methods("POST")
	api.HandleFunc("/validate", s.handleValidate).Methods("POST")
	api.HandleFunc("/stats", s.handleStats).Methods("GET")
	api.HandleFunc("/config", s.handleGetConfig).Methods("GET")
	api.HandleFunc("/config", s.handleUpdateConfig).Methods("PUT")

	// Prometheus metrics
	r.Handle("/metrics", promhttp.Handler())

	// Static files for web interface
	r.PathPrefix("/").Handler(http.FileServer(http.Dir("web")))

	// Start server
	srv := &http.Server{
		Handler:      r,
		Addr:         addr,
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}

	return srv.ListenAndServe()
}

// handleIndex handles requests to start indexing
func (s *IndexingServer) handleIndex(w http.ResponseWriter, r *http.Request) {
	var req IndexRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Validate request
	if req.Source == "" && len(req.Files) == 0 {
		http.Error(w, "source or files must be specified", http.StatusBadRequest)
		return
	}

	// Generate job ID
	jobID := generateJobID()

	// If source directory specified, collect files
	if req.Source != "" {
		files, err := s.collectFiles(req.Source, req.Recursive)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		req.Files = files
	}

	// Start indexing in background
	go s.runIndexingJob(jobID, req)

	// Return initial response
	resp := IndexResponse{
		JobID:   jobID,
		Status:  "started",
		Started: time.Now(),
		Files:   len(req.Files),
	}

	json.NewEncoder(w).Encode(resp)
}

// handleGetJob returns the status of an indexing job
func (s *IndexingServer) handleGetJob(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	jobID := vars["jobId"]

	status, ok := s.getJobStatus(jobID)
	if !ok {
		http.Error(w, "job not found", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(status)
}

// handleCancelJob cancels an ongoing indexing job
func (s *IndexingServer) handleCancelJob(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	jobID := vars["jobId"]

	if err := s.cancelJob(jobID); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// handleValidate validates the indexed documents
func (s *IndexingServer) handleValidate(w http.ResponseWriter, r *http.Request) {
	resp, err := s.validateCollection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(resp)
}

// handleStats returns indexing statistics
func (s *IndexingServer) handleStats(w http.ResponseWriter, r *http.Request) {
	stats := s.getStats()
	json.NewEncoder(w).Encode(stats)
}

// handleGetConfig returns the current configuration
func (s *IndexingServer) handleGetConfig(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(s.config)
}

// handleUpdateConfig updates the configuration
func (s *IndexingServer) handleUpdateConfig(w http.ResponseWriter, r *http.Request) {
	var newConfig indexing.IndexingConfig
	if err := json.NewDecoder(r.Body).Decode(&newConfig); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// We'll use the Validate method from the indexing package directly
	config := &newConfig
	if err := config.Validate(); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	s.config = config
	w.WriteHeader(http.StatusOK)
}

// collectFiles recursively collects files from a directory
func (s *IndexingServer) collectFiles(root string, recursive bool) ([]string, error) {
	var files []string
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			ext := filepath.Ext(path)
			for _, supported := range s.config.FileTypes.SupportedFormats {
				if ext == supported {
					files = append(files, path)
					break
				}
			}
		}
		if !recursive && info.IsDir() && path != root {
			return filepath.SkipDir
		}
		return nil
	})
	return files, err
}

// Helper functions for job management would be implemented here
func generateJobID() string {
	// Implementation
	return ""
}

func (s *IndexingServer) getJobStatus(jobID string) (*IndexResponse, bool) {
	// Implementation
	return nil, false
}

func (s *IndexingServer) cancelJob(jobID string) error {
	// Implementation
	return nil
}

func (s *IndexingServer) validateCollection() (*ValidationResponse, error) {
	// Implementation
	return nil, nil
}

func (s *IndexingServer) getStats() map[string]interface{} {
	// Implementation
	return nil
}

func (s *IndexingServer) runIndexingJob(jobID string, req IndexRequest) {
	// Implementation
}

func main() {
	fmt.Println("Indexing server: point d'entrée principal non implémenté.")
}
