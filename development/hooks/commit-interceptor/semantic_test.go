// development/hooks/commit-interceptor/semantic_test.go
package commitinterceptor

import (
	"context"
	"testing"
	"time"
)

func TestSemanticEmbeddingManager(t *testing.T) {
	config := &Config{
		Server: ServerConfig{
			Port: 8080,
			Host: "localhost",
		},
		Git: GitConfig{
			DefaultBranch: "main",
			RemoteName:    "origin",
		},
		Routing: RoutingConfig{
			DefaultStrategy: "type-based",
		},
		Logging: LoggingConfig{
			Level: "info",
		},
	}

	sem := NewSemanticEmbeddingManager(config)
	if sem == nil {
		t.Fatal("Failed to create SemanticEmbeddingManager")
	}

	// Test commit data
	commitData := &CommitData{
		Hash:      "abc123",
		Message:   "feat: add new user authentication system",
		Author:    "developer@example.com",
		Timestamp: time.Now(),
		Files:     []string{"auth/user.go", "auth/middleware.go", "config/auth.yaml"},
	}

	ctx := context.Background()

	// Test creating commit context
	commitContext, err := sem.CreateCommitContext(ctx, commitData)
	if err != nil {
		t.Fatalf("Failed to create commit context: %v", err)
	}

	// Validate commit context
	if commitContext.ContextID == "" {
		t.Error("ContextID should not be empty")
	}

	if len(commitContext.Embeddings) == 0 {
		t.Error("Embeddings should not be empty")
	}

	if commitContext.PredictedType == "" {
		t.Error("PredictedType should not be empty")
	}

	if commitContext.Confidence <= 0 {
		t.Error("Confidence should be greater than 0")
	}

	if len(commitContext.Keywords) == 0 {
		t.Error("Keywords should be extracted from commit message")
	}

	// Check if keywords contain expected values
	expectedKeywords := []string{"feat", "add"}
	found := make(map[string]bool)
	for _, keyword := range commitContext.Keywords {
		for _, expected := range expectedKeywords {
			if keyword == expected {
				found[expected] = true
			}
		}
	}

	if !found["feat"] {
		t.Error("Should extract 'feat' keyword from commit message")
	}

	t.Logf("✅ Semantic analysis successful:")
	t.Logf("   - Predicted Type: %s (confidence: %.2f)", commitContext.PredictedType, commitContext.Confidence)
	t.Logf("   - Semantic Score: %.3f", commitContext.SemanticScore)
	t.Logf("   - Keywords: %v", commitContext.Keywords)
	t.Logf("   - Context ID: %s", commitContext.ContextID)
}

func TestCommitAnalyzerWithSemantic(t *testing.T) {
	config := &Config{
		Server: ServerConfig{
			Port: 8080,
			Host: "localhost",
		},
		Git: GitConfig{
			DefaultBranch: "main",
			RemoteName:    "origin",
		},
		Routing: RoutingConfig{
			DefaultStrategy: "type-based",
		},
		Logging: LoggingConfig{
			Level: "info",
		},
	}

	analyzer := NewCommitAnalyzer(config)
	if analyzer == nil {
		t.Fatal("Failed to create CommitAnalyzer")
	}

	// Test different types of commits
	testCases := []struct {
		name          string
		commitData    *CommitData
		expectedType  string
		minConfidence float64
	}{
		{
			name: "Feature commit",
			commitData: &CommitData{
				Hash:      "feat123",
				Message:   "feat: implement user dashboard with real-time updates",
				Author:    "dev@example.com",
				Timestamp: time.Now(),
				Files:     []string{"dashboard/user.go", "dashboard/realtime.go"},
			},
			expectedType:  "feature",
			minConfidence: 0.8,
		},
		{
			name: "Bug fix commit",
			commitData: &CommitData{
				Hash:      "fix123",
				Message:   "fix: resolve memory leak in cache manager",
				Author:    "dev@example.com",
				Timestamp: time.Now(),
				Files:     []string{"cache/manager.go", "cache/memory.go"},
			},
			expectedType:  "fix",
			minConfidence: 0.8,
		},
		{
			name: "Documentation commit",
			commitData: &CommitData{
				Hash:      "docs123",
				Message:   "docs: update API documentation with examples",
				Author:    "dev@example.com",
				Timestamp: time.Now(),
				Files:     []string{"README.md", "docs/api.md"},
			},
			expectedType:  "docs",
			minConfidence: 0.8,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			analysis, err := analyzer.AnalyzeCommit(tc.commitData)
			if err != nil {
				t.Fatalf("Failed to analyze commit: %v", err)
			}

			if analysis.ChangeType != tc.expectedType {
				t.Errorf("Expected change type %s, got %s", tc.expectedType, analysis.ChangeType)
			}

			if analysis.Confidence < tc.minConfidence {
				t.Errorf("Expected confidence >= %.2f, got %.2f", tc.minConfidence, analysis.Confidence)
			}

			if analysis.SuggestedBranch == "" {
				t.Error("SuggestedBranch should not be empty")
			}

			t.Logf("✅ Analysis for %s:", tc.name)
			t.Logf("   - Type: %s", analysis.ChangeType)
			t.Logf("   - Confidence: %.2f", analysis.Confidence)
			t.Logf("   - Impact: %s", analysis.Impact)
			t.Logf("   - Suggested Branch: %s", analysis.SuggestedBranch)
			t.Logf("   - Keywords: %v", analysis.Keywords)
		})
	}
}

