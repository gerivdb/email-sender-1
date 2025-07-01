package example

import (
	"context"
	"fmt"
	"log"
	"time"

	"EMAIL_SENDER_1/development/managers/contextual-memory-manager/development"
	"EMAIL_SENDER_1/development/managers/contextual-memory-manager/interfaces"
)

// Example implementation showing how to use the Contextual Memory Manager
func main() {
	ctx := context.Background()

	// Note: In a real implementation, you would initialize actual managers
	// This is just a demonstration of the API
	fmt.Println("=== Contextual Memory Manager Integration Example ===")

	// Mock managers for demonstration
	storageManager := &MockStorageManager{}
	errorManager := &MockErrorManager{}
	configManager := &MockConfigManager{
		config: map[string]interface{}{
			"database.postgresql.host":     "localhost",
			"database.postgresql.port":     5432,
			"database.postgresql.database": "email_sender_dev",
			"indexing.qdrant.url":          "http://localhost:6333",
			"mcp_gateway.url":              "http://localhost:8080",
			"n8n.webhook_url":              "http://localhost:5678/webhook",
		},
	}

	// Create contextual memory manager
	manager := development.NewContextualMemoryManager(
		storageManager,
		errorManager,
		configManager,
	)

	fmt.Println("1. Initializing Contextual Memory Manager...")
	if err := manager.Initialize(ctx); err != nil {
		log.Fatalf("Failed to initialize manager: %v", err)
	}
	fmt.Println("✓ Manager initialized successfully")

	// Example 1: Capture a single action
	fmt.Println("\n2. Capturing user actions...")
	action := interfaces.Action{
		ID:            "example-action-001",
		Type:          "edit",
		Text:          "Added error handling to authentication function",
		WorkspacePath: "/workspace/email-sender",
		FilePath:      "/workspace/email-sender/auth/auth.go",
		LineNumber:    127,
		Timestamp:     time.Now(),
		Metadata: map[string]interface{}{
			"language":    "go",
			"function":    "authenticateUser",
			"change_type": "error_handling",
			"lines_added": 5,
			"complexity":  "medium",
		},
	}

	if err := manager.CaptureAction(ctx, action); err != nil {
		log.Printf("Failed to capture action: %v", err)
	} else {
		fmt.Printf("✓ Captured action: %s\n", action.Text)
	}

	// Example 2: Batch capture multiple actions
	fmt.Println("\n3. Batch capturing multiple actions...")
	batchActions := []interfaces.Action{
		{
			ID:            "batch-action-001",
			Type:          "search",
			Text:          "Searched for email validation patterns",
			WorkspacePath: "/workspace/email-sender",
			Timestamp:     time.Now(),
			Metadata: map[string]interface{}{
				"search_terms":  []string{"email", "validation", "regex"},
				"results_count": 15,
			},
		},
		{
			ID:            "batch-action-002",
			Type:          "command",
			Text:          "go test ./auth/...",
			WorkspacePath: "/workspace/email-sender",
			Timestamp:     time.Now(),
			Metadata: map[string]interface{}{
				"command_type": "test",
				"exit_code":    0,
				"duration_ms":  1250,
			},
		},
		{
			ID:            "batch-action-003",
			Type:          "edit",
			Text:          "Refactored email template rendering logic",
			WorkspacePath: "/workspace/email-sender",
			FilePath:      "/workspace/email-sender/templates/renderer.go",
			LineNumber:    89,
			Timestamp:     time.Now(),
			Metadata: map[string]interface{}{
				"refactor_type":     "extraction",
				"functions_created": 2,
				"lines_removed":     45,
				"lines_added":       32,
			},
		},
	}

	if err := manager.BatchCaptureActions(ctx, batchActions); err != nil {
		log.Printf("Failed to batch capture actions: %v", err)
	} else {
		fmt.Printf("✓ Batch captured %d actions\n", len(batchActions))
	}

	// Example 3: Session management
	fmt.Println("\n4. Managing user sessions...")
	sessionID, err := manager.StartSession(ctx, "/workspace/email-sender")
	if err != nil {
		log.Printf("Failed to start session: %v", err)
	} else {
		fmt.Printf("✓ Started session: %s\n", sessionID)

		// Simulate some work in the session
		time.Sleep(100 * time.Millisecond)

		// Get session actions
		sessionActions, err := manager.GetSessionActions(ctx, sessionID)
		if err != nil {
			log.Printf("Failed to get session actions: %v", err)
		} else {
			fmt.Printf("✓ Session has %d actions\n", len(sessionActions))
		}

		// End the session
		if err := manager.EndSession(ctx, sessionID); err != nil {
			log.Printf("Failed to end session: %v", err)
		} else {
			fmt.Println("✓ Session ended successfully")
		}
	}

	// Example 4: Context search
	fmt.Println("\n5. Searching contextual actions...")
	query := interfaces.ContextQuery{
		Text:          "authentication error handling",
		WorkspacePath: "/workspace/email-sender",
		ActionTypes:   []string{"edit", "search"},
		TimeRange: interfaces.TimeRange{
			Start: time.Now().Add(-24 * time.Hour),
			End:   time.Now(),
		},
		Limit:               10,
		SimilarityThreshold: 0.7,
	}

	results, err := manager.SearchContext(ctx, query)
	if err != nil {
		log.Printf("Failed to search context: %v", err)
	} else {
		fmt.Printf("✓ Found %d contextually relevant actions\n", len(results))
		for i, result := range results {
			if i < 3 { // Show first 3 results
				fmt.Printf("  - %s (score: %.2f)\n", result.Action.Text, result.Score)
			}
		}
	}

	// Example 5: Pattern analysis
	fmt.Println("\n6. Analyzing usage patterns...")
	patterns, err := manager.AnalyzePatternsUsage(ctx, "/workspace/email-sender")
	if err != nil {
		log.Printf("Failed to analyze patterns: %v", err)
	} else {
		fmt.Printf("✓ Analyzed patterns: %d metrics collected\n", len(patterns))
		for key, value := range patterns {
			fmt.Printf("  - %s: %v\n", key, value)
		}
	}

	// Example 6: Getting similar actions
	fmt.Println("\n7. Finding similar actions...")
	similarActions, err := manager.GetSimilarActions(ctx, "example-action-001", 5)
	if err != nil {
		log.Printf("Failed to get similar actions: %v", err)
	} else {
		fmt.Printf("✓ Found %d similar actions\n", len(similarActions))
	}

	// Example 7: System metrics
	fmt.Println("\n8. Retrieving system metrics...")
	metrics, err := manager.GetMetrics(ctx)
	if err != nil {
		log.Printf("Failed to get metrics: %v", err)
	} else {
		fmt.Println("✓ System metrics:")
		fmt.Printf("  - Total actions: %d\n", metrics.TotalActions)
		fmt.Printf("  - Cache hit ratio: %.2f%%\n", metrics.CacheHitRatio*100)
		fmt.Printf("  - Average latency: %v\n", metrics.AverageLatency)
		fmt.Printf("  - Active sessions: %d\n", metrics.ActiveSessions)
		fmt.Printf("  - MCP notifications: %d\n", metrics.MCPNotifications)
		fmt.Printf("  - Error count: %d\n", metrics.ErrorCount)
		fmt.Printf("  - Last operation: %v\n", metrics.LastOperationTime.Format(time.RFC3339))
	}

	fmt.Println("\n=== Integration Example Complete ===")
}

