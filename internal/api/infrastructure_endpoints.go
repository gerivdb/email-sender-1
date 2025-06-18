package api

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"email_sender/internal/infrastructure"
)

// InfrastructureAPIHandler gère les endpoints API pour l'infrastructure
type InfrastructureAPIHandler struct {
	orchestrator infrastructure.InfrastructureOrchestrator
	server       *http.Server
}

// NewInfrastructureAPIHandler crée un nouveau handler API
func NewInfrastructureAPIHandler(orchestrator infrastructure.InfrastructureOrchestrator) *InfrastructureAPIHandler {
	return &InfrastructureAPIHandler{
		orchestrator: orchestrator,
	}
}

// StartServer démarre le serveur HTTP d'API
func (h *InfrastructureAPIHandler) StartServer(port int) error {
	mux := http.NewServeMux()
	
	// Endpoints de base
	mux.HandleFunc("/api/v1/infrastructure/status", h.handleGetStatus)
	mux.HandleFunc("/api/v1/infrastructure/health", h.handleHealthCheck)
	mux.HandleFunc("/api/v1/infrastructure/start", h.handleStartServices)
	mux.HandleFunc("/api/v1/infrastructure/stop", h.handleStopServices)
	mux.HandleFunc("/api/v1/infrastructure/recover", h.handleAutoRecover)
	
	// Endpoints Phase 2: Monitoring avancé
	mux.HandleFunc("/api/v1/monitoring/start", h.handleStartAdvancedMonitoring)
	mux.HandleFunc("/api/v1/monitoring/stop", h.handleStopAdvancedMonitoring)
	mux.HandleFunc("/api/v1/monitoring/status", h.handleGetMonitoringStatus)
	mux.HandleFunc("/api/v1/monitoring/health-advanced", h.handleGetAdvancedHealthStatus)
	
	// Endpoints Phase 2: Auto-healing
	mux.HandleFunc("/api/v1/auto-healing/enable", h.handleEnableAutoHealing)
	mux.HandleFunc("/api/v1/auto-healing/disable", h.handleDisableAutoHealing)

	h.server = &http.Server{
		Addr:    fmt.Sprintf(":%d", port),
		Handler: mux,
	}

	log.Printf("🚀 Starting Infrastructure API server on port %d", port)
	return h.server.ListenAndServe()
}

// StopServer arrête le serveur HTTP
func (h *InfrastructureAPIHandler) StopServer(ctx context.Context) error {
	if h.server == nil {
		return nil
	}
	return h.server.Shutdown(ctx)
}

// Response structure générique
type APIResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

// writeJSONResponse écrit une réponse JSON
func (h *InfrastructureAPIHandler) writeJSONResponse(w http.ResponseWriter, statusCode int, response APIResponse) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(response)
}

