// Package integration provides comprehensive tests for 100% coverage - Part 2
package integration

import (
	"context"
	"fmt"
	"testing"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/types"
)

// Test MemoryCache eviction logic by forcing max size constraint
func TestMemoryCacheBackend_EvictionLogic(t *testing.T) {
	// Create a memory cache backend and manually set a small max size
	backend := NewMemoryCacheBackend()
	backend.maxSize = 2 // Force small max size for testing eviction

	// Add items to exceed max size
	for i := 0; i < 5; i++ {
		key := fmt.Sprintf("key-%d", i)
		err := backend.Set(key, fmt.Sprintf("value-%d", i), time.Minute)
		if err != nil {
			t.Errorf("Failed to set key %s: %v", key, err)
		}
	}

	// Check that eviction occurred
	keys := backend.Keys()
	if len(keys) > backend.maxSize {
		t.Errorf("Expected max %d keys after eviction, got %d", backend.maxSize, len(keys))
	}
}

// Test email providers with missing configurations to trigger validation errors
func TestEmailProviders_ValidationErrors(t *testing.T) {
	// Test SendGrid with missing API key
	sendgridConfig := types.EmailProviderConfig{
		Type:   "sendgrid",
		APIKey: "", // Empty API key should cause validation error
	}
	sendgridProvider := NewSendGridProvider(sendgridConfig)

	err := sendgridProvider.ValidateConfig()
	if err == nil {
		t.Error("Expected SendGrid validation error for missing API key")
	}

	// Test Mailgun with missing API key
	mailgunConfig := types.EmailProviderConfig{
		Type:   "mailgun",
		APIKey: "", // Empty API key should cause validation error
	}
	mailgunProvider := NewMailgunProvider(mailgunConfig)

	err = mailgunProvider.ValidateConfig()
	if err == nil {
		t.Error("Expected Mailgun validation error for missing API key")
	}
}

// Test SMTP provider actual send methods (they will fail but test code paths)
func TestSMTPProvider_SendMethods(t *testing.T) {
	config := types.EmailProviderConfig{
		Type:     "smtp",
		Host:     "nonexistent.host",
		Port:     587,
		Username: "test",
		Password: "test",
	}

	provider := NewSMTPProvider(config)

	// Test single email send (will fail with connection error)
	email := &EmailMessage{
		ID:       "test-1",
		From:     "test@example.com",
		To:       []string{"recipient@example.com"},
		Subject:  "Test Email",
		TextBody: "This is a test email",
	}

	err := provider.SendEmail(email)
	if err == nil {
		t.Error("Expected SMTP send to fail with nonexistent host")
	}

	// Test bulk send
	emails := []*EmailMessage{email}
	err = provider.SendBulk(emails)
	if err == nil {
		t.Error("Expected SMTP bulk send to fail with nonexistent host")
	} // Test GetDeliveryStatus (stub method)
	status, err := provider.GetDeliveryStatus("test-1")
	if err != nil {
		t.Errorf("GetDeliveryStatus failed: %v", err)
	}
	if status == nil || status.Status != "sent" {
		t.Error("Expected SMTP status 'sent'")
	}
}

