// scripts/fix-yaml-structure.go
package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

type Correction struct {
	File    string
	Line    int
	Message string
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: fix-yaml-structure <directory-or-file>")
		os.Exit(1)
	}

	target := os.Args[1]
	var files []string
	info, err := os.Stat(target)
	if err != nil {
		fmt.Printf("Erreur accès %s: %v\n", target, err)
		os.Exit(1)
	}
	if info.IsDir() {
		files, err = filepath.Glob(filepath.Join(target, "*.yml"))
		if err != nil {
			fmt.Printf("Erreur lecture dossier: %v\n", err)
			os.Exit(1)
		}
		files2, _ := filepath.Glob(filepath.Join(target, "*.yaml"))
		files = append(files, files2...)
	} else {
		files = []string{target}
	}

	var corrections []Correction
	for _, file := range files {
		corrs, err := processYAMLFile(file)
		if err != nil {
			fmt.Printf("Erreur traitement %s: %v\n", file, err)
			continue
		}
		corrections = append(corrections, corrs...)
	}

	reportFile := "fix-yaml-structure-report.md"
	err = writeReport(reportFile, corrections)
	if err != nil {
		fmt.Printf("Erreur écriture rapport: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Correction terminée. Rapport: %s\n", reportFile)
}

func processYAMLFile(path string) ([]Correction, error) {
	data, err := ioutil.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var node yaml.Node
	err = yaml.Unmarshal(data, &node)
	if err != nil {
		return []Correction{{
			File:    path,
			Line:    0,
			Message: fmt.Sprintf("Erreur de parsing YAML: %v", err),
		}}, nil
	}

	var corrections []Correction
	// Correction structurelle (exemple simple)
	if node.Kind == yaml.DocumentNode && len(node.Content) > 0 {
		root := node.Content[0]
		corrections = append(corrections, checkAndFixNode(path, root)...)
	}

	// Réécriture du fichier corrigé
	out, err := yaml.Marshal(&node)
	if err == nil {
		_ = ioutil.WriteFile(path, out, 0644)
	}
	return corrections, nil
}

func checkAndFixNode(file string, node *yaml.Node) []Correction {
	var corrs []Correction
	// Exemple: détecter les clés implicites ou block collections mal formées
	if node.Kind == yaml.MappingNode {
		for i := 0; i < len(node.Content); i += 2 {
			key := node.Content[i]
			val := node.Content[i+1]
			if key.Kind != yaml.ScalarNode {
				corrs = append(corrs, Correction{
					File:    file,
					Line:    key.Line,
					Message: "Clé non scalaire détectée (clé implicite ou structure complexe)",
				})
				key.Kind = yaml.ScalarNode
				key.Value = fmt.Sprintf("clé_corrigée_%d", key.Line)
			}
			corrs = append(corrs, checkAndFixNode(file, val)...)
		}
	}
	if node.Kind == yaml.SequenceNode {
		for _, elem := range node.Content {
			corrs = append(corrs, checkAndFixNode(file, elem)...)
		}
	}
	return corrs
}

func writeReport(path string, corrections []Correction) error {
	var b strings.Builder
	b.WriteString("# Rapport de corrections structurelles YAML\n\n")
	for _, c := range corrections {
		b.WriteString(fmt.Sprintf("- Fichier: `%s`, Ligne: %d — %s\n", c.File, c.Line, c.Message))
	}
	return ioutil.WriteFile(path, []byte(b.String()), 0644)
}
