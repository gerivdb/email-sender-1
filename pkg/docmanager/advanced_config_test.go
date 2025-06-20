// SPDX-License-Identifier: MIT
// Package docmanager : tests pour la configuration avancée
// TASK ATOMIQUE 3.3.2.1 & 3.3.2.2 - Advanced Configuration Tests

package docmanager

import (
	"testing"
	"time"
)

// TestNewAdvancedConfig teste la création d'une configuration avancée par défaut
func TestNewAdvancedConfig(t *testing.T) {
	config := NewAdvancedConfig()

	if config == nil {
		t.Fatal("expected non-nil advanced config")
	}

	// Test document types defaults
	if len(config.DocumentTypes) == 0 {
		t.Error("expected default document types to be configured")
	}

	// Test that markdown config exists
	markdownConfig, err := config.GetDocumentTypeConfig("markdown")
	if err != nil {
		t.Errorf("error getting markdown config: %v", err)
	}
	if markdownConfig.Type != "markdown" {
		t.Errorf("expected markdown type, got %s", markdownConfig.Type)
	}

	// Test quality thresholds
	if len(config.QualityThresholds) == 0 {
		t.Error("expected quality thresholds to be configured")
	}

	// Test detailed quality
	if config.DetailedQuality.MinLength <= 0 {
		t.Error("expected positive min length")
	}

	// Test cache defaults
	if config.CacheDefaults.DefaultTTL <= 0 {
		t.Error("expected positive default TTL")
	}
}

// TestAdvancedConfig_Validate teste la validation de configuration avancée
func TestAdvancedConfig_Validate(t *testing.T) {
	tests := []struct {
		name        string
		config      *AdvancedConfig
		shouldError bool
	}{
		{
			name:        "valid default config",
			config:      NewAdvancedConfig(),
			shouldError: false,
		},
		{
			name: "invalid document type config",
			config: &AdvancedConfig{
				DocumentTypes: []DocumentTypeConfig{
					{
						Type:          "", // Invalid: empty type
						CacheStrategy: "lru",
						TTL:           time.Minute,
						Priority:      5,
						MaxSize:       1024,
					},
				},
				DetailedQuality: QualityThresholds{
					MinLength:        100,
					MaxComplexity:    0.8,
					RequiredSections: []string{"title"},
					LinkDensity:      0.1,
					KeywordDensity:   0.05,
					ReadabilityScore: 0.6,
					CustomThresholds: make(map[string]float64),
					ValidationRules:  make(map[string]interface{}),
				},
				CacheDefaults: CacheDefaultConfig{
					DefaultTTL:      time.Minute,
					DefaultStrategy: "lru",
					DefaultPriority: 5,
					MaxMemoryUsage:  1024 * 1024,
					EvictionPolicy:  "lru",
				},
				AutoGeneration: AutoGenerationConfig{
					QualityGates:         make(map[string]float64),
					GenerationStrategies: []string{"template"},
				},
				Monitoring: MonitoringConfig{
					MetricsInterval: time.Minute,
					AlertThresholds: make(map[string]float64),
				},
			},
			shouldError: true,
		},
		{
			name: "invalid quality thresholds",
			config: &AdvancedConfig{
				DocumentTypes: []DocumentTypeConfig{
					{
						Type:          "test",
						CacheStrategy: "lru",
						TTL:           time.Minute,
						Priority:      5,
						MaxSize:       1024,
					},
				},
				DetailedQuality: QualityThresholds{
					MinLength:        -1, // Invalid: negative
					MaxComplexity:    0.8,
					RequiredSections: []string{"title"},
					LinkDensity:      0.1,
					KeywordDensity:   0.05,
					ReadabilityScore: 0.6,
					CustomThresholds: make(map[string]float64),
					ValidationRules:  make(map[string]interface{}),
				},
				CacheDefaults: CacheDefaultConfig{
					DefaultTTL:      time.Minute,
					DefaultStrategy: "lru",
					DefaultPriority: 5,
					MaxMemoryUsage:  1024 * 1024,
					EvictionPolicy:  "lru",
				},
				AutoGeneration: AutoGenerationConfig{
					QualityGates:         make(map[string]float64),
					GenerationStrategies: []string{"template"},
				},
				Monitoring: MonitoringConfig{
					MetricsInterval: time.Minute,
					AlertThresholds: make(map[string]float64),
				},
			},
			shouldError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.config.Validate()

			if tt.shouldError {
				if err == nil {
					t.Errorf("expected error for test '%s', but got none", tt.name)
				}
			} else {
				if err != nil {
					t.Errorf("unexpected error for test '%s': %v", tt.name, err)
				}
			}
		})
	}
}

