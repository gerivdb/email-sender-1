/*
Package graphgen fournit des fonctions pour générer et analyser des graphes de dépendances ou de structure du projet.

Fonctions principales :
- ScanGraph : génère une représentation simple du graphe du projet.
- ExportGraphJSON : exporte le graphe au format JSON.
- ExportGraphGapAnalysis : génère un rapport markdown d’écarts de graphe.

Utilisation typique :
graph, err := graphgen.ScanGraph("chemin/du/projet")
err := graphgen.ExportGraphJSON(graph, "graphgen-scan.json")
err := graphgen.ExportGraphGapAnalysis(graph, "GRAPHGEN_GAP_ANALYSIS.md")
*/
package graphgen

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

type Node struct {
	Name  string   `json:"name"`
	Type  string   `json:"type"`
	Links []string `json:"links"`
}

// ScanGraph génère une représentation simple du graphe du projet.
func ScanGraph(root string) ([]Node, error) {
	var nodes []Node
	filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}
		nodes = append(nodes, Node{
			Name:  info.Name(),
			Type:  filepath.Ext(path),
			Links: []string{}, // À spécialiser pour détecter les liens/dépendances réelles
		})
		return nil
	})
	return nodes, nil
}

// ExportGraphJSON exporte le graphe au format JSON.
func ExportGraphJSON(nodes []Node, outPath string) error {
	data, err := json.MarshalIndent(nodes, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(outPath, data, 0644)
}

// ExportGraphGapAnalysis génère un rapport markdown d’écarts de graphe.
func ExportGraphGapAnalysis(nodes []Node, outPath string) error {
	f, err := os.Create(outPath)
	if err != nil {
		return err
	}
	defer f.Close()
	f.WriteString("# GRAPHGEN_GAP_ANALYSIS.md\n\n| Noeud | Type | Nb liens |\n|---|---|---|\n")
	for _, n := range nodes {
		f.WriteString(fmt.Sprintf("| %s | %s | %d |\n", n.Name, n.Type, len(n.Links)))
	}
	return nil
}
