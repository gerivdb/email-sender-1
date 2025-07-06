package main

import (
	"os"
	"testing"
)

func TestAuditGapReportGeneration(t *testing.T) {
	_ = os.Remove("audit_gap_report.md")
	main()
	if _, err := os.Stat("audit_gap_report.md"); os.IsNotExist(err) {
		t.Fatalf("audit_gap_report.md n'a pas été généré")
	}
	_ = os.Remove("audit_gap_report.md")
}
