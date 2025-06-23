// SPDX-License-Identifier: MIT
package orchestrator

import (
	"context"
	"testing"
	"time"
)

type mockQDrant struct{}
func (m *mockQDrant) SemanticSearch(query string, filters SearchFilters) ([]string, error) { return []string{"vector1"}, nil }

type mockPostgreSQL struct{}
func (m *mockPostgreSQL) FullTextSearch(query string, filters SearchFilters) ([]string, error) { return []string{"text1"}, nil }

type mockRedis struct{}
func (m *mockRedis) SearchCache(query string, filters SearchFilters) ([]string, error) { return []string{"cache1"}, nil }
func (m *mockRedis) CacheDocument(doc *Document) error { return nil }

func (m *mockPostgreSQL) UpdateDocument(doc *Document) error { return nil }
func (m *mockQDrant) IndexDocument(doc *Document) error { return nil }

func TestTechStackOrchestrator_ProcessDocumentationUpdate(t *testing.T) {
	orch := &TechStackOrchestrator{
		QDrant:     &mockQDrant{},
		PostgreSQL: &mockPostgreSQL{},
		Redis:      &mockRedis{},
		InfluxDB:   nil, // Peut être mocké si besoin
	}
	doc := &Document{ID: "1", Manager: "test", Content: "abc", DocumentType: "API", QualityScore: 90}
	err := orch.ProcessDocumentationUpdate(doc)
	if err != nil {
		t.Errorf("ProcessDocumentationUpdate failed: %v", err)
	}
}

func TestTechStackOrchestrator_HybridIntelligentSearch(t *testing.T) {
	orch := &TechStackOrchestrator{
		QDrant:     &mockQDrant{},
		PostgreSQL: &mockPostgreSQL{},
		Redis:      &mockRedis{},
	}
	filters := SearchFilters{Managers: []string{"test"}}
	results, err := orch.HybridIntelligentSearch("query", filters)
	if err != nil {
		t.Errorf("HybridIntelligentSearch failed: %v", err)
	}
	if results == nil || len(results.Results) != 3 {
		t.Errorf("Expected 3 result sources, got %v", results)
	}
}

func TestTechStackOrchestrator_RealTimeHealthCheck(t *testing.T) {
	orch := &TechStackOrchestrator{}
	health := orch.RealTimeHealthCheck()
	if health == nil || len(health.Services) != 4 {
		t.Errorf("Expected 4 services in health check, got %v", health)
	}
	if health.Services["qdrant"] != "healthy" {
		t.Errorf("QDrant health not healthy")
	}
}
