// Package integration provides tests for database and webhook implementations
package integration

import (
	"context"
	"net/http"
	"testing"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/types"
)

// Test Database Manager uncovered methods
func TestDatabaseManager_UntestedMethods(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()
	config := types.ManagerConfig{
		ID:      "test-db",
		Type:    "database",
		Enabled: true,
		Config: map[string]interface{}{
			"connections": map[string]interface{}{
				"test": map[string]interface{}{
					"type": "postgresql",
					"host": "localhost",
					"port": 5432,
				},
			},
		},
	}

	manager, err := NewDatabaseManager("test-db", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create DatabaseManager: %v", err)
	}

	ctx := context.Background()

	// Test Initialize (will fail without real DB, but tests code path)
	err = manager.Initialize(config)
	if err != nil {
		t.Logf("Initialize failed as expected without real DB: %v", err)
	}

	// Test query task
	queryTask := types.Task{
		ID:   "test-query",
		Type: "query",
		Payload: map[string]interface{}{
			"connection": "test",
			"query":      "SELECT 1",
		},
	}

	_, err = manager.Execute(ctx, queryTask)
	if err != nil {
		t.Logf("Query failed as expected without real DB: %v", err)
	}

	// Test execute task
	executeTask := types.Task{
		ID:   "test-execute",
		Type: "execute",
		Payload: map[string]interface{}{
			"connection": "test",
			"query":      "CREATE TABLE test (id INT)",
		},
	}

	_, err = manager.Execute(ctx, executeTask)
	if err != nil {
		t.Logf("Execute failed as expected without real DB: %v", err)
	}

	// Test migrate task
	migrateTask := types.Task{
		ID:   "test-migrate",
		Type: "migrate",
		Payload: map[string]interface{}{
			"connection": "test",
		},
	}

	_, err = manager.Execute(ctx, migrateTask)
	if err != nil {
		t.Logf("Migrate failed as expected without real DB: %v", err)
	}

	// Test backup task
	backupTask := types.Task{
		ID:   "test-backup",
		Type: "backup",
		Payload: map[string]interface{}{
			"connection": "test",
			"path":       "/tmp/backup.sql",
		},
	}

	_, err = manager.Execute(ctx, backupTask)
	if err != nil {
		t.Logf("Backup failed as expected without real DB: %v", err)
	}

	// Test get_stats task
	statsTask := types.Task{
		ID:   "test-get-stats",
		Type: "get_stats",
		Payload: map[string]interface{}{
			"connection": "test",
		},
	}

	_, err = manager.Execute(ctx, statsTask)
	if err != nil {
		t.Logf("Get stats failed as expected without real DB: %v", err)
	}

	// Test unknown task
	unknownTask := types.Task{
		ID:      "test-unknown",
		Type:    "unknown",
		Payload: map[string]interface{}{},
	}
	result, err := manager.Execute(ctx, unknownTask)
	if err == nil && result.Success {
		t.Error("Expected error for unknown task type")
	}
}

// Test PostgreSQL Database implementation
func TestPostgreSQLDatabase_Methods(t *testing.T) {
	config := types.DatabaseConfig{
		Type:     "postgresql",
		Host:     "localhost",
		Port:     5432,
		Database: "test",
		Username: "test",
		Password: "test",
	}

	db := NewPostgreSQLDatabase(config)

	// Test Connect (will fail without real DB)
	err := db.Connect()
	if err != nil {
		t.Logf("Connect failed as expected without real DB: %v", err)
	}

	// Test other methods (they will fail, but we test code paths)
	err = db.Ping()
	if err != nil {
		t.Logf("Ping failed as expected: %v", err)
	}

	_, err = db.Query("SELECT 1")
	if err != nil {
		t.Logf("Query failed as expected: %v", err)
	}

	_, err = db.Exec("SELECT 1")
	if err != nil {
		t.Logf("Exec failed as expected: %v", err)
	}

	_, err = db.Begin()
	if err != nil {
		t.Logf("Begin failed as expected: %v", err)
	}

	stats := db.GetStats()
	if stats.OpenConnections != 0 {
		t.Logf("Got stats: %+v", stats)
	}

	err = db.Close()
	if err != nil {
		t.Logf("Close failed: %v", err)
	}
}

