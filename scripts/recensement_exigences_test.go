// Test de complétude de l’extraction YAML des exigences agents
package main

import (
	"os"
	"testing"

	"gopkg.in/yaml.v3"
)

type Exigences struct {
	Exigences []Exigence `yaml:"exigences"`
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

	// Charger le YAML
	data, err := os.ReadFile("exigences-interoperabilite.yaml")
	if err != nil {
		t.Fatalf("Impossible de lire le fichier YAML: %v", err)
	}
	var parsed Exigences
	if err := yaml.Unmarshal(data, &parsed); err != nil {
		t.Fatalf("Erreur de parsing YAML: %v", err)
	}

	// Indexation des agents extraits
	found := map[string]Exigence{}
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
	if len(found["DocManager"].Interfaces) == 0 {
		t.Error("DocManager doit avoir des interfaces documentées")
	}
	if len(found["N8NManager"].Interfaces) == 0 {
		t.Error("N8NManager doit avoir des interfaces documentées")
	}
	if len(found["ErrorManager"].Interfaces) == 0 {
		t.Error("ErrorManager doit avoir des interfaces documentées")
	}

	// Vérification du nombre total d’agents
	if len(parsed.Exigences) < len(expectedAgents) {
		t.Errorf("Nombre d’agents extraits (%d) inférieur au nombre attendu (%d)", len(parsed.Exigences), len(expectedAgents))
	}
}
