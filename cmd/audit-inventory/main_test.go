// cmd/audit-inventory/main_test.go
package main

import (
	"encoding/json"
	"os"
	"os/exec"
	"testing"
)

func TestInventoryGeneration(t *testing.T) {
	cmd := exec.Command("go", "run", "main.go")
	cmd.Dir = "."
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Erreur exécution script: %v\nSortie: %s", err, string(out))
	}

	// Vérifie la présence du fichier inventaire
	inventoryPath := "projet/roadmaps/plans/consolidated/inventory.json"
	f, err := os.Open(inventoryPath)
	if err != nil {
		t.Fatalf("Fichier inventaire non trouvé: %v", err)
	}
	defer f.Close()

	var files []string
	if err := json.NewDecoder(f).Decode(&files); err != nil {
		t.Fatalf("Erreur décodage JSON: %v", err)
	}
	if len(files) == 0 {
		t.Error("Inventaire vide")
	}
}
