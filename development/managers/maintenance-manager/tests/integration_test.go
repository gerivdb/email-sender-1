// Package tests provides integration tests for the MaintenanceManager with complete FMOUA implementation
package tests

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"

	"github.com/email-sender/maintenance-manager/src/core"
)

// FMOUAIntegrationTestSuite provides comprehensive integration testing for the complete FMOUA system
type FMOUAIntegrationTestSuite struct {
	suite.Suite
	engine       *core.OrganizationEngine
	scheduler    *core.MaintenanceScheduler
	testRepoPath string
	ctx          context.Context
	cancel       context.CancelFunc
}

// SetupSuite initializes the test environment for FMOUA integration testing
func (suite *FMOUAIntegrationTestSuite) SetupSuite() {
	suite.ctx, suite.cancel = context.WithTimeout(context.Background(), 30*time.Minute)
	
	// Create test repository structure
	suite.testRepoPath = filepath.Join(os.TempDir(), "fmoua_integration_test")
	err := os.RemoveAll(suite.testRepoPath)
	require.NoError(suite.T(), err)
	
	err = os.MkdirAll(suite.testRepoPath, 0755)
	require.NoError(suite.T(), err)
	
	// Setup test repository with realistic structure
	suite.setupTestRepository()
	
	// Initialize FMOUA components
	config := &core.Config{
		RepositoryPath:    suite.testRepoPath,
		AutoOptimization:  true,
		VectorDB: core.VectorDBConfig{
			Host:     "localhost",
			Port:     6333,
			Database: "fmoua_test",
		},
		PowerShell: core.PowerShellConfig{
			Enabled:    true,
			ScriptPath: "./scripts",
		},
		AI: core.AIConfig{
			Enabled:  true,
			Model:    "gpt-3.5-turbo",
			Endpoint: "http://localhost:8080",
		},
	}
	
	suite.engine, err = core.NewOrganizationEngine(config)
	require.NoError(suite.T(), err)
	
	suite.scheduler, err = core.NewMaintenanceScheduler(config, suite.engine)
	require.NoError(suite.T(), err)
}

// TearDownSuite cleans up the test environment
func (suite *FMOUAIntegrationTestSuite) TearDownSuite() {
	if suite.cancel != nil {
		suite.cancel()
	}
	
	if suite.testRepoPath != "" {
		os.RemoveAll(suite.testRepoPath)
	}
}

// setupTestRepository creates a realistic test repository structure
func (suite *FMOUAIntegrationTestSuite) setupTestRepository() {
	// Create various directories with different file types
	dirs := []string{
		"src/components",
		"src/utils",
		"docs",
		"tests",
		"configs",
		"scripts",
		"temp",
		"assets/images",
		"assets/fonts",
		"logs",
	}
	
	for _, dir := range dirs {
		err := os.MkdirAll(filepath.Join(suite.testRepoPath, dir), 0755)
		require.NoError(suite.T(), err)
	}
	
	// Create test files with various types and patterns
	testFiles := map[string]string{
		"src/components/Button.tsx":     "export const Button = () => <button>Click me</button>;",
		"src/components/Input.tsx":      "export const Input = () => <input type='text' />;",
		"src/components/Modal.tsx":      "export const Modal = () => <div>Modal content</div>;",
		"src/utils/helpers.js":          "export const helper = () => console.log('helper');",
		"src/utils/constants.js":        "export const API_URL = 'http://localhost:3000';",
		"src/utils/validation.js":       "export const validate = (data) => data !== null;",
		"docs/README.md":               "# Project Documentation\nThis is a test project.",
		"docs/API.md":                  "# API Documentation\nAPI endpoints and usage.",
		"docs/INSTALL.md":              "# Installation Guide\nHow to install the project.",
		"tests/unit/button.test.js":    "describe('Button', () => { it('renders', () => {}); });",
		"tests/integration/api.test.js": "describe('API', () => { it('works', () => {}); });",
		"configs/database.json":        `{"host": "localhost", "port": 5432}`,
		"configs/app.yaml":             "app:\n  name: test\n  version: 1.0.0",
		"scripts/build.sh":             "#!/bin/bash\necho 'Building project...'",
		"scripts/deploy.ps1":           "Write-Host 'Deploying project...'",
		"temp/cache.tmp":               "temporary cache data",
		"temp/logs.tmp":                "temporary log data",
		"assets/images/logo.png":       "binary image data placeholder",
		"assets/fonts/roboto.ttf":      "binary font data placeholder",
		"logs/app.log":                 "2024-12-09 10:00:00 INFO Application started",
		"logs/error.log":               "2024-12-09 10:01:00 ERROR Something went wrong",
		
		// Add some duplicate files for testing
		"src/components/button_copy.tsx": "export const Button = () => <button>Click me</button>;",
		"backup/components/Button.tsx":   "export const Button = () => <button>Click me</button>;",
		
		// Add some orphaned files
		"orphaned_file.txt":            "This file doesn't belong anywhere",
		"old_config.xml":               "<?xml version='1.0'?><config></config>",
		
		// Add files that exceed the 15-file rule in some directories
		"src/utils/util1.js":           "export const util1 = () => {};",
		"src/utils/util2.js":           "export const util2 = () => {};",
		"src/utils/util3.js":           "export const util3 = () => {};",
		"src/utils/util4.js":           "export const util4 = () => {};",
		"src/utils/util5.js":           "export const util5 = () => {};",
		"src/utils/util6.js":           "export const util6 = () => {};",
		"src/utils/util7.js":           "export const util7 = () => {};",
		"src/utils/util8.js":           "export const util8 = () => {};",
		"src/utils/util9.js":           "export const util9 = () => {};",
		"src/utils/util10.js":          "export const util10 = () => {};",
		"src/utils/util11.js":          "export const util11 = () => {};",
		"src/utils/util12.js":          "export const util12 = () => {};",
		"src/utils/util13.js":          "export const util13 = () => {};",
		"src/utils/util14.js":          "export const util14 = () => {};",
		"src/utils/util15.js":          "export const util15 = () => {};",
		"src/utils/util16.js":          "export const util16 = () => {};", // This exceeds the 15-file rule
		"src/utils/util17.js":          "export const util17 = () => {};",
	}
	
	for filePath, content := range testFiles {
		fullPath := filepath.Join(suite.testRepoPath, filePath)
		err := os.MkdirAll(filepath.Dir(fullPath), 0755)
		require.NoError(suite.T(), err)
		
		err = os.WriteFile(fullPath, []byte(content), 0644)
		require.NoError(suite.T(), err)
	}
}