// TestDocumentTypeConfig_Validate teste la validation de configuration par type de document
func TestDocumentTypeConfig_Validate(t *testing.T) {
	tests := []struct {
		name        string
		config      DocumentTypeConfig
		shouldError bool
	}{
		{
			name: "valid config",
			config: DocumentTypeConfig{
				Type:          "markdown",
				CacheStrategy: "lru",
				TTL:           time.Minute,
				Priority:      5,
				MaxSize:       1024,
				Compression:   true,
			},
			shouldError: false,
		},
		{
			name: "empty type",
			config: DocumentTypeConfig{
				Type:          "",
				CacheStrategy: "lru",
				TTL:           time.Minute,
				Priority:      5,
				MaxSize:       1024,
			},
			shouldError: true,
		},
		{
			name: "invalid cache strategy",
			config: DocumentTypeConfig{
				Type:          "test",
				CacheStrategy: "invalid",
				TTL:           time.Minute,
				Priority:      5,
				MaxSize:       1024,
			},
			shouldError: true,
		},
		{
			name: "zero TTL",
			config: DocumentTypeConfig{
				Type:          "test",
				CacheStrategy: "lru",
				TTL:           0,
				Priority:      5,
				MaxSize:       1024,
			},
			shouldError: true,
		},
		{
			name: "invalid priority",
			config: DocumentTypeConfig{
				Type:          "test",
				CacheStrategy: "lru",
				TTL:           time.Minute,
				Priority:      0,
				MaxSize:       1024,
			},
			shouldError: true,
		},
		{
			name: "zero max size",
			config: DocumentTypeConfig{
				Type:          "test",
				CacheStrategy: "lru",
				TTL:           time.Minute,
				Priority:      5,
				MaxSize:       0,
			},
			shouldError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.config.Validate()

			if tt.shouldError {
				if err == nil {
					t.Errorf("expected error for config '%s', but got none", tt.name)
				}
			} else {
				if err != nil {
					t.Errorf("unexpected error for config '%s': %v", tt.name, err)
				}
			}
		})
	}
}

// TestQualityThresholds_Validate teste la validation des seuils de qualité
func TestQualityThresholds_Validate(t *testing.T) {
	tests := []struct {
		name        string
		thresholds  QualityThresholds
		shouldError bool
	}{
		{
			name: "valid thresholds",
			thresholds: QualityThresholds{
				MinLength:        100,
				MaxComplexity:    0.8,
				RequiredSections: []string{"title", "content"},
				LinkDensity:      0.1,
				KeywordDensity:   0.05,
				ReadabilityScore: 0.6,
				CustomThresholds: map[string]float64{
					"custom": 0.7,
				},
				ValidationRules: map[string]interface{}{
					"rule": true,
				},
			},
			shouldError: false,
		},
		{
			name: "negative min length",
			thresholds: QualityThresholds{
				MinLength:        -1,
				MaxComplexity:    0.8,
				RequiredSections: []string{"title"},
				LinkDensity:      0.1,
				KeywordDensity:   0.05,
				ReadabilityScore: 0.6,
				CustomThresholds: make(map[string]float64),
				ValidationRules:  make(map[string]interface{}),
			},
			shouldError: true,
		},
		{
			name: "invalid max complexity",
			thresholds: QualityThresholds{
				MinLength:        100,
				MaxComplexity:    1.5,
				RequiredSections: []string{"title"},
				LinkDensity:      0.1,
				KeywordDensity:   0.05,
				ReadabilityScore: 0.6,
				CustomThresholds: make(map[string]float64),
				ValidationRules:  make(map[string]interface{}),
			},
			shouldError: true,
		},
		{
			name: "no required sections",
			thresholds: QualityThresholds{
				MinLength:        100,
				MaxComplexity:    0.8,
				RequiredSections: []string{},
				LinkDensity:      0.1,
				KeywordDensity:   0.05,
				ReadabilityScore: 0.6,
				CustomThresholds: make(map[string]float64),
				ValidationRules:  make(map[string]interface{}),
			},
			shouldError: true,
		},
		{
			name: "invalid custom threshold",
			thresholds: QualityThresholds{
				MinLength:        100,
				MaxComplexity:    0.8,
				RequiredSections: []string{"title"},
				LinkDensity:      0.1,
				KeywordDensity:   0.05,
				ReadabilityScore: 0.6,
				CustomThresholds: map[string]float64{
					"invalid": 1.5,
				},
				ValidationRules: make(map[string]interface{}),
			},
			shouldError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.thresholds.Validate()

			if tt.shouldError {
				if err == nil {
					t.Errorf("expected error for thresholds '%s', but got none", tt.name)
				}
			} else {
				if err != nil {
					t.Errorf("unexpected error for thresholds '%s': %v", tt.name, err)
				}
			}
		})
	}
}

