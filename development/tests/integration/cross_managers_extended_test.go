// === CONTINUATION OF CROSS MANAGERS INTEGRATION TESTS ===

// TestEndToEndCompleteWorkflow teste le workflow complet end-to-end
func (suite *CrossManagersTestSuite) TestEndToEndCompleteWorkflow() {
	suite.T().Log("=== Test End-to-End Complete Workflow ===")

	// Micro-étape 5.1.2.1.3: Test end-to-end complet

	// Phase 1: Setup test data
	testDeps := []Dependency{
		{
			Name:        "critical-security-lib",
			Version:     "3.0.0",
			Type:        "go",
			Description: "Critical security library for authentication and authorization",
			Metadata:    map[string]string{"category": "security", "priority": "high"},
		},
	}

	testSchema := Schema{
		Name: "user_authentication",
		Fields: map[string]FieldType{
			"username": {Type: "string", Required: true, Description: "User login name"},
			"password": {Type: "string", Required: true, Description: "Encrypted password"},
			"role":     {Type: "string", Required: true, Description: "User role"},
		},
		Version: "1.0.0",
	}

	testPolicy := SecurityPolicy{
		ID:   "pol_001",
		Name: "Authentication Policy",
		Rules: []SecurityRule{
			{ID: "rule_001", Description: "Password complexity", Pattern: "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$", Severity: "high"},
		},
		Priority: 1,
	}

	// Phase 2: Dependency Manager Operations
	suite.T().Log("Phase 2: Testing Dependency Manager Operations")

	err := suite.dependencyManager.EnableVectorization()
	require.NoError(suite.T(), err, "Should enable vectorization")

	err = suite.dependencyManager.AutoVectorize(suite.ctx, testDeps)
	require.NoError(suite.T(), err, "Should auto-vectorize dependencies")

	// Phase 3: Storage Manager Operations
	suite.T().Log("Phase 3: Testing Storage Manager Operations")

	err = suite.storageManager.AutoIndex(suite.ctx, testSchema)
	require.NoError(suite.T(), err, "Should auto-index schema")

	schemaVector, err := suite.storageManager.VectorizeSchema(suite.ctx, testSchema)
	require.NoError(suite.T(), err, "Should vectorize schema")
	assert.NotEmpty(suite.T(), schemaVector, "Schema vector should not be empty")

	// Phase 4: Security Manager Operations
	suite.T().Log("Phase 4: Testing Security Manager Operations")

	policyVector, err := suite.securityManager.VectorizePolicy(suite.ctx, testPolicy)
	require.NoError(suite.T(), err, "Should vectorize security policy")
	assert.NotEmpty(suite.T(), policyVector, "Policy vector should not be empty")

	// Simulate potential vulnerability
	testVuln := Vulnerability{
		ID:          "vuln_001",
		CVE:         "CVE-2024-0001",
		Description: "Buffer overflow in authentication module",
		Severity:    "high",
		Component:   "auth-lib",
		Vector:      "network",
	}

	classification, err := suite.securityManager.ClassifyVulnerability(suite.ctx, testVuln)
	require.NoError(suite.T(), err, "Should classify vulnerability")
	assert.NotEmpty(suite.T(), classification.Category, "Classification should have category")

	// Phase 5: Planning Ecosystem Sync
	suite.T().Log("Phase 5: Testing Planning Ecosystem Sync")

	err = suite.planningEcosync.SyncWithDependencyManager(suite.ctx)
	require.NoError(suite.T(), err, "Should sync with dependency manager")

	conflicts, err := suite.planningEcosync.DetectConflicts(suite.ctx)
	require.NoError(suite.T(), err, "Should detect conflicts")

	// Phase 6: Cross-Manager Communication
	suite.T().Log("Phase 6: Testing Cross-Manager Communication")

	// Test vectorization event propagation
	event := VectorizationEvent{
		Type:   "end_to_end_test",
		Source: "integration_test",
		Target: "all_managers",
		Data: map[string]interface{}{
			"test_id":      "e2e_001",
			"dependencies": len(testDeps),
			"schemas":      1,
			"policies":     1,
		},
		Timestamp: time.Now(),
	}

	// Notify all managers
	err = suite.dependencyManager.NotifyVectorizationEvent(suite.ctx, event)
	require.NoError(suite.T(), err, "Dependency manager should handle event")

	err = suite.planningEcosync.HandleVectorizationEvent(suite.ctx, event)
	require.NoError(suite.T(), err, "Planning ecosystem sync should handle event")

	// Phase 7: Semantic Search Across Managers
	suite.T().Log("Phase 7: Testing Semantic Search Across Managers")

	// Test semantic search in dependency manager
	depResults, err := suite.dependencyManager.SearchSemantic(suite.ctx, "authentication security", 5)
	require.NoError(suite.T(), err, "Should perform semantic search in dependencies")
	assert.NotEmpty(suite.T(), depResults, "Should find semantic matches in dependencies")

	// Test semantic search in storage manager
	storageOptions := SearchOptions{
		Limit:     5,
		Threshold: 0.7,
		Filters:   map[string]interface{}{"type": "schema"},
	}

	storageResults, err := suite.storageManager.SearchSemantic(suite.ctx, "user authentication", storageOptions)
	require.NoError(suite.T(), err, "Should perform semantic search in storage")
	assert.NotEmpty(suite.T(), storageResults, "Should find semantic matches in storage")

	// Phase 8: Performance and Metrics Validation
	suite.T().Log("Phase 8: Testing Performance and Metrics")

	securityMetrics := suite.securityManager.GetSecurityMetrics()
	assert.Greater(suite.T(), securityMetrics.TotalPolicies, 0, "Should have policies")

	syncStatus := suite.planningEcosync.GetSyncStatus()
	assert.True(suite.T(), syncStatus.IsActive, "Sync should be active")

	// Phase 9: Cleanup and State Verification
	suite.T().Log("Phase 9: Testing Cleanup and State Verification")

	err = suite.storageManager.OptimizeStorage(suite.ctx)
	require.NoError(suite.T(), err, "Should optimize storage")

	// Verify final state
	assert.True(suite.T(), suite.dependencyManager.GetVectorizationStatus(), "Vectorization should remain enabled")

	// Test anomaly detection with the integrated data
	anomalies, err := suite.securityManager.DetectAnomalies(suite.ctx, map[string]interface{}{
		"dependencies": testDeps,
		"schema":       testSchema,
		"policy":       testPolicy,
	})
	require.NoError(suite.T(), err, "Should detect anomalies")

	suite.T().Logf("End-to-end test completed successfully. Found %d anomalies", len(anomalies))
}

