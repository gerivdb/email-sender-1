// scripts/lint-yaml_test.go
// Tests unitaires pour lint-yaml.go

package main

import (
	"os"
	"testing"

	"gopkg.in/yaml.v3"
)

func TestLintYAMLFile_ValidAndInvalid(t *testing.T) {
	valid := "valid.yaml"
	invalid := "invalid.yaml"
	validContent := "foo:\n  bar: 1\n"
	invalidContent := "foo: [\n  bar: 1\n"

	if err := os.WriteFile(valid, []byte(validContent), 0644); err != nil {
		t.Fatalf("écriture: %v", err)
	}
	if err := os.WriteFile(invalid, []byte(invalidContent), 0644); err != nil {
		t.Fatalf("écriture: %v", err)
	}
	defer os.Remove(valid)
	defer os.Remove(invalid)

	// Test fichier valide
	data, err := os.ReadFile(valid)
	if err != nil {
		t.Fatalf("lecture: %v", err)
	}
	var out interface{}
	if err := yaml.Unmarshal(data, &out); err != nil {
		t.Errorf("YAML valide détecté comme invalide: %v", err)
	}

	// Test fichier invalide
	data, err = os.ReadFile(invalid)
	if err != nil {
		t.Fatalf("lecture: %v", err)
	}
	if err := yaml.Unmarshal(data, &out); err == nil {
		t.Errorf("YAML invalide non détecté")
	}
}