// TestAdvancedConfig_GetDocumentTypeConfig teste la récupération de configuration par type
func TestAdvancedConfig_GetDocumentTypeConfig(t *testing.T) {
	config := NewAdvancedConfig()

	// Test existing type
	markdownConfig, err := config.GetDocumentTypeConfig("markdown")
	if err != nil {
		t.Errorf("error getting markdown config: %v", err)
	}
	if markdownConfig.Type != "markdown" {
		t.Errorf("expected markdown type, got %s", markdownConfig.Type)
	}

	// Test non-existing type (should return default)
	unknownConfig, err := config.GetDocumentTypeConfig("unknown")
	if err != nil {
		t.Errorf("error getting unknown config: %v", err)
	}
	if unknownConfig.Type != "unknown" {
		t.Errorf("expected unknown type, got %s", unknownConfig.Type)
	}
	if unknownConfig.CacheStrategy != config.CacheDefaults.DefaultStrategy {
		t.Errorf("expected default cache strategy %s, got %s", config.CacheDefaults.DefaultStrategy, unknownConfig.CacheStrategy)
	}
}

// TestAdvancedConfig_SetDocumentTypeConfig teste la mise à jour de configuration par type
func TestAdvancedConfig_SetDocumentTypeConfig(t *testing.T) {
	config := NewAdvancedConfig()

	// Test adding new config
	newConfig := DocumentTypeConfig{
		Type:          "xml",
		CacheStrategy: "lfu",
		TTL:           45 * time.Minute,
		Priority:      8,
		MaxSize:       2048,
		Compression:   true,
	}

	err := config.SetDocumentTypeConfig(newConfig)
	if err != nil {
		t.Errorf("error setting new config: %v", err)
	}

	// Verify it was added
	retrievedConfig, err := config.GetDocumentTypeConfig("xml")
	if err != nil {
		t.Errorf("error getting xml config: %v", err)
	}
	if retrievedConfig.Priority != 8 {
		t.Errorf("expected priority 8, got %d", retrievedConfig.Priority)
	}

	// Test updating existing config
	updatedConfig := DocumentTypeConfig{
		Type:          "markdown",
		CacheStrategy: "fifo",
		TTL:           60 * time.Minute,
		Priority:      9,
		MaxSize:       4096,
		Compression:   false,
	}

	err = config.SetDocumentTypeConfig(updatedConfig)
	if err != nil {
		t.Errorf("error updating config: %v", err)
	}

	// Verify it was updated
	retrievedConfig, err = config.GetDocumentTypeConfig("markdown")
	if err != nil {
		t.Errorf("error getting updated markdown config: %v", err)
	}
	if retrievedConfig.CacheStrategy != "fifo" {
		t.Errorf("expected fifo strategy, got %s", retrievedConfig.CacheStrategy)
	}

	// Test invalid config
	invalidConfig := DocumentTypeConfig{
		Type:          "",
		CacheStrategy: "lru",
		TTL:           time.Minute,
		Priority:      5,
		MaxSize:       1024,
	}

	err = config.SetDocumentTypeConfig(invalidConfig)
	if err == nil {
		t.Error("expected error for invalid config, but got none")
	}
}

// TestAdvancedConfig_EvaluateQuality teste l'évaluation de qualité
func TestAdvancedConfig_EvaluateQuality(t *testing.T) {
	config := NewAdvancedConfig()

	tests := []struct {
		name             string
		content          string
		metadata         map[string]interface{}
		expectedMinScore float64
		expectedMaxScore float64
	}{
		{
			name: "high quality content",
			content: `# Title
			
This is a comprehensive content piece with multiple paragraphs and good structure.
It contains all required sections including title and substantial content.

## Content Section

The content is well-structured with appropriate length and complexity.
It maintains good readability while providing valuable information.

Links are used sparingly: http://example.com for reference.`,
			metadata:         map[string]interface{}{},
			expectedMinScore: 0.7,
			expectedMaxScore: 1.0,
		},
		{
			name:             "low quality content",
			content:          "Short content without title.",
			metadata:         map[string]interface{}{},
			expectedMinScore: 0.0,
			expectedMaxScore: 0.5,
		},
		{
			name: "medium quality content",
			content: `Title: Test

This content has some structure but could be improved.
It has the basic requirements but lacks depth.`,
			metadata:         map[string]interface{}{},
			expectedMinScore: 0.4,
			expectedMaxScore: 0.8,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			score, scores, err := config.EvaluateQuality(tt.content, tt.metadata)
			if err != nil {
				t.Errorf("error evaluating quality: %v", err)
			}

			if score < tt.expectedMinScore || score > tt.expectedMaxScore {
				t.Errorf("expected score between %f and %f, got %f", tt.expectedMinScore, tt.expectedMaxScore, score)
			}

			// Verify individual scores exist
			expectedMetrics := []string{"length", "complexity", "link_density", "sections"}
			for _, metric := range expectedMetrics {
				if _, exists := scores[metric]; !exists {
					t.Errorf("expected score for metric '%s'", metric)
				}
			}
		})
	}
}