// TestConcurrentOperations teste les opérations concurrentes entre managers
func (suite *CrossManagersTestSuite) TestConcurrentOperations() {
	suite.T().Log("=== Test Concurrent Operations Between Managers ===")

	const numGoroutines = 10
	const operationsPerGoroutine = 5

	// Test concurrent vectorization operations
	var wg sync.WaitGroup
	errorsChan := make(chan error, numGoroutines*operationsPerGoroutine)

	for i := 0; i < numGoroutines; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()

			for j := 0; j < operationsPerGoroutine; j++ {
				// Concurrent dependency operations
				testDep := Dependency{
					Name:        fmt.Sprintf("concurrent-lib-%d-%d", id, j),
					Version:     "1.0.0",
					Type:        "go",
					Description: fmt.Sprintf("Concurrent test library %d-%d", id, j),
				}

				if err := suite.dependencyManager.AutoVectorize(suite.ctx, []Dependency{testDep}); err != nil {
					errorsChan <- err
					return
				}

				// Concurrent search operations
				if _, err := suite.dependencyManager.SearchSemantic(suite.ctx, fmt.Sprintf("library %d", id), 3); err != nil {
					errorsChan <- err
					return
				}

				// Concurrent sync operations
				if err := suite.planningEcosync.SyncWithDependencyManager(suite.ctx); err != nil {
					errorsChan <- err
					return
				}
			}
		}(i)
	}

	wg.Wait()
	close(errorsChan)

	// Check for errors
	var errors []error
	for err := range errorsChan {
		errors = append(errors, err)
	}

	assert.Empty(suite.T(), errors, "Concurrent operations should not produce errors")
	suite.T().Logf("Concurrent test completed successfully with %d goroutines", numGoroutines)
}

// TestErrorHandlingAndRecovery teste la gestion d'erreurs et la récupération
func (suite *CrossManagersTestSuite) TestErrorHandlingAndRecovery() {
	suite.T().Log("=== Test Error Handling and Recovery ===")

	// Test with invalid dependency
	invalidDep := Dependency{
		Name:        "", // Invalid empty name
		Version:     "invalid-version",
		Type:        "unknown",
		Description: "",
	}

	err := suite.dependencyManager.AutoVectorize(suite.ctx, []Dependency{invalidDep})
	assert.Error(suite.T(), err, "Should fail with invalid dependency")

	// Test recovery after error
	validDep := Dependency{
		Name:        "recovery-test-lib",
		Version:     "1.0.0",
		Type:        "go",
		Description: "Testing recovery after error",
	}

	err = suite.dependencyManager.AutoVectorize(suite.ctx, []Dependency{validDep})
	assert.NoError(suite.T(), err, "Should recover and process valid dependency")

	// Test sync status after errors
	status := suite.planningEcosync.GetSyncStatus()
	suite.T().Logf("Sync status after error recovery: active=%v, errors=%d", status.IsActive, status.ErrorCount)
}

