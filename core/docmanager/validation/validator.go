// core/docmanager/validation/validator.go
// Moteur de validation documentaire DocManager v66

package validation

import (
	"context"
)

type (
	Document         struct{}
	ValidationReport struct{}
)

func ValidateDocument(ctx context.Context, doc *Document) error {
	// Stub : valide toujours le document
	return nil
}

func ValidateAll(ctx context.Context) ValidationReport {
	// Stub : retourne un rapport vide
	return ValidationReport{}
}

func AutoFixIssues(ctx context.Context, doc *Document) error {
	// Stub : ne fait rien
	return nil
}
