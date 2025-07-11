// cmd/manager-gap-analysis/gap_analysis_test.go
package main

import (
	"os"
	"testing"
)

func TestGapReportCreated(t *testing.T) {
	_ = os.Remove("gap_report.md") // Nettoyage avant test
	main()
	if _, err := os.Stat("gap_report.md"); os.IsNotExist(err) {
		t.Error("gap_report.md n'a pas été généré")
	}
}
