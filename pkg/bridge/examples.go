package bridge

import (
	"fmt"
	"time"
)

// ConfigExample montre un exemple de configuration pour le client N8N
func ConfigExample() N8NClientConfig {
	return N8NClientConfig{
		BaseURL:        "http://localhost:5678",
		APIKey:         "your-n8n-api-key",
		Timeout:        30 * time.Second,
		MaxRetries:     3,
		RetryDelay:     1 * time.Second,
		CircuitBreaker: true,
	}
}

// Usage example du client N8N
func ExampleUsage() error {
	// Configuration
	config := N8NClientConfig{
		BaseURL:    "http://localhost:5678",
		APIKey:     "your-api-key",
		Timeout:    30 * time.Second,
		MaxRetries: 3,
		RetryDelay: 1 * time.Second,
	}

	// Créer le client
	client, err := NewN8NClient(config)
	if err != nil {
		return fmt.Errorf("failed to create N8N client: %w", err)
	}

	// Vérifier la santé de N8N
	if err := client.Health(); err != nil {
		return fmt.Errorf("N8N health check failed: %w", err)
	}

	// Données à envoyer au workflow
	workflowData := map[string]interface{}{
		"email":  "user@example.com",
		"name":   "John Doe",
		"action": "send_welcome_email",
		"metadata": map[string]interface{}{
			"source":    "go-manager",
			"timestamp": time.Now().Unix(),
		},
	}

	// Déclencher un workflow
	err = client.TriggerWorkflow("workflow-email-sender", workflowData)
	if err != nil {
		return fmt.Errorf("failed to trigger workflow: %w", err)
	}

	fmt.Println("Workflow triggered successfully")
	return nil
}
