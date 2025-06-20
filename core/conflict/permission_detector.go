package conflict

import "os"

// PermissionConflictDetector detects permission-related conflicts.
type PermissionConflictDetector struct{}

// Detect checks for permission conflicts in the provided files (dummy: files not readable).
func (p *PermissionConflictDetector) Detect(files []string) ([]Conflict, error) {
	var conflicts []Conflict
	for _, file := range files {
		f, err := os.Open(file)
		if err != nil {
			conflicts = append(conflicts, Conflict{
				Type:         PermissionConflict,
				Severity:     2,
				Participants: []string{file},
				Metadata:     map[string]interface{}{"reason": "unreadable file"},
			})
		} else {
			f.Close()
		}
	}
	return conflicts, nil
}