// Test SendGrid and Mailgun provider methods (stubs that return errors)
func TestEmailProviders_StubMethods(t *testing.T) {
	// Test SendGrid
	sendgridConfig := types.EmailProviderConfig{
		Type:   "sendgrid",
		APIKey: "test-key",
	}
	sendgridProvider := NewSendGridProvider(sendgridConfig)

	email := &EmailMessage{
		ID:       "test-sendgrid",
		From:     "test@example.com",
		To:       []string{"recipient@example.com"},
		Subject:  "SendGrid Test",
		TextBody: "Test",
	}

	err := sendgridProvider.SendEmail(email)
	if err == nil {
		t.Error("Expected SendGrid send to fail (stub implementation)")
	}
	err = sendgridProvider.SendBulk([]*EmailMessage{email})
	if err == nil {
		t.Error("Expected SendGrid bulk send to fail (stub implementation)")
	}

	status, err := sendgridProvider.GetDeliveryStatus("test-sendgrid")
	if err == nil {
		t.Error("Expected SendGrid GetDeliveryStatus to fail (stub implementation)")
	}
	if status != nil {
		t.Error("Expected SendGrid status to be nil when error occurs")
	}

	// Test Mailgun
	mailgunConfig := types.EmailProviderConfig{
		Type:   "mailgun",
		APIKey: "test-key",
	}
	mailgunProvider := NewMailgunProvider(mailgunConfig)

	err = mailgunProvider.SendEmail(email)
	if err == nil {
		t.Error("Expected Mailgun send to fail (stub implementation)")
	}
	err = mailgunProvider.SendBulk([]*EmailMessage{email})
	if err == nil {
		t.Error("Expected Mailgun bulk send to fail (stub implementation)")
	}

	status, err = mailgunProvider.GetDeliveryStatus("test-sendgrid")
	if err == nil {
		t.Error("Expected Mailgun GetDeliveryStatus to fail (stub implementation)")
	}
	if status != nil {
		t.Error("Expected Mailgun status to be nil when error occurs")
	}
}

// Test delivery tracker edge cases
func TestDeliveryTracker_EdgeCases(t *testing.T) {
	tracker := NewDefaultDeliveryTracker()

	now := time.Now()
	// Test TrackDelivered
	err := tracker.TrackDelivered("test-delivered")
	if err != nil {
		t.Errorf("TrackDelivered failed: %v", err)
	}

	// Test TrackOpened
	err = tracker.TrackOpened("test-opened", now)
	if err != nil {
		t.Errorf("TrackOpened failed: %v", err)
	}

	// Test TrackClicked with different URL
	err = tracker.TrackClicked("test-clicked", "https://different.com", now)
	if err != nil {
		t.Errorf("TrackClicked failed: %v", err)
	}
	// Test GetStatistics with no data initially
	stats, err := tracker.GetStatistics(now.Add(-24 * time.Hour))
	if err != nil {
		t.Errorf("GetStatistics failed: %v", err)
	}
	if stats.TotalSent != 0 {
		t.Errorf("Expected 0 sent emails, got %d", stats.TotalSent)
	}
}

// Test database manager with different connection configurations
func TestDatabaseManager_ConnectionConfigs(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	// Test with multiple connection types
	config := types.ManagerConfig{
		ID:      "test-multi-db",
		Type:    "database",
		Enabled: true,
		Config: map[string]interface{}{
			"connections": map[string]interface{}{
				"postgres": map[string]interface{}{
					"type":     "postgresql",
					"host":     "localhost",
					"port":     5432,
					"database": "test",
					"username": "test",
					"password": "test",
				},
				"mysql": map[string]interface{}{
					"type":     "mysql",
					"host":     "localhost",
					"port":     3306,
					"database": "test",
					"username": "test",
					"password": "test",
				},
				"mongo": map[string]interface{}{
					"type": "mongodb",
					"host": "localhost",
					"port": 27017,
				},
			},
		},
	}

	manager, err := NewDatabaseManager("test-multi-db", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create DatabaseManager: %v", err)
	}

	// Test initialization (will fail but tests code paths)
	err = manager.Initialize(config)
	if err != nil {
		t.Logf("Initialize failed as expected: %v", err)
	}

	ctx := context.Background()

	// Test query with specific connection
	queryTask := types.Task{
		ID:   "test-postgres-query",
		Type: "query",
		Payload: map[string]interface{}{
			"connection": "postgres",
			"query":      "SELECT version()",
		},
	}

	_, err = manager.Execute(ctx, queryTask)
	if err != nil {
		t.Logf("Query failed as expected: %v", err)
	}
}
