//go:build unit

package main

import (
	"io/fs"
	"os"
	"path/filepath"
	"testing"
)

// MockFS implémente fs.FS pour simuler un système de fichiers en mémoire
type MockFS struct {
	files map[string][]byte
}

func (m *MockFS) Open(name string) (fs.File, error) {
	content, ok := m.files[name]
	if !ok {
		return nil, fs.ErrNotExist
	}
	return &MockFile{data: content, name: name}, nil
}

type MockFile struct {
	data []byte
	name string
	pos  int
}

func (f *MockFile) Stat() (fs.FileInfo, error) { return nil, nil }
func (f *MockFile) Read(b []byte) (int, error) {
	if f.pos >= len(f.data) {
		return 0, os.EOF
	}
	n := copy(b, f.data[f.pos:])
	f.pos += n
	return n, nil
}
func (f *MockFile) Close() error { return nil }
func (f *MockFile) Name() string { return f.name }

func TestScanProject_Basic_WithMockFS(t *testing.T) {
	// Injection d'un FS mocké
	mockFS := &MockFS{
		files: map[string][]byte{
			"README.md": []byte("# Test Project"),
		},
	}
	// Ici, il faudrait adapter RecensementScanner pour accepter un fs.FS en paramètre (non fait dans la version actuelle)
	// scanner := NewRecensementScannerWithFS(".", false, mockFS)
	// if err := scanner.ScanProject(); err != nil {
	// 	t.Errorf("ScanProject doit réussir avec un FS mocké: %v", err)
	// }
	// if scanner.besoins == nil {
	// 	t.Error("Le champ besoins doit être initialisé")
	// }
	// if scanner.besoins.Metadata.ProjectName == "" {
	// 	t.Error("Le champ ProjectName doit être renseigné")
	// }
	// Pour l’instant, on garde le test classique :
	tmpDir := t.TempDir()
	readme := filepath.Join(tmpDir, "README.md")
	if err := os.WriteFile(readme, []byte("# Test Project"), 0644); err != nil {
		t.Fatalf("Erreur création README.md: %v", err)
	}
	scanner := NewRecensementScanner(tmpDir, false)
	if err := scanner.ScanProject(); err != nil {
		t.Errorf("ScanProject doit réussir sur un projet minimal: %v", err)
	}
	if scanner.besoins == nil {
		t.Error("Le champ besoins doit être initialisé")
	}
	if scanner.besoins.Metadata.ProjectName == "" {
		t.Error("Le champ ProjectName doit être renseigné")
	}
}
