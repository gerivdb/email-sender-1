package audit_orchestration

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// ScriptInfo represents details about an automation script.
type ScriptInfo struct {
	Path		string
	Description	string
	Dependencies	[]string	// List of other scripts or tools it depends on
	EntryPoint	string		// How to run this script (e.g., "go run", "bash", "pwsh -File")
}

func main() {
	// Define known scripts and their properties
	knownScripts := []ScriptInfo{
		{Path: "cmd/audit_read_file/audit_read_file.go", Description: "Scans code for read_file usages", Dependencies: []string{}, EntryPoint: "go run"},
		{Path: "cmd/gap_analysis/gap_analysis.go", Description: "Compares read_file usages with user needs", Dependencies: []string{"docs/read_file_usage_audit.md", "docs/read_file_user_needs.md"}, EntryPoint: "go run"},
		{Path: "cmd/gen_read_file_spec/gen_read_file_spec.go", Description: "Generates read_file specification template", Dependencies: []string{"docs/read_file_user_needs.md"}, EntryPoint: "go run"},
		{Path: "cmd/read_file_navigator/read_file_navigator.go", Description: "CLI for navigating large files", Dependencies: []string{"pkg/common/read_file.go"}, EntryPoint: "go run"},
		{Path: "cmd/audit_rollback_points/audit_rollback_points.go", Description: "Audits critical files for rollback", Dependencies: []string{}, EntryPoint: "go run"},
		{Path: "cmd/gen_rollback_spec/gen_rollback_spec.go", Description: "Generates rollback specification template", Dependencies: []string{"docs/rollback_points_audit.md"}, EntryPoint: "go run"},
		// Orchestration scripts (will be added later in the roadmap)
		{Path: "cmd/auto-roadmap-runner.go", Description: "Global roadmap orchestrator", Dependencies: []string{"scripts/backup/backup.go", "scripts/backup/backup_test.go", "scripts/gen_read_file_report/gen_read_file_report.go", "scripts/gen_rollback_report/gen_rollback_report.go"}, EntryPoint: "go run"},
		// Other scripts
		{Path: "scripts/gen_user_needs_template.sh", Description: "Generates user needs template", Dependencies: []string{}, EntryPoint: "bash"},
		{Path: "scripts/collect_user_needs.sh", Description: "Collects user needs interactively (Bash)", Dependencies: []string{"docs/read_file_user_needs.md"}, EntryPoint: "bash"},
		{Path: "scripts/validate_and_archive_user_needs.sh", Description: "Validates and archives user needs", Dependencies: []string{"docs/read_file_user_needs.md"}, EntryPoint: "bash"},
		{Path: "scripts/archive_spec.sh", Description: "Archives read_file specification", Dependencies: []string{"specs/read_file_spec.md"}, EntryPoint: "bash"},
		{Path: "scripts/gen_read_file_report.go", Description: "Generates read_file test and coverage report", Dependencies: []string{"pkg/common/read_file_test.go", "integration/read_file_integration_test.go"}, EntryPoint: "go run"},
		{Path: "scripts/vscode_read_file_selection.js", Description: "VSCode extension for selection analysis", Dependencies: []string{"cmd/read_file_navigator/read_file_navigator.go"}, EntryPoint: "node"},
		{Path: "scripts/collect_user_feedback.sh", Description: "Collects user feedback interactively (Bash)", Dependencies: []string{"docs/read_file_user_feedback.md"}, EntryPoint: "bash"},
		{Path: "scripts/collect_user_feedback.ps1", Description: "Collects user feedback interactively (PowerShell)", Dependencies: []string{"docs/read_file_user_feedback.md"}, EntryPoint: "pwsh -File"},
		{Path: "scripts/backup/backup.go", Description: "Automated backup script", Dependencies: []string{}, EntryPoint: "go run"},
		{Path: "scripts/backup/backup_test.go", Description: "Tests for backup script", Dependencies: []string{"scripts/backup/backup.go"}, EntryPoint: "go test"},
		{Path: "scripts/git_versioning.sh", Description: "Automates critical git operations", Dependencies: []string{}, EntryPoint: "bash"},
		{Path: "scripts/gen_rollback_report/gen_rollback_report.go", Description: "Generates rollback and versioning report", Dependencies: []string{"backup/", "git"}, EntryPoint: "go run"},
	}

	fmt.Println("# Audit des scripts d'orchestration et de leurs dépendances\n")
	fmt.Println("Ce rapport liste tous les scripts d'automatisation identifiés, leurs dépendances et leurs points d'entrée.\n")
	fmt.Println("## Scripts Identifiés\n")
	fmt.Println("| Chemin du script | Description | Point d'entrée | Dépendances | Statut (Présent/Absent) |")
	fmt.Println("|---|---|---|---|---|")

	for _, script := range knownScripts {
		status := "Absent"
		if _, err := os.Stat(script.Path); err == nil {
			status = "Présent"
		} else if os.IsNotExist(err) {
			// File does not exist, status is Absent
		} else {
			// Other error, e.g., permission denied
			status = fmt.Sprintf("Erreur: %v", err)
		}

		dependencies := "Aucune"
		if len(script.Dependencies) > 0 {
			dependencies = strings.Join(script.Dependencies, ", ")
		}

		fmt.Printf("| %s | %s | `%s` | %s | %s |\n", script.Path, script.Description, script.EntryPoint, dependencies, status)
	}

	fmt.Println("\n## Recommandations\n")
	fmt.Println("Vérifiez que tous les scripts nécessaires sont présents et que leurs dépendances sont satisfaites avant d'exécuter l'orchestrateur global.")
}

// Helper function to find Go files (not used in main, but good for context)
func findGoFiles(root string) ([]string, error) {
	var files []string
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && strings.HasSuffix(info.Name(), ".go") {
			files = append(files, path)
		}
		return nil
	})
	return files, err
}