// Mock implementations (same as in test files)
type MockStorageManager struct{}

func (m *MockStorageManager) Initialize(ctx context.Context) error { return nil }
func (m *MockStorageManager) Shutdown(ctx context.Context) error   { return nil }
func (m *MockStorageManager) GetStatus() string                    { return "healthy" }
func (m *MockStorageManager) GetPostgreSQLConnection() (interface{}, error) {
	return &MockDB{}, nil
}
func (m *MockStorageManager) GetSQLiteConnection(dbPath string) (interface{}, error) {
	return &MockDB{}, nil
}

type MockErrorManager struct{}

func (m *MockErrorManager) Initialize(ctx context.Context) error { return nil }
func (m *MockErrorManager) Shutdown(ctx context.Context) error   { return nil }
func (m *MockErrorManager) GetStatus() string                    { return "healthy" }
func (m *MockErrorManager) LogError(ctx context.Context, message string, err error) {
	if err != nil {
		log.Printf("Error logged: %s - %v", message, err)
	}
}
func (m *MockErrorManager) ProcessError(ctx context.Context, err error) error { return nil }

type MockConfigManager struct {
	config map[string]interface{}
}

func (m *MockConfigManager) Initialize(ctx context.Context) error { return nil }
func (m *MockConfigManager) Shutdown(ctx context.Context) error   { return nil }
func (m *MockConfigManager) GetStatus() string                    { return "healthy" }
func (m *MockConfigManager) GetString(key string) string {
	if val, ok := m.config[key].(string); ok {
		return val
	}
	return ""
}
func (m *MockConfigManager) GetInt(key string) int {
	if val, ok := m.config[key].(int); ok {
		return val
	}
	return 0
}
func (m *MockConfigManager) GetBool(key string) bool {
	if val, ok := m.config[key].(bool); ok {
		return val
	}
	return false
}

type MockDB struct{}

func (m *MockDB) Close() error { return nil }
func (m *MockDB) Ping() error  { return nil }
