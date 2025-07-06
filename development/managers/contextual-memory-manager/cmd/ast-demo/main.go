// cmd/ast-demo/main.go
package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/interfaces"
	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/internal/ast"
)

// Mock implementations pour la démo
type (
	demoStorageManager    struct{}
	demoErrorManager      struct{}
	demoConfigManager     struct{}
	demoMonitoringManager struct{}
)

func (d *demoStorageManager) Initialize(ctx context.Context) error { return nil }
func (d *demoStorageManager) Shutdown(ctx context.Context) error   { return nil }
func (d *demoStorageManager) GetStatus(ctx context.Context) interfaces.ManagerStatus {
	return interfaces.ManagerStatus{Name: "DemoStorage", Status: "healthy", Initialized: true}
}

func (d *demoErrorManager) Initialize(ctx context.Context) error { return nil }
func (d *demoErrorManager) Shutdown(ctx context.Context) error   { return nil }
func (d *demoErrorManager) GetStatus(ctx context.Context) interfaces.ManagerStatus {
	return interfaces.ManagerStatus{Name: "DemoError", Status: "healthy", Initialized: true}
}

func (d *demoErrorManager) LogError(ctx context.Context, component, message string, err error) {
	fmt.Printf("[ERROR] %s - %s: %v\n", component, message, err)
}

func (d *demoConfigManager) Initialize(ctx context.Context) error { return nil }
func (d *demoConfigManager) Shutdown(ctx context.Context) error   { return nil }
func (d *demoConfigManager) GetStatus(ctx context.Context) interfaces.ManagerStatus {
	return interfaces.ManagerStatus{Name: "DemoConfig", Status: "healthy", Initialized: true}
}

func (d *demoMonitoringManager) Initialize(ctx context.Context) error { return nil }
func (d *demoMonitoringManager) Shutdown(ctx context.Context) error   { return nil }
func (d *demoMonitoringManager) GetStatus(ctx context.Context) interfaces.ManagerStatus {
	return interfaces.ManagerStatus{Name: "DemoMonitoring", Status: "healthy", Initialized: true}
}
func (d *demoMonitoringManager) RecordCacheHit(ctx context.Context, hit bool) error { return nil }
func (d *demoMonitoringManager) RecordOperation(ctx context.Context, operation string, duration time.Duration, metadata map[string]interface{}) error {
	fmt.Printf("[METRIC] %s completed in %v\n", operation, duration)
	return nil
}

func main() {
	fmt.Println("🔍 AST Analysis Manager Demo")
	fmt.Println("============================")

	ctx := context.Background()

	// Créer le manager AST
	astManager, err := ast.NewASTAnalysisManager(
		&demoStorageManager{},
		&demoErrorManager{},
		&demoConfigManager{},
		&demoMonitoringManager{},
	)
	if err != nil {
		log.Fatalf("Failed to create AST manager: %v", err)
	}

	// Initialiser le manager
	fmt.Println("\n📡 Initializing AST Analysis Manager...")
	err = astManager.Initialize(ctx)
	if err != nil {
		log.Fatalf("Failed to initialize AST manager: %v", err)
	}

	status := astManager.GetStatus(ctx)
	fmt.Printf("✅ Manager Status: %s (Initialized: %v)\n", status.Status, status.Initialized)

	// Créer un fichier de démonstration
	demoFile := createDemoFile()
	defer os.Remove(demoFile)

	fmt.Printf("\n📄 Demo file created: %s\n", demoFile)

	// Analyser le fichier
	fmt.Println("\n🔬 Analyzing demo file...")
	result, err := astManager.AnalyzeFile(ctx, demoFile)
	if err != nil {
		log.Fatalf("Failed to analyze file: %v", err)
	}

	// Afficher les résultats de l'analyse
	printAnalysisResults(result)

	// Démonstration du cache
	fmt.Println("\n💾 Testing cache performance...")
	testCachePerformance(ctx, astManager, demoFile)

	// Démonstration de l'enrichissement contextuel
	fmt.Println("\n🎯 Testing context enrichment...")
	testContextEnrichment(ctx, astManager, demoFile)

	// Démonstration du contexte structurel
	fmt.Println("\n🏗️ Testing structural context...")
	testStructuralContext(ctx, astManager, demoFile)

	// Statistiques du cache
	fmt.Println("\n📊 Cache statistics:")
	printCacheStats(ctx, astManager)

	// Arrêter le manager
	fmt.Println("\n🛑 Shutting down manager...")
	err = astManager.Shutdown(ctx)
	if err != nil {
		log.Printf("Error during shutdown: %v", err)
	}

	fmt.Println("\n✨ Demo completed successfully!")
}