// handleGetStatus retourne le statut des services
func (h *InfrastructureAPIHandler) handleGetStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		h.writeJSONResponse(w, http.StatusMethodNotAllowed, APIResponse{
			Success: false,
			Error:   "Method not allowed",
		})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	status, err := h.orchestrator.GetServiceStatus(ctx)
	if err != nil {
		h.writeJSONResponse(w, http.StatusInternalServerError, APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	h.writeJSONResponse(w, http.StatusOK, APIResponse{
		Success: true,
		Message: "Service status retrieved successfully",
		Data:    status,
	})
}

// handleHealthCheck effectue un health check complet
func (h *InfrastructureAPIHandler) handleHealthCheck(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		h.writeJSONResponse(w, http.StatusMethodNotAllowed, APIResponse{
			Success: false,
			Error:   "Method not allowed",
		})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	err := h.orchestrator.HealthCheck(ctx)
	if err != nil {
		h.writeJSONResponse(w, http.StatusServiceUnavailable, APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	h.writeJSONResponse(w, http.StatusOK, APIResponse{
		Success: true,
		Message: "Health check passed",
	})
}

// handleStartServices démarre tous les services
func (h *InfrastructureAPIHandler) handleStartServices(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		h.writeJSONResponse(w, http.StatusMethodNotAllowed, APIResponse{
			Success: false,
			Error:   "Method not allowed",
		})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 120*time.Second)
	defer cancel()

	err := h.orchestrator.StartServices(ctx)
	if err != nil {
		h.writeJSONResponse(w, http.StatusInternalServerError, APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	h.writeJSONResponse(w, http.StatusOK, APIResponse{
		Success: true,
		Message: "Services started successfully",
	})
}

// handleStopServices arrête tous les services
func (h *InfrastructureAPIHandler) handleStopServices(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		h.writeJSONResponse(w, http.StatusMethodNotAllowed, APIResponse{
			Success: false,
			Error:   "Method not allowed",
		})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	err := h.orchestrator.StopServices(ctx)
	if err != nil {
		h.writeJSONResponse(w, http.StatusInternalServerError, APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	h.writeJSONResponse(w, http.StatusOK, APIResponse{
		Success: true,
		Message: "Services stopped successfully",
	})
}

// handleAutoRecover lance la récupération automatique
func (h *InfrastructureAPIHandler) handleAutoRecover(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		h.writeJSONResponse(w, http.StatusMethodNotAllowed, APIResponse{
			Success: false,
			Error:   "Method not allowed",
		})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 120*time.Second)
	defer cancel()

	err := h.orchestrator.AutoRecover(ctx)
	if err != nil {
		h.writeJSONResponse(w, http.StatusInternalServerError, APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	h.writeJSONResponse(w, http.StatusOK, APIResponse{
		Success: true,
		Message: "Auto-recovery completed successfully",
	})
}

// PHASE 2: Endpoints pour monitoring avancé

// handleStartAdvancedMonitoring démarre le monitoring avancé
func (h *InfrastructureAPIHandler) handleStartAdvancedMonitoring(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		h.writeJSONResponse(w, http.StatusMethodNotAllowed, APIResponse{
			Success: false,
			Error:   "Method not allowed",
		})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	err := h.orchestrator.StartAdvancedMonitoring(ctx)
	if err != nil {
		h.writeJSONResponse(w, http.StatusInternalServerError, APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	h.writeJSONResponse(w, http.StatusOK, APIResponse{
		Success: true,
		Message: "Advanced monitoring started successfully",
	})
}

// handleStopAdvancedMonitoring arrête le monitoring avancé
func (h *InfrastructureAPIHandler) handleStopAdvancedMonitoring(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		h.writeJSONResponse(w, http.StatusMethodNotAllowed, APIResponse{
			Success: false,
			Error:   "Method not allowed",
		})
		return
	}

	err := h.orchestrator.StopAdvancedMonitoring()
	if err != nil {
		h.writeJSONResponse(w, http.StatusInternalServerError, APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	h.writeJSONResponse(w, http.StatusOK, APIResponse{
		Success: true,
		Message: "Advanced monitoring stopped successfully",
	})
}

// handleGetMonitoringStatus retourne le statut du monitoring
func (h *InfrastructureAPIHandler) handleGetMonitoringStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		h.writeJSONResponse(w, http.StatusMethodNotAllowed, APIResponse{
			Success: false,
			Error:   "Method not allowed",
		})
		return
	}

	// Vérifier si l'orchestrator supporte GetMonitoringStatus
	if smartManager, ok := h.orchestrator.(*infrastructure.SmartInfrastructureManager); ok {
		status := smartManager.GetMonitoringStatus()
		h.writeJSONResponse(w, http.StatusOK, APIResponse{
			Success: true,
			Message: "Monitoring status retrieved successfully",
			Data:    status,
		})
	} else {
		h.writeJSONResponse(w, http.StatusNotImplemented, APIResponse{
			Success: false,
			Error:   "Monitoring status not available for this orchestrator",
		})
	}
}

// handleGetAdvancedHealthStatus retourne le statut de santé avancé
func (h *InfrastructureAPIHandler) handleGetAdvancedHealthStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		h.writeJSONResponse(w, http.StatusMethodNotAllowed, APIResponse{
			Success: false,
			Error:   "Method not allowed",
		})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	healthStatus, err := h.orchestrator.GetAdvancedHealthStatus(ctx)
	if err != nil {
		h.writeJSONResponse(w, http.StatusInternalServerError, APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	h.writeJSONResponse(w, http.StatusOK, APIResponse{
		Success: true,
		Message: "Advanced health status retrieved successfully",
		Data:    healthStatus,
	})
}

// handleEnableAutoHealing active l'auto-healing
func (h *InfrastructureAPIHandler) handleEnableAutoHealing(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		h.writeJSONResponse(w, http.StatusMethodNotAllowed, APIResponse{
			Success: false,
			Error:   "Method not allowed",
		})
		return
	}

	err := h.orchestrator.EnableAutoHealing(true)
	if err != nil {
		h.writeJSONResponse(w, http.StatusInternalServerError, APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	h.writeJSONResponse(w, http.StatusOK, APIResponse{
		Success: true,
		Message: "Auto-healing enabled successfully",
	})
}

// handleDisableAutoHealing désactive l'auto-healing
func (h *InfrastructureAPIHandler) handleDisableAutoHealing(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		h.writeJSONResponse(w, http.StatusMethodNotAllowed, APIResponse{
			Success: false,
			Error:   "Method not allowed",
		})
		return
	}

	err := h.orchestrator.EnableAutoHealing(false)
	if err != nil {
		h.writeJSONResponse(w, http.StatusInternalServerError, APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	h.writeJSONResponse(w, http.StatusOK, APIResponse{
		Success: true,
		Message: "Auto-healing disabled successfully",
	})
}