// TestCacheDefaultConfig_Validate teste la validation de configuration de cache par défaut
func TestCacheDefaultConfig_Validate(t *testing.T) {
	tests := []struct {
		name        string
		config      CacheDefaultConfig
		shouldError bool
	}{
		{
			name: "valid config",
			config: CacheDefaultConfig{
				DefaultTTL:      time.Minute,
				DefaultStrategy: "lru",
				DefaultPriority: 5,
				MaxMemoryUsage:  1024 * 1024,
				EvictionPolicy:  "lru-expire",
			},
			shouldError: false,
		},
		{
			name: "zero TTL",
			config: CacheDefaultConfig{
				DefaultTTL:      0,
				DefaultStrategy: "lru",
				DefaultPriority: 5,
				MaxMemoryUsage:  1024 * 1024,
				EvictionPolicy:  "lru",
			},
			shouldError: true,
		},
		{
			name: "invalid strategy",
			config: CacheDefaultConfig{
				DefaultTTL:      time.Minute,
				DefaultStrategy: "invalid",
				DefaultPriority: 5,
				MaxMemoryUsage:  1024 * 1024,
				EvictionPolicy:  "lru",
			},
			shouldError: true,
		},
		{
			name: "invalid priority",
			config: CacheDefaultConfig{
				DefaultTTL:      time.Minute,
				DefaultStrategy: "lru",
				DefaultPriority: 0,
				MaxMemoryUsage:  1024 * 1024,
				EvictionPolicy:  "lru",
			},
			shouldError: true,
		},
		{
			name: "zero memory usage",
			config: CacheDefaultConfig{
				DefaultTTL:      time.Minute,
				DefaultStrategy: "lru",
				DefaultPriority: 5,
				MaxMemoryUsage:  0,
				EvictionPolicy:  "lru",
			},
			shouldError: true,
		},
		{
			name: "invalid eviction policy",
			config: CacheDefaultConfig{
				DefaultTTL:      time.Minute,
				DefaultStrategy: "lru",
				DefaultPriority: 5,
				MaxMemoryUsage:  1024 * 1024,
				EvictionPolicy:  "invalid",
			},
			shouldError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.config.Validate()

			if tt.shouldError {
				if err == nil {
					t.Errorf("expected error for config '%s', but got none", tt.name)
				}
			} else {
				if err != nil {
					t.Errorf("unexpected error for config '%s': %v", tt.name, err)
				}
			}
		})
	}
}

// TestAutoGenerationConfig_Validate teste la validation de configuration de génération automatique
func TestAutoGenerationConfig_Validate(t *testing.T) {
	tests := []struct {
		name        string
		config      AutoGenerationConfig
		shouldError bool
	}{
		{
			name: "valid config",
			config: AutoGenerationConfig{
				Enabled: true,
				QualityGates: map[string]float64{
					"min_quality": 0.8,
				},
				TriggerThresholds: map[string]interface{}{
					"threshold": 0.5,
				},
				GenerationStrategies: []string{"template", "ai"},
				ValidationRequired:   true,
			},
			shouldError: false,
		},
		{
			name: "invalid quality gate",
			config: AutoGenerationConfig{
				Enabled: true,
				QualityGates: map[string]float64{
					"invalid": 1.5,
				},
				TriggerThresholds: map[string]interface{}{
					"threshold": 0.5,
				},
				GenerationStrategies: []string{"template"},
				ValidationRequired:   true,
			},
			shouldError: true,
		},
		{
			name: "no generation strategies",
			config: AutoGenerationConfig{
				Enabled: true,
				QualityGates: map[string]float64{
					"min_quality": 0.8,
				},
				TriggerThresholds: map[string]interface{}{
					"threshold": 0.5,
				},
				GenerationStrategies: []string{},
				ValidationRequired:   true,
			},
			shouldError: true,
		},
		{
			name: "invalid generation strategy",
			config: AutoGenerationConfig{
				Enabled: true,
				QualityGates: map[string]float64{
					"min_quality": 0.8,
				},
				TriggerThresholds: map[string]interface{}{
					"threshold": 0.5,
				},
				GenerationStrategies: []string{"invalid"},
				ValidationRequired:   true,
			},
			shouldError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.config.Validate()

			if tt.shouldError {
				if err == nil {
					t.Errorf("expected error for config '%s', but got none", tt.name)
				}
			} else {
				if err != nil {
					t.Errorf("unexpected error for config '%s': %v", tt.name, err)
				}
			}
		})
	}
}
