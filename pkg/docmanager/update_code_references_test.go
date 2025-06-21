package docmanager

import (
	"os"
	"path/filepath"
	"testing"
)

func TestUpdateCodeReferences_ValidGo(t *testing.T) {
	dir := t.TempDir()
	file := filepath.Join(dir, "main.go")
	os.WriteFile(file, []byte(`package main
import "./old/path"
var s = "./old/path/file.md"
`), 0o644)
	err := updateCodeReferences(dir, "./old/path", "./new/path")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	data, _ := os.ReadFile(file)
	if string(data) == "" || !containsAll(string(data), []string{"./new/path"}) {
		t.Error("reference not updated")
	}
}

func TestUpdateCodeReferences_InvalidGo(t *testing.T) {
	dir := t.TempDir()
	file := filepath.Join(dir, "broken.go")
	os.WriteFile(file, []byte(`package main
func {`), 0o644)
	// Should not fail on invalid Go
	err := updateCodeReferences(dir, "./old/path", "./new/path")
	if err != nil {
		t.Fatalf("should not fail on invalid Go: %v", err)
	}
}

func containsAll(s string, subs []string) bool {
	for _, sub := range subs {
		if !contains(s, sub) {
			return false
		}
	}
	return true
}

func contains(s, sub string) bool {
	return len(sub) == 0 || (len(s) >= len(sub) && (s == sub || contains(s[1:], sub)))
}
