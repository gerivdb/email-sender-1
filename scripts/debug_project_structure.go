// Script de diagnostic pour projet Go (à lancer avec go run scripts/debug_project_structure.go)
// Objectif : lister imports, redéfinitions de types, fichiers main, variables non utilisées

package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	root := "."
	fmt.Println("=== Diagnostic Go Project Structure ===")

	// 1. Imports
	fmt.Println("\n--- Imports par fichier ---")
	filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if strings.HasSuffix(path, ".go") {
			content, _ := os.ReadFile(path)
			lines := strings.Split(string(content), "\n")
			for _, line := range lines {
				if strings.HasPrefix(line, "import") || strings.Contains(line, "\"github.com/gerivdb/email-sender-1") || strings.Contains(line, "EMAIL_SENDER_1/") {
					fmt.Printf("%s: %s\n", path, line)
				}
			}
		}
		return nil
	})

	// 2. Redéfinitions de types
	fmt.Println("\n--- Redéfinitions de type Dependency ---")
	filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if strings.HasSuffix(path, ".go") {
			content, _ := os.ReadFile(path)
			if strings.Contains(string(content), "type Dependency struct") {
				fmt.Printf("%s: type Dependency struct\n", path)
			}
		}
		return nil
	})

	// 3. Fichiers main
	fmt.Println("\n--- Fichiers package main ---")
	filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if strings.HasSuffix(path, ".go") {
			content, _ := os.ReadFile(path)
			if strings.Contains(string(content), "package main") {
				fmt.Printf("%s: package main\n", path)
			}
		}
		return nil
	})

	// 4. Usages de types sans préfixe
	fmt.Println("\n--- Usages de DependencyMetadata sans préfixe ---")
	filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if strings.HasSuffix(path, ".go") {
			content, _ := os.ReadFile(path)
			if strings.Contains(string(content), "DependencyMetadata") && !strings.Contains(string(content), "interfaces.DependencyMetadata") {
				fmt.Printf("%s: Usage sans préfixe\n", path)
			}
		}
		return nil
	})

	// 5. Variables non utilisées (simple détection)
	fmt.Println("\n--- Variables non utilisées (détection simple) ---")
	filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if strings.HasSuffix(path, ".go") {
			content, _ := os.ReadFile(path)
			if strings.Contains(string(content), "declared and not used") {
				fmt.Printf("%s: Variable non utilisée détectée\n", path)
			}
		}
		return nil
	})
}
