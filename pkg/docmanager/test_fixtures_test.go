package docmanager

import (
	"testing"
)

func TestCreateTestDocument(t *testing.T) {
	doc := CreateTestDocument("test-doc-001", "/tmp/test", "Contenu", 1)
	if doc.ID != "test-doc-001" {
		t.Errorf("ID non déterministe: %v", doc.ID)
	}
	if doc.Path != "/tmp/test" {
		t.Errorf("Path incorrect: %v", doc.Path)
	}
	if string(doc.Content) != "Contenu" {
		t.Errorf("Contenu incorrect: %s", string(doc.Content))
	}
	if doc.Version != 1 {
		t.Errorf("Version incorrecte: %d", doc.Version)
	}
}

func TestCreateTestConflict(t *testing.T) {
	docA := CreateTestDocument("A", "/tmp/A", "A", 1)
	docB := CreateTestDocument("B", "/tmp/B", "B", 2)
	conflict := CreateTestConflict(docA, docB)
	if conflict.LocalDoc != docA || conflict.RemoteDoc != docB {
		t.Error("Conflit incorrect")
	}
	if conflict.Type != ContentConflict {
		t.Error("Type de conflit incorrect")
	}
	if conflict.ID != "conflict-001" {
		t.Error("ID de conflit incorrect")
	}
}

func TestCreateTempTestFiles(t *testing.T) {
	files, cleanup := CreateTempTestFiles(2)
	defer cleanup()
	if len(files) != 2 {
		t.Errorf("Nombre de fichiers incorrect: %d", len(files))
	}
	for _, f := range files {
		if f == "" {
			t.Error("Nom de fichier vide")
		}
	}
}
