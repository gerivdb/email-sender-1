package main

import (
	"os"
	"testing"
)

func TestStandardsInventoryGeneration(t *testing.T) {
	_ = os.Remove("standards_inventory.md")
	main()
	if _, err := os.Stat("standards_inventory.md"); os.IsNotExist(err) {
		t.Fatalf("standards_inventory.md n'a pas été généré")
	}
	_ = os.Remove("standards_inventory.md")
}