// TestRun lance la suite de tests
func TestCrossManagersIntegration(t *testing.T) {
	suite.Run(t, new(CrossManagersTestSuite))
}

// === MOCK IMPLEMENTATIONS FOR TESTING ===

// MockDependencyManager implémentation mock du gestionnaire de dépendances
type MockDependencyManager struct {
	vectorizationEnabled bool
	dependencies         []Dependency
	events               []VectorizationEvent
}

func NewMockDependencyManager() *MockDependencyManager {
	return &MockDependencyManager{
		vectorizationEnabled: false,
		dependencies:         make([]Dependency, 0),
		events:               make([]VectorizationEvent, 0),
	}
}

func (m *MockDependencyManager) AutoVectorize(ctx context.Context, deps []Dependency) error {
	if !m.vectorizationEnabled {
		return fmt.Errorf("vectorization not enabled")
	}

	for _, dep := range deps {
		if dep.Name == "" {
			return fmt.Errorf("invalid dependency: name cannot be empty")
		}
	}

	m.dependencies = append(m.dependencies, deps...)
	return nil
}

func (m *MockDependencyManager) SearchSemantic(ctx context.Context, query string, limit int) ([]SemanticResult, error) {
	if !m.vectorizationEnabled {
		return nil, fmt.Errorf("vectorization not enabled")
	}

	results := make([]SemanticResult, 0, limit)
	for i, dep := range m.dependencies {
		if i >= limit {
			break
		}

		if strings.Contains(strings.ToLower(dep.Description), strings.ToLower(query)) ||
			strings.Contains(strings.ToLower(dep.Name), strings.ToLower(query)) {
			results = append(results, SemanticResult{
				ID:      dep.Name,
				Score:   0.8,
				Content: dep.Description,
				Metadata: map[string]interface{}{
					"name":    dep.Name,
					"version": dep.Version,
					"type":    dep.Type,
				},
			})
		}
	}

	return results, nil
}

func (m *MockDependencyManager) EnableVectorization() error {
	m.vectorizationEnabled = true
	return nil
}

func (m *MockDependencyManager) DisableVectorization() error {
	m.vectorizationEnabled = false
	return nil
}

func (m *MockDependencyManager) GetVectorizationStatus() bool {
	return m.vectorizationEnabled
}

func (m *MockDependencyManager) NotifyVectorizationEvent(ctx context.Context, event VectorizationEvent) error {
	m.events = append(m.events, event)
	return nil
}

// MockPlanningEcosystemSync implémentation mock du planning ecosystem sync
type MockPlanningEcosystemSync struct {
	isActive   bool
	conflicts  []Conflict
	syncCount  int
	errorCount int
	lastSync   time.Time
	events     []VectorizationEvent
}

func NewMockPlanningEcosystemSync() *MockPlanningEcosystemSync {
	return &MockPlanningEcosystemSync{
		isActive:   true,
		conflicts:  make([]Conflict, 0),
		syncCount:  0,
		errorCount: 0,
		lastSync:   time.Now(),
		events:     make([]VectorizationEvent, 0),
	}
}

func (m *MockPlanningEcosystemSync) SyncWithDependencyManager(ctx context.Context) error {
	m.syncCount++
	m.lastSync = time.Now()
	return nil
}

func (m *MockPlanningEcosystemSync) DetectConflicts(ctx context.Context) ([]Conflict, error) {
	return m.conflicts, nil
}

func (m *MockPlanningEcosystemSync) ResolveConflicts(ctx context.Context, conflicts []Conflict) error {
	// Mock resolution: remove conflicts
	m.conflicts = make([]Conflict, 0)
	return nil
}

func (m *MockPlanningEcosystemSync) HandleVectorizationEvent(ctx context.Context, event VectorizationEvent) error {
	m.events = append(m.events, event)
	return nil
}

func (m *MockPlanningEcosystemSync) GetSyncStatus() SyncStatus {
	return SyncStatus{
		IsActive:      m.isActive,
		LastSync:      m.lastSync,
		ConflictCount: len(m.conflicts),
		ErrorCount:    m.errorCount,
	}
}

