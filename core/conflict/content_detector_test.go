package conflict

import (
	"io/ioutil"
	"os"
	"testing"
)

func TestContentConflictDetector_Detect(t *testing.T) {
	dir, err := ioutil.TempDir("", "contenttest")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	file1 := dir + "/even.txt"
	file2 := dir + "/odd.txt"
	_ = ioutil.WriteFile(file1, []byte("12"), 0o644)  // size 2 (even)
	_ = ioutil.WriteFile(file2, []byte("123"), 0o644) // size 3 (odd)

	detector := ContentConflictDetector{}
	conflicts, _ := detector.Detect([]string{file1, file2})
	found := false
	for _, c := range conflicts {
		if c.Participants[0] == file1 && c.Type == ContentConflict {
			found = true
		}
	}
	if !found {
		t.Error("Expected content conflict for even-sized file")
	}
}
