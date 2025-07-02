// scripts/fix-github-workflows.go
// Détecte et suggère/corrige les accès contextuels invalides dans les workflows GitHub Actions.
// Usage : go run scripts/fix-github-workflows.go

package main

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

var invalidContextVars = []string{
	"LOWERCASE_REPO", "LOWERCASE_OWNER", "VERSION", "CHANGELOG_CONTENT", "SLACK_WEBHOOK",
}

func findInvalidContextVars(line string) []string {
	var found []string
	for _, v := range invalidContextVars {
		if strings.Contains(line, v) {
			found = append(found, v)
		}
	}
	return found
}

func suggestFix(varName string) string {
	// Suggestions basiques, à adapter selon conventions du projet
	switch varName {
	case "LOWERCASE_REPO":
		return "github.repository (ou steps.<id>.outputs.repo)"
	case "LOWERCASE_OWNER":
		return "github.repository_owner"
	case "VERSION":
		return "github.ref_name ou steps.<id>.outputs.version"
	case "CHANGELOG_CONTENT":
		return "steps.<id>.outputs.changelog"
	case "SLACK_WEBHOOK":
		return "secret.SLACK_WEBHOOK"
	default:
		return "Vérifier la documentation GitHub Actions"
	}
}

func main() {
	root := "."
	var files []string
	_ = filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err == nil && strings.HasSuffix(info.Name(), ".yml") && strings.Contains(path, ".github/workflows/") {
			files = append(files, path)
		}
		return nil
	})

	type WorkflowReport struct {
		File   string
		Issues []string
	}
	var report []WorkflowReport

	for _, file := range files {
		f, err := os.Open(file)
		if err != nil {
			report = append(report, WorkflowReport{File: file, Issues: []string{fmt.Sprintf("Erreur ouverture: %v", err)}})
			continue
		}
		defer f.Close()
		var issues []string
		scanner := NewLineScanner(f)
		for scanner.Scan() {
			line := scanner.Text()
			for _, v := range findInvalidContextVars(line) {
				// Recherche si la variable est utilisée dans une expression ${{ ... }}
				re := regexp.MustCompile(`\${{\s*[^}]*` + regexp.QuoteMeta(v) + `[^}]*}}`)
				if re.MatchString(line) {
					issues = append(issues, fmt.Sprintf("Variable contextuelle invalide '%s' détectée : %s | Suggestion : %s", v, strings.TrimSpace(line), suggestFix(v)))
				}
			}
		}
		if len(issues) > 0 {
			report = append(report, WorkflowReport{File: file, Issues: issues})
		}
	}

	_ = os.MkdirAll("audit-reports", 0755)
	out, _ := os.Create("audit-reports/github-workflows-fix-report.md")
	defer out.Close()
	fmt.Fprintln(out, "# Rapport corrections contextuelles GitHub Actions")
	for _, r := range report {
		fmt.Fprintf(out, "## %s\n", r.File)
		for _, issue := range r.Issues {
			fmt.Fprintf(out, "- %s\n", issue)
		}
	}
	fmt.Println("Rapport généré : audit-reports/github-workflows-fix-report.md")
}

// NewLineScanner est un wrapper pour bufio.Scanner qui gère les fins de ligne Windows/Linux/Mac.
import "bufio"
func NewLineScanner(f *os.File) *bufio.Scanner {
	return bufio.NewScanner(f)
}