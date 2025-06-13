package integration

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/email-sender/development/managers/contextual-memory-manager/interfaces"
	baseInterfaces "./interfaces"
)

// integrationManagerImpl implÃ©mente IntegrationManager pour les intÃ©grations externes
type integrationManagerImpl struct {
	storageManager baseInterfaces.StorageManager
	configManager  baseInterfaces.ConfigManager
	errorManager   baseInterfaces.ErrorManager

	mcpDB         *sql.DB
	mcpGatewayURL string
	n8nWebhookURL string
	initialized   bool

	httpClient *http.Client
}

// NewIntegrationManager crÃ©e une nouvelle instance de IntegrationManager
func NewIntegrationManager(
	storageManager baseInterfaces.StorageManager,
	configManager baseInterfaces.ConfigManager,
	errorManager baseInterfaces.ErrorManager,
) (*integrationManagerImpl, error) {
	if storageManager == nil {
		return nil, fmt.Errorf("storageManager cannot be nil")
	}
	if configManager == nil {
		return nil, fmt.Errorf("configManager cannot be nil")
	}
	if errorManager == nil {
		return nil, fmt.Errorf("errorManager cannot be nil")
	}

	return &integrationManagerImpl{
		storageManager: storageManager,
		configManager:  configManager,
		errorManager:   errorManager,
		mcpGatewayURL:  "http://localhost:8080",
		n8nWebhookURL:  "http://localhost:5678/webhook",
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}, nil
}

// Initialize implÃ©mente BaseManager.Initialize
func (im *integrationManagerImpl) Initialize(ctx context.Context) error {
	if im.initialized {
		return nil
	}

	// Initialiser la connexion MCP Gateway SQLite
	err := im.initializeMCPDatabase(ctx)
	if err != nil {
		return fmt.Errorf("failed to initialize MCP database: %w", err)
	}

	// Charger la configuration depuis ConfigManager
	err = im.loadConfiguration(ctx)
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	im.initialized = true
	return nil
}

// NotifyMCPGateway notifie le MCP Gateway d'un Ã©vÃ©nement contextuel
func (im *integrationManagerImpl) NotifyMCPGateway(ctx context.Context, event interfaces.ContextEvent) error {
	if !im.initialized {
		return fmt.Errorf("IntegrationManager not initialized")
	}

	// PrÃ©parer le payload pour MCP Gateway
	payload := map[string]interface{}{
		"event_type": "contextual_action",
		"data": map[string]interface{}{
			"action":    event.Action,
			"context":   event.Context,
			"timestamp": event.Timestamp.Unix(),
		},
	}

	// Envoyer au MCP Gateway
	err := im.sendHTTPRequest(ctx, im.mcpGatewayURL+"/api/events", payload)
	if err != nil {
		return fmt.Errorf("failed to notify MCP Gateway: %w", err)
	}

	return nil
}

// TriggerN8NWorkflow dÃ©clenche un workflow N8N avec des donnÃ©es
func (im *integrationManagerImpl) TriggerN8NWorkflow(ctx context.Context, workflowID string, data interface{}) error {
	if !im.initialized {
		return fmt.Errorf("IntegrationManager not initialized")
	}

	// PrÃ©parer le payload pour N8N
	payload := map[string]interface{}{
		"workflow_id": workflowID,
		"data":        data,
		"timestamp":   time.Now().Unix(),
	}

	// Construire l'URL du webhook N8N
	webhookURL := fmt.Sprintf("%s/contextual-memory/%s", im.n8nWebhookURL, workflowID)

	// Envoyer au webhook N8N
	err := im.sendHTTPRequest(ctx, webhookURL, payload)
	if err != nil {
		return fmt.Errorf("failed to trigger N8N workflow: %w", err)
	}

	return nil
}

