//go:build unit

package main

import (
	"os"
	"testing"
	"time"
)

func TestWriteFile_Callback(t *testing.T) {
	testPath := "test_callback.txt"
	content := "test"
	called := false
	callback := func(path string) {
		called = true
		if path != testPath {
			t.Errorf("Callback path incorrect: got %s, want %s", path, testPath)
		}
	}
	err := writeFile(testPath, content, callback)
	if err != nil {
		t.Fatalf("Erreur écriture : %v", err)
	}
	if !called {
		t.Error("Callback non déclenché")
	}
	data, err := os.ReadFile(testPath)
	if err != nil {
		t.Fatalf("Erreur lecture fichier écrit : %v", err)
	}
	if string(data) != content {
		t.Errorf("Contenu écrit incorrect : got %s, want %s", string(data), content)
	}
	os.Remove(testPath)
}

func TestWriteFile_AttenteControlee(t *testing.T) {
	testPath := "test_attente.txt"
	content := "test"
	err := writeFile(testPath, content, nil)
	if err != nil {
		t.Fatalf("Erreur écriture/validation : %v", err)
	}
	data, err := os.ReadFile(testPath)
	if err != nil {
		t.Fatalf("Erreur lecture fichier écrit : %v", err)
	}
	if string(data) != content {
		t.Errorf("Contenu écrit incorrect : got %s, want %s", string(data), content)
	}
	os.Remove(testPath)
}

func TestWriteFile_EchecValidation(t *testing.T) {
	// Simule un chemin non accessible pour forcer l'échec
	badPath := "/non_existant_dir/test.txt"
	content := "test"
	start := time.Now()
	err := writeFile(badPath, content, nil)
	if err == nil {
		t.Error("Erreur attendue mais non reçue")
	}
	if time.Since(start) < 500*time.Millisecond {
		t.Error("Attente contrôlée trop courte, boucle non respectée")
	}
}
