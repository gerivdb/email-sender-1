// Package integration provides tests for EmailManager
package integration

import (
	"context"
	"fmt"
	"testing"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/types"
)

// TestEmailManager_Initialize tests EmailManager initialization
func TestEmailManager_Initialize(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	tests := []struct {
		name        string
		config      types.ManagerConfig
		wantErr     bool
		errContains string
	}{
		{
			name: "valid_smtp_provider",
			config: types.ManagerConfig{
				ID:   "email-test",
				Type: "email",
				Config: map[string]interface{}{
					"providers": map[string]interface{}{
						"smtp": map[string]interface{}{
							"type": "smtp",
							"host": "smtp.example.com",
							"port": 587,
						},
					},
				},
			},
			wantErr: false,
		}, {
			name: "no_providers_but_default_added",
			config: types.ManagerConfig{
				ID:     "email-test",
				Type:   "email",
				Config: map[string]interface{}{},
			},
			wantErr: false, // Now we expect success because default provider is added
		},
		{
			name: "empty_id",
			config: types.ManagerConfig{
				Type: "email",
			},
			wantErr:     true,
			errContains: "manager ID cannot be empty",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			em, err := NewEmailManager("test-email", tt.config, logger, metrics)
			if err != nil {
				if !tt.wantErr {
					t.Errorf("NewEmailManager() error = %v, wantErr %v", err, tt.wantErr)
				}
				return
			}

			err = em.Initialize(tt.config)

			if (err != nil) != tt.wantErr {
				t.Errorf("EmailManager.Initialize() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if err != nil && tt.errContains != "" {
				if !contains(err.Error(), tt.errContains) {
					t.Errorf("EmailManager.Initialize() error = %v, should contain %v", err, tt.errContains)
				}
			}
		})
	}
}

// TestEmailManager_Execute tests EmailManager task execution
func TestEmailManager_Execute(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	config := types.ManagerConfig{
		ID:   "email-test",
		Type: "email",
		Config: map[string]interface{}{
			"providers": map[string]interface{}{
				"test": map[string]interface{}{
					"type": "smtp",
					"host": "smtp.test.com",
					"port": 587,
				},
			},
		},
	}

	em, err := NewEmailManager("test-email", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create EmailManager: %v", err)
	}

	if err := em.Initialize(config); err != nil {
		t.Fatalf("Failed to initialize EmailManager: %v", err)
	}

	tests := []struct {
		name       string
		task       types.Task
		wantErr    bool
		wantResult bool
	}{
		{
			name: "send_email_task",
			task: types.Task{
				ID:   "task-1",
				Type: "send_email",
				Payload: map[string]interface{}{
					"email": map[string]interface{}{
						"from":      "test@example.com",
						"to":        []interface{}{"recipient@example.com"},
						"subject":   "Test Subject",
						"html_body": "<p>Test HTML</p>",
						"text_body": "Test Text",
					},
				},
			},
			wantErr:    false,
			wantResult: true,
		},
		{
			name: "invalid_task_type",
			task: types.Task{
				ID:   "task-2",
				Type: "unknown_task",
			},
			wantErr:    false, // Execute returns result with error, not an error
			wantResult: false,
		},
		{
			name: "send_email_missing_data",
			task: types.Task{
				ID:      "task-3",
				Type:    "send_email",
				Payload: map[string]interface{}{},
			},
			wantErr:    false,
			wantResult: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx := context.Background()
			result, err := em.Execute(ctx, tt.task)

			if (err != nil) != tt.wantErr {
				t.Errorf("EmailManager.Execute() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if result.Success != tt.wantResult {
				t.Errorf("EmailManager.Execute() result.Success = %v, want %v", result.Success, tt.wantResult)
			}

			if result.TaskID != tt.task.ID {
				t.Errorf("EmailManager.Execute() result.TaskID = %v, want %v", result.TaskID, tt.task.ID)
			}
		})
	}
}

// TestEmailManager_GetType tests EmailManager type
func TestEmailManager_GetType(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	config := types.ManagerConfig{
		ID:   "email-test",
		Type: "email",
		Config: map[string]interface{}{
			"providers": map[string]interface{}{
				"test": map[string]interface{}{
					"type": "smtp",
					"host": "smtp.test.com",
					"port": 587,
				},
			},
		},
	}

	em, err := NewEmailManager("test-email", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create EmailManager: %v", err)
	}

	if got := em.GetType(); got != "email" {
		t.Errorf("EmailManager.GetType() = %v, want %v", got, "email")
	}
}