func TestMockAdvancedAutonomyManager(t *testing.T) {
	manager := NewMockAdvancedAutonomyManager()
	ctx := context.Background()

	// Test embedding generation
	text := "feat: add user authentication with JWT tokens"
	embeddings, err := manager.GenerateEmbeddings(ctx, text)
	if err != nil {
		t.Fatalf("Failed to generate embeddings: %v", err)
	}

	if len(embeddings) != 384 {
		t.Errorf("Expected 384 dimensions, got %d", len(embeddings))
	}

	// Test deterministic behavior
	embeddings2, err := manager.GenerateEmbeddings(ctx, text)
	if err != nil {
		t.Fatalf("Failed to generate embeddings second time: %v", err)
	}

	for i := 0; i < len(embeddings); i++ {
		if embeddings[i] != embeddings2[i] {
			t.Error("Embeddings should be deterministic")
			break
		}
	}

	// Test commit type prediction
	history := &ProjectHistory{
		TotalCommits:   100,
		CommitPatterns: make(map[string]int),
	}

	predictedType, confidence, err := manager.PredictCommitType(ctx, embeddings, history)
	if err != nil {
		t.Fatalf("Failed to predict commit type: %v", err)
	}

	if predictedType == "" {
		t.Error("Predicted type should not be empty")
	}

	if confidence <= 0 || confidence > 1 {
		t.Errorf("Confidence should be between 0 and 1, got %.2f", confidence)
	}

	// Test conflict detection
	files := []string{"main.go", "go.mod", "config/app.yaml"}
	conflictProb, err := manager.DetectConflicts(ctx, files, embeddings)
	if err != nil {
		t.Fatalf("Failed to detect conflicts: %v", err)
	}

	if conflictProb < 0 || conflictProb > 1 {
		t.Errorf("Conflict probability should be between 0 and 1, got %.2f", conflictProb)
	}

	t.Logf("✅ Mock Autonomy Manager tests passed:")
	t.Logf("   - Embedding dimensions: %d", len(embeddings))
	t.Logf("   - Predicted type: %s (confidence: %.2f)", predictedType, confidence)
	t.Logf("   - Conflict probability: %.2f", conflictProb)
}

func TestMockContextualMemory(t *testing.T) {
	memory := NewMockContextualMemory()
	ctx := context.Background()

	// Create test commit context
	commitCtx := &CommitContext{
		ContextID:  "test123",
		Message:    "feat: test commit",
		Author:     "test@example.com",
		Timestamp:  time.Now(),
		Embeddings: []float64{0.1, 0.2, 0.3, 0.4, 0.5},
		Confidence: 0.9,
		Keywords:   []string{"feat", "test"},
	}

	// Test storing commit context
	err := memory.StoreCommitContext(ctx, commitCtx)
	if err != nil {
		t.Fatalf("Failed to store commit context: %v", err)
	}

	// Test retrieving similar commits
	similarCommits, err := memory.RetrieveSimilarCommits(ctx, commitCtx.Embeddings, 5)
	if err != nil {
		t.Fatalf("Failed to retrieve similar commits: %v", err)
	}

	if len(similarCommits) == 0 {
		t.Error("Should retrieve at least the stored commit")
	}

	// Test caching embeddings
	key := "test_embedding"
	embeddings := []float64{0.1, 0.2, 0.3}

	err = memory.CacheEmbeddings(key, embeddings)
	if err != nil {
		t.Fatalf("Failed to cache embeddings: %v", err)
	}

	cached, exists := memory.GetCachedEmbeddings(key)
	if !exists {
		t.Error("Cached embeddings should exist")
	}

	if len(cached) != len(embeddings) {
		t.Error("Cached embeddings should match original")
	}

	t.Logf("✅ Mock Contextual Memory tests passed:")
	t.Logf("   - Stored contexts: %d", len(memory.commitStore))
	t.Logf("   - Cached embeddings: %d", len(memory.embeddings))
	t.Logf("   - Retrieved similar commits: %d", len(similarCommits))
}
