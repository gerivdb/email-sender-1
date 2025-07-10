// tools/scripts/collect_needs.go
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func main() {
	// Lecture du rapport d'écart généré par gap_analysis.go
	file, err := os.Open("gap_analysis_v101.md")
	if err != nil {
		fmt.Println("Erreur : impossible de lire gap_analysis_v101.md")
		os.Exit(1)
	}
	defer file.Close()

	fmt.Println("# Besoins de restauration/réécriture v101\n")
	fmt.Println("| Fichier | Action à prévoir | Priorité |")
	fmt.Println("|---|---|---|")

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "| ") && strings.Contains(line, ".go") {
			cols := strings.Split(line, "|")
			if len(cols) >= 3 {
				file := strings.TrimSpace(cols[1])
				// Suggestion automatique : à personnaliser ensuite
				fmt.Printf("| %s | À restaurer ou réécrire | À prioriser selon dépendances |\n", file)
			}
		}
	}
	fmt.Println("\n*Généré automatiquement par collect_needs.go*")
}
