package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gerivdb/email-sender-1/cmd/go/dependency-manager/utils"
)

// ModuleInfo représente les informations extraites d'un fichier go.mod
// (Déplacé dans utils/utils.go)
// AuditReport représente le rapport d'audit global
// (Déplacé dans utils/utils.go)

func main() {
	// Parse arguments
	outputJSON := ""
	outputMD := ""

	args := os.Args[1:]
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--output-json":
			if i+1 < len(args) {
				outputJSON = args[i+1]
				i++
			}
		case "--output-md":
			if i+1 < len(args) {
				outputMD = args[i+1]
				i++
			}
		}
	}

	if outputJSON == "" || outputMD == "" {
		fmt.Println("Usage: go run audit_modules.go --output-json <path_to_json> --output-md <path_to_md>")
		os.Exit(1)
	}

	report := utils.AuditReport{ // Utilisation de utils.AuditReport
		Timestamp: time.Now().Format("2006-01-02T15-04-05"),
	}

	rootDir, err := os.Getwd()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lors de l'obtention du répertoire courant : %v\n", err)
		os.Exit(1)
	}

	// Parcours pour trouver go.mod et go.sum
	err = filepath.Walk(rootDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() && strings.Contains(path, "vendor") { // Ignorer le dossier vendor
			return filepath.SkipDir
		}

		if info.Name() == "go.mod" {
			// relPath, _ := filepath.Rel(rootDir, path) // relPath n'est pas utilisé ici
			moduleInfo, err := parseGoMod(path) // parseGoMod reste ici car spécifique à cet outil
			if err != nil {
				fmt.Fprintf(os.Stderr, "Erreur lors de l'analyse de %s: %v\n", path, err)
				return nil // Ne pas bloquer l'audit pour un seul fichier
			}
			report.GoModsFound = append(report.GoModsFound, moduleInfo)
		} else if info.Name() == "go.sum" {
			relPath, _ := filepath.Rel(rootDir, path)
			report.GoSumsFound = append(report.GoSumsFound, relPath)
		}
		return nil
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lors du parcours des fichiers : %v\n", err)
		os.Exit(1)
	}

	// Générer le rapport Markdown
	report.ReportMarkdown = utils.GenerateMarkdownReportAudit(report) // Utilisation de utils.GenerateMarkdownReportAudit

	// Écrire le rapport JSON
	err = utils.WriteReportJSON(report, outputJSON) // Utilisation de utils.WriteReportJSON
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lors de l'écriture du rapport JSON : %v\n", err)
		os.Exit(1)
	}

	// Écrire le rapport Markdown
	err = utils.WriteReportMD(report.ReportMarkdown, outputMD) // Utilisation de utils.WriteReportMD
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lors de l'écriture du rapport Markdown : %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Audit terminé. Rapports générés : %s et %s\n", outputJSON, outputMD)
}

// parseGoMod reste ici car c'est une fonction interne spécifique à cet outil
func parseGoMod(path string) (utils.ModuleInfo, error) { // Utilisation de utils.ModuleInfo
	content, err := ioutil.ReadFile(path)
	if err != nil {
		return utils.ModuleInfo{}, err
	}

	// NOTE: os.Getenv("CWD") n'est pas fiable en Go. Il est préférable de passer rootDir
	// ou de calculer le chemin relatif à partir de rootDir. Pour l'instant, on utilise le chemin absolu
	// ou le chemin relatif à rootDir si rootDir est disponible.
	relPath, err := filepath.Rel(os.Getenv("CWD"), path)
	if err != nil || os.Getenv("CWD") == "" {
		relPath = path // Fallback si CWD n'est pas défini ou erreur
	}

	moduleInfo := utils.ModuleInfo{Path: relPath} // Utilisation de utils.ModuleInfo

	lines := strings.Split(string(content), "\n")
	for _, line := range lines {
		trimmedLine := strings.TrimSpace(line)
		if strings.HasPrefix(trimmedLine, "module ") {
			moduleInfo.Name = strings.TrimPrefix(trimmedLine, "module ")
		} else if strings.HasPrefix(trimmedLine, "go ") {
			moduleInfo.GoVersion = strings.TrimPrefix(trimmedLine, "go ")
		} else if strings.HasPrefix(trimmedLine, "require (") {
			// Début d'un bloc require, lire jusqu'à la parenthèse fermante
			for i := 0; i < len(lines); i++ {
				if strings.TrimSpace(lines[i]) == ")" {
					break
				}
				if strings.Contains(lines[i], "require") && !strings.Contains(lines[i], "(") {
					parts := strings.Fields(strings.TrimSpace(lines[i]))
					if len(parts) >= 2 {
						moduleInfo.Requires = append(moduleInfo.Requires, parts[0]+" "+parts[1])
					}
				}
			}
		} else if strings.HasPrefix(trimmedLine, "require ") && !strings.Contains(trimmedLine, "(") {
			parts := strings.Fields(trimmedLine)
			if len(parts) >= 2 {
				moduleInfo.Requires = append(moduleInfo.Requires, parts[1]+" "+parts[2])
			}
		}
	}
	return moduleInfo, nil
}
