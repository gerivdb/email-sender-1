// scripts/fix-go-mods_test.go
// Tests unitaires pour fix-go-mods.go

package main

import (
	"os"
	"strings"
	"testing"
)

func TestProcessFile_RemovesForbiddenDirectivesAndLocalImports(t *testing.T) {
	tmp := "test-go.mod"
	content := `
module example.com/test

replace example.com/foo => ./foo
exclude example.com/bar v1.0.0
require example.com/ok v1.2.3
require ./local v0.0.0
`
	if err := os.WriteFile(tmp, []byte(content), 0644); err != nil {
		t.Fatalf("écriture: %v", err)
	}
	defer os.Remove(tmp)
	defer os.Remove(tmp + ".bak")

	err := processFile(tmp)
	if err != nil {
		t.Fatalf("processFile: %v", err)
	}
	data, err := os.ReadFile(tmp)
	if err != nil {
		t.Fatalf("lecture: %v", err)
	}
	out := string(data)
	if strings.Contains(out, "replace") || strings.Contains(out, "exclude") || strings.Contains(out, "./local") {
		t.Errorf("Directives interdites ou imports locaux non supprimés:\n%s", out)
	}
	if !strings.Contains(out, "require example.com/ok v1.2.3") {
		t.Errorf("Ligne valide manquante:\n%s", out)
	}
}
