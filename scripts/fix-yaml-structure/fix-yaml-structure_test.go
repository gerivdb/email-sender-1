// scripts/fix-yaml-structure_test.go
package main

import (
	"io/ioutil"
	"os"
	"os/exec"
	"strings"
	"testing"
)

func TestFixYAMLStructure(t *testing.T) {
	tmpfile, err := ioutil.TempFile("", "bad-structure-*.yaml")
	if err != nil {
		t.Fatalf("Erreur création fichier temporaire: %v", err)
	}
	defer os.Remove(tmpfile.Name())

	// YAML mal formé : clé non scalaire
	badYAML := `
? [clé1, clé2]
: valeur
`
	if _, err := tmpfile.Write([]byte(badYAML)); err != nil {
		t.Fatalf("Erreur écriture YAML: %v", err)
	}
	tmpfile.Close()

	cmd := exec.Command("go", "run", "fix-yaml-structure.go", tmpfile.Name())
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Erreur exécution script: %v\nSortie: %s", err, string(out))
	}

	// Vérifie que le rapport est généré et contient la correction
	report, err := ioutil.ReadFile("fix-yaml-structure-report.md")
	if err != nil {
		t.Fatalf("Rapport non généré: %v", err)
	}
	defer os.Remove("fix-yaml-structure-report.md")

	content := string(report)
	if !strings.Contains(content, "Clé non scalaire détectée") {
		t.Errorf("Correction attendue non trouvée dans le rapport:\n%s", content)
	}
}
