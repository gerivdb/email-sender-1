// tools/scripts/gen_stubs.go
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func main() {
	// Lecture du tableau des specs généré par gen_stub_specs.go
	file, err := os.Open("restauration_specs_v101.md")
	if err != nil {
		fmt.Println("Erreur : impossible de lire restauration_specs_v101.md")
		os.Exit(1)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "| ") && strings.Contains(line, ".go") {
			cols := strings.Split(line, "|")
			if len(cols) >= 3 {
				fileName := strings.TrimSpace(cols[1])
				stub := strings.TrimSpace(cols[2])
				stub = strings.Trim(stub, "`") // Nettoyage du code Go
				// Création du fichier stub
				err := os.WriteFile(fileName, []byte(stub), 0o644)
				if err != nil {
					fmt.Printf("Erreur lors de la création de %s : %v\n", fileName, err)
				} else {
					fmt.Printf("Stub généré : %s\n", fileName)
				}
			}
		}
	}
	fmt.Println("\n*Généré automatiquement par gen_stubs.go*")
}
