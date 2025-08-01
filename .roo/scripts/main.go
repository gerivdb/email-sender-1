// main.go - Script Roo-Code de recensement documentaire
//
// Ce script recense tous les fichiers YAML et Markdown du projet Roo-Code.
// Documentation : conforme aux standards Roo-Code (.roo/rules/), traçabilité assurée.
// Usage : go run main.go
// Maintenance : voir .roo/rules/rules-code.md

package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	root := "."
	var files []string
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && (strings.HasSuffix(path, ".yaml") || strings.HasSuffix(path, ".yml") || strings.HasSuffix(path, ".md")) {
			files = append(files, path)
		}
		return nil
	})
	if err != nil {
		fmt.Println("Erreur lors du scan :", err)
		os.Exit(1)
	}
	fmt.Println("Fichiers YAML/Markdown détectés :")
	for _, f := range files {
		fmt.Println("-", f)
	}
}
