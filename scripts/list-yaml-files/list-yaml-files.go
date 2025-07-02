// scripts/list-yaml-files.go
// Recensement de tous les fichiers YAML (Helm, CI/CD) du dépôt.
// Usage : go run scripts/list-yaml-files.go

package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	root := "."
	var found []string
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && (strings.HasSuffix(info.Name(), ".yaml") || strings.HasSuffix(info.Name(), ".yml")) {
			found = append(found, path)
		}
		return nil
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lors du scan : %v\n", err)
		os.Exit(1)
	}
	fmt.Println("# Fichiers YAML trouvés :")
	for _, f := range found {
		fmt.Println(f)
	}
}