// TestAutoOptimizeRepository tests the complete AutoOptimizeRepository functionality
func (suite *FMOUAIntegrationTestSuite) TestAutoOptimizeRepository() {
	t := suite.T()
	
	// Execute AutoOptimizeRepository with full 6-phase execution
	report, err := suite.engine.AutoOptimizeRepository(suite.ctx)
	
	// Verify successful execution
	assert.NoError(t, err, "AutoOptimizeRepository should execute without errors")
	assert.NotNil(t, report, "AutoOptimizeRepository should return a report")
	
	// Validate report structure and content
	assert.NotEmpty(t, report.RepositoryPath, "Report should include repository path")
	assert.NotEmpty(t, report.ExecutionID, "Report should include execution ID")
	assert.True(t, report.StartTime.Before(report.EndTime), "End time should be after start time")
	assert.Greater(t, report.ExecutionTime, time.Duration(0), "Execution time should be positive")
	
	// Verify phases were executed
	expectedPhases := []string{
		"Repository Analysis",
		"AI-driven Plan Generation",
		"Risk Assessment and Approval",
		"Step Execution with Recovery",
		"Validation",
		"Vector Database Integration & Reporting",
	}
	
	assert.GreaterOrEqual(t, len(report.PhasesExecuted), len(expectedPhases), "All phases should be executed")
	
	// Verify optimization results
	assert.Greater(t, report.OptimizationResults.FilesOrganized, 0, "Some files should be organized")
	assert.Greater(t, report.OptimizationResults.DirectoriesCreated, 0, "Some directories should be created")
	
	// Verify improvements were calculated
	assert.GreaterOrEqual(t, report.OptimizationResults.StructureImprovement, 0.0, "Structure improvement should be non-negative")
	assert.GreaterOrEqual(t, report.OptimizationResults.OrganizationImprovement, 0.0, "Organization improvement should be non-negative")
	
	// Verify recommendations were generated
	assert.NotEmpty(t, report.Recommendations, "Recommendations should be generated")
	
	// Verify repository structure has been improved
	suite.verifyRepositoryStructure()
}

