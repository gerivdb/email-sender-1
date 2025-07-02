// scripts/fix-github-workflows_test.go
// Test unitaire pour fix-github-workflows.go

package main

import (
	"os"
	"testing"
)

func TestFindInvalidContextVars(t *testing.T) {
	line := "image: ${{ secrets.LOWERCASE_REPO }}/foo:latest"
	found := findInvalidContextVars(line)
	if len(found) == 0 || found[0] != "LOWERCASE_REPO" {
		t.Errorf("LOWERCASE_REPO aurait dû être détecté")
	}
}

func TestSuggestFix(t *testing.T) {
	if suggestFix("LOWERCASE_REPO") == "" {
		t.Errorf("Suggestion manquante pour LOWERCASE_REPO")
	}
}

func TestWorkflowDetectionAndReport(t *testing.T) {
	tmp := ".github/workflows/test-workflow.yml"
	_ = os.MkdirAll(".github/workflows", 0755)
	content := `
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo ${{ secrets.LOWERCASE_REPO }}
      - run: echo ${{ env.VERSION }}
`
	if err := os.WriteFile(tmp, []byte(content), 0644); err != nil {
		t.Fatalf("écriture: %v", err)
	}
	defer os.Remove(tmp)

	// On simule l'exécution principale
	main()

	// Vérifie que le rapport a été généré
	report := "audit-reports/github-workflows-fix-report.md"
	data, err := os.ReadFile(report)
	if err != nil {
		t.Fatalf("lecture rapport: %v", err)
	}
	out := string(data)
	if !(contains(out, "LOWERCASE_REPO") && contains(out, "VERSION")) {
		t.Errorf("Variables contextuelles non détectées dans le rapport: %s", out)
	}
}

func contains(s, sub string) bool {
	return len(s) >= len(sub) && (s == sub || (len(s) > len(sub) && (contains(s[1:], sub) || contains(s[:len(s)-1], sub))))
}
