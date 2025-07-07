// analyze_imports.go
//
// Analyse la liste des imports internes (JSON généré par scan_imports.go),
// génère un plan de correction (JSON) et un patch (diff) pour centraliser les imports.

package analyze_imports

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"strings"
)

type FileImports struct {
	File    string   `json:"file"`
	Imports []string `json:"imports"`
}

type Report struct {
	Files []FileImports `json:"files"`
}

type Correction struct {
	File         string            `json:"file"`
	Replacements map[string]string `json:"replacements"` // ancien import -> nouvel import
}

var (
	inputJSON   = flag.String("input-json", "", "Fichier JSON listant les imports internes")
	outputJSON  = flag.String("output-json", "plan_import_correction.json", "Chemin du plan de correction JSON")
	outputPatch = flag.String("output-patch", "diff_import_correction.patch", "Chemin du patch diff")
)

func main() {
	flag.Parse()
	if *inputJSON == "" {
		fmt.Fprintln(os.Stderr, "Usage: --input-json <file>")
		os.Exit(1)
	}

	// Lecture du rapport d'import
	f, err := os.Open(*inputJSON)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur ouverture %s: %v\n", *inputJSON, err)
		os.Exit(1)
	}
	defer f.Close()
	var report Report
	dec := json.NewDecoder(f)
	if err := dec.Decode(&report); err != nil {
		fmt.Fprintf(os.Stderr, "Erreur décodage JSON: %v\n", err)
		os.Exit(1)
	}

	// Génération du plan de correction
	var corrections []Correction
	for _, fi := range report.Files {
		replacements := make(map[string]string)
		for _, imp := range fi.Imports {
			if !strings.HasPrefix(imp, "email_sender/core/") {
				newImport := toCentralImport(imp)
				if newImport != imp {
					replacements[imp] = newImport
				}
			}
		}
		if len(replacements) > 0 {
			corrections = append(corrections, Correction{File: fi.File, Replacements: replacements})
		}
	}

	// Écriture du plan JSON
	planFile, err := os.Create(*outputJSON)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur création plan JSON: %v\n", err)
		os.Exit(1)
	}
	defer planFile.Close()
	enc := json.NewEncoder(planFile)
	enc.SetIndent("", "  ")
	enc.Encode(corrections)

	// Génération du patch diff (format simple)
	patchFile, err := os.Create(*outputPatch)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur création patch: %v\n", err)
		os.Exit(1)
	}
	defer patchFile.Close()
	for _, corr := range corrections {
		for old, new := range corr.Replacements {
			fmt.Fprintf(patchFile, "=== %s ===\n", corr.File)
			fmt.Fprintf(patchFile, "- import \"%s\"\n", old)
			fmt.Fprintf(patchFile, "+ import \"%s\"\n", new)
		}
	}
	fmt.Println("Plan de correction et patch générés.")
}

// toCentralImport convertit un import interne relatif ou non centralisé en import centralisé
func toCentralImport(imp string) string {
	// Exemples de conversion : "./foo/bar" -> "email_sender/core/foo/bar"
	imp = strings.TrimPrefix(imp, "./")
	imp = strings.TrimPrefix(imp, "../")
	if !strings.HasPrefix(imp, "email_sender/core/") {
		return "email_sender/core/" + strings.TrimPrefix(imp, "core/")
	}
	return imp
}
