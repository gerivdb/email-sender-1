package conflict

import (
	"testing"
)

func TestIntegration_DetectionEngine(t *testing.T) {
	// Simulate integration scenario: path, content, version, permission
	pathDetector := PathConflictDetector{}
	contentDetector := ContentConflictDetector{}
	versionDetector := VersionConflictDetector{}
	permissionDetector := PermissionConflictDetector{}

	// Dummy data
	files := []string{"/tmp/file1", "/tmp/file2"}
	versions := map[string]string{"modA": "1.0.0", "modB": "0.0.0"}

	_, _ = pathDetector.Detect("/tmp")
	_, _ = contentDetector.Detect(files)
	_, _ = versionDetector.Detect(versions)
	_, _ = permissionDetector.Detect(files)

	// No assertion: just ensure no panic and all detectors callable
}