// TestEmailManager_StartStop tests EmailManager start and stop
func TestEmailManager_StartStop(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	config := types.ManagerConfig{
		ID:   "email-test",
		Type: "email",
		Config: map[string]interface{}{
			"providers": map[string]interface{}{
				"test": map[string]interface{}{
					"type": "smtp",
					"host": "smtp.test.com",
					"port": 587,
				},
			},
		},
	}

	em, err := NewEmailManager("test-email", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create EmailManager: %v", err)
	}

	if err := em.Initialize(config); err != nil {
		t.Fatalf("Failed to initialize EmailManager: %v", err)
	}

	// Test start
	if err := em.Start(); err != nil {
		t.Errorf("EmailManager.Start() error = %v", err)
	}

	if em.GetStatus() != types.ManagerStatusRunning {
		t.Errorf("EmailManager status after start = %v, want %v", em.GetStatus(), types.ManagerStatusRunning)
	}

	// Test stop
	if err := em.Stop(); err != nil {
		t.Errorf("EmailManager.Stop() error = %v", err)
	}

	if em.GetStatus() != types.ManagerStatusStopped {
		t.Errorf("EmailManager status after stop = %v, want %v", em.GetStatus(), types.ManagerStatusStopped)
	}
}

// TestSMTPProvider_ValidateConfig tests SMTP provider config validation
func TestSMTPProvider_ValidateConfig(t *testing.T) {
	tests := []struct {
		name        string
		config      types.EmailProviderConfig
		wantErr     bool
		errContains string
	}{
		{
			name: "valid_config",
			config: types.EmailProviderConfig{
				Type: "smtp",
				Host: "smtp.example.com",
				Port: 587,
			},
			wantErr: false,
		},
		{
			name: "missing_host",
			config: types.EmailProviderConfig{
				Type: "smtp",
				Port: 587,
			},
			wantErr:     true,
			errContains: "host is required",
		},
		{
			name: "missing_port",
			config: types.EmailProviderConfig{
				Type: "smtp",
				Host: "smtp.example.com",
			},
			wantErr:     true,
			errContains: "port is required",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			provider := NewSMTPProvider(tt.config)
			err := provider.ValidateConfig()

			if (err != nil) != tt.wantErr {
				t.Errorf("SMTPProvider.ValidateConfig() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if err != nil && tt.errContains != "" {
				if !contains(err.Error(), tt.errContains) {
					t.Errorf("SMTPProvider.ValidateConfig() error = %v, should contain %v", err, tt.errContains)
				}
			}
		})
	}
}

// TestDefaultTemplateEngine tests template engine functionality
func TestDefaultTemplateEngine_LoadTemplate(t *testing.T) {
	config := types.TemplateEngineConfig{
		TemplatesPath: "/tmp/templates",
		CacheEnabled:  true,
		CacheSize:     100,
	}

	engine := NewDefaultTemplateEngine(config)

	template, err := engine.LoadTemplate("test-template")
	if err != nil {
		t.Errorf("DefaultTemplateEngine.LoadTemplate() error = %v", err)
		return
	}

	if template.Name != "test-template" {
		t.Errorf("DefaultTemplateEngine.LoadTemplate() template.Name = %v, want %v", template.Name, "test-template")
	}

	if len(template.Variables) == 0 {
		t.Errorf("DefaultTemplateEngine.LoadTemplate() template.Variables is empty")
	}
}

// TestDefaultTemplateEngine_RenderTemplate tests template rendering
func TestDefaultTemplateEngine_RenderTemplate(t *testing.T) {
	config := types.TemplateEngineConfig{}
	engine := NewDefaultTemplateEngine(config)

	template := &EmailTemplate{
		Name:        "test",
		Subject:     "Hello {{.name}}",
		HTMLContent: "<p>Hello {{.name}}, your message: {{.message}}</p>",
		TextContent: "Hello {{.name}}, your message: {{.message}}",
		Variables:   []string{"name", "message"},
	}

	data := map[string]interface{}{
		"name":    "John",
		"message": "Welcome!",
	}

	email, err := engine.RenderTemplate(template, data)
	if err != nil {
		t.Errorf("DefaultTemplateEngine.RenderTemplate() error = %v", err)
		return
	}

	expectedSubject := "Hello John"
	if email.Subject != expectedSubject {
		t.Errorf("DefaultTemplateEngine.RenderTemplate() subject = %v, want %v", email.Subject, expectedSubject)
	}

	if !contains(email.HTMLBody, "Hello John") {
		t.Errorf("DefaultTemplateEngine.RenderTemplate() HTML body doesn't contain expected content")
	}

	if !contains(email.TextBody, "Welcome!") {
		t.Errorf("DefaultTemplateEngine.RenderTemplate() text body doesn't contain expected content")
	}
}

