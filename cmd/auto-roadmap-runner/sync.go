// cmd/auto-roadmap-runner/sync.go
package main

import (
	"fmt"
	"log"
	"os"
	"time"
)

// FilePerms définit la permission pour les fichiers log (0600).
const FilePerms = 0o600

func SyncMarkdownQdrant(mdFile string, qdrantData string, priority string) error {
	logFile := "projet/roadmaps/plans/consolidated/sync.log"

	f, err := os.OpenFile(logFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, FilePerms)
	if err != nil {
		return fmt.Errorf("échec ouverture log: %w", err)
	}

	// wsl_v5: espace avant defer
	defer func() {
		cerr := f.Close()
		if cerr != nil {
			log.Printf("Avertissement: fermeture log échouée: %v", cerr)
		}
	}()

	timestamp := time.Now().Format(time.RFC3339)
	logEntry := fmt.Sprintf("[%s] Sync: %s ↔ %s | Priorité: %s\n", timestamp, mdFile, qdrantData, priority)
	_, err = f.WriteString(logEntry)
	// wsl_v5: espace avant if
	if err != nil {
		return fmt.Errorf("échec écriture log: %w", err)
	}

	// wsl_v5: espace avant switch
	switch priority {
	case "markdown":
		log.Printf("Synchronisation: Markdown prioritaire (%s)", mdFile)
	case "qdrant":
		log.Printf("Synchronisation: Qdrant prioritaire (%s)", qdrantData)
	default:
		log.Printf("Synchronisation: priorité indéfinie")
	}

	// wsl_v5: espace avant return
	return nil
}
