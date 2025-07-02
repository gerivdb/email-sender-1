// cmd/standards-inventory/main.go
package main

import (
	"fmt"
	"io/ioutil"
	"os"
)

func main() {
	files, err := ioutil.ReadDir(".github/docs")
	if err != nil {
		fmt.Println("Erreur de lecture du dossier .github/docs :", err)
		os.Exit(1)
	}
	var mdFiles []string
	for _, f := range files {
		if !f.IsDir() && len(f.Name()) > 3 && f.Name()[len(f.Name())-3:] == ".md" {
			mdFiles = append(mdFiles, f.Name())
		}
	}
	fout, err := os.Create("standards_inventory.md")
	if err != nil {
		fmt.Println("Erreur lors de la création de l'inventaire des standards :", err)
		os.Exit(1)
	}
	defer fout.Close()
	fmt.Fprintln(fout, "# Inventaire des standards documentés\n")
	for _, file := range mdFiles {
		fmt.Fprintln(fout, "-", file)
	}
	fmt.Println("Inventaire généré dans standards_inventory.md")
}
