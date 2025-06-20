package conflict

import (
	"testing"
)

func BenchmarkPathConflictDetector(b *testing.B) {
	detector := PathConflictDetector{}
	for i := 0; i < b.N; i++ {
		_, _ = detector.Detect("/tmp")
	}
}

func BenchmarkContentConflictDetector(b *testing.B) {
	detector := ContentConflictDetector{}
	files := []string{"/tmp/file1", "/tmp/file2"}
	for i := 0; i < b.N; i++ {
		_, _ = detector.Detect(files)
	}
}

func BenchmarkVersionConflictDetector(b *testing.B) {
	detector := VersionConflictDetector{}
	versions := map[string]string{"modA": "1.0.0", "modB": "0.0.0"}
	for i := 0; i < b.N; i++ {
		_, _ = detector.Detect(versions)
	}
}

func BenchmarkPermissionConflictDetector(b *testing.B) {
	detector := PermissionConflictDetector{}
	files := []string{"/tmp/file1", "/tmp/file2"}
	for i := 0; i < b.N; i++ {
		_, _ = detector.Detect(files)
	}
}
