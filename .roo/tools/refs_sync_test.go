// +build unit

package main

import (
"os"
"path/filepath"
"testing"
"reflect"
"io/ioutil"
"gopkg.in/yaml.v3"
)

// Mock de ScanRulesDir pour tester la détection des fichiers .md dans .roo/rules/
func ScanRulesDir(dir string) ([]string, error) {
	var files []string
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
}

// Test de parsing du fichier de configuration YAML
func TestParseRefsSyncConfig(t *testing.T) {
	data, err := ioutil.ReadFile(".roo/tools/refs_sync.config.yaml")
	if err != nil {
		t.Fatalf("Erreur lecture config: %v", err)
	}
	var cfg map[string]interface{}
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		t.Fatalf("Erreur parsing YAML: %v", err)
	}
	required := []string{"include", "exclude", "format", "personnalisation"}
	for _, k := range required {
		if _, ok := cfg[k]; !ok {
			t.Errorf("Clé manquante dans la config: %s", k)
		}
	}
}
	for _, entry := range entries {
		if !entry.IsDir() && filepath.Ext(entry.Name()) == ".md" {
			files = append(files, entry.Name())
		}
	}
	return files, nil
}

func TestScanRulesDir(t *testing.T) {
	expected := []string{
		"README.md",
		"rules-agents.md",
		"rules-code.md",
		"rules-debug.md",
		"rules-documentation.md",
		"rules-maintenance.md",
		"rules-migration.md",
		"rules-orchestration.md",
		"rules-plugins.md",
		"rules-security.md",
		"rules.md",
		"tools-registry.md",
		"workflows-matrix.md",
	}
	result, err := ScanRulesDir(".roo/rules/")
	if err != nil {
		t.Fatalf("Erreur lors du scan : %v", err)
	}
	if !reflect.DeepEqual(result, expected) {
		t.Errorf("Liste des fichiers incorrecte.\nAttendu : %v\nObtenu : %v", expected, result)
	}
}
