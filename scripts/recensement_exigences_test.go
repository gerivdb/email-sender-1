// Test Roo-Code : ce fichier vérifie la complétude des exigences agents extraites par [`main.go`](scripts/recensement_exigences/main.go:1).
// Limite : aucune fonction exportée n’est testable directement (pas d’API Go publique dans main.go). Pour une couverture optimale, prévoir d’exposer une fonction d’extraction testable dans [`main.go`](scripts/recensement_exigences/main.go:1).
package main

// Test de complétude de l’extraction YAML des exigences agents

import (
	"os"
	"testing"

	"gopkg.in/yaml.v3"
)

type Exigences struct {
	Exigences []struct {
		Dependencies []string `yaml:"dependencies,omitempty"`
		Agent        string   `yaml:"agent"`
		Description  string   `yaml:"description"`
		Interfaces   []string `yaml:"interfaces,omitempty"`
		Extensions   []string `yaml:"extensions,omitempty"`
		DependsOn    []string `yaml:"depends_on,omitempty"`
	} `yaml:"exigences"`
}

func TestExigencesCompletes(t *testing.T) {
	expectedAgents := []string{
		"DocManager", "ConfigurableSyncRuleManager", "SmartMergeManager", "SyncHistoryManager", "ConflictManager",
		"ExtensibleManagerType", "N8NManager", "ErrorManager", "ScriptManager", "StorageManager", "SecurityManager",
		"MonitoringManager", "MaintenanceManager", "MigrationManager", "NotificationManagerImpl", "ChannelManagerImpl",
		"AlertManagerImpl", "SmartVariableSuggestionManager", "ProcessManager", "ContextManager", "ModeManager",
		"RoadmapManager", "RollbackManager", "CleanupManager", "QdrantManager", "SimpleAdvancedAutonomyManager",
		"VersionManagerImpl", "VectorOperationsManager",
	}

	yamlPaths := []string{
		"exigences-interoperabilite.yaml",
		"./exigences-interoperabilite.yaml",
		"../exigences-interoperabilite.yaml",
		"../../exigences-interoperabilite.yaml",
	}
	var data []byte
	var err error
	for _, path := range yamlPaths {
		data, err = os.ReadFile(path)
		if err == nil {
			break
		}
	}
	if err != nil {
		t.Fatalf("Impossible de lire le fichier YAML à l'un des emplacements testés: %v", err)
	}
	var parsed Exigences
	if err := yaml.Unmarshal(data, &parsed); err != nil {
		t.Fatalf("Erreur de parsing YAML: %v", err)
	}

	// Indexation des agents extraits
	found := map[string]struct {
		Dependencies []string `yaml:"dependencies,omitempty"`
		Agent        string   `yaml:"agent"`
		Description  string   `yaml:"description"`
		Interfaces   []string `yaml:"interfaces,omitempty"`
		Extensions   []string `yaml:"extensions,omitempty"`
		DependsOn    []string `yaml:"depends_on,omitempty"`
	}{}
	for _, ex := range parsed.Exigences {
		found[ex.Agent] = ex
	}

	// Vérification de la présence de tous les agents attendus
	for _, agent := range expectedAgents {
		if _, ok := found[agent]; !ok {
			t.Errorf("Agent manquant dans le YAML: %s", agent)
		}
	}

	// Vérification d’exemples clés (présence d’interfaces pour DocManager, N8NManager, ErrorManager)
	if doc, ok := found["DocManager"]; ok {
		if len(doc.Interfaces) == 0 {
			t.Error("DocManager doit avoir des interfaces documentées")
		}
	}
	if n8n, ok := found["N8NManager"]; ok {
		if len(n8n.Interfaces) == 0 {
			t.Error("N8NManager doit avoir des interfaces documentées")
		}
	}
	if errm, ok := found["ErrorManager"]; ok {
		if len(errm.Interfaces) == 0 {
			t.Error("ErrorManager doit avoir des interfaces documentées")
		}
	}

	// Vérification du nombre total d’agents
	if len(parsed.Exigences) < len(expectedAgents) {
		t.Errorf("Nombre d’agents extraits (%d) inférieur au nombre attendu (%d)", len(parsed.Exigences), len(expectedAgents))
	}
}
