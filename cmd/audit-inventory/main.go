// cmd/audit-inventory/main.go
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

func main() {
	var files []string
	err := filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			files = append(files, path)
		}
		return nil
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lors du scan: %v\n", err)
		os.Exit(1)
	}

	// Backup automatique
	backupPath := "projet/roadmaps/plans/consolidated/inventory.json.bak"
	outPath := "projet/roadmaps/plans/consolidated/inventory.json"
	_ = os.MkdirAll("projet/roadmaps/plans/consolidated", 0o755)
	if _, err := os.Stat(outPath); err == nil {
		os.Rename(outPath, backupPath)
	}

	// Sauvegarde JSON
	f, err := os.Create(outPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur création fichier: %v\n", err)
		os.Exit(1)
	}
	defer f.Close()
	json.NewEncoder(f).Encode(files)

	// Rapport Markdown
	reportPath := "projet/roadmaps/plans/consolidated/inventory-report.md"
	rf, err := os.Create(reportPath)
	if err == nil {
		defer rf.Close()
		rf.WriteString("# Rapport d’inventaire\n\n")
		rf.WriteString(fmt.Sprintf("_Généré le %s_\n\n", time.Now().Format(time.RFC3339)))
		for _, file := range files {
			rf.WriteString(fmt.Sprintf("- `%s`\n", file))
		}
	}

	// Log d’exécution
	logPath := "logs/inventory.log"
	_ = os.MkdirAll("logs", 0o755)
	lf, err := os.OpenFile(logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err == nil {
		defer lf.Close()
		lf.WriteString(fmt.Sprintf("%s - Inventaire généré (%d fichiers)\n", time.Now().Format(time.RFC3339), len(files)))
	}

	fmt.Printf("Inventaire généré : %d fichiers\n", len(files))
}