// SyncToMCPDatabase synchronise les actions vers la base MCP
func (im *integrationManagerImpl) SyncToMCPDatabase(ctx context.Context, actions []interfaces.Action) error {
	if !im.initialized {
		return fmt.Errorf("IntegrationManager not initialized")
	}

	// Commencer une transaction
	tx, err := im.mcpDB.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// PrÃ©parer la requÃªte d'insertion
	query := `
		INSERT OR REPLACE INTO mcp_contextual_actions 
		(action_id, action_type, action_text, workspace_path, file_path, line_number, timestamp, metadata)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)`

	stmt, err := tx.PrepareContext(ctx, query)
	if err != nil {
		return fmt.Errorf("failed to prepare statement: %w", err)
	}
	defer stmt.Close()

	// InsÃ©rer chaque action
	for _, action := range actions {
		metadataJSON, err := json.Marshal(action.Metadata)
		if err != nil {
			metadataJSON = []byte("{}")
		}

		_, err = stmt.ExecContext(ctx,
			action.ID,
			action.Type,
			action.Text,
			action.WorkspacePath,
			action.FilePath,
			action.LineNumber,
			action.Timestamp.Unix(),
			string(metadataJSON),
		)
		if err != nil {
			return fmt.Errorf("failed to insert action %s: %w", action.ID, err)
		}
	}

	// Confirmer la transaction
	err = tx.Commit()
	if err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

// SendWebhook envoie un webhook gÃ©nÃ©rique
func (im *integrationManagerImpl) SendWebhook(ctx context.Context, url string, payload interface{}) error {
	if !im.initialized {
		return fmt.Errorf("IntegrationManager not initialized")
	}

	return im.sendHTTPRequest(ctx, url, payload)
}

// Cleanup implÃ©mente BaseManager.Cleanup
func (im *integrationManagerImpl) Cleanup() error {
	if im.mcpDB != nil {
		return im.mcpDB.Close()
	}
	return nil
}

// HealthCheck implÃ©mente BaseManager.HealthCheck
func (im *integrationManagerImpl) HealthCheck(ctx context.Context) error {
	if !im.initialized {
		return fmt.Errorf("IntegrationManager not initialized")
	}

	// VÃ©rifier la connexion MCP SQLite
	err := im.mcpDB.PingContext(ctx)
	if err != nil {
		return fmt.Errorf("MCP database unhealthy: %w", err)
	}

	// Tester la connectivitÃ© MCP Gateway
	testCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	err = im.testHTTPEndpoint(testCtx, im.mcpGatewayURL+"/health")
	if err != nil {
		return fmt.Errorf("MCP Gateway unhealthy: %w", err)
	}

	return nil
}

// NotifyAction notifie les systÃ¨mes externes d'une nouvelle action
func (im *integrationManagerImpl) NotifyAction(ctx context.Context, action interfaces.Action) error {
	if !im.initialized {
		return fmt.Errorf("integration manager not initialized")
	}

	// CrÃ©er un Ã©vÃ©nement contextuel
	event := interfaces.ContextEvent{
		Action:    action,
		Context:   map[string]interface{}{"source": "contextual_memory"},
		Timestamp: action.Timestamp,
	}

	// Notifier le MCP Gateway
	if err := im.NotifyMCPGateway(ctx, event); err != nil {
		if im.errorManager != nil {
			im.errorManager.LogError(ctx, "Failed to notify MCP Gateway", err)
		}
		// Ne pas Ã©chouer complÃ¨tement si MCP Gateway n'est pas disponible
	}

	// Synchroniser avec la base de donnÃ©es MCP si disponible
	if im.mcpDB != nil {
		if err := im.SyncToMCPDatabase(ctx, []interfaces.Action{action}); err != nil {
			if im.errorManager != nil {
				im.errorManager.LogError(ctx, "Failed to sync to MCP database", err)
			}
		}
	}

	// DÃ©clencher les workflows N8N si configurÃ©s
	workflowID := im.configManager.GetString("n8n.default_workflow_id")
	if workflowID != "" {
		payload := map[string]interface{}{
			"action": action,
			"event":  "action_captured",
		}
		if err := im.TriggerN8NWorkflow(ctx, workflowID, payload); err != nil {
			if im.errorManager != nil {
				im.errorManager.LogError(ctx, "Failed to trigger N8N workflow", err)
			}
		}
	}

	return nil
}

// MÃ©thodes privÃ©es

func (im *integrationManagerImpl) initializeMCPDatabase(ctx context.Context) error {
	// Utiliser SQLite pour la base MCP Gateway
	db, err := sql.Open("sqlite3", "./data/mcp-contextual.db")
	if err != nil {
		return fmt.Errorf("failed to open MCP database: %w", err)
	}

	// CrÃ©er la table si elle n'existe pas
	schema := `
	CREATE TABLE IF NOT EXISTS mcp_contextual_actions (
		action_id TEXT PRIMARY KEY,
		action_type TEXT NOT NULL,
		action_text TEXT NOT NULL,
		workspace_path TEXT,
		file_path TEXT,
		line_number INTEGER,
		timestamp INTEGER NOT NULL,
		metadata TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	
	CREATE INDEX IF NOT EXISTS idx_mcp_timestamp ON mcp_contextual_actions(timestamp);
	CREATE INDEX IF NOT EXISTS idx_mcp_workspace ON mcp_contextual_actions(workspace_path);
	`

	_, err = db.ExecContext(ctx, schema)
	if err != nil {
		return fmt.Errorf("failed to create MCP schema: %w", err)
	}

	im.mcpDB = db
	return nil
}

func (im *integrationManagerImpl) loadConfiguration(ctx context.Context) error {
	// Charger la configuration depuis ConfigManager (simulation)
	// Dans un vrai systÃ¨me, utiliser im.configManager.GetConfig()

	// Configuration par dÃ©faut
	config := map[string]interface{}{
		"mcp_gateway_url": "http://localhost:8080",
		"n8n_webhook_url": "http://localhost:5678/webhook",
	}

	if url, ok := config["mcp_gateway_url"].(string); ok {
		im.mcpGatewayURL = url
	}

	if url, ok := config["n8n_webhook_url"].(string); ok {
		im.n8nWebhookURL = url
	}

	return nil
}

func (im *integrationManagerImpl) sendHTTPRequest(ctx context.Context, url string, payload interface{}) error {
	// SÃ©rialiser le payload
	jsonPayload, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	// CrÃ©er la requÃªte
	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(jsonPayload))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "ContextualMemoryManager/1.0")

	// Envoyer la requÃªte
	resp, err := im.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	// VÃ©rifier le code de statut
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("HTTP request failed with status %d: %s", resp.StatusCode, string(body))
	}

	return nil
}

func (im *integrationManagerImpl) testHTTPEndpoint(ctx context.Context, url string) error {
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create test request: %w", err)
	}

	resp, err := im.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to test endpoint: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("endpoint returned status %d", resp.StatusCode)
	}

	return nil
}
