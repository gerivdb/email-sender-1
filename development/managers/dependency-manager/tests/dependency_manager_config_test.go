package main

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"go.uber.org/zap"
	"go.uber.org/zap/zaptest"
)

// TestConfigManagerIntegration tests integration with ConfigManager
func TestConfigManagerIntegration(t *testing.T) {
	logger := zaptest.NewLogger(t)
	tempDir := t.TempDir()
	configPath := filepath.Join(tempDir, "dependency-manager.config.json")
	
	// Create a test config file
	configContent := `{
		"name": "dependency-manager",
		"version": "1.0.0",
		"settings": {
			"logPath": "test-logs/dependency-manager.log",
			"logLevel": "info",
			"goModPath": "go.mod",
			"autoTidy": true,
			"vulnerabilityCheck": true,
			"backupOnChange": true
		}
	}`
	
	err := os.WriteFile(configPath, []byte(configContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create test config file: %v", err)
	}
	
	// Create ErrorManager for ConfigManager
	errorManager := &ErrorManagerImpl{logger: logger}
	
	// Create ConfigManager
	configManager := NewDepConfigManager(nil, logger, errorManager)
	
	// Load config file
	err = configManager.LoadConfigFile(configPath, "json")
	if err != nil {
		t.Fatalf("Failed to load config file: %v", err)
	}
	
	// Test GetString
	logPath, err := configManager.GetString("dependency-manager.settings.logPath")
	if err != nil {
		t.Errorf("GetString failed: %v", err)
	}
	if logPath != "test-logs/dependency-manager.log" {
		t.Errorf("Expected logPath to be 'test-logs/dependency-manager.log', got '%s'", logPath)
	}
	
	// Test GetBool
	autoTidy, err := configManager.GetBool("dependency-manager.settings.autoTidy")
	if err != nil {
		t.Errorf("GetBool failed: %v", err)
	}
	if !autoTidy {
		t.Errorf("Expected autoTidy to be true")
	}
	
	// Test IsSet
	if !configManager.IsSet("dependency-manager.settings.logPath") {
		t.Error("IsSet failed for existing key")
	}
	if configManager.IsSet("dependency-manager.nonexistent") {
		t.Error("IsSet incorrectly returned true for non-existent key")
	}
	
	// Test SetDefault and Get
	configManager.SetDefault("dependency-manager.test.default", "default-value")
	value := configManager.Get("dependency-manager.test.default")
	if value != "default-value" {
		t.Errorf("Expected default value to be 'default-value', got '%v'", value)
	}
	
	// Test Set and Get
	configManager.Set("dependency-manager.test.custom", "custom-value")
	customValue := configManager.Get("dependency-manager.test.custom")
	if customValue != "custom-value" {
		t.Errorf("Expected custom value to be 'custom-value', got '%v'", customValue)
	}
	
	// Create DependencyManager with ConfigManager
	manager := &GoModManager{
		modFilePath:   "go.mod",
		configManager: configManager,
		logger:        logger,
		errorManager:  errorManager,
	}
	
	// Test the integration
	// This will use configManager.GetString to get logPath
	manager.Log("TEST", "Config integration test")
	
	// Test backupGoMod which uses configManager.GetBool
	err = manager.backupGoMod()
	if err != nil {
		// We expect an error since we're not actually modifying a real go.mod file
		t.Logf("Expected error in backupGoMod: %v", err)
	}
}

// TestConfigDefaultFallback tests that default config is used when file not found
func TestConfigDefaultFallback(t *testing.T) {
	logger := zaptest.NewLogger(t)
	errorManager := &ErrorManagerImpl{logger: logger}
	
	// Non-existent config path
	nonExistentPath := "/tmp/nonexistent/config.json"
	
	// Create ConfigManager with nil config
	configManager := NewDepConfigManager(nil, logger, errorManager)
	
	// Try to load non-existent file
	err := configManager.LoadConfigFile(nonExistentPath, "json")
	if err == nil {
		// We actually expect it to return nil and use defaults
		t.Logf("LoadConfigFile with non-existent file did not return error, using defaults")
	}
	
	// Check defaults are set
	logLevel, err := configManager.GetString("dependency-manager.settings.logLevel")
	if err != nil {
		t.Errorf("GetString for default logLevel failed: %v", err)
	}
	
	// Default log level should be "info"
	if logLevel != "info" {
		t.Errorf("Expected default logLevel to be 'info', got '%s'", logLevel)
	}
	
	// Test setting required keys and validation
	configManager.SetRequiredKeys([]string{"dependency-manager.settings.logPath"})
	err = configManager.Validate()
	if err != nil {
		t.Errorf("Validation failed: %v", err)
	}
	
	// Test validation with non-existent required key
	configManager.SetRequiredKeys([]string{"dependency-manager.nonexistent"})
	err = configManager.Validate()
	if err == nil {
		t.Error("Expected validation to fail for non-existent required key")
	}
}

// TestErrorManagerIntegration tests integration with ErrorManager
func TestErrorManagerIntegration(t *testing.T) {
	logger := zaptest.NewLogger(t)
	errorManager := &ErrorManagerImpl{logger: logger}
	
	// Create a test context
	ctx := context.Background()
	
	// Test ProcessError
	testErr := errorManager.ProcessError(ctx, 
		        	  	 	       	 	 	      	  	 	   	 	  		 	  		   	 	
		 	 	 	        	   	  	  	   		  			   	  	   	  	 	 	   
		   	   	 	   	   	  	      	  	  	     	 	  	 		   	   	 	 	   
		 	 	 	          		     	 	  	  	     	  	 	 	     		  	     
	 	  		     	 	            		 	 	      	 	 	     	  	     	 	 
	 	   		 	 		  	        		    	 	  	  	 	     	 	     	  	
	 		     	 		      	        	 	 	     	 		   	 	  	    	 	 
	 	     	    		 	  		        	     	 	  	    	 	  	    	 	   
	          	      	 	    	          	      	  	     	 	    	  	 	  
	          	    	 	  	  	          	   	  	  		 	     	 	    	  	 	  
		 	    	  	         	 	        	 	   	 	   	 	        	 		 	   
		  	   	 	    	 	          	    	 	   	 	         	 	   	 		 	  
		   	   	 	  	 	            	    	 	   	 	        	 	     	 	 	  
		  	 	   	     	 	 	       	    	 	      	        	  	  	  	 		 
						
	

// TestStorageManagerIntegration tests integration with StorageManager
func TestStorageManagerIntegration(t *testing.T) {
	logger := zaptest.NewLogger(t)
	errorManager := &ErrorManagerImpl{logger: logger}
	
	// Create mock managers
	configManager := NewDepConfigManager(getDefaultConfig(), logger, errorManager)
	storageManager := NewMockStorageManager(logger)
	
	// Create manager integrator
	integrator := NewManagerIntegrator(logger, errorManager)
	integrator.SetStorageManager(storageManager)
	
	// Create dependency manager with integrator
	manager := &GoModManager{
		modFilePath:       "go.mod",
		configManager:     configManager,
		logger:            logger,
		errorManager:      errorManager,
		managerIntegrator: integrator,
	}
	
	// Test dependencies
	testDeps := []Dependency{
		{Name: "github.com/test/module1", Version: "v1.0.0"},
		{Name: "github.com/test/module2", Version: "v2.0.0"},
	}
	
	// Test persisting dependency metadata
	ctx := context.Background()
	err := integrator.PersistDependencyMetadata(ctx, testDeps)
	if err != nil {
		t.Errorf("PersistDependencyMetadata failed: %v", err)
	}
	
	// Test sync dependency metadata
	err = manager.SyncDependencyMetadata()
	if err != nil {
		t.Errorf("SyncDependencyMetadata failed: %v", err)
	}
	
	// This should retrieve the metadata from the mock storage manager
	enhancedDeps, err := manager.ListWithEnhancedMetadata()
	if err != nil {
		t.Errorf("ListWithEnhancedMetadata failed: %v", err)
	}
	
	// The mock might return empty or have pre-populated data
	t.Logf("Retrieved %d enhanced dependencies", len(enhancedDeps))
}

// TestSecurityManagerIntegration tests integration with SecurityManager
func TestSecurityManagerIntegration(t *testing.T) {
	logger := zaptest.NewLogger(t)
	errorManager := &ErrorManagerImpl{logger: logger}
	
	// Create mock managers
	configManager := NewDepConfigManager(getDefaultConfig(), logger, errorManager)
	securityManager := &MockSecurityManager{logger: logger}
	
	// Create manager integrator
	integrator := NewManagerIntegrator(logger, errorManager)
	integrator.SetSecurityManager(securityManager)
	
	// Create dependency manager with integrator
	manager := &GoModManager{
		modFilePath:       "go.mod",
		configManager:     configManager,
		logger:            logger,
		errorManager:      errorManager,
		managerIntegrator: integrator,
	}
	
	// Test audit with security manager
	err := manager.AuditWithSecurityManager()
	if err != nil {
		t.Errorf("AuditWithSecurityManager failed: %v", err)
	}
}

// Mock types for testing

type MockSecurityManager struct {
	logger *zap.Logger
}

func (m *MockSecurityManager) GetSecret(key string) (string, error) {
	return "mock-secret", nil
}

func (m *MockSecurityManager) EncryptData(data []byte) ([]byte, error) {
	return append([]byte("encrypted:"), data...), nil
}

func (m *MockSecurityManager) DecryptData(encryptedData []byte) ([]byte, error) {
	return []byte("decrypted-data"), nil
}

func (m *MockSecurityManager) ScanForVulnerabilities(ctx context.Context, dependencies []Dependency) (*VulnerabilityReport, error) {
	report := &VulnerabilityReport{
		TotalScanned:         len(dependencies),
		VulnerabilitiesFound: 0,
		Details:              make(map[string]*VulnerabilityInfo),
	}
	
	// For testing purposes, mark one dependency as vulnerable
	if len(dependencies) > 0 {
		report.VulnerabilitiesFound = 1
		report.Details[dependencies[0].Name] = &VulnerabilityInfo{
			Severity:    "medium",
			Description: "Mock vulnerability for testing",
			CVEIDs:      []string{"CVE-TEST-2025-12345"},
			FixVersion:  "v2.0.0",
		}
	}
	
	return report, nil
}

type MockStorageManager struct {
	logger   *zap.Logger
	metadata map[string]*DependencyMetadata
}

func NewMockStorageManager(logger *zap.Logger) *MockStorageManager {
	return &MockStorageManager{
		logger:   logger,
		metadata: make(map[string]*DependencyMetadata),
	}
}

func (m *MockStorageManager) StoreObject(ctx context.Context, key string, data interface{}) error {
	dataBytes, err := json.Marshal(data)
	if err != nil {
		return err
	}
	
	var metadata DependencyMetadata
	if err := json.Unmarshal(dataBytes, &metadata); err != nil {
		return err
	}
	
	m.metadata[metadata.Name] = &metadata
	return nil
}

func (m *MockStorageManager) GetObject(ctx context.Context, key string, target interface{}) error {
	if metadata, exists := m.metadata[key]; exists {
		dataBytes, err := json.Marshal(metadata)
		if err != nil {
			return err
		}
		
		return json.Unmarshal(dataBytes, target)
	}
	
	return nil
}

func (m *MockStorageManager) DeleteObject(ctx context.Context, key string) error {
	delete(m.metadata, key)
	return nil
}

func (m *MockStorageManager) ListObjects(ctx context.Context, prefix string) ([]string, error) {
	var keys []string
	for key := range m.metadata {
		keys = append(keys, key)
	}
	return keys, nil
}
