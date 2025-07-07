// core/docmanager/validation/conflict_detector.go
// Détection automatique des conflits DocManager v66

package validation

type Conflict struct {
	Type    string
	Details string
}

func DetectConflicts(doc *Document) ([]Conflict, error) {
	// Stub : retourne un conflit fictif pour test
	return []Conflict{{Type: "branch", Details: "Conflit multi-branche"}}, nil
}

func DetectCrossBranchConflicts() ([]Conflict, error) {
	// Stub : retourne un conflit fictif pour test
	return []Conflict{{Type: "cross-branch", Details: "Conflit cross-branch"}}, nil
}
