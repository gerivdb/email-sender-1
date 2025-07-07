package backup

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"time"
)

// CriticalFile represents a file or directory to be backed up.
type CriticalFile struct {
	Path        string
	Category    string
	Description string
}

// getCriticalFiles returns a hardcoded list of critical files for backup.
// In a real scenario, this list might be dynamically generated or read from a config.
func getCriticalFiles() []CriticalFile {
	return []CriticalFile{
		{Path: "config.yaml", Category: "config", Description: "Main application configuration"},
		{Path: ".golangci.yaml", Category: "config", Description: "Go linter configuration"},
		{Path: ".cline_mcp_settings.json", Category: "config", Description: "MCP settings"},
		{Path: ".vscode/tasks.json", Category: "config", Description: "VSCode tasks configuration"},
		{Path: "pkg/common/read_file.go", Category: "code", Description: "File reading API"},
		{Path: "cmd/audit_read_file", Category: "code", Description: "read_file usage audit script directory"}, // Directory
		{Path: "cmd/gap_analysis", Category: "code", Description: "Gap analysis script directory"},             // Directory
		{Path: "cmd/gen_read_file_spec", Category: "code", Description: "Specification generation script directory"},
		{Path: "cmd/read_file_navigator", Category: "code", Description: "CLI file navigator directory"},
		{Path: "docs/read_file_usage_audit.md", Category: "report", Description: "read_file usage audit report"},
		{Path: "docs/read_file_gap_analysis.md", Category: "report", Description: "Gap analysis report"},
		{Path: "specs/read_file_spec.md", Category: "report", Description: "read_file functional and technical specification"},
		{Path: "reports/read_file_report.md", Category: "report", Description: "Automated test and coverage report"},
		{Path: "docs/read_file_user_needs.md", Category: "report", Description: "User needs collection"},
		{Path: "docs/read_file_user_feedback.md", Category: "report", Description: "User feedback collection"},
		{Path: "scripts/gen_user_needs_template.sh", Category: "script", Description: "Script to generate user needs template"},
		{Path: "scripts/collect_user_needs.sh", Category: "script", Description: "Script to collect user needs"},
		{Path: "scripts/validate_and_archive_user_needs.sh", Category: "script", Description: "Script to validate and archive user needs"},
		{Path: "scripts/archive_spec.sh", Category: "script", Description: "Script to archive specification"},
		{Path: "scripts/gen_read_file_report.go", Category: "script", Description: "Script to generate read_file reports"},
		{Path: "scripts/vscode_read_file_selection.js", Category: "script", Description: "VSCode extension script"},
		{Path: "scripts/collect_user_feedback.sh", Category: "script", Description: "Script to collect user feedback (Bash)"},
		{Path: "scripts/collect_user_feedback.ps1", Category: "script", Description: "Script to collect user feedback (PowerShell)"},
		{Path: "pkg/common/read_file_test.go", Category: "test", Description: "Unit tests for read_file API"},
		{Path: "integration/read_file_integration_test.go", Category: "test", Description: "Integration tests for CLI and VSCode"},
	}
}

func main() {
	backupDir := filepath.Join("backup", time.Now().Format("20060102-150405"))
	fmt.Printf("Création du répertoire de sauvegarde: %s\n", backupDir)

	err := os.MkdirAll(backupDir, 0o755)
	if err != nil {
		fmt.Printf("Erreur lors de la création du répertoire de sauvegarde: %v\n", err)
		os.Exit(1)
	}

	criticalFiles := getCriticalFiles()
	backupCount := 0
	errorCount := 0

	for _, fileToBackup := range criticalFiles {
		srcPath := fileToBackup.Path
		destPath := filepath.Join(backupDir, srcPath)

		info, err := os.Stat(srcPath)
		if os.IsNotExist(err) {
			fmt.Printf("AVERTISSEMENT: Le fichier ou répertoire '%s' n'existe pas, ignoré.\n", srcPath)
			continue
		} else if err != nil {
			fmt.Printf("ERREUR: Impossible d'accéder à '%s': %v\n", srcPath, err)
			errorCount++
			continue
		}

		if info.IsDir() {
			// Copy directory recursively
			err = copyDir(srcPath, destPath)
			if err != nil {
				fmt.Printf("ERREUR: Impossible de sauvegarder le répertoire '%s': %v\n", srcPath, err)
				errorCount++
			} else {
				fmt.Printf("Répertoire sauvegardé: %s -> %s\n", srcPath, destPath)
				backupCount++
			}
		} else {
			// Copy file
			err = copyFile(srcPath, destPath)
			if err != nil {
				fmt.Printf("ERREUR: Impossible de sauvegarder le fichier '%s': %v\n", srcPath, err)
				errorCount++
			} else {
				fmt.Printf("Fichier sauvegardé: %s -> %s\n", srcPath, destPath)
				backupCount++
			}
		}
	}

	fmt.Printf("\nSauvegarde terminée. %d éléments sauvegardés, %d erreurs.\n", backupCount, errorCount)
	if errorCount > 0 {
		os.Exit(1)
	}
}

func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return fmt.Errorf("impossible d'ouvrir le fichier source %s: %w", src, err)
	}
	defer in.Close()

	err = os.MkdirAll(filepath.Dir(dst), 0o755)
	if err != nil {
		return fmt.Errorf("impossible de créer le répertoire de destination pour %s: %w", dst, err)
	}

	out, err := os.Create(dst)
	if err != nil {
		return fmt.Errorf("impossible de créer le fichier de destination %s: %w", dst, err)
	}
	defer out.Close()

	_, err = io.Copy(out, in)
	if err != nil {
		return fmt.Errorf("impossible de copier le contenu du fichier %s à %s: %w", src, dst, err)
	}
	return out.Close()
}

func copyDir(src, dst string) error {
	src = filepath.Clean(src)
	dst = filepath.Clean(dst)

	si, err := os.Stat(src)
	if err != nil {
		return fmt.Errorf("impossible de stat le répertoire source %s: %w", src, err)
	}
	if !si.IsDir() {
		return fmt.Errorf("la source %s n'est pas un répertoire", src)
	}

	err = os.MkdirAll(dst, si.Mode())
	if err != nil {
		return fmt.Errorf("impossible de créer le répertoire de destination %s: %w", dst, err)
	}

	entries, err := ioutil.ReadDir(src)
	if err != nil {
		return fmt.Errorf("impossible de lire le répertoire source %s: %w", src, err)
	}

	for _, entry := range entries {
		srcPath := filepath.Join(src, entry.Name())
		dstPath := filepath.Join(dst, entry.Name())

		if entry.IsDir() {
			err = copyDir(srcPath, dstPath)
			if err != nil {
				return err
			}
		} else {
			err = copyFile(srcPath, dstPath)
			if err != nil {
				return err
			}
		}
	}
	return nil
}
