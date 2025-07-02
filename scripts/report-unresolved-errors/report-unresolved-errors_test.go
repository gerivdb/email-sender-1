// scripts/report-unresolved-errors_test.go
// Test unitaire pour report-unresolved-errors.go

package main

import (
	"os"
	"strings"
	"testing"
)

func TestReportUnresolvedErrors_GeneratesReport(t *testing.T) {
	_ = os.MkdirAll("audit-reports", 0755)
	tmp := "audit-reports/test-report.md"
	content := `
- test.yaml : Erreur : YAML non valide : Unexpected scalar at node end
- test.go.mod : Erreur : unknown directive: m
- test.yaml : OK (aucune correction)
`
	if err := os.WriteFile(tmp, []byte(content), 0644); err != nil {
		t.Fatalf("écriture: %v", err)
	}
	defer os.Remove(tmp)
	defer os.Remove("audit-reports/unresolved-errors.md")

	main()

	data, err := os.ReadFile("audit-reports/unresolved-errors.md")
	if err != nil {
		t.Fatalf("lecture: %v", err)
	}
	out := string(data)
	if !strings.Contains(out, "Erreur") || !strings.Contains(out, "test.go.mod") {
		t.Errorf("Rapport des erreurs non généré correctement:\n%s", out)
	}
}
