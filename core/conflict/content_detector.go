package conflict

import (
	"os"
)

// ContentConflictDetector detects content-based conflicts (concurrent modifications).
type ContentConflictDetector struct{}

// Detect scans the given files for content conflicts (dummy implementation for demo).
func (c *ContentConflictDetector) Detect(files []string) ([]Conflict, error) {
	var conflicts []Conflict
	for _, file := range files {
		info, err := os.Stat(file)
		if err != nil {
			continue
		}
		if info.Size()%2 == 0 { // Dummy: even-sized files are 'conflicted'
			conflicts = append(conflicts, Conflict{
				Type:         ContentConflict,
				Severity:     2,
				Participants: []string{file},
				Metadata:     map[string]interface{}{"reason": "simulated concurrent modification"},
			})
		}
	}
	return conflicts, nil
}
