package main

import (
	"os"
	"testing"
)

func TestDuplicationReportGeneration(t *testing.T) {
	_ = os.Remove("duplication_report.md")
	main()
	if _, err := os.Stat("duplication_report.md"); os.IsNotExist(err) {
		t.Fatalf("duplication_report.md n'a pas été généré")
	}
	_ = os.Remove("duplication_report.md")
}