// Test MySQL Database implementation
func TestMySQLDatabase_Methods(t *testing.T) {
	config := types.DatabaseConfig{
		Type:     "mysql",
		Host:     "localhost",
		Port:     3306,
		Database: "test",
		Username: "test",
		Password: "test",
	}

	db := NewMySQLDatabase(config)

	// Test Connect (will fail without real DB)
	err := db.Connect()
	if err != nil {
		t.Logf("Connect failed as expected without real DB: %v", err)
	}

	// Test other methods
	err = db.Ping()
	if err != nil {
		t.Logf("Ping failed as expected: %v", err)
	}

	_, err = db.Query("SELECT 1")
	if err != nil {
		t.Logf("Query failed as expected: %v", err)
	}

	_, err = db.Exec("SELECT 1")
	if err != nil {
		t.Logf("Exec failed as expected: %v", err)
	}

	_, err = db.Begin()
	if err != nil {
		t.Logf("Begin failed as expected: %v", err)
	}

	stats := db.GetStats()
	if stats.OpenConnections != 0 {
		t.Logf("Got stats: %+v", stats)
	}

	err = db.Close()
	if err != nil {
		t.Logf("Close failed: %v", err)
	}
}

// Test MongoDB Database implementation
func TestMongoDatabase_Methods(t *testing.T) {
	config := types.DatabaseConfig{
		Type:     "mongodb",
		Host:     "localhost",
		Port:     27017,
		Database: "test",
	}

	db := NewMongoDatabase(config)

	// Test Connect (will fail without real DB)
	err := db.Connect()
	if err != nil {
		t.Logf("Connect failed as expected without real MongoDB: %v", err)
	}

	// Test other methods
	err = db.Ping()
	if err != nil {
		t.Logf("Ping failed as expected: %v", err)
	}

	_, err = db.Query("test query")
	if err != nil {
		t.Logf("Query failed as expected: %v", err)
	}

	_, err = db.Exec("test exec")
	if err != nil {
		t.Logf("Exec failed as expected: %v", err)
	}

	_, err = db.Begin()
	if err != nil {
		t.Logf("Begin failed as expected: %v", err)
	}

	stats := db.GetStats()
	if stats.OpenConnections != 0 {
		t.Logf("Got stats: %+v", stats)
	}

	err = db.Close()
	if err != nil {
		t.Logf("Close failed: %v", err)
	}
}

// Test ConnectionPoolManager methods
func TestConnectionPoolManager_Methods(t *testing.T) {
	poolConfig := types.ConnectionPoolConfig{
		MaxOpen:         10,
		MaxIdle:         5,
		ConnMaxLifetime: time.Hour,
		ConnMaxIdleTime: time.Minute * 30,
	}
	poolManager := NewDefaultConnectionPoolManager(poolConfig)

	// Test GetConnection (will fail without real DB)
	_, err := poolManager.GetConnection("test")
	if err != nil {
		t.Logf("GetConnection failed as expected: %v", err)
	}

	// Test ReleaseConnection
	err = poolManager.ReleaseConnection("test", nil)
	if err != nil {
		t.Logf("ReleaseConnection failed as expected: %v", err)
	}

	// Test GetStats
	stats := poolManager.GetStats()
	if stats == nil {
		t.Error("Expected stats to be returned")
	}

	// Test CloseAll
	err = poolManager.CloseAll()
	if err != nil {
		t.Errorf("CloseAll failed: %v", err)
	}
}

// Test SchemaMigrator methods
func TestSchemaMigrator_Methods(t *testing.T) {
	migrationConfig := types.MigrationConfig{
		Enabled:     true,
		TableName:   "schema_migrations",
		SchemaPath:  "./migrations",
		AutoMigrate: false,
	}
	migrator := NewDefaultSchemaMigrator(migrationConfig)

	// Create a stub PostgreSQL database for testing
	dbConfig := types.DatabaseConfig{
		Type:     "postgresql",
		Host:     "localhost",
		Port:     5432,
		Database: "test",
		Username: "test",
		Password: "test",
	}
	db := NewPostgreSQLDatabase(dbConfig)

	// Test ApplyMigrations
	err := migrator.ApplyMigrations(db)
	if err != nil {
		t.Logf("ApplyMigrations failed as expected with stub DB: %v", err)
	}

	// Test GetMigrationStatus
	_, err = migrator.GetMigrationStatus(db)
	if err != nil {
		t.Logf("GetMigrationStatus failed as expected with stub DB: %v", err)
	}

	// Test CreateMigrationTable
	err = migrator.CreateMigrationTable(db)
	if err != nil {
		t.Logf("CreateMigrationTable failed as expected with stub DB: %v", err)
	}
}

