package conflict

import (
	"os"
	"path/filepath"
	"testing"
)

func TestPermissionConflictDetector_Detect(t *testing.T) {
	dir, err := os.MkdirTemp("", "permtest") // Use os.MkdirTemp
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	detector := PermissionConflictDetector{}

	// Test with a non-existent file to simulate an unreadable scenario more reliably
	nonExistentFile := filepath.Join(dir, "non_existent_file.txt")
	conflicts, err := detector.Detect([]string{nonExistentFile})
	if err != nil {
		t.Fatalf("Detector.Detect returned an unexpected error for non-existent file: %v", err)
	}

	found := false
	for _, c := range conflicts {
		if c.Participants[0] == nonExistentFile && c.Type == PermissionConflict {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("Expected permission conflict for non-existent file '%s', but none was found.", nonExistentFile)
	}
}
