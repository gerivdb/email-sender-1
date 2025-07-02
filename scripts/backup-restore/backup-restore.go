// scripts/backup-restore.go
// Restaure les fichiers .bak générés par les scripts de correction automatique.
// Usage : go run scripts/backup-restore.go

package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	root := "."
	var restored int
	_ = filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err == nil && strings.HasSuffix(path, ".bak") {
			orig := strings.TrimSuffix(path, ".bak")
			fmt.Printf("Restauration de %s -> %s\n", path, orig)
			if err := os.Rename(path, orig); err != nil {
				fmt.Fprintf(os.Stderr, "Erreur restauration %s : %v\n", path, err)
			} else {
				restored++
			}
		}
		return nil
	})
	fmt.Printf("Restauration terminée. %d fichiers restaurés.\n", restored)
}
