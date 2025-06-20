package conflict

import (
	"os"
	"path/filepath"
)

// PathConflictDetector detects path-related conflicts (broken links, duplicates).
type PathConflictDetector struct{}

// Detect scans the given root directory for path conflicts.
func (p *PathConflictDetector) Detect(root string) ([]Conflict, error) {
	var conflicts []Conflict
	seen := make(map[string]struct{})
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		// Detect duplicate paths
		if _, exists := seen[path]; exists {
			conflicts = append(conflicts, Conflict{
				Type:         PathConflict,
				Severity:     1,
				Participants: []string{path},
				Metadata:     map[string]interface{}{"reason": "duplicate"},
			})
		} else {
			seen[path] = struct{}{}
		}
		// Detect broken symlinks
		if info.Mode()&os.ModeSymlink != 0 {
			target, err := os.Readlink(path)
			if err != nil || !filepath.IsAbs(target) && !existsPath(filepath.Join(filepath.Dir(path), target)) {
				conflicts = append(conflicts, Conflict{
					Type:         PathConflict,
					Severity:     2,
					Participants: []string{path},
					Metadata:     map[string]interface{}{"reason": "broken symlink"},
				})
			}
		}
		return nil
	})
	return conflicts, err
}

func existsPath(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}
