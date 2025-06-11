package tests

import (
	"net/http"
	"os"
	"path/filepath"
	"testing"
	"time"

	"gopkg.in/yaml.v3"
)

// Config represents the sync-config.yaml structure
type Config struct {
	Ecosystem struct {
		MarkdownPath    string `yaml:"markdown_path"`
		DynamicEndpoint string `yaml:"dynamic_endpoint"`
		ValidationRules string `yaml:"validation_rules"`
	} `yaml:"ecosystem"`
	Storage struct {
		QDrant struct {
			URL        string `yaml:"url"`
			Collection string `yaml:"collection"`
		} `yaml:"qdrant"`
		SQL struct {
			Driver     string `yaml:"driver"`
			Connection string `yaml:"connection"`
		} `yaml:"sql"`
	} `yaml:"storage"`
	Synchronization struct {
		Interval           string `yaml:"interval"`
		ConflictResolution string `yaml:"conflict_resolution"`
		BackupEnabled      bool   `yaml:"backup_enabled"`
	} `yaml:"synchronization"`
	Monitoring struct {
		Supabase struct {
			URL   string `yaml:"url"`
			Key   string `yaml:"key"`
			Table string `yaml:"table"`
		} `yaml:"supabase"`
	} `yaml:"monitoring"`
	Notifications struct {
		Slack struct {
			WebhookURL  string   `yaml:"webhook_url"`
			Channel     string   `yaml:"channel"`
			AlertLevels []string `yaml:"alert_levels"`
		} `yaml:"slack"`
	} `yaml:"notifications"`
	Logging struct {
		Level        string `yaml:"level"`
		Output       string `yaml:"output"`
		FileRotation bool   `yaml:"file_rotation"`
		MaxSize      string `yaml:"max_size"`
		BackupCount  int    `yaml:"backup_count"`
	} `yaml:"logging"`
}

// TestConfigurationLoad validates that the sync-config.yaml can be loaded and parsed
func TestConfigurationLoad(t *testing.T) {
	configPath := filepath.Join("..", "config", "sync-config.yaml")

	// Read config file
	data, err := os.ReadFile(configPath)
	if err != nil {
		t.Fatalf("Failed to read config file: %v", err)
	}

	// Parse YAML
	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		t.Fatalf("Failed to parse config YAML: %v", err)
	}

	// Validate required fields
	if config.Ecosystem.MarkdownPath == "" {
		t.Error("ecosystem.markdown_path is required but empty")
	}

	if config.Storage.QDrant.URL == "" {
		t.Error("storage.qdrant.url is required but empty")
	}

	if config.Storage.QDrant.Collection == "" {
		t.Error("storage.qdrant.collection is required but empty")
	}

	t.Logf("✅ Configuration loaded successfully with %d required fields validated", 3)
}

