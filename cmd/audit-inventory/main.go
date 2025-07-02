// cmd/audit-inventory/main.go
package main

import (
	"fmt"
	"os"
	"path/filepath"
)

func main() {
	var files []string
	filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && (filepath.Ext(path) == ".md" || filepath.Ext(path) == ".go" || filepath.Ext(path) == ".ps1") {
			files = append(files, path)
		}
		return nil
	})

	f, err := os.Create("audit_inventory.md")
	if err != nil {
		fmt.Println("Erreur lors de la création de l'inventaire :", err)
		os.Exit(1)
	}
	defer f.Close()
	fmt.Fprintln(f, "# Inventaire des artefacts à auditer\n")
	for _, file := range files {
		fmt.Fprintln(f, "-", file)
	}
	fmt.Println("Inventaire généré dans audit_inventory.md")
}
