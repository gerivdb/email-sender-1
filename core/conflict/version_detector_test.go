package conflict

import "testing"

func TestVersionConflictDetector_Detect(t *testing.T) {
	detector := VersionConflictDetector{}
	versions := map[string]string{
		"moduleA": "1.2.3",
		"moduleB": "0.0.0",
	}
	conflicts, _ := detector.Detect(versions)
	found := false
	for _, c := range conflicts {
		if c.Participants[0] == "moduleB" && c.Type == VersionConflict {
			found = true
		}
	}
	if !found {
		t.Error("Expected version conflict for moduleB")
	}
}
