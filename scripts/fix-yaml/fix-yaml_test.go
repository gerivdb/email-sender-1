// scripts/fix-yaml_test.go
// Tests unitaires pour fix-yaml.go

package main

import (
	"os"
	"testing"

	"gopkg.in/yaml.v3"
)

func TestFixYAMLFile_CorrectsIndentationAndBackup(t *testing.T) {
	tmp := "test.yaml"
	content := `
foo:
  bar: 1
baz:
- a: 2
  b: 3
`
	if err := os.WriteFile(tmp, []byte(content), 0644); err != nil {
		t.Fatalf("écriture: %v", err)
	}
	defer os.Remove(tmp)
	defer os.Remove(tmp + ".bak")

	err := fixYAMLFile(tmp)
	if err != nil {
		t.Fatalf("fixYAMLFile: %v", err)
	}
	data, err := os.ReadFile(tmp)
	if err != nil {
		t.Fatalf("lecture: %v", err)
	}
	var out interface{}
	if err := yaml.Unmarshal(data, &out); err != nil {
		t.Errorf("YAML non valide après correction: %v", err)
	}
	if _, err := os.Stat(tmp + ".bak"); err != nil {
		t.Errorf("Backup .bak non créé")
	}
}