func createDemoFile() string {
	content := `package demo

import (
	"context"
	"fmt"
	"time"
)

// User represents a user in the system
type User struct {
	ID       int64     ` + "`json:\"id\"`" + `
	Name     string    ` + "`json:\"name\"`" + `
	Email    string    ` + "`json:\"email\"`" + `
	Created  time.Time ` + "`json:\"created\"`" + `
}

// UserService provides user management operations
type UserService interface {
	GetUser(ctx context.Context, id int64) (*User, error)
	CreateUser(ctx context.Context, user *User) error
	UpdateUser(ctx context.Context, user *User) error
	DeleteUser(ctx context.Context, id int64) error
}

// userServiceImpl implements UserService
type userServiceImpl struct {
	users map[int64]*User
}

// NewUserService creates a new user service
func NewUserService() UserService {
	return &userServiceImpl{
		users: make(map[int64]*User),
	}
}

// GetUser retrieves a user by ID
func (s *userServiceImpl) GetUser(ctx context.Context, id int64) (*User, error) {
	if user, exists := s.users[id]; exists {
		return user, nil
	}
	return nil, fmt.Errorf("user with ID %d not found", id)
}

// CreateUser creates a new user
func (s *userServiceImpl) CreateUser(ctx context.Context, user *User) error {
	if user == nil {
		return fmt.Errorf("user cannot be nil")
	}
	
	if user.ID == 0 {
		user.ID = time.Now().Unix()
	}
	
	if user.Created.IsZero() {
		user.Created = time.Now()
	}
	
	s.users[user.ID] = user
	return nil
}

// UpdateUser updates an existing user
func (s *userServiceImpl) UpdateUser(ctx context.Context, user *User) error {
	if user == nil {
		return fmt.Errorf("user cannot be nil")
	}
	
	if _, exists := s.users[user.ID]; !exists {
		return fmt.Errorf("user with ID %d not found", user.ID)
	}
	
	s.users[user.ID] = user
	return nil
}

// DeleteUser deletes a user by ID
func (s *userServiceImpl) DeleteUser(ctx context.Context, id int64) error {
	if _, exists := s.users[id]; !exists {
		return fmt.Errorf("user with ID %d not found", id)
	}
	
	delete(s.users, id)
	return nil
}

// GetUserStats returns statistics about users
func (s *userServiceImpl) GetUserStats() map[string]interface{} {
	stats := make(map[string]interface{})
	stats["total_users"] = len(s.users)
	stats["last_updated"] = time.Now()
	
	return stats
}

// ValidateUser validates a user's data
func ValidateUser(user *User) error {
	if user == nil {
		return fmt.Errorf("user cannot be nil")
	}
	
	if user.Name == "" {
		return fmt.Errorf("user name is required")
	}
	
	if user.Email == "" {
		return fmt.Errorf("user email is required")
	}
	
	// Simple email validation
	if !strings.Contains(user.Email, "@") {
		return fmt.Errorf("invalid email format")
	}
	
	return nil
}

// Helper function for email validation
func isValidEmail(email string) bool {
	return strings.Contains(email, "@") && strings.Contains(email, ".")
}
`

	// Créer un fichier temporaire
	tmpFile, err := os.CreateTemp("", "ast-demo-*.go")
	if err != nil {
		log.Fatalf("Failed to create temp file: %v", err)
	}

	_, err = tmpFile.WriteString(content)
	if err != nil {
		log.Fatalf("Failed to write to temp file: %v", err)
	}

	tmpFile.Close()
	return tmpFile.Name()
}

func printAnalysisResults(result *interfaces.ASTAnalysisResult) {
	fmt.Printf("\n📋 Analysis Results for %s:\n", filepath.Base(result.FilePath))
	fmt.Printf("   Package: %s\n", result.Package)
	fmt.Printf("   Analysis Duration: %v\n", result.AnalysisDuration)
	fmt.Printf("   Lines of Code: %d\n", result.Complexity.LinesOfCode)
	fmt.Printf("   Cyclomatic Complexity: %d\n", result.Complexity.CyclomaticComplexity)

	fmt.Printf("\n📦 Imports (%d):\n", len(result.Imports))
	for _, imp := range result.Imports {
		fmt.Printf("   - %s", imp.Path)
		if imp.Alias != "" {
			fmt.Printf(" (as %s)", imp.Alias)
		}
		if imp.IsStandard {
			fmt.Printf(" [standard]")
		}
		fmt.Printf("\n")
	}

	fmt.Printf("\n🏗️ Types (%d):\n", len(result.Types))
	for _, typ := range result.Types {
		fmt.Printf("   - %s (%s)", typ.Name, typ.Kind)
		if typ.IsExported {
			fmt.Printf(" [exported]")
		}
		if len(typ.Fields) > 0 {
			fmt.Printf(" - %d fields", len(typ.Fields))
		}
		if len(typ.Methods) > 0 {
			fmt.Printf(" - %d methods", len(typ.Methods))
		}
		fmt.Printf("\n")
	}

	fmt.Printf("\n🔧 Functions (%d):\n", len(result.Functions))
	for _, fn := range result.Functions {
		fmt.Printf("   - %s", fn.Name)
		if fn.IsExported {
			fmt.Printf(" [exported]")
		}
		fmt.Printf(" (complexity: %d, params: %d, returns: %d)\n",
			fn.Complexity, len(fn.Parameters), len(fn.ReturnTypes))
	}

	fmt.Printf("\n🔗 Dependencies (%d):\n", len(result.Dependencies))
	for _, dep := range result.Dependencies {
		fmt.Printf("   - %s -> %s (%s)\n", dep.From, dep.To, dep.Type)
	}
}

