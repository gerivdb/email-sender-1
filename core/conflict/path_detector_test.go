package conflict

import (
	"io/ioutil"
	"os"
	"testing"
)

func TestPathConflictDetector_Detect(t *testing.T) {
	dir, err := ioutil.TempDir("", "conflicttest")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	// Create a file
	file1 := dir + "/file1.txt"
	if err := ioutil.WriteFile(file1, []byte("test"), 0o644); err != nil {
		t.Fatal(err)
	}
	// Create a duplicate file (simulate by hard link)
	file2 := dir + "/file1.txt"
	if err := os.Link(file1, file2); err == nil {
		detector := PathConflictDetector{}
		conflicts, _ := detector.Detect(dir)
		if len(conflicts) == 0 {
			t.Error("Expected duplicate path conflict")
		}
	}
	// Create a broken symlink
	symlink := dir + "/broken"
	_ = os.Symlink("/nonexistent", symlink)
	detector := PathConflictDetector{}
	conflicts, _ := detector.Detect(dir)
	found := false
	for _, c := range conflicts {
		if c.Metadata["reason"] == "broken symlink" {
			found = true
		}
	}
	if !found {
		t.Error("Expected broken symlink conflict")
	}
}
