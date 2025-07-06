// cmd/cross-doc-inventory/main.go
package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"strings"
)

func main() {
	files, err := ioutil.ReadDir("projet/roadmaps/plans/consolidated")
	if err != nil {
		fmt.Println("Erreur de lecture du dossier consolidated :", err)
		os.Exit(1)
	}
	fout, err := os.Create("cross_doc_inventory.md")
	if err != nil {
		fmt.Println("Erreur lors de la création de l'inventaire cross-doc :", err)
		os.Exit(1)
	}
	defer fout.Close()
	fmt.Fprintln(fout, "# Inventaire des liens internes/externes dans les fichiers Markdown\n")
	for _, f := range files {
		if !f.IsDir() && strings.HasSuffix(f.Name(), ".md") {
			path := "projet/roadmaps/plans/consolidated/" + f.Name()
			content, err := os.ReadFile(path)
			if err != nil {
				fmt.Fprintf(fout, "## %s (erreur de lecture)\n\n", f.Name())
				continue
			}
			lines := strings.Split(string(content), "\n")
			fmt.Fprintf(fout, "## %s\n", f.Name())
			for _, line := range lines {
				if strings.Contains(line, "](") {
					fmt.Fprintf(fout, "%s\n", line)
				}
			}
			fmt.Fprintln(fout)
		}
	}
	fmt.Println("Inventaire généré dans cross_doc_inventory.md")
}
