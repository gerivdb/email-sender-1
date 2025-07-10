// tools/scripts/gen_stub_specs.go
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func main() {
	// Lecture du tableau des besoins généré par collect_needs.go
	file, err := os.Open("restauration_needs_v101.md")
	if err != nil {
		fmt.Println("Erreur : impossible de lire restauration_needs_v101.md")
		os.Exit(1)
	}
	defer file.Close()

	fmt.Println("# Spécifications de stubs/fonctions à restaurer v101\n")
	fmt.Println("| Fichier | Exemple de stub Go |")
	fmt.Println("|---|---|")

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "| ") && strings.Contains(line, ".go") {
			cols := strings.Split(line, "|")
			if len(cols) >= 3 {
				file := strings.TrimSpace(cols[1])
				// Génération d'un exemple de stub Go minimal
				stub := fmt.Sprintf("package %s\n\n// TODO: Implémenter les fonctions nécessaires\n", strings.TrimSuffix(file, ".go"))
				fmt.Printf("| %s | `%s` |\n", file, stub)
			}
		}
	}
	fmt.Println("\n*Généré automatiquement par gen_stub_specs.go*")
}
