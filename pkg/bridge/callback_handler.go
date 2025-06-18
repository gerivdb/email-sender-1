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

// CallbackEvent représente un événement de callback
type CallbackEvent struct {
	ID          string                 `json:"id"`
	WorkflowID  string                 `json:"workflow_id"`
	ExecutionID string                 `json:"execution_id"`
	Status      string                 `json:"status"`
	Data        map[string]interface{} `json:"data"`
	Error       string                 `json:"error,omitempty"`
	Timestamp   time.Time              `json:"timestamp"`
	Source      string                 `json:"source"`
}

// CallbackHandler interface pour gérer les callbacks
type CallbackHandler interface {
	HandleCallback(ctx context.Context, event CallbackEvent) error
	RegisterObserver(observer CallbackObserver)
	UnregisterObserver(observerID string)
	SetupRoutes(router *gin.Engine)
	Start() error
	Stop() error
}

// CallbackObserver interface pour observer les callbacks (Observer pattern)
type CallbackObserver interface {
	OnWorkflowCallback(event CallbackEvent) error
	GetID() string
}

// WebhookCallbackHandler implémente CallbackHandler
type WebhookCallbackHandler struct {
	observers    map[string]CallbackObserver
	observersMux sync.RWMutex
	eventChan    chan CallbackEvent
	ctx          context.Context
	cancel       context.CancelFunc
	wg           sync.WaitGroup
}

// CallbackRequest structure pour les requêtes de callback
type CallbackRequest struct {
	WorkflowID  string                 `json:"workflow_id" binding:"required"`
	ExecutionID string                 `json:"execution_id"`
	Status      string                 `json:"status" binding:"required"`
	Data        map[string]interface{} `json:"data"`
	Error       string                 `json:"error,omitempty"`
	Source      string                 `json:"source"`
}

// CallbackResponse structure pour les réponses
type CallbackResponse struct {
	Success   bool   `json:"success"`
	Message   string `json:"message"`
	EventID   string `json:"event_id,omitempty"`
	Timestamp string `json:"timestamp"`
}

// NewWebhookCallbackHandler crée un nouveau gestionnaire de callbacks
func NewWebhookCallbackHandler() *WebhookCallbackHandler {
	ctx, cancel := context.WithCancel(context.Background())

	return &WebhookCallbackHandler{
		observers:    make(map[string]CallbackObserver),
		observersMux: sync.RWMutex{},
		eventChan:    make(chan CallbackEvent, 100), // Buffer pour performances
		ctx:          ctx,
		cancel:       cancel,
	}
}

// RegisterObserver enregistre un observateur
func (h *WebhookCallbackHandler) RegisterObserver(observer CallbackObserver) {
	h.observersMux.Lock()
	defer h.observersMux.Unlock()

	h.observers[observer.GetID()] = observer
}

// UnregisterObserver supprime un observateur
func (h *WebhookCallbackHandler) UnregisterObserver(observerID string) {
	h.observersMux.Lock()
	defer h.observersMux.Unlock()

	delete(h.observers, observerID)
}

// HandleCallback traite un événement de callback
func (h *WebhookCallbackHandler) HandleCallback(ctx context.Context, event CallbackEvent) error {
	if event.ID == "" {
		event.ID = uuid.New().String()
	}

	if event.Timestamp.IsZero() {
		event.Timestamp = time.Now()
	}

	// Envoyer l'événement de manière asynchrone
	select {
	case h.eventChan <- event:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	default:
		return fmt.Errorf("event channel is full, dropping event %s", event.ID)
	}
}

// SetupRoutes configure les routes HTTP pour les callbacks
func (h *WebhookCallbackHandler) SetupRoutes(router *gin.Engine) {
	callbackGroup := router.Group("/api/v1/callbacks")
	{
		callbackGroup.POST("/:workflow_id", h.handleWebhookCallback)
		callbackGroup.GET("/:workflow_id/status", h.getCallbackStatus)
	}
}

