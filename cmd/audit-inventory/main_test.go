package main

import (
	"os"
	"testing"
)

func TestAuditInventoryGeneration(t *testing.T) {
	// Nettoyage avant test
	_ = os.Remove("audit_inventory.md")
	// Exécution du script principal
	main()
	// Vérification du fichier généré
	if _, err := os.Stat("audit_inventory.md"); os.IsNotExist(err) {
		t.Fatalf("audit_inventory.md n'a pas été généré")
	}
	// Nettoyage après test
	_ = os.Remove("audit_inventory.md")
}
