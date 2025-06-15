// Package config provides test configuration for Phase 5 validation
package config

import (
	"os"
	"path/filepath"
	"time"
)

// TestConfig configuration pour les tests de la Phase 5
type TestConfig struct {
	// Paths
	ProjectRoot string
	TestDataDir string
	ReportsDir  string
	TempDir     string

	// Qdrant configuration
	QdrantEndpoint string
	QdrantTimeout  time.Duration
	TestCollection string

	// Performance thresholds
	MaxExecutionTime time.Duration
	MaxMemoryUsageMB int
	MinThroughputOPS float64
	MaxErrorRate     float64

	// Concurrency settings
	MaxGoroutines    int
	MaxConcurrentOps int

	// Test environment
	SkipIntegrationTests bool
	SkipBenchmarks       bool
	SkipLoadTests        bool
	ShortMode            bool

	// Validation settings
	RequiredSuccessRate float64
	TimeoutMultiplier   float64
}

// DefaultTestConfig retourne la configuration par défaut pour les tests
func DefaultTestConfig() *TestConfig {
	projectRoot, _ := os.Getwd()

	return &TestConfig{
		// Paths
		ProjectRoot: projectRoot,
		TestDataDir: filepath.Join(projectRoot, "development", "tests", "testdata"),
		ReportsDir:  filepath.Join(projectRoot, "development", "tests", "reports"),
		TempDir:     filepath.Join(os.TempDir(), "phase5_tests"),

		// Qdrant configuration
		QdrantEndpoint: "localhost:6333",
		QdrantTimeout:  30 * time.Second,
		TestCollection: "test_phase5_collection",

		// Performance thresholds
		MaxExecutionTime: 5 * time.Minute,
		MaxMemoryUsageMB: 512,
		MinThroughputOPS: 100.0,
		MaxErrorRate:     0.01, // 1% max error rate

		// Concurrency settings
		MaxGoroutines:    50,
		MaxConcurrentOps: 1000,

		// Test environment
		SkipIntegrationTests: false,
		SkipBenchmarks:       false,
		SkipLoadTests:        false,
		ShortMode:            false,

		// Validation settings
		RequiredSuccessRate: 0.8, // 80% minimum success rate
		TimeoutMultiplier:   1.0,
	}
}

// GetTestConfig crée la configuration en fonction des variables d'environnement
func GetTestConfig() *TestConfig {
	config := DefaultTestConfig()

	// Override avec les variables d'environnement si disponibles
	if endpoint := os.Getenv("QDRANT_ENDPOINT"); endpoint != "" {
		config.QdrantEndpoint = endpoint
	}

	if os.Getenv("SKIP_INTEGRATION_TESTS") == "true" {
		config.SkipIntegrationTests = true
	}

	if os.Getenv("SKIP_BENCHMARKS") == "true" {
		config.SkipBenchmarks = true
	}

	if os.Getenv("SKIP_LOAD_TESTS") == "true" {
		config.SkipLoadTests = true
	}

	if os.Getenv("SHORT_MODE") == "true" {
		config.ShortMode = true
		config.TimeoutMultiplier = 0.1 // Reduce timeouts in short mode
	}

	return config
}

// EnsureDirectories crée les répertoires nécessaires pour les tests
func (c *TestConfig) EnsureDirectories() error {
	dirs := []string{
		c.TestDataDir,
		c.ReportsDir,
		c.TempDir,
	}

	for _, dir := range dirs {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return err
		}
	}

	return nil
}

// GetTimeoutWithMultiplier retourne un timeout avec le multiplicateur appliqué
func (c *TestConfig) GetTimeoutWithMultiplier(baseTimeout time.Duration) time.Duration {
	return time.Duration(float64(baseTimeout) * c.TimeoutMultiplier)
}

// IsCI vérifie si nous sommes dans un environnement CI
func (c *TestConfig) IsCI() bool {
	return os.Getenv("CI") == "true" || os.Getenv("GITHUB_ACTIONS") == "true"
}

// ShouldSkipTest vérifie si un type de test doit être ignoré
func (c *TestConfig) ShouldSkipTest(testType string) bool {
	switch testType {
	case "integration":
		return c.SkipIntegrationTests
	case "benchmark":
		return c.SkipBenchmarks
	case "load":
		return c.SkipLoadTests
	default:
		return false
	}
}
