// scripts/backup-restore_test.go
// Test unitaire pour backup-restore.go

package main

import (
	"os"
	"testing"
)

func TestBackupRestore_RestoresBakFile(t *testing.T) {
	orig := "testfile.txt"
	bak := orig + ".bak"
	content := []byte("original")
	bakContent := []byte("backup")

	if err := os.WriteFile(orig, content, 0644); err != nil {
		t.Fatalf("écriture: %v", err)
	}
	if err := os.WriteFile(bak, bakContent, 0644); err != nil {
		t.Fatalf("écriture: %v", err)
	}
	defer os.Remove(orig)
	defer os.Remove(bak)

	main() // exécute la restauration

	data, err := os.ReadFile(orig)
	if err != nil {
		t.Fatalf("lecture: %v", err)
	}
	if string(data) != string(bakContent) {
		t.Errorf("Le contenu restauré ne correspond pas au backup")
	}
}
