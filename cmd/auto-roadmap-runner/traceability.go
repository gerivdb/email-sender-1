// cmd/auto-roadmap-runner/traceability.go
package main

import (
	"fmt"
	"os"
	"time"
)

func GenerateTraceLog(inventoryFile string, syncStatus string) error {
	logFile := "projet/roadmaps/plans/consolidated/traceability.log"
	f, err := os.OpenFile(logFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return err
	}
	defer f.Close()
	timestamp := time.Now().Format(time.RFC3339)
	logEntry := fmt.Sprintf("[%s] Inventaire: %s | Synchronisation: %s\n", timestamp, inventoryFile, syncStatus)
	_, err = f.WriteString(logEntry)
	return err
}
