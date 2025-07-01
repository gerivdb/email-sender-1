package audit_rollback_points

import (
	"fmt"
	"os"
)

type CriticalFile struct {
	Path		string
	Category	string	// e.g., "config", "code", "report", "data", "script"
	Description	string
}

func main() {
	criticalFiles := []CriticalFile{
		// Configuration files
		{Path: "config.yaml", Category: "config", Description: "Main application configuration"},
		{Path: ".golangci.yaml", Category: "config", Description: "Go linter configuration"},
		{Path: ".cline_mcp_settings.json", Category: "config", Description: "MCP settings"},
		{Path: ".vscode/tasks.json", Category: "config", Description: "VSCode tasks configuration"},
		// Code files (examples)
		{Path: "pkg/common/read_file.go", Category: "code", Description: "File reading API"},
		{Path: "cmd/audit_read_file/audit_read_file.go", Category: "code", Description: "read_file usage audit script"},
		{Path: "cmd/gap_analysis/gap_analysis.go", Category: "code", Description: "Gap analysis script"},
		{Path: "cmd/gen_read_file_spec/gen_read_file_spec.go", Category: "code", Description: "Specification generation script"},
		{Path: "cmd/read_file_navigator/read_file_navigator.go", Category: "code", Description: "CLI file navigator"},
		// Report files
		{Path: "docs/read_file_usage_audit.md", Category: "report", Description: "read_file usage audit report"},
		{Path: "docs/read_file_gap_analysis.md", Category: "report", Description: "Gap analysis report"},
		{Path: "specs/read_file_spec.md", Category: "report", Description: "read_file functional and technical specification"},
		{Path: "reports/read_file_report.md", Category: "report", Description: "Automated test and coverage report"},
		{Path: "docs/read_file_user_needs.md", Category: "report", Description: "User needs collection"},
		{Path: "docs/read_file_user_feedback.md", Category: "report", Description: "User feedback collection"},
		// Script files
		{Path: "scripts/gen_user_needs_template.sh", Category: "script", Description: "Script to generate user needs template"},
		{Path: "scripts/collect_user_needs.sh", Category: "script", Description: "Script to collect user needs"},
		{Path: "scripts/validate_and_archive_user_needs.sh", Category: "script", Description: "Script to validate and archive user needs"},
		{Path: "scripts/archive_spec.sh", Category: "script", Description: "Script to archive specification"},
		{Path: "scripts/gen_read_file_report.go", Category: "script", Description: "Script to generate read_file reports"},
		{Path: "scripts/vscode_read_file_selection.js", Category: "script", Description: "VSCode extension script"},
		{Path: "scripts/collect_user_feedback.sh", Category: "script", Description: "Script to collect user feedback (Bash)"},
		{Path: "scripts/collect_user_feedback.ps1", Category: "script", Description: "Script to collect user feedback (PowerShell)"},
		// Test files
		{Path: "pkg/common/read_file_test.go", Category: "test", Description: "Unit tests for read_file API"},
		{Path: "integration/read_file_integration_test.go", Category: "test", Description: "Integration tests for CLI and VSCode"},
		// Data files (examples if applicable)
		{Path: "test_cli_integration.txt", Category: "data", Description: "Test data for CLI integration"},
		{Path: "test_file_range.txt", Category: "data", Description: "Test data for ReadFileRange"},
		{Path: "test_hex_file.bin", Category: "data", Description: "Test data for PreviewHex"},
		{Path: "large_test_file.txt", Category: "data", Description: "Large test file for performance testing (if created)"},
		{Path: "binary_test_file.bin", Category: "data", Description: "Binary test file (if created)"},
	}

	fmt.Println("# Audit des points de rollback/versionning\n")
	fmt.Println("Ce rapport identifie les fichiers critiques du dépôt qui devraient être considérés pour les procédures de sauvegarde et de restauration.\n")
	fmt.Println("## Fichiers Critiques\n")
	fmt.Println("| Chemin du fichier | Catégorie | Description | Statut (Présent/Absent) |")
	fmt.Println("|---|---|---|---|")

	for _, file := range criticalFiles {
		status := "Absent"
		if _, err := os.Stat(file.Path); err == nil {
			status = "Présent"
		} else if os.IsNotExist(err) {
			// File does not exist, status is Absent
		} else {
			// Other error, e.g., permission denied
			status = fmt.Sprintf("Erreur: %v", err)
		}
		fmt.Printf("| %s | %s | %s | %s |\n", file.Path, file.Category, file.Description, status)
	}

	fmt.Println("\n## Recommandations\n")
	fmt.Println("Il est recommandé de s'assurer que tous les fichiers marqués comme 'Présent' dans ce rapport sont inclus dans les stratégies de sauvegarde et de versionning. Les fichiers 'Absent' peuvent être des livrables futurs ou des artefacts de test qui ne sont pas toujours persistants.")
	fmt.Println("Il est crucial de versionner toutes les configurations, le code source, les scripts d'automatisation, les rapports et les données de test essentielles.")
}
