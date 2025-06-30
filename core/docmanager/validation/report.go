// core/docmanager/validation/report.go
// Structure de rapport de validation DocManager v66

package validation

type Document struct {
	// Ajoutez les champs pertinents pour un document ici
	// Par exemple:
	ID      string
	Content string
	IsValid bool
}

type ValidationIssue struct {
	Type    string
	Message string
	Fixable bool
}

type ValidationReport struct {
	Issues    []ValidationIssue
	Summary   string
	Validated bool
}
