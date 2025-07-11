// cmd/feedback-generator/main.go
package main

import (
	"fmt"
	"os"
)

func main() {
	// TODO: Générer le rapport de feedback automatisé
	f, err := os.Create("feedback_report.md")
	if err != nil {
		fmt.Println("Erreur création feedback_report.md:", err)
		return
	}
	defer f.Close()

	_, err = f.WriteString("# Rapport de Feedback Automatisé\n\n- Conformité des artefacts\n- Suggestions d’amélioration\n- Statut des validations\n")
	if err != nil {
		fmt.Println("Erreur écriture feedback_report.md:", err)
		return
	}

	fmt.Println("feedback_report.md généré (squelette).")
}
