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
	root := "."
	var files []string
	_ = filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err == nil && !info.IsDir() && (strings.HasSuffix(info.Name(), ".yaml") || strings.HasSuffix(info.Name(), ".yml")) {
			files = append(files, path)
		}
		return nil
	})

	hasError := false
	for _, file := range files {
		data, err := os.ReadFile(file)
		if err != nil {
			fmt.Printf("Erreur lecture %s : %v\n", file, err)
			hasError = true
			continue
		}
		var out interface{}
		if err := yaml.Unmarshal(data, &out); err != nil {
			fmt.Printf("Erreur YAML dans %s : %v\n", file, err)
			hasError = true
		} else {
			fmt.Printf("OK : %s\n", file)
		}
	}
	if hasError {
		os.Exit(1)
	}
}
