package docmanager

import (
	"os"
	"path/filepath"
	"testing"
)

func TestUpdateMarkdownLinks_Simple(t *testing.T) {
	tmpDir := t.TempDir()
	file1 := filepath.Join(tmpDir, "test1.md")
	os.WriteFile(file1, []byte("[link](./doc.md)"), 0644)
	if err := updateMarkdownLinks(tmpDir); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestUpdateMarkdownLinks_ComplexStructure(t *testing.T) {
	tmpDir := t.TempDir()
	subDir := filepath.Join(tmpDir, "sub")
	os.Mkdir(subDir, 0755)
	file1 := filepath.Join(subDir, "test2.md")
	os.WriteFile(file1, []byte("[doc](../README.md)"), 0644)
	if err := updateMarkdownLinks(tmpDir); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestUpdateMarkdownLinks_Atomicity(t *testing.T) {
	tmpDir := t.TempDir()
	file1 := filepath.Join(tmpDir, "atomic.md")
	os.WriteFile(file1, []byte("[frag](#fragment)"), 0644)
	if err := updateMarkdownLinks(tmpDir); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if _, err := os.Stat(file1 + ".tmp"); err == nil {
		t.Error("temp file should not exist after atomic rename")
	}
}
