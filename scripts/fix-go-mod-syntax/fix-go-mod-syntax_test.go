// scripts/fix-go-mod-syntax_test.go
// Test unitaire pour fix-go-mod-syntax.go

package main

import (
	"os"
	"strings"
	"testing"
)

func TestFixGoModSyntax_CorrectsModuleLineAndDirectives(t *testing.T) {
	tmp := "test-go.mod"
	content := `m odule github.com/foo/bar
r equire github.com/bar/baz v1.2.3
e xclude github.com/err/err v0.0.1
`
	if err := os.WriteFile(tmp, []byte(content), 0644); err != nil {
		t.Fatalf("écriture: %v", err)
	}
	defer os.Remove(tmp)
	defer os.Remove(tmp + ".bak")

	changed, err := fixGoModSyntax(tmp)
	if err != nil {
		t.Fatalf("fixGoModSyntax: %v", err)
	}
	if !changed {
		t.Errorf("Le fichier aurait dû être corrigé")
	}
	data, err := os.ReadFile(tmp)
	if err != nil {
		t.Fatalf("lecture: %v", err)
	}
	out := string(data)
	if !strings.HasPrefix(out, "module ") {
		t.Errorf("La première ligne n'est pas corrigée en 'module ...':\n%s", out)
	}
	if strings.Contains(out, "m odule") || strings.Contains(out, "r equire") || strings.Contains(out, "e xclude") {
		t.Errorf("Directives mal orthographiées non corrigées:\n%s", out)
	}
}
