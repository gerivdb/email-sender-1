// scripts/fix-yaml-advanced_test.go
// Test unitaire pour fix-yaml-advanced.go

package main

import (
	"os"
	"testing"

	"gopkg.in/yaml.v3"
)

func TestFixYAMLFileAdvanced_CorrectsIndentationAndBackup(t *testing.T) {
	tmp := "test-advanced.yaml"
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

	rep := fixYAMLFileAdvanced(tmp)
	if !rep.Changed || len(rep.Errors) > 0 {
		t.Errorf("La correction avancée a échoué: %+v", rep)
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