// TestDefaultDeliveryTracker tests delivery tracking functionality
func TestDefaultDeliveryTracker_TrackSent(t *testing.T) {
	tracker := NewDefaultDeliveryTracker()

	messageID := "test-message-1"
	recipient := "test@example.com"

	err := tracker.TrackSent(messageID, recipient)
	if err != nil {
		t.Errorf("DefaultDeliveryTracker.TrackSent() error = %v", err)
	}

	// Verify tracking was recorded
	since := time.Now().Add(-1 * time.Hour)
	stats, err := tracker.GetStatistics(since)
	if err != nil {
		t.Errorf("DefaultDeliveryTracker.GetStatistics() error = %v", err)
		return
	}

	if stats.TotalSent != 1 {
		t.Errorf("DefaultDeliveryTracker.GetStatistics() TotalSent = %v, want %v", stats.TotalSent, 1)
	}
}

// TestMemoryEmailQueue tests in-memory email queue
func TestMemoryEmailQueue_EnqueueDequeue(t *testing.T) {
	config := types.QueueConfig{
		MaxSize: 10,
	}

	queue := NewMemoryEmailQueue(config)

	// Test enqueue
	email := &EmailMessage{
		ID:      "test-1",
		From:    "sender@example.com",
		To:      []string{"recipient@example.com"},
		Subject: "Test",
	}

	err := queue.Enqueue(email)
	if err != nil {
		t.Errorf("MemoryEmailQueue.Enqueue() error = %v", err)
	}

	// Test size
	if queue.Size() != 1 {
		t.Errorf("MemoryEmailQueue.Size() = %v, want %v", queue.Size(), 1)
	}

	// Test dequeue
	dequeuedEmail, err := queue.Dequeue()
	if err != nil {
		t.Errorf("MemoryEmailQueue.Dequeue() error = %v", err)
		return
	}

	if dequeuedEmail.ID != email.ID {
		t.Errorf("MemoryEmailQueue.Dequeue() ID = %v, want %v", dequeuedEmail.ID, email.ID)
	}

	// Test empty queue
	if queue.Size() != 0 {
		t.Errorf("MemoryEmailQueue.Size() after dequeue = %v, want %v", queue.Size(), 0)
	}

	// Test dequeue from empty queue
	emptyEmail, err := queue.Dequeue()
	if err != nil {
		t.Errorf("MemoryEmailQueue.Dequeue() from empty queue error = %v", err)
	}

	if emptyEmail != nil {
		t.Errorf("MemoryEmailQueue.Dequeue() from empty queue = %v, want nil", emptyEmail)
	}
}

// TestMemoryEmailQueue_MaxSize tests queue size limit
func TestMemoryEmailQueue_MaxSize(t *testing.T) {
	config := types.QueueConfig{
		MaxSize: 2,
	}

	queue := NewMemoryEmailQueue(config)

	// Fill queue to max size
	for i := 0; i < 2; i++ {
		email := &EmailMessage{
			ID: fmt.Sprintf("test-%d", i),
		}

		err := queue.Enqueue(email)
		if err != nil {
			t.Errorf("MemoryEmailQueue.Enqueue() error = %v", err)
		}
	}

	// Try to exceed max size
	email := &EmailMessage{
		ID: "test-overflow",
	}

	err := queue.Enqueue(email)
	if err == nil {
		t.Errorf("MemoryEmailQueue.Enqueue() should fail when queue is full")
	}

	if !contains(err.Error(), "queue is full") {
		t.Errorf("MemoryEmailQueue.Enqueue() error should mention queue is full, got: %v", err)
	}
}

// Helper function to check if string contains substring
func contains(s, substr string) bool {
	return indexOf(s, substr) >= 0
}
