// scan_go_mods.go
//
// Scanne le dépôt pour détecter tous les fichiers go.mod qui ne sont pas à la racine (go.mod parasites).
// Génère un rapport JSON et un rapport Markdown.

package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

var (
	outputJSON = flag.String("output-json", "list_go_mod_parasites.json", "Chemin du rapport JSON")
	outputMD   = flag.String("output-md", "report_go_mod_parasites.md", "Chemin du rapport Markdown")
	rootDir    = flag.String("root", ".", "Racine du monorepo à scanner")
)

func main() {
	flag.Parse()
	var parasites []string

	err := filepath.Walk(*rootDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && filepath.Base(path) == "go.mod" && !isRootFile(path) {
			parasites = append(parasites, path)
		}
		return nil
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur parcours fichiers: %v\n", err)
		os.Exit(1)
	}

	// Écriture JSON
	jsonFile, err := os.Create(*outputJSON)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur création fichier JSON: %v\n", err)
		os.Exit(1)
	}
	defer jsonFile.Close()
	enc := json.NewEncoder(jsonFile)
	enc.SetIndent("", "  ")
	enc.Encode(parasites)

	// Écriture Markdown
	mdFile, err := os.Create(*outputMD)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur création fichier Markdown: %v\n", err)
		os.Exit(1)
	}
	defer mdFile.Close()
	fmt.Fprintf(mdFile, "# go.mod parasites détectés\n\n")
	if len(parasites) == 0 {
		fmt.Fprintf(mdFile, "Aucun go.mod parasite détecté.\n")
	} else {
		fmt.Fprintf(mdFile, "Les fichiers suivants sont des go.mod parasites (hors racine) :\n\n")
		for _, f := range parasites {
			fmt.Fprintf(mdFile, "- `%s`\n", f)
		}
	}
	fmt.Println("Scan terminé. Rapports générés.")
}

// isRootFile retourne true si le fichier est à la racine du repo (pas de / dans le chemin)
func isRootFile(path string) bool {
	clean := filepath.ToSlash(path)
	return !strings.Contains(clean, "/") && filepath.Base(clean) == "go.mod"
}