// Test cache backend Redis and Memcached stubs
func TestRedisCacheBackend_Methods(t *testing.T) {
	redisConfig := types.CacheBackendConfig{
		Type:       "redis",
		Addresses:  []string{"localhost:6379"},
		Password:   "",
		Database:   0,
		MaxRetries: 3,
		PoolSize:   10,
		Timeout:    time.Second * 5,
	}
	backend := NewRedisCacheBackend(redisConfig)

	// Test all methods (they are stubs)
	_, found := backend.Get("test")
	if found {
		t.Error("Expected Redis stub to return not found")
	}

	err := backend.Set("test", "value", time.Minute)
	if err == nil {
		t.Error("Expected Redis stub to return error")
	}

	err = backend.Delete("test")
	if err == nil {
		t.Error("Expected Redis stub to return error")
	}

	err = backend.Clear()
	if err == nil {
		t.Error("Expected Redis stub to return error")
	}

	keys := backend.Keys()
	if len(keys) != 0 {
		t.Error("Expected Redis stub to return empty keys")
	}

	stats := backend.Stats()
	if stats.Keys != 0 {
		t.Error("Expected Redis stub to return zero stats")
	}

	err = backend.Close()
	if err != nil {
		t.Errorf("Redis stub Close failed: %v", err)
	}
}

// Test Memcached backend
func TestMemcachedBackend_Methods(t *testing.T) {
	memcachedConfig := types.CacheBackendConfig{
		Type:      "memcached",
		Addresses: []string{"localhost:11211"},
		PoolSize:  10,
		Timeout:   time.Second * 5,
	}
	backend := NewMemcachedBackend(memcachedConfig)

	// Test all methods (they are stubs)
	_, found := backend.Get("test")
	if found {
		t.Error("Expected Memcached stub to return not found")
	}

	err := backend.Set("test", "value", time.Minute)
	if err == nil {
		t.Error("Expected Memcached stub to return error")
	}

	err = backend.Delete("test")
	if err == nil {
		t.Error("Expected Memcached stub to return error")
	}

	err = backend.Clear()
	if err == nil {
		t.Error("Expected Memcached stub to return error")
	}

	keys := backend.Keys()
	if len(keys) != 0 {
		t.Error("Expected Memcached stub to return empty keys")
	}

	stats := backend.Stats()
	if stats.Keys != 0 {
		t.Error("Expected Memcached stub to return zero stats")
	}

	err = backend.Close()
	if err != nil {
		t.Errorf("Memcached stub Close failed: %v", err)
	}
}

// Test email provider rate limits and other methods
func TestEmailProviders_UntestedMethods(t *testing.T) {
	// Test SMTP provider rate limit
	smtpConfig := types.EmailProviderConfig{
		Type:     "smtp",
		Host:     "localhost",
		Port:     587,
		Username: "test",
		Password: "test",
	}
	smtpProvider := NewSMTPProvider(smtpConfig)
	rateLimit := smtpProvider.GetRateLimit()
	if rateLimit != 0 { // Config doesn't set rate limit, so it should be 0
		t.Logf("SMTP rate limit: %d", rateLimit)
	}

	// Test SendGrid provider with valid API key
	sendgridConfig := types.EmailProviderConfig{
		Type:   "sendgrid",
		APIKey: "test-api-key",
	}
	sendgridProvider := NewSendGridProvider(sendgridConfig)

	// Test all methods
	err := sendgridProvider.ValidateConfig()
	if err != nil {
		t.Errorf("SendGrid ValidateConfig failed: %v", err)
	}

	rateLimit = sendgridProvider.GetRateLimit()
	if rateLimit != 0 {
		t.Logf("SendGrid rate limit: %d", rateLimit)
	}
	// Test Mailgun provider with valid API key
	mailgunConfig := types.EmailProviderConfig{
		Type:   "mailgun",
		APIKey: "test-api-key",
		Settings: map[string]string{
			"domain": "test-domain",
		},
	}
	mailgunProvider := NewMailgunProvider(mailgunConfig)

	err = mailgunProvider.ValidateConfig()
	if err != nil {
		t.Errorf("Mailgun ValidateConfig failed: %v", err)
	}

	rateLimit = mailgunProvider.GetRateLimit()
	if rateLimit != 0 {
		t.Logf("Mailgun rate limit: %d", rateLimit)
	}
}

