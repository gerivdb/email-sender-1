/*
Package gapanalyzer fournit des fonctions pour analyser les écarts détectés dans les modules.

Fonctions principales :
- AnalyzeGaps : lit un fichier JSON de modules et retourne la liste des écarts détectés.
- ExportMarkdown : exporte la liste des écarts au format Markdown.

Utilisation typique :
gaps, err := gapanalyzer.AnalyzeGaps("modules.json")
err := gapanalyzer.ExportMarkdown(gaps, "INIT_GAP_ANALYSIS.md")
*/
package gapanalyzer

import (
	"encoding/json"
	"fmt"
	"os"
)

type Gap struct {
	Module         string
	Ecart          string
	Risque         string
	Recommandation string
}

/*
AnalyzeGaps lit un fichier JSON de modules et retourne la liste des écarts détectés.

Paramètre :
- scanPath : chemin du fichier JSON à analyser

Retourne :
- []Gap : liste des écarts détectés
- error : erreur éventuelle
*/
func AnalyzeGaps(scanPath string) ([]Gap, error) {
	data, err := os.ReadFile(scanPath)
	if err != nil {
		return nil, err
	}
	var modules []map[string]interface{}
	json.Unmarshal(data, &modules)
	var gaps []Gap
	for _, m := range modules {
		if m["lang"] == "unknown" {
			gaps = append(gaps, Gap{
				Module:         m["name"].(string),
				Ecart:          "Langage non détecté",
				Risque:         "Non analysé",
				Recommandation: "Compléter manuellement",
			})
		}
	}
	return gaps, nil
}

/*
ExportMarkdown exporte la liste des écarts au format Markdown.

Paramètres :
- gaps : liste des écarts à exporter
- outPath : chemin du fichier de sortie

Retourne :
- error : erreur éventuelle
*/
func ExportMarkdown(gaps []Gap, outPath string) error {
	f, err := os.Create(outPath)
	if err != nil {
		return err
	}
	defer f.Close()
	f.WriteString("# INIT_GAP_ANALYSIS.md\n\n| Module/Fichier | Écart identifié | Risque | Recommandation |\n|---|---|---|---|\n")
	for _, g := range gaps {
		f.WriteString(fmt.Sprintf("| %s | %s | %s | %s |\n", g.Module, g.Ecart, g.Risque, g.Recommandation))
	}
	return nil
}
