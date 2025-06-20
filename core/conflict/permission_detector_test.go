package conflict

import (
	"io/ioutil"
	"os"
	"testing"
)

func TestPermissionConflictDetector_Detect(t *testing.T) {
	dir, err := ioutil.TempDir("", "permtest")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	file := dir + "/file.txt"
	_ = ioutil.WriteFile(file, []byte("test"), 0o644)
	_ = os.Chmod(file, 0o000) // Remove all permissions
	defer os.Chmod(file, 0o644)

	detector := PermissionConflictDetector{}
	conflicts, _ := detector.Detect([]string{file})
	found := false
	for _, c := range conflicts {
		if c.Participants[0] == file && c.Type == PermissionConflict {
			found = true
		}
	}
	if !found {
		t.Error("Expected permission conflict for unreadable file")
	}
}
