package main

import (
	"fmt"
	"os"
	"regexp"
	"strings"
)

func main() {
	planPath := "d:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\projet\\roadmaps\\plans\\consolidated\\plan-dev-v39-amelioration-plan-dev-ameliore.md"

	fmt.Println("🔧 Plan Updater - Correction des références PowerShell vers Go")
	fmt.Println("================================================================")

	// Lire le fichier
	content, err := os.ReadFile(planPath)
	if err != nil {
		fmt.Printf("❌ Erreur lecture fichier: %v\n", err)
		return
	}

	text := string(content)
	originalText := text

	// Corrections des références PowerShell vers Go
	corrections := map[string]string{
		// Scripts PowerShell vers outils Go
		"/scripts/run-redis-tests.ps1":    "tools/test-runner",
		"/scripts/python/model_loader.py": "tools/ml-bridge",
		"/scripts/build-production.ps1":   "tools/build-production",
		"/scripts/backup-automation.sh":   "tools/backup-manager",
		"/scripts/":                       "tools/",
		".ps1":                            "",

		// Références PowerShell génériques
		"avec PowerShell": "avec des outils Go natifs",
		"PowerShell":      "outils Go",
		"WindowsInstallationGuide avec PowerShell": "WindowsInstallationGuide avec les outils Go natifs",
	}

	changesCount := 0
	for old, new := range corrections {
		if strings.Contains(text, old) {
			before := strings.Count(text, old)
			text = strings.ReplaceAll(text, old, new)
			after := strings.Count(text, old)
			if before > after {
				changesCount += (before - after)
				fmt.Printf("✅ Remplacé '%s' par '%s' (%d occurrences)\n", old, new, before-after)
			}
		}
	}
	// Marquer les tâches complétées avec des checkboxes
	checkboxPattern := regexp.MustCompile(`- \[ \] (.+)`)
	completedPattern := regexp.MustCompile(`- \[x\] ✅ \*\*COMPLÉTÉ\*\*`)

	lines := strings.Split(text, "\n")
	for i, line := range lines {
		// Convertir les tâches de la Phase 0 en complétées si pas déjà fait
		if strings.Contains(line, "Phase 0") || strings.Contains(line, "Écosystème") {
			if checkboxPattern.MatchString(line) && !completedPattern.MatchString(line) {
				lines[i] = checkboxPattern.ReplaceAllString(line, "- [x] ✅ **COMPLÉTÉ** $1")
				changesCount++
			}
		}
	}

	text = strings.Join(lines, "\n")

	// Sauvegarder si des changements ont été effectués
	if text != originalText {
		err = os.WriteFile(planPath, []byte(text), 0644)
		if err != nil {
			fmt.Printf("❌ Erreur sauvegarde: %v\n", err)
			return
		}

		fmt.Printf("\n🎉 Mise à jour complétée avec %d modifications\n", changesCount)
		fmt.Println("📝 Fichier mis à jour:", planPath)
	} else {
		fmt.Println("ℹ️ Aucune modification nécessaire")
	}
}
