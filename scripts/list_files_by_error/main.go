// scripts/list_files_by_error.go
// Génère un tableau Markdown listant les fichiers/packages concernés par chaque catégorie d’erreur

package main

import (
	"encoding/json"
	"fmt"
	"os"
	"regexp"
)

type Categorized struct {
	Category string `json:"category"`
	Error    struct {
		Message string `json:"message"`
	} `json:"error"`
}

func extractFile(msg string) string {
	re := regexp.MustCompile(`^([^\s:]+)`)
	matches := re.FindStringSubmatch(msg)
	if len(matches) > 1 {
		return matches[1]
	}
	return ""
}

func main() {
	f, err := os.Open("errors-categorized.json")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur ouverture errors-categorized.json: %v\n", err)
		os.Exit(1)
	}
	defer f.Close()

	var categorized []Categorized
	dec := json.NewDecoder(f)
	if err := dec.Decode(&categorized); err != nil {
		fmt.Fprintf(os.Stderr, "Erreur parsing JSON: %v\n", err)
		os.Exit(1)
	}

	byCat := map[string][]string{}
	for _, c := range categorized {
		file := extractFile(c.Error.Message)
		if file != "" {
			byCat[c.Category] = append(byCat[c.Category], file)
		}
	}

	// Génération Markdown
	out, err := os.Create("files-by-error-type.md")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur création files-by-error-type.md: %v\n", err)
		os.Exit(1)
	}
	defer out.Close()

	for cat, files := range byCat {
		fmt.Fprintf(out, "### %s\n", cat)
		for _, f := range files {
			fmt.Fprintf(out, "- %s\n", f)
		}
		fmt.Fprintln(out)
	}
	fmt.Println("Listing Markdown généré : files-by-error-type.md")
}