func testCachePerformance(ctx context.Context, manager interfaces.ASTAnalysisManager, filePath string) {
	// Premier appel (cache miss)
	start := time.Now()
	_, err := manager.AnalyzeFile(ctx, filePath)
	duration1 := time.Since(start)
	if err != nil {
		fmt.Printf("❌ First analysis failed: %v\n", err)
		return
	}
	fmt.Printf("⏱️  First analysis (cache miss): %v\n", duration1)

	// Deuxième appel (cache hit)
	start = time.Now()
	_, err = manager.AnalyzeFile(ctx, filePath)
	duration2 := time.Since(start)
	if err != nil {
		fmt.Printf("❌ Second analysis failed: %v\n", err)
		return
	}
	fmt.Printf("⚡ Second analysis (cache hit): %v\n", duration2)

	speedup := float64(duration1) / float64(duration2)
	fmt.Printf("🚀 Speedup: %.2fx faster\n", speedup)
}

func testContextEnrichment(ctx context.Context, manager interfaces.ASTAnalysisManager, filePath string) {
	action := interfaces.Action{
		ID:         "demo-action",
		Type:       "edit",
		Text:       "Editing user validation logic",
		FilePath:   filePath,
		LineNumber: 75, // Ligne dans ValidateUser
		Timestamp:  time.Now(),
		Metadata: map[string]interface{}{
			"editor": "demo",
		},
	}

	enriched, err := manager.EnrichContextWithAST(ctx, action)
	if err != nil {
		fmt.Printf("❌ Context enrichment failed: %v\n", err)
		return
	}

	fmt.Printf("📝 Original Action: %s (line %d)\n", action.Text, action.LineNumber)
	fmt.Printf("🎯 Enriched Context:\n")
	for key, value := range enriched.ASTContext {
		fmt.Printf("   - %s: %v\n", key, value)
	}

	if enriched.StructuralContext != nil {
		fmt.Printf("🏗️ Structural Context:\n")
		fmt.Printf("   - Scope: %s\n", enriched.StructuralContext.Scope)
		if enriched.StructuralContext.CurrentFunction != nil {
			fmt.Printf("   - Current Function: %s\n", enriched.StructuralContext.CurrentFunction.Name)
		}
	}
}

func testStructuralContext(ctx context.Context, manager interfaces.ASTAnalysisManager, filePath string) {
	// Tester différentes lignes
	testLines := []struct {
		line     int
		expected string
	}{
		{10, "Type definition area"},
		{45, "Function GetUser"},
		{85, "Function ValidateUser"},
		{1, "Package level"},
	}

	for _, test := range testLines {
		context, err := manager.GetStructuralContext(ctx, filePath, test.line)
		if err != nil {
			fmt.Printf("❌ Failed to get context for line %d: %v\n", test.line, err)
			continue
		}

		fmt.Printf("📍 Line %d - %s:\n", test.line, test.expected)
		fmt.Printf("   - Scope: %s\n", context.Scope)

		if context.CurrentFunction != nil {
			fmt.Printf("   - Function: %s (complexity: %d)\n",
				context.CurrentFunction.Name, context.CurrentFunction.Complexity)
		}

		if context.CurrentType != nil {
			fmt.Printf("   - Type: %s (%s)\n", context.CurrentType.Name, context.CurrentType.Kind)
		}
	}
}

func printCacheStats(ctx context.Context, manager interfaces.ASTAnalysisManager) {
	stats, err := manager.GetCacheStats(ctx)
	if err != nil {
		fmt.Printf("❌ Failed to get cache stats: %v\n", err)
		return
	}

	fmt.Printf("📊 Cache Statistics:\n")
	fmt.Printf("   - Total Entries: %d\n", stats.TotalEntries)
	fmt.Printf("   - Hit Rate: %.2f%%\n", stats.HitRate*100)
	fmt.Printf("   - Miss Rate: %.2f%%\n", stats.MissRate*100)
	fmt.Printf("   - Memory Usage: %d bytes\n", stats.MemoryUsage)

	if !stats.OldestEntry.IsZero() {
		fmt.Printf("   - Oldest Entry: %v\n", stats.OldestEntry.Format(time.RFC3339))
	}

	if !stats.NewestEntry.IsZero() {
		fmt.Printf("   - Newest Entry: %v\n", stats.NewestEntry.Format(time.RFC3339))
	}
}
