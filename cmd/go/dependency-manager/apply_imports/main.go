// apply_imports.go
//
// Applique les corrections d'import listées dans un patch diff (généré par analyze_imports.go).
// Modifie les fichiers Go concernés et génère un rapport JSON du succès/échec de chaque modification.

package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"strings"
)

type ApplyResult struct {
	File   string `json:"file"`
	Status string `json:"status"` // "modified", "unchanged", "error"
	Error  string `json:"error,omitempty"`
}

var (
	inputPatch = flag.String("input-patch", "", "Fichier patch diff à appliquer")
	report     = flag.String("report", "apply_import_correction_report.json", "Chemin du rapport JSON")
)

func main() {
	flag.Parse()
	if *inputPatch == "" {
		fmt.Fprintln(os.Stderr, "Usage: --input-patch <file>")
		os.Exit(1)
	}

	// Lecture du patch diff
	patches, err := parsePatch(*inputPatch)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lecture patch: %v\n", err)
		os.Exit(1)
	}

	var results []ApplyResult
	for file, replacements := range patches {
		status, errMsg := applyReplacements(file, replacements)
		res := ApplyResult{File: file}
		if errMsg != "" {
			res.Status = "error"
			res.Error = errMsg
		} else if status {
			res.Status = "modified"
		} else {
			res.Status = "unchanged"
		}
		results = append(results, res)
	}

	// Écriture du rapport JSON
	repFile, err := os.Create(*report)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur création rapport JSON: %v\n", err)
		os.Exit(1)
	}
	defer repFile.Close()
	enc := json.NewEncoder(repFile)
	enc.SetIndent("", "  ")
	enc.Encode(results)

	fmt.Printf("Application du patch terminée. Rapport: %s\n", *report)
}

// parsePatch lit un patch diff simple et retourne une map fichier -> remplacements (ancien import -> nouvel import)
func parsePatch(path string) (map[string]map[string]string, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	patches := make(map[string]map[string]string)
	var currentFile string
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "===") {
			currentFile = strings.TrimSpace(strings.Trim(line, "= "))
			patches[currentFile] = make(map[string]string)
		} else if strings.HasPrefix(line, "- import ") {
			oldImport := strings.Trim(strings.TrimPrefix(line, "- import "), "\"")
			if scanner.Scan() {
				next := scanner.Text()
				if strings.HasPrefix(next, "+ import ") {
					newImport := strings.Trim(strings.TrimPrefix(next, "+ import "), "\"")
					patches[currentFile][oldImport] = newImport
				}
			}
		}
	}
	return patches, scanner.Err()
}

// applyReplacements modifie le fichier Go en remplaçant les imports selon la map fournie
func applyReplacements(file string, replacements map[string]string) (bool, string) {
	input, err := os.ReadFile(file)
	if err != nil {
		return false, err.Error()
	}
	content := string(input)
	modified := false
	for old, new := range replacements {
		if strings.Contains(content, old) {
			content = strings.ReplaceAll(content, old, new)
			modified = true
		}
	}
	if modified {
		err := os.WriteFile(file, []byte(content), 0o644)
		if err != nil {
			return false, err.Error()
		}
		return true, ""
	}
	return false, ""
}
