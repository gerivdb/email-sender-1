package conflict

import (
	"io/ioutil"
	"os"
	"testing"
	"time"
)

func TestRealTimeDetector_Watch(t *testing.T) {
	dir, err := ioutil.TempDir("", "realtime")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	detector, err := NewRealTimeDetector()
	if err != nil {
		t.Fatal(err)
	}
	defer detector.Close()

	err = detector.Watch(dir)
	if err != nil {
		t.Fatal(err)
	}

	file := dir + "/file.txt"
	_ = ioutil.WriteFile(file, []byte("test"), 0o644)
	_ = os.Remove(file)

	time.Sleep(100 * time.Millisecond)
	found := false
	for {
		select {
		case c := <-detector.Events:
			if c.Metadata["reason"] == "file removed" {
				found = true
			}
		case <-time.After(200 * time.Millisecond):
			if !found {
				t.Error("Expected real-time conflict event for file removal")
			}
			return
		}
	}
}
