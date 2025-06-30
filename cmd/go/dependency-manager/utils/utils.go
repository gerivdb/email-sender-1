package utils

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

// ModuleInfo représente les informations extraites d'un fichier go.mod
type ModuleInfo struct {
	Path      string   `json:"path"`
	Name      string   `json:"name"`
	GoVersion string   `json:"go_version,omitempty"`
	Requires  []string `json:"requires,omitempty"`
}

// AuditReport représente le rapport d'audit global
type AuditReport struct {
	Timestamp      string       `json:"timestamp"`
	GoModsFound    []ModuleInfo `json:"go_mods_found"`
	GoSumsFound    []string     `json:"go_sums_found"`
	ReportMarkdown string       `json:"-"`
}

// NonCompliantImport représente un import non conforme trouvé
type NonCompliantImport struct {
	FilePath    string `json:"file_path"`
	ImportPath  string `json:"import_path"`
	Line        int    `json:"line"`
	Column      int    `json:"column"`
	Explanation string `json:"explanation"`
}

// NonCompliantImportsReport représente le rapport des imports non conformes
type NonCompliantImportsReport struct {
	Timestamp           string               `json:"timestamp"`
	NonCompliantImports []NonCompliantImport `json:"non_compliant_imports"`
	TotalFilesScanned   int                  `json:"total_files_scanned"`
	TotalImportsFound   int                  `json:"total_imports_found"`
	TotalNonCompliant   int                  `json:"total_non_compliant"`
	ReportMarkdown      string               `json:"-"`
}

// GenerateMarkdownReportAudit génère un rapport Markdown pour l'audit des modules
func GenerateMarkdownReportAudit(report AuditReport) string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("# Rapport d'Audit des Modules Go - %s\n\n", report.Timestamp))
	sb.WriteString("## Fichiers `go.mod` trouvés :\n\n")
	if len(report.GoModsFound) == 0 {
		sb.WriteString("Aucun fichier `go.mod` trouvé.\n\n")
	} else {
		for _, mod := range report.GoModsFound {
			sb.WriteString(fmt.Sprintf("- **Chemin :** `%s`\n", mod.Path))
			sb.WriteString(fmt.Sprintf("  - **Nom du module :** `%s`\n", mod.Name))
			if mod.GoVersion != "" {
				sb.WriteString(fmt.Sprintf("  - **Version Go :** `%s`\n", mod.GoVersion))
			}
			if len(mod.Requires) > 0 {
				sb.WriteString("  - **Dépendances requises :**\n")
				for _, req := range mod.Requires {
					sb.WriteString(fmt.Sprintf("    - `%s`\n", req))
				}
			}
			sb.WriteString("\n")
		}
	}

	sb.WriteString("## Fichiers `go.sum` trouvés :\n\n")
	if len(report.GoSumsFound) == 0 {
		sb.WriteString("Aucun fichier `go.sum` trouvé.\n\n")
	} else {
		for _, sum := range report.GoSumsFound {
			sb.WriteString(fmt.Sprintf("- `%s`\n", sum))
		}
	}

	return sb.String()
}

// GenerateMarkdownReportNonCompliantImports génère un rapport Markdown pour les imports non conformes
func GenerateMarkdownReportNonCompliantImports(report NonCompliantImportsReport) string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("# Rapport des Imports Go Non Conformes - %s\n\n", report.Timestamp))
	sb.WriteString(fmt.Sprintf("## Résumé\n\n"))
	sb.WriteString(fmt.Sprintf("- **Fichiers Go scannés :** %d\n", report.TotalFilesScanned))
	sb.WriteString(fmt.Sprintf("- **Imports trouvés :** %d\n", report.TotalImportsFound))
	sb.WriteString(fmt.Sprintf("- **Imports non conformes détectés :** %d\n\n", report.TotalNonCompliant))

	if report.TotalNonCompliant == 0 {
		sb.WriteString("Félicitations ! Aucun import non conforme n'a été détecté.\n\n")
	} else {
		sb.WriteString("## Détails des Imports Non Conformes :\n\n")
		for _, imp := range report.NonCompliantImports {
			sb.WriteString(fmt.Sprintf("### Fichier : `%s`\n", imp.FilePath))
			sb.WriteString(fmt.Sprintf("- **Import :** `%s`\n", imp.ImportPath))
			sb.WriteString(fmt.Sprintf("- **Localisation :** Ligne %d, Colonne %d\n", imp.Line, imp.Column))
			sb.WriteString(fmt.Sprintf("- **Explication :** %s\n\n", imp.Explanation))
		}
	}

	return sb.String()
}

// WriteReportJSON écrit un rapport au format JSON
func WriteReportJSON(report interface{}, outputPath string) error {
	err := os.MkdirAll(filepath.Dir(outputPath), 0o755)
	if err != nil {
		return fmt.Errorf("impossible de créer le répertoire pour le rapport JSON : %w", err)
	}
	file, err := os.Create(outputPath)
	if err != nil {
		return err
	}
	defer file.Close()
	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	return encoder.Encode(report)
}

// WriteReportMD écrit un rapport au format Markdown
func WriteReportMD(reportMDContent string, outputPath string) error {
	err := os.MkdirAll(filepath.Dir(outputPath), 0o755)
	if err != nil {
		return fmt.Errorf("impossible de créer le répertoire pour le rapport Markdown : %w", err)
	}
	return ioutil.WriteFile(outputPath, []byte(reportMDContent), 0o644)
}
