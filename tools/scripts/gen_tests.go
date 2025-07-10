// tools/scripts/gen_tests.go
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
				testFile := strings.TrimSuffix(fileName, ".go") + "_test.go"
				packageName := strings.Split(fileName, "/")
				packageName = packageName[:len(packageName)-1]
				pkg := "main"
				if len(packageName) > 0 {
					pkg = packageName[len(packageName)-1]
				}
				testContent := fmt.Sprintf(`package %s

import "testing"

func TestStub_%s(t *testing.T) {
	// TODO: Implémenter un test minimal pour %s
	t.Log("Test de stub pour %s")
}
`, pkg, strings.ReplaceAll(strings.TrimSuffix(fileName, ".go"), "/", "_"), fileName, fileName)
				os.WriteFile(testFile, []byte(testContent), 0o644)
				fmt.Printf("Test généré : %s\n", testFile)
			}
		}
	}
	fmt.Println("\n*Généré automatiquement par gen_tests.go*")
}