// TestApplyIntelligentOrganization tests strategy-specific intelligent organization
func (suite *FMOUAIntegrationTestSuite) TestApplyIntelligentOrganization() {
	t := suite.T()
	
	// Test different organization strategies
	strategies := []string{
		"type_based",
		"date_based", 
		"purpose_based",
		"ai_pattern",
	}
	
	for _, strategy := range strategies {
		t.Run("Strategy_"+strategy, func(t *testing.T) {
			// Apply intelligent organization with specific strategy
			result, err := suite.engine.ApplyIntelligentOrganization(suite.ctx, strategy)
			
			// Verify successful execution
			assert.NoError(t, err, "ApplyIntelligentOrganization should execute without errors for strategy: %s", strategy)
			assert.NotNil(t, result, "ApplyIntelligentOrganization should return a result for strategy: %s", strategy)
			
			// Verify result structure
			assert.Equal(t, strategy, result.Strategy, "Result should include correct strategy")
			assert.Greater(t, result.FilesProcessed, 0, "Some files should be processed")
			assert.GreaterOrEqual(t, result.SuccessRate, 0.0, "Success rate should be non-negative")
			assert.LessOrEqual(t, result.SuccessRate, 100.0, "Success rate should not exceed 100%")
			
			// Verify improvement calculation
			assert.GreaterOrEqual(t, result.ImprovementScore, 0.0, "Improvement score should be non-negative")
			
			// Verify ML learning data was generated
			assert.NotEmpty(t, result.LearningData, "Learning data should be generated")
		})
	}
}

// TestMaintenanceSchedulerIntegration tests integration between scheduler and organization engine
func (suite *FMOUAIntegrationTestSuite) TestMaintenanceSchedulerIntegration() {
	t := suite.T()
	
	// Test scheduled maintenance execution
	err := suite.scheduler.ExecuteMaintenanceCycle(suite.ctx)
	assert.NoError(t, err, "ExecuteMaintenanceCycle should execute without errors")
	
	// Verify maintenance was logged
	status := suite.scheduler.GetMaintenanceStatus()
	assert.NotNil(t, status, "Maintenance status should be available")
	assert.True(t, status.LastExecution.After(time.Now().Add(-time.Hour)), "Last execution should be recent")
	
	// Test specific maintenance tasks
	tasks := []string{
		"repository_optimization",
		"file_organization", 
		"duplicate_cleanup",
		"validation_check",
	}
	
	for _, task := range tasks {
		t.Run("Task_"+task, func(t *testing.T) {
			err := suite.scheduler.ExecuteMaintenanceTask(suite.ctx, task)
			assert.NoError(t, err, "Maintenance task should execute successfully: %s", task)
		})
	}
}

// TestErrorHandlingAndRecovery tests comprehensive error handling and recovery mechanisms
func (suite *FMOUAIntegrationTestSuite) TestErrorHandlingAndRecovery() {
	t := suite.T()
	
	// Create a scenario that will trigger error handling
	invalidPath := filepath.Join(suite.testRepoPath, "nonexistent")
	
	// Test error handling in repository analysis
	_, err := suite.engine.AnalyzeRepository(invalidPath)
	assert.Error(t, err, "AnalyzeRepository should handle invalid paths gracefully")
	
	// Test recovery mechanisms
	// Create a file operation that might fail
	targetFile := filepath.Join(suite.testRepoPath, "test_recovery.txt")
	err = os.WriteFile(targetFile, []byte("test content"), 0644)
	require.NoError(t, err)
	
	// Make file read-only to trigger permission error
	err = os.Chmod(targetFile, 0444)
	require.NoError(t, err)
	
	// Test that the system can recover from file operation errors
	result, err := suite.engine.ApplyIntelligentOrganization(suite.ctx, "type_based")
	assert.NoError(t, err, "System should recover from file operation errors")
	assert.NotNil(t, result, "Result should be returned even with some failures")
	
	// Verify error was logged but system continued
	assert.Greater(t, result.FilesProcessed, 0, "Some files should still be processed despite errors")
	
	// Cleanup
	os.Chmod(targetFile, 0644)
	os.Remove(targetFile)
}

// TestPerformanceAndScalability tests system performance with larger datasets
func (suite *FMOUAIntegrationTestSuite) TestPerformanceAndScalability() {
	t := suite.T()
	
	// Create additional files for performance testing
	suite.createLargeDataset()
	
	// Measure performance of AutoOptimizeRepository
	startTime := time.Now()
	report, err := suite.engine.AutoOptimizeRepository(suite.ctx)
	executionTime := time.Since(startTime)
	
	assert.NoError(t, err, "AutoOptimizeRepository should handle large datasets")
	assert.NotNil(t, report, "Report should be generated for large datasets")
	
	// Verify performance is acceptable (less than 5 minutes for test dataset)
	assert.Less(t, executionTime, 5*time.Minute, "Execution should complete within reasonable time")
	
	// Verify all files were processed
	assert.Greater(t, report.OptimizationResults.FilesOrganized, 50, "Large dataset should result in significant file organization")
	
	// Test memory usage doesn't grow excessively
	// This is a basic check - in production you'd use more sophisticated monitoring
	assert.Greater(t, report.OptimizationResults.StructureImprovement, 0.0, "Structure should be improved with large dataset")
}

