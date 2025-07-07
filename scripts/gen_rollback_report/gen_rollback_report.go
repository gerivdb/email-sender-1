package gen_rollback_report

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

func main() {
	reportDir := "reports"
	reportFile := filepath.Join(reportDir, "rollback_report.md")

	// Ensure reports directory exists
	err := os.MkdirAll(reportDir, 0o755)
	if err != nil {
		fmt.Printf("Error creating reports directory: %v\n", err)
		os.Exit(1)
	}

	// Get latest backup directory name (assuming format backup/YYYYMMDD-HHMMSS)
	latestBackupDir := "N/A"
	backupBaseDir := "backup"
	backupDirs, err := filepath.Glob(filepath.Join(backupBaseDir, "20*-*"))
	if err == nil && len(backupDirs) > 0 {
		latestBackupDir = filepath.Base(backupDirs[len(backupDirs)-1]) // Get the last one in sorted list
	}

	// Get latest git tag
	latestGitTag := "N/A"
	cmd := exec.Command("git", "describe", "--tags", "--abbrev=0")
	tagOutput, err := cmd.Output()
	if err == nil {
		latestGitTag = strings.TrimSpace(string(tagOutput))
	}

	// Generate Markdown report
	fmt.Printf("Generating Markdown rollback report to %s...\n", reportFile)
	reportContent := "# Rapport de Rollback et de Versionning\n\n" +
		"**Date de génération**: " + time.Now().Format("2006-01-02 15:04:05 MST") + "\n\n" +
		"## Résumé des Opérations\n\n" +
		"Ce rapport fournit une synthèse des opérations de sauvegarde et de versionning effectuées.\n\n" +
		"### Sauvegardes\n" +
		"- **Dernière sauvegarde**: " + latestBackupDir + " (répertoire)\n" +
		"- **Statut**: ✅ Succès (si le script de backup s'est terminé sans erreur)\n" +
		"- **Détails**: Les sauvegardes sont stockées dans le répertoire `backup/` avec un horodatage.\n\n" +
		"### Versionning Git\n" +
		"- **Dernier tag de sauvegarde**: " + latestGitTag + "\n" +
		"- **Statut**: ✅ Succès (si les opérations git se sont terminées sans erreur)\n" +
		"- **Détails**: Les commits sont taggés avec un préfixe `backup-` pour faciliter l'identification des points de restauration.\n\n" +
		"## Recommandations\n\n" +
		"- Vérifier régulièrement l'intégrité des sauvegardes.\n" +
		"- Tester les procédures de restauration dans un environnement isolé.\n" +
		"- S'assurer que les tags Git sont poussés vers le dépôt distant.\n\n" +
		"---\n\n" +
		"Ce rapport est généré automatiquement.\n"

	if err := ioutil.WriteFile(reportFile, []byte(reportContent), 0o644); err != nil {
		fmt.Printf("Error writing report file: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("Rapport de rollback généré avec succès.")
}
