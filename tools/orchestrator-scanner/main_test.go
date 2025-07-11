package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestExtractDescription(t *testing.T) {
	// Créer un fichier temporaire avec une description
	tmpDir := os.TempDir()
	testFile := filepath.Join(tmpDir, "test_description.go")

	// Contenu du fichier de test
	content := `package test

// Description: Ceci est une description de test
func main() {
	// Code ici
}
`

	// Écrire le contenu dans le fichier
	err := os.WriteFile(testFile, []byte(content), 0644)
	if err != nil {
		t.Fatalf("Erreur lors de la création du fichier de test: %v", err)
	}
	defer os.Remove(testFile)

	// Tester l'extraction de la description
	description := extractDescription(testFile)
	expected := "Ceci est une description de test"

	if description != expected {
		t.Errorf("extractDescription() = %q, attendu %q", description, expected)
	}
}

func TestExtractHooksAndEndpoints(t *testing.T) {
	// Créer un fichier temporaire avec des hooks et endpoints
	tmpDir := os.TempDir()
	testFile := filepath.Join(tmpDir, "test_manager.go")

	// Contenu du fichier de test
	content := `package test

func RegisterComponents() {
	RegisterHook("pre-commit")
	AddHook("post-update")
	RegisterEndpoint("api/events")
	AddEndpoint("webhook/notify")
}
`

	// Écrire le contenu dans le fichier
	err := os.WriteFile(testFile, []byte(content), 0644)
	if err != nil {
		t.Fatalf("Erreur lors de la création du fichier de test: %v", err)
	}
	defer os.Remove(testFile)

	// Tester l'extraction des hooks et endpoints
	hooks, endpoints := extractHooksAndEndpoints(testFile)

	// Vérifier les hooks
	expectedHooks := []string{"pre-commit", "post-update"}
	if len(hooks) != len(expectedHooks) {
		t.Errorf("Nombre de hooks incorrect: %d, attendu %d", len(hooks), len(expectedHooks))
	}

	for i, hook := range expectedHooks {
		if i < len(hooks) && hooks[i] != hook {
			t.Errorf("Hook[%d] = %q, attendu %q", i, hooks[i], hook)
		}
	}

	// Vérifier les endpoints
	expectedEndpoints := []string{"api/events", "webhook/notify"}
	if len(endpoints) != len(expectedEndpoints) {
		t.Errorf("Nombre d'endpoints incorrect: %d, attendu %d", len(endpoints), len(expectedEndpoints))
	}

	for i, endpoint := range expectedEndpoints {
		if i < len(endpoints) && endpoints[i] != endpoint {
			t.Errorf("Endpoint[%d] = %q, attendu %q", i, endpoints[i], endpoint)
		}
	}
}

func TestFindProjectRoot(t *testing.T) {
	// Cette fonction est difficile à tester de manière isolée
	// car elle dépend de la structure du système de fichiers
	// On vérifie simplement qu'elle ne renvoie pas une chaîne vide
	root := findProjectRoot()
	if root == "" {
		t.Error("findProjectRoot() a retourné une chaîne vide")
	}
}

func TestGenerateMarkdownReport(t *testing.T) {
	// Créer un inventaire de test
	inventory := OrchestratorInventory{
		Managers: []Manager{
			{
				Name:        "test_manager.go",
				Path:        "path/to/test_manager.go",
				Type:        "Go",
				Description: "Test manager",
				Hooks:       []string{"hook1", "hook2"},
				Endpoints:   []string{"endpoint1", "endpoint2"},
			},
		},
		Hooks: []Hook{
			{
				Name:        "test_hook.go",
				Path:        "path/to/test_hook.go",
				Type:        "Go",
				Description: "Test hook",
				Events:      []string{"event1", "event2"},
			},
		},
		Scripts: []Script{
			{
				Name:        "test_script.go",
				Path:        "path/to/test_script.go",
				Type:        "Go",
				Description: "Test script",
				Triggers:    []string{"trigger1", "trigger2"},
			},
		},
		Events: []Event{
			{
				Name:        "test_event",
				Type:        "System",
				Description: "Test event",
				Producers:   []string{"producer1", "producer2"},
				Consumers:   []string{"consumer1", "consumer2"},
			},
		},
	}

	// Définir les métadonnées
	inventory.Metadata.GeneratedAt = "2023-01-01T00:00:00Z"
	inventory.Metadata.Version = "1.0.0"

	// Générer le rapport
	report := generateMarkdownReport(inventory)

	// Vérifier que le rapport contient les sections attendues
	expectedSections := []string{
		"# Inventaire des Managers, Hooks, Scripts et Événements",
		"## Résumé",
		"## Managers",
		"## Hooks",
		"## Scripts",
		"## Événements",
	}

	for _, section := range expectedSections {
		if !strings.Contains(report, section) {
			t.Errorf("Le rapport ne contient pas la section: %s", section)
		}
	}

	// Vérifier que les données sont présentes
	expectedData := []string{
		"test_manager.go",
		"test_hook.go",
		"test_script.go",
		"test_event",
		"hook1, hook2",
		"endpoint1, endpoint2",
		"event1, event2",
		"trigger1, trigger2",
		"producer1, producer2",
		"consumer1, consumer2",
	}

	for _, data := range expectedData {
		if !strings.Contains(report, data) {
			t.Errorf("Le rapport ne contient pas les données: %s", data)
		}
	}
}