// cmd/audit-gap-analysis/main.go
package main

import (
	"fmt"
	"os"
	"path/filepath"
)

func main() {
	filesMap := make(map[string][]string)
	filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && (filepath.Ext(path) == ".md" || filepath.Ext(path) == ".go" || filepath.Ext(path) == ".ps1") {
			filesMap[info.Name()] = append(filesMap[info.Name()], path)
		}
		return nil
	})

	f, err := os.Create("audit_gap_report.md")
	if err != nil {
		fmt.Println("Erreur lors de la création du rapport d'écart :", err)
		os.Exit(1)
	}
	defer f.Close()
	fmt.Fprintln(f, "# Rapport d'écart et détection des doublons\n")
	for name, paths := range filesMap {
		if len(paths) > 1 {
			fmt.Fprintf(f, "## Doublon : %s\n", name)
			for _, p := range paths {
				fmt.Fprintf(f, "- %s\n", p)
			}
			fmt.Fprintln(f)
		}
	}
	fmt.Println("Rapport généré dans audit_gap_report.md")
}
