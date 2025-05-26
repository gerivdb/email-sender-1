package config

import (
	"os"
	"testing"
	"time"
)

func TestNewConfig(t *testing.T) {
	// Sauvegarde des variables d'environnement à restaurer après le test
	oldHost := os.Getenv("QDRANT_HOST")
	oldPort := os.Getenv("QDRANT_PORT")
	defer func() {
		os.Setenv("QDRANT_HOST", oldHost)
		os.Setenv("QDRANT_PORT", oldPort)
	}()

	// Test avec les valeurs par défaut
	config := NewConfig()
	if config.QdrantHost != "localhost" {
		t.Errorf("Expected default QdrantHost to be 'localhost', got %s", config.QdrantHost)
	}
	if config.QdrantPort != 6333 {
		t.Errorf("Expected default QdrantPort to be 6333, got %d", config.QdrantPort)
	}

	// Test avec surcharge par variables d'environnement
	os.Setenv("QDRANT_HOST", "test-host")
	os.Setenv("QDRANT_PORT", "7000")
	config = NewConfig()
	if config.QdrantHost != "test-host" {
		t.Errorf("Expected QdrantHost to be 'test-host', got %s", config.QdrantHost)
	}
	if config.QdrantPort != 7000 {
		t.Errorf("Expected QdrantPort to be 7000, got %d", config.QdrantPort)
	}
}

func TestConfigValidate(t *testing.T) {
	// Config valide
	config := &Config{
		QdrantHost:        "localhost",
		QdrantPort:        6333,
		Timeout:           30 * time.Second,
		EmbeddingProvider: ProviderSimulation,
		EmbeddingModel:    "all-MiniLM-L6-v2",
		VectorDimensions:  384,
		LogLevel:          LogLevelInfo,
	}

	if err := config.Validate(); err != nil {
		t.Errorf("Valid config should pass validation: %v", err)
	}

	// Test port invalide
	invalidConfig := *config
	invalidConfig.QdrantPort = 70000
	if err := invalidConfig.Validate(); err == nil {
		t.Error("Expected error for invalid port")
	}

	// Test provider invalide
	invalidConfig = *config
	invalidConfig.EmbeddingProvider = "invalid"
	if err := invalidConfig.Validate(); err == nil {
		t.Error("Expected error for invalid provider")
	}

	// Test dimensions invalides
	invalidConfig = *config
	invalidConfig.VectorDimensions = 10
	if err := invalidConfig.Validate(); err == nil {
		t.Error("Expected error for invalid dimensions")
	}

	// Test API key pour OpenAI
	invalidConfig = *config
	invalidConfig.EmbeddingProvider = ProviderOpenAI
	invalidConfig.OpenAIAPIKey = ""
	if err := invalidConfig.Validate(); err == nil {
		t.Error("Expected error for missing OpenAI API key")
	}
}

func TestSetLogLevel(t *testing.T) {
	config := NewConfig()
	config.SetLogLevel(LogLevelDebug)
	if config.LogLevel != LogLevelDebug {
		t.Errorf("Expected LogLevel to be DEBUG, got %s", config.LogLevel)
	}
}