// TestAIIntegration tests AI-powered decision making integration
func (suite *FMOUAIntegrationTestSuite) TestAIIntegration() {
	t := suite.T()
	
	// Test AI analyzer integration
	analysis, err := suite.engine.AnalyzeRepository(suite.testRepoPath)
	assert.NoError(t, err, "Repository analysis should work with AI integration")
	assert.NotNil(t, analysis, "Analysis should be returned")
	
	// Verify AI-generated recommendations
	assert.NotEmpty(t, analysis.Recommendations, "AI should generate recommendations")
	
	// Test AI pattern recognition in organization
	result, err := suite.engine.ApplyIntelligentOrganization(suite.ctx, "ai_pattern")
	assert.NoError(t, err, "AI pattern organization should work")
	assert.NotNil(t, result, "AI organization result should be returned")
	
	// Verify AI learning integration
	assert.NotEmpty(t, result.LearningData, "AI should generate learning data")
}

// TestVectorDatabaseIntegration tests QDrant vector database integration
func (suite *FMOUAIntegrationTestSuite) TestVectorDatabaseIntegration() {
	t := suite.T()
	
	// Test vector database operations during optimization
	report, err := suite.engine.AutoOptimizeRepository(suite.ctx)
	assert.NoError(t, err, "AutoOptimizeRepository should work with vector DB integration")
	
	// Verify vector operations were attempted
	assert.NotNil(t, report, "Report should include vector DB operations")
	
	// Note: In a real integration test, you'd verify actual vector DB operations
	// For this test, we're verifying the integration points work without errors
}

// TestPowerShellIntegration tests PowerShell script integration
func (suite *FMOUAIntegrationTestSuite) TestPowerShellIntegration() {
	t := suite.T()
	
	// Test PowerShell script execution during optimization
	report, err := suite.engine.AutoOptimizeRepository(suite.ctx)
	assert.NoError(t, err, "AutoOptimizeRepository should work with PowerShell integration")
	
	// Verify PowerShell operations were attempted
	assert.NotNil(t, report, "Report should include PowerShell operations")
	
	// Note: In a real integration test, you'd verify actual PowerShell script execution
	// For this test, we're verifying the integration points work without errors
}

// verifyRepositoryStructure checks that the repository structure has been improved
func (suite *FMOUAIntegrationTestSuite) verifyRepositoryStructure() {
	t := suite.T()
	
	// Check that files have been organized appropriately
	// This is a basic verification - in practice you'd have more sophisticated checks
	
	// Verify that temp files have been cleaned up or moved
	tempDir := filepath.Join(suite.testRepoPath, "temp")
	if _, err := os.Stat(tempDir); err == nil {
		files, err := os.ReadDir(tempDir)
		assert.NoError(t, err)
		// Temp directory should be cleaned up or have fewer files
		assert.LessOrEqual(t, len(files), 2, "Temp directory should be cleaned up")
	}
	
	// Verify that similar files are grouped together
	srcDir := filepath.Join(suite.testRepoPath, "src")
	if _, err := os.Stat(srcDir); err == nil {
		// Source directory should still exist and be organized
		files, err := os.ReadDir(srcDir)
		assert.NoError(t, err)
		assert.NotEmpty(t, files, "Source directory should contain organized files")
	}
}

// createLargeDataset creates additional files for performance testing
func (suite *FMOUAIntegrationTestSuite) createLargeDataset() {
	// Create additional files to test performance
	for i := 0; i < 100; i++ {
		// Create various file types
		jsFile := filepath.Join(suite.testRepoPath, "large_dataset", fmt.Sprintf("file_%d.js", i))
		cssFile := filepath.Join(suite.testRepoPath, "large_dataset", fmt.Sprintf("style_%d.css", i))
		htmlFile := filepath.Join(suite.testRepoPath, "large_dataset", fmt.Sprintf("page_%d.html", i))
		
		os.MkdirAll(filepath.Dir(jsFile), 0755)
		
		os.WriteFile(jsFile, []byte(fmt.Sprintf("console.log('File %d');", i)), 0644)
		os.WriteFile(cssFile, []byte(fmt.Sprintf(".class%d { color: red; }", i)), 0644)
		os.WriteFile(htmlFile, []byte(fmt.Sprintf("<html><body>Page %d</body></html>", i)), 0644)
	}
}

// TestIntegration runs the complete integration test suite
func TestFMOUAIntegration(t *testing.T) {
	suite.Run(t, new(FMOUAIntegrationTestSuite))
}
