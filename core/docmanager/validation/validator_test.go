// core/docmanager/validation/validator_test.go
// Tests unitaires pour le moteur de validation

package validation

import (
	"context"
	"testing"
)

func TestValidateDocument(t *testing.T) {
	err := ValidateDocument(context.Background(), &Document{})
	if err != nil {
		t.Errorf("ValidateDocument a échoué : %v", err)
	}
}

func TestValidateAll(t *testing.T) {
	report := ValidateAll(context.Background())
	if !report.Validated && len(report.Issues) != 0 {
		t.Errorf("ValidateAll devrait retourner un rapport vide et validé")
	}
}