// MockStorageManager implémentation mock du gestionnaire de stockage
type MockStorageManager struct {
	schemas []Schema
	indices map[string][]float32
}

func NewMockStorageManager() *MockStorageManager {
	return &MockStorageManager{
		schemas: make([]Schema, 0),
		indices: make(map[string][]float32),
	}
}

func (m *MockStorageManager) AutoIndex(ctx context.Context, data interface{}) error {
	if schema, ok := data.(Schema); ok {
		m.schemas = append(m.schemas, schema)
	}
	return nil
}

func (m *MockStorageManager) VectorizeSchema(ctx context.Context, schema Schema) ([]float32, error) {
	vector := make([]float32, 384) // Mock 384-dimensional vector
	for i := range vector {
		vector[i] = float32(i%100) / 100.0
	}

	m.indices[schema.Name] = vector
	return vector, nil
}

func (m *MockStorageManager) SearchSemantic(ctx context.Context, query string, options SearchOptions) ([]SemanticResult, error) {
	results := make([]SemanticResult, 0, options.Limit)

	for _, schema := range m.schemas {
		if len(results) >= options.Limit {
			break
		}

		if strings.Contains(strings.ToLower(schema.Name), strings.ToLower(query)) {
			results = append(results, SemanticResult{
				ID:      schema.Name,
				Score:   0.85,
				Content: schema.Name,
				Metadata: map[string]interface{}{
					"version": schema.Version,
					"fields":  len(schema.Fields),
				},
			})
		}
	}

	return results, nil
}

func (m *MockStorageManager) OptimizeStorage(ctx context.Context) error {
	// Mock optimization
	return nil
}

// MockSecurityManager implémentation mock du gestionnaire de sécurité
type MockSecurityManager struct {
	policies        []SecurityPolicy
	anomalies       []Anomaly
	vulnerabilities []Vulnerability
}

func NewMockSecurityManager() *MockSecurityManager {
	return &MockSecurityManager{
		policies:        make([]SecurityPolicy, 0),
		anomalies:       make([]Anomaly, 0),
		vulnerabilities: make([]Vulnerability, 0),
	}
}

func (m *MockSecurityManager) VectorizePolicy(ctx context.Context, policy SecurityPolicy) ([]float32, error) {
	m.policies = append(m.policies, policy)

	vector := make([]float32, 384)
	for i := range vector {
		vector[i] = float32((i+policy.Priority)%100) / 100.0
	}

	return vector, nil
}

func (m *MockSecurityManager) DetectAnomalies(ctx context.Context, data interface{}) ([]Anomaly, error) {
	// Mock anomaly detection
	return m.anomalies, nil
}

func (m *MockSecurityManager) ClassifyVulnerability(ctx context.Context, vuln Vulnerability) (Classification, error) {
	m.vulnerabilities = append(m.vulnerabilities, vuln)

	return Classification{
		Category:    "authentication",
		Confidence:  0.92,
		Risk:        vuln.Severity,
		Remediation: "Update to latest version",
	}, nil
}

func (m *MockSecurityManager) GetSecurityMetrics() SecurityMetrics {
	return SecurityMetrics{
		TotalPolicies:     len(m.policies),
		ActivePolicies:    len(m.policies),
		TotalAnomalies:    len(m.anomalies),
		HighRiskAnomalies: 0,
		AverageScore:      0.85,
	}
}

// MockVectorizationEngine implémentation mock du moteur de vectorisation
type MockVectorizationEngine struct {
	cache map[string][]float32
}

func NewMockVectorizationEngine() *MockVectorizationEngine {
	return &MockVectorizationEngine{
		cache: make(map[string][]float32),
	}
}

func (m *MockVectorizationEngine) GenerateEmbedding(ctx context.Context, text string) ([]float32, error) {
	vector := make([]float32, 384)
	for i := range vector {
		vector[i] = float32(len(text)+i) / 1000.0
	}
	return vector, nil
}

func (m *MockVectorizationEngine) ParseMarkdown(content string) (*MarkdownDocument, error) {
	return &MarkdownDocument{
		Title:      "Mock Document",
		Headers:    []string{"Introduction", "Content"},
		Paragraphs: strings.Split(content, "\n"),
		Metadata:   map[string]string{"type": "mock"},
	}, nil
}

func (m *MockVectorizationEngine) CacheEmbedding(key string, embedding []float32) error {
	m.cache[key] = embedding
	return nil
}

func (m *MockVectorizationEngine) GetCachedEmbedding(key string) ([]float32, bool) {
	embedding, exists := m.cache[key]
	return embedding, exists
}
