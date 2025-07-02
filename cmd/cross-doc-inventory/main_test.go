package main

import (
	"os"
	"testing"
)

func TestCrossDocInventoryGeneration(t *testing.T) {
	_ = os.Remove("cross_doc_inventory.md")
	main()
	if _, err := os.Stat("cross_doc_inventory.md"); os.IsNotExist(err) {
		t.Fatalf("cross_doc_inventory.md n'a pas été généré")
	}
	_ = os.Remove("cross_doc_inventory.md")
}
