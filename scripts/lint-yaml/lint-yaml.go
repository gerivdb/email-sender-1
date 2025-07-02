// scripts/lint-yaml.go
// Valide la syntaxe YAML de tous les fichiers du dépôt (Helm, CI/CD).
// Usage : go run scripts/lint-yaml.go

package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

func main() {
	// Limite le scope aux dossiers YAML métier
	targetDirs := []string{
		"charts",
		".github/workflows",
		"deploy",
	}
	var files []string
	for _, dir := range targetDirs {
		_ = filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
			if err == nil && !info.IsDir() &&
				(strings.HasSuffix(info.Name(), ".yaml") || strings.HasSuffix(info.Name(), ".yml")) &&
				!strings.HasSuffix(info.Name(), ".bak") && !strings.Contains(info.Name(), "tmp") {
				files = append(files, path)
			}
			return nil
		})
	}

	fmt.Printf("Analyse de %d fichiers YAML dans %v\n", len(files), targetDirs)
	hasError := false
	nbErr := 0
	for _, file := range files {
		data, err := os.ReadFile(file)
		if err != nil {
			fmt.Printf("Erreur lecture %s : %v\n", file, err)
			hasError = true
			nbErr++
			continue
		}
		var out interface{}
		if err := yaml.Unmarshal(data, &out); err != nil {
			fmt.Printf("Erreur YAML dans %s : %v\n", file, err)
			hasError = true
			nbErr++
		}
	}
	fmt.Printf("Total erreurs YAML détectées : %d\n", nbErr)
	if hasError {
		os.Exit(1)
	}
}
