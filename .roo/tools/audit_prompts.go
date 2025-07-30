package main

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

var promptFiles = []string{
	".roo/system-prompt-architect",
	".roo/system-prompt-ask",
	".roo/system-prompt-code",
	".roo/system-prompt-debug",
	".roo/system-prompt-documentation-writer",
	".roo/system-prompt-mode-writer",
	".roo/system-prompt-orchestrator",
	".roo/system-prompt-project-research",
	".roo/system-prompt-user-story-creator",
}

const referenceText = "La liste des outils autorisés/restrictifs pour ce mode est définie dynamiquement dans `.roo/rules/tools-registry.md`"

func main() {
	var errors []string
	toolListRegex := regexp.MustCompile(`(?i)Outils autorisés\s*:\s*[\w, ]+`)

	for _, file := range promptFiles {
		f, err := os.Open(file)
		if err != nil {
			errors = append(errors, fmt.Sprintf("%s : fichier manquant", file))
			continue
		}
		defer f.Close()

		foundReference := false
		foundToolList := false

		scanner := bufio.NewScanner(f)
		for scanner.Scan() {
			line := scanner.Text()
			if strings.Contains(line, referenceText) {
				foundReference = true
			}
			if toolListRegex.MatchString(line) {
				foundToolList = true
			}
		}
		if !foundReference {
			errors = append(errors, fmt.Sprintf("%s : référence au registre manquante", file))
		}
		if foundToolList {
			errors = append(errors, fmt.Sprintf("%s : liste d’outils en dur détectée", file))
		}
	}

	if len(errors) > 0 {
		fmt.Println("Erreurs détectées :")
		for _, err := range errors {
			fmt.Println("-", err)
		}
		os.Exit(1)
	} else {
		fmt.Println("Tous les prompts sont conformes.")
	}
}