// scripts/list-go-mods.go
// Recensement de tous les fichiers go.mod et go.work du dépôt.
// Usage : go run scripts/list-go-mods.go

package main

import (
	"fmt"
	"os"
	"path/filepath"
)

func main() {
	root := "."
	var found []string
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.Name() == "go.mod" || info.Name() == "go.work" {
			found = append(found, path)
		}
		return nil
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lors du scan : %v\n", err)
		os.Exit(1)
	}
	fmt.Println("# Fichiers go.mod et go.work trouvés :")
	for _, f := range found {
		fmt.Println(f)
	}
}