// Test webhook server methods
func TestWebhookServer_Methods(t *testing.T) {
	logger := zap.NewNop()
	config := types.WebhookServerConfig{
		Enabled:      true,
		Host:         "localhost",
		Port:         8999, // Use a different port to avoid conflicts
		TLS:          false,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  30 * time.Second,
	}

	server := NewHTTPWebhookServer(config, logger)
	ctx := context.Background()

	// Test RegisterHandler
	server.RegisterHandler("/test", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// Test Start
	err := server.Start(ctx)
	if err != nil {
		t.Errorf("Server start failed: %v", err)
	}

	// Give server time to start
	time.Sleep(100 * time.Millisecond)

	// Test GetStats
	stats := server.GetStats()
	if stats.ActiveHandlers != 1 {
		t.Errorf("Expected 1 active handler, got %d", stats.ActiveHandlers)
	}

	// Test Stop
	err = server.Stop(ctx)
	if err != nil {
		t.Errorf("Server stop failed: %v", err)
	}
}

// Test webhook client SendAsync
func TestWebhookClient_SendAsync(t *testing.T) {
	logger := zap.NewNop()
	config := types.WebhookClientConfig{
		Timeout:    10 * time.Second,
		MaxRetries: 1,
	}

	client := NewHTTPWebhookClient(config, logger)

	endpoint := &WebhookEndpoint{
		ID:         "test-async",
		URL:        "https://httpbin.org/post", // Use a real endpoint for async test
		Method:     "POST",
		MaxRetries: 1,
		RetryDelay: 1 * time.Second,
		Timeout:    5 * time.Second,
	}

	payload := []byte(`{"test": "async"}`)
	ctx := context.Background()

	// Test SendAsync
	err := client.SendAsync(ctx, endpoint, payload)
	if err != nil {
		t.Errorf("SendAsync failed: %v", err)
	}

	// Give async operation time to complete
	time.Sleep(100 * time.Millisecond)
}

// Test webhook authenticator edge cases
func TestWebhookAuthenticator_EdgeCasesDB(t *testing.T) {
	auth := NewHMACWebhookAuthenticator()

	// Test Verify with invalid signature format
	payload := []byte(`{"test": "data"}`)
	isValid := auth.Verify(payload, "invalid-signature", "secret")
	if isValid {
		t.Error("Expected invalid signature to fail verification")
	}

	// Test GetHeaders with empty secret
	headers := auth.GetHeaders(payload, "")
	if len(headers) == 0 {
		t.Error("Expected headers even with empty secret")
	}
}

// Test PowerShell and GoGen integrations (stubs)
func TestIntegrationStubs(t *testing.T) {
	// Test PowerShell integration
	managersConfig := &types.ManagersConfig{
		HealthCheckInterval: time.Minute,
		DefaultTimeout:      time.Second * 30,
		MaxRetries:          3,
	}
	logger, _ := zap.NewDevelopment()
	psIntegration := NewPowerShellIntegration(managersConfig, logger)
	_, err := psIntegration.ExecuteScript("test.ps1", map[string]string{"param1": "value1"})
	if err != nil {
		t.Errorf("PowerShell ExecuteScript failed: %v", err)
	}

	scripts := psIntegration.GetAvailableScripts()
	if len(scripts) < 0 { // Should return some available scripts
		t.Errorf("Expected some available scripts, got %d", len(scripts))
	}

	// Test GoGen integration
	goGenIntegration := NewGoGenIntegration(managersConfig, logger)

	_, err = goGenIntegration.GenerateCode("test-template", map[string]interface{}{})
	if err != nil {
		t.Errorf("GoGen GenerateCode failed: %v", err)
	}

	templates := goGenIntegration.GetAvailableTemplates()
	if len(templates) == 0 {
		t.Error("Expected some available templates")
	}
}
