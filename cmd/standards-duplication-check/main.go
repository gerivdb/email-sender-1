// cmd/standards-duplication-check/main.go
package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
)

func main() {
	standards := make(map[string]bool)
	files, err := ioutil.ReadDir(".github/docs")
	if err == nil {
		for _, f := range files {
			if !f.IsDir() && len(f.Name()) > 3 && f.Name()[len(f.Name())-3:] == ".md" {
				standards[f.Name()] = true
			}
		}
	}

	duplications := make(map[string][]string)
	filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && filepath.Ext(path) == ".md" && !filepath.HasPrefix(path, ".github/docs") {
			if standards[info.Name()] {
				duplications[info.Name()] = append(duplications[info.Name()], path)
			}
		}
		return nil
	})

	f, err := os.Create("duplication_report.md")
	if err != nil {
		fmt.Println("Erreur lors de la création du rapport de duplication :", err)
		os.Exit(1)
	}
	defer f.Close()
	fmt.Fprintln(f, "# Rapport de duplication des standards\n")
	for name, paths := range duplications {
		fmt.Fprintf(f, "## Standard dupliqué : %s\n", name)
		for _, p := range paths {
			fmt.Fprintf(f, "- %s\n", p)
		}
		fmt.Fprintln(f)
	}
	fmt.Println("Rapport généré dans duplication_report.md")
}
