// scripts/aggregate-diagnostics_test.go
// Test basique pour vérifier la génération du rapport d’audit.

package main

import (
	"os"
	"testing"
)

func TestAggregateDiagnostics_GeneratesReport(t *testing.T) {
	reportPath := "audit-reports/diagnostics-report.md"
	_ = os.Remove(reportPath)
	main()
	if _, err := os.Stat(reportPath); err != nil {
		t.Errorf("Le rapport %s n’a pas été généré", reportPath)
	}
}