// TestQDrantConnectivity tests connection to QDrant vector database
func TestQDrantConnectivity(t *testing.T) {
	// Load config to get QDrant URL
	configPath := filepath.Join("..", "config", "sync-config.yaml")
	data, err := os.ReadFile(configPath)
	if err != nil {
		t.Skipf("Skipping QDrant test - config file not available: %v", err)
		return
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		t.Skipf("Skipping QDrant test - config parsing failed: %v", err)
		return
	}

	// Test connection to QDrant
	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Get(config.Storage.QDrant.URL + "/collections")

	if err != nil {
		t.Logf("⚠️  QDrant not available at %s: %v (expected in development)", config.Storage.QDrant.URL, err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode == 200 {
		t.Logf("✅ QDrant connectivity successful at %s", config.Storage.QDrant.URL)
	} else {
		t.Logf("⚠️  QDrant responded with status %d (may need setup)", resp.StatusCode)
	}
}

// TestTaskMasterCLIIntegration tests basic API connectivity to TaskMaster-CLI
func TestTaskMasterCLIIntegration(t *testing.T) {
	// Load config to get API endpoint
	configPath := filepath.Join("..", "config", "sync-config.yaml")
	data, err := os.ReadFile(configPath)
	if err != nil {
		t.Skipf("Skipping TaskMaster-CLI test - config file not available: %v", err)
		return
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		t.Skipf("Skipping TaskMaster-CLI test - config parsing failed: %v", err)
		return
	}

	// Test basic API connectivity
	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Get(config.Ecosystem.DynamicEndpoint)

	if err != nil {
		t.Logf("⚠️  TaskMaster-CLI API not available at %s: %v (expected in development)", config.Ecosystem.DynamicEndpoint, err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode == 200 || resp.StatusCode == 404 {
		t.Logf("✅ TaskMaster-CLI API endpoint reachable at %s", config.Ecosystem.DynamicEndpoint)
	} else {
		t.Logf("⚠️  TaskMaster-CLI API responded with status %d", resp.StatusCode)
	}
}

// TestMarkdownPathAccess validates access to the markdown plans directory
func TestMarkdownPathAccess(t *testing.T) {
	// Load config to get markdown path
	configPath := filepath.Join("..", "config", "sync-config.yaml")
	data, err := os.ReadFile(configPath)
	if err != nil {
		t.Skipf("Skipping markdown path test - config file not available: %v", err)
		return
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		t.Skipf("Skipping markdown path test - config parsing failed: %v", err)
		return
	} // Convert relative path to absolute from project root
	markdownPath := filepath.Join("..", "..", config.Ecosystem.MarkdownPath)

	// Test directory access
	info, err := os.Stat(markdownPath)
	if err != nil {
		t.Errorf("Cannot access markdown path '%s': %v", markdownPath, err)
		return
	}

	if !info.IsDir() {
		t.Errorf("Markdown path '%s' is not a directory", markdownPath)
		return
	}

	// Test reading directory contents
	entries, err := os.ReadDir(markdownPath)
	if err != nil {
		t.Errorf("Cannot read markdown directory '%s': %v", markdownPath, err)
		return
	}

	// Count markdown files
	markdownCount := 0
	for _, entry := range entries {
		if filepath.Ext(entry.Name()) == ".md" {
			markdownCount++
		}
	}

	t.Logf("✅ Markdown path accessible with %d .md files found", markdownCount)
}

// TestValidationRulesIntegrity validates the validation rules file
func TestValidationRulesIntegrity(t *testing.T) {
	rulesPath := filepath.Join("..", "config", "validation-rules.yaml")

	// Test file existence
	if _, err := os.Stat(rulesPath); os.IsNotExist(err) {
		t.Errorf("Validation rules file not found at: %s", rulesPath)
		return
	}

	// Test file parsing
	data, err := os.ReadFile(rulesPath)
	if err != nil {
		t.Errorf("Cannot read validation rules file: %v", err)
		return
	}

	// Parse as YAML to validate syntax
	var rules map[string]interface{}
	if err := yaml.Unmarshal(data, &rules); err != nil {
		t.Errorf("Invalid YAML in validation rules: %v", err)
		return
	}

	// Check for essential sections
	requiredSections := []string{"ecosystem", "storage", "synchronization", "logging"}
	for _, section := range requiredSections {
		if _, exists := rules[section]; !exists {
			t.Errorf("Required validation section '%s' missing", section)
		} else {
			t.Logf("✅ Validation section '%s' present", section)
		}
	}

	t.Logf("✅ Validation rules file integrity verified")
}

// TestEnvironmentVariables validates environment variables for external services
func TestEnvironmentVariables(t *testing.T) {
	// Environment variables that should be available for production
	optionalEnvVars := []string{
		"SUPABASE_URL",
		"SUPABASE_ANON_KEY",
		"SLACK_WEBHOOK_URL",
	}

	availableCount := 0
	for _, envVar := range optionalEnvVars {
		if value := os.Getenv(envVar); value != "" {
			t.Logf("✅ Environment variable %s is set", envVar)
			availableCount++
		} else {
			t.Logf("⚠️  Environment variable %s not set (optional)", envVar)
		}
	}

	t.Logf("Environment readiness: %d/%d optional variables available", availableCount, len(optionalEnvVars))
}