// handleWebhookCallback gère les requêtes HTTP de callback
func (h *WebhookCallbackHandler) handleWebhookCallback(c *gin.Context) {
	workflowID := c.Param("workflow_id")

	var request CallbackRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, CallbackResponse{
			Success:   false,
			Message:   fmt.Sprintf("Invalid request format: %v", err),
			Timestamp: time.Now().Format(time.RFC3339),
		})
		return
	}

	// Valider que le workflow_id correspond
	if request.WorkflowID != workflowID {
		c.JSON(http.StatusBadRequest, CallbackResponse{
			Success:   false,
			Message:   "Workflow ID mismatch",
			Timestamp: time.Now().Format(time.RFC3339),
		})
		return
	}

	// Créer l'événement
	event := CallbackEvent{
		ID:          uuid.New().String(),
		WorkflowID:  request.WorkflowID,
		ExecutionID: request.ExecutionID,
		Status:      request.Status,
		Data:        request.Data,
		Error:       request.Error,
		Timestamp:   time.Now(),
		Source:      request.Source,
	}

	// Traiter l'événement
	if err := h.HandleCallback(c.Request.Context(), event); err != nil {
		c.JSON(http.StatusInternalServerError, CallbackResponse{
			Success:   false,
			Message:   fmt.Sprintf("Failed to process callback: %v", err),
			Timestamp: time.Now().Format(time.RFC3339),
		})
		return
	}

	// Réponse de succès
	c.JSON(http.StatusOK, CallbackResponse{
		Success:   true,
		Message:   "Callback processed successfully",
		EventID:   event.ID,
		Timestamp: time.Now().Format(time.RFC3339),
	})
}

// getCallbackStatus retourne le statut des callbacks pour un workflow
func (h *WebhookCallbackHandler) getCallbackStatus(c *gin.Context) {
	workflowID := c.Param("workflow_id")

	// Pour l'instant, retourne un statut simple
	// Ceci sera enrichi avec le Status Tracking System (tâche 029)
	c.JSON(http.StatusOK, gin.H{
		"workflow_id": workflowID,
		"status":      "active",
		"observers":   len(h.observers),
		"timestamp":   time.Now().Format(time.RFC3339),
	})
}

// Start démarre le traitement asynchrone des événements
func (h *WebhookCallbackHandler) Start() error {
	h.wg.Add(1)
	go h.processEvents()
	return nil
}

// Stop arrête le gestionnaire de callbacks
func (h *WebhookCallbackHandler) Stop() error {
	h.cancel()
	close(h.eventChan)
	h.wg.Wait()
	return nil
}

// processEvents traite les événements de manière asynchrone
func (h *WebhookCallbackHandler) processEvents() {
	defer h.wg.Done()

	for {
		select {
		case event, ok := <-h.eventChan:
			if !ok {
				return // Channel fermé
			}

			h.notifyObservers(event)

		case <-h.ctx.Done():
			return
		}
	}
}

// notifyObservers notifie tous les observateurs d'un événement
func (h *WebhookCallbackHandler) notifyObservers(event CallbackEvent) {
	h.observersMux.RLock()
	observers := make([]CallbackObserver, 0, len(h.observers))
	for _, observer := range h.observers {
		observers = append(observers, observer)
	}
	h.observersMux.RUnlock()

	// Notifier chaque observateur en parallèle
	var wg sync.WaitGroup
	for _, observer := range observers {
		wg.Add(1)
		go func(obs CallbackObserver) {
			defer wg.Done()

			// Timeout pour éviter les blocages
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			done := make(chan error, 1)
			go func() {
				done <- obs.OnWorkflowCallback(event)
			}()

			select {
			case err := <-done:
				if err != nil {
					// Log l'erreur (ici on pourrait utiliser un logger)
					fmt.Printf("Observer %s failed to process event %s: %v\n",
						obs.GetID(), event.ID, err)
				}
			case <-ctx.Done():
				fmt.Printf("Observer %s timed out processing event %s\n",
					obs.GetID(), event.ID)
			}
		}(observer)
	}

	wg.Wait()
}

// SimpleCallbackObserver exemple d'implémentation d'observateur
type SimpleCallbackObserver struct {
	ID       string
	Callback func(CallbackEvent) error
}

// NewSimpleCallbackObserver crée un observateur simple
func NewSimpleCallbackObserver(id string, callback func(CallbackEvent) error) *SimpleCallbackObserver {
	return &SimpleCallbackObserver{
		ID:       id,
		Callback: callback,
	}
}

// GetID retourne l'ID de l'observateur
func (o *SimpleCallbackObserver) GetID() string {
	return o.ID
}

// OnWorkflowCallback traite un événement de callback
func (o *SimpleCallbackObserver) OnWorkflowCallback(event CallbackEvent) error {
	if o.Callback != nil {
		return o.Callback(event)
	}
	return nil
}
