package scanmodules

import (
	"os"
	"testing"
)

func TestScanDir(t *testing.T) {
	// Crée un dossier temporaire avec un fichier factice pour le test
	tmpDir := t.TempDir()
	testFile := tmpDir + "/test.go"
	os.WriteFile(testFile, []byte("package main\n"), 0o644)

	modules, err := ScanDir(tmpDir)
	if err != nil {
		t.Fatalf("Erreur lors du scan: %v", err)
	}
	if len(modules) != 1 {
		t.Errorf("Attendu 1 module, obtenu %d", len(modules))
	}
	if modules[0].Lang != "Go" {
		t.Errorf("Langage détecté incorrect: %s", modules[0].Lang)
	}
}
