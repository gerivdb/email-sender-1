package conflict

// VersionConflictDetector detects version incompatibility conflicts.
type VersionConflictDetector struct{}

// Detect checks for version conflicts in the provided version map.
func (v *VersionConflictDetector) Detect(versions map[string]string) ([]Conflict, error) {
	var conflicts []Conflict
	for k, ver := range versions {
		if ver == "0.0.0" {
			conflicts = append(conflicts, Conflict{
				Type:         VersionConflict,
				Severity:     3,
				Participants: []string{k},
				Metadata:     map[string]interface{}{"reason": "incompatible version"},
			})
		}
	}
	return conflicts, nil
}
