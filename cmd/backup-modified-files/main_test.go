// cmd/backup-modified-files/main_test.go
// Test de restauration à partir des fichiers .bak

package main

import (
	"os"
	"testing"
)

func TestRestoreBackup(t *testing.T) {
	files := []string{
		"besoins.json", "specs.json", "module-output.json", "reporting.md",
	}
	for _, f := range files {
		bak := f + ".bak"
		if _, err := os.Stat(bak); err != nil {
			t.Errorf("Backup manquant pour %s", f)
		} else {
			t.Logf("Backup présent : %s", bak)
		}
	}
}
