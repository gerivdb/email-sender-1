// cmd/auto-roadmap-runner/reporting.go
package main

import (
	"fmt"
	"os"
	"time"
)

func GenerateReport(successCount, failCount int, details string) error {
	reportFile := "projet/roadmaps/plans/consolidated/migration-report.md"
	f, err := os.OpenFile(reportFile, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o644)
	if err != nil {
		return err
	}
	defer f.Close()
	timestamp := time.Now().Format(time.RFC3339)
	report := fmt.Sprintf("## Rapport de migration (%s)\n- Succès : %d\n- Échecs : %d\n- Détails : %s\n\n", timestamp, successCount, failCount, details)
	_, err = f.WriteString(report)
	return err
}
