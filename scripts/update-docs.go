package main

import (
	"fmt"
	"os"
	"time"
)

// Script d'actualisation automatique des specs, checklists et docs
func main() {
	fmt.Println("Mise à jour automatique des documents de roadmap SOTA...")
	// Exemple : mise à jour d'un timestamp dans chaque checklist
	checklists := []string{
		"docs/checklist-architecture.md",
		"docs/checklist-devops.md",
		"docs/checklist-qualite.md",
		"docs/checklist-securite.md",
	}
	for _, file := range checklists {
		f, err := os.OpenFile(file, os.O_APPEND|os.O_WRONLY, 0644)
		if err == nil {
			f.WriteString(fmt.Sprintf("\nDernière mise à jour : %s\n", time.Now().Format(time.RFC3339)))
			f.Close()
		}
	}
	fmt.Println("Checklists mises à jour.")
}
