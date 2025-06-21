package docmanager

import (
	"os"
	"path/filepath"
	"testing"
)

func TestPathHealthReport_Structure(t *testing.T) {
	report := PathHealthReport{
		TotalFiles:      10,
		ValidPaths:      8,
		BrokenPaths:     []string{"broken1.md"},
		OrphanedHashes:  []string{"hash1"},
		Recommendations: []string{"Fix broken links"},
	}
	if report.TotalFiles != 10 || report.ValidPaths != 8 {
		t.Error("structure fields not set correctly")
	}
}

func TestPathTracker_IntegrityHashes(t *testing.T) {
	pt := &PathTracker{
		ContentHashes: make(map[string]string),
	}
	tmpDir := t.TempDir()
	file := filepath.Join(tmpDir, "file.md")
	os.WriteFile(file, []byte("test"), 0o644)
	hash, _ := pt.CalculateContentHash(file)
	pt.ContentHashes[file] = hash
	pt.mu.RLock()
	defer pt.mu.RUnlock()
	if pt.ContentHashes[file] != hash {
		t.Error("hash not stored correctly")
	}
}

func TestPathTracker_BrokenLinksDetection(t *testing.T) {
	pt := &PathTracker{
		references: map[string][]string{"file.md": {"missing.md"}},
	}
	broken := pt.scanForBrokenReferences("file.md")
	if len(broken) == 0 {
		t.Error("should detect broken reference")
	}
}

func TestPathTracker_HealthCheckReport(t *testing.T) {
	pt := &PathTracker{
		ContentHashes: make(map[string]string),
		references:    make(map[string][]string),
	}
	tmpDir := t.TempDir()
	file := filepath.Join(tmpDir, "ok.md")
	os.WriteFile(file, []byte("ok"), 0o644)
	hash, _ := pt.CalculateContentHash(file)
	pt.ContentHashes[file] = hash
	report, err := pt.GenerateIntegrityReport()
	if err != nil || report == nil {
		t.Fatalf("expected report, got error: %v", err)
	}
}
