/*
Package extraction fournit des fonctions pour extraire et parser les fichiers du projet, et générer des rapports d’extraction.

Fonctions principales :
- ScanExtraction : extrait les fichiers et métadonnées cibles.
- ExportExtractionJSON : exporte les résultats d’extraction au format JSON.
- ExportExtractionGapAnalysis : génère un rapport markdown d’écarts d’extraction/parsing.

Utilisation typique :
results, err := extraction.ScanExtraction("chemin/du/projet")
err := extraction.ExportExtractionJSON(results, "extraction-parsing-scan.json")
err := extraction.ExportExtractionGapAnalysis(results, "EXTRACTION_PARSING_GAP_ANALYSIS.md")
*/
package extraction

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

type ExtractionResult struct {
	File        string `json:"file"`
	Type        string `json:"type"`
	Size        int64  `json:"size"`
	ParseStatus string `json:"parse_status"`
}

// ScanExtraction extrait les fichiers et métadonnées cibles du dossier root.
func ScanExtraction(root string) ([]ExtractionResult, error) {
	var results []ExtractionResult
	filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}
		parseStatus := "OK"
		if info.Size() == 0 {
			parseStatus = "Vide"
		}
		results = append(results, ExtractionResult{
			File:        path,
			Type:        filepath.Ext(path),
			Size:        info.Size(),
			ParseStatus: parseStatus,
		})
		return nil
	})
	return results, nil
}

// ExportExtractionJSON exporte les résultats d’extraction au format JSON.
func ExportExtractionJSON(results []ExtractionResult, outPath string) error {
	data, err := json.MarshalIndent(results, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(outPath, data, 0644)
}

// ExportExtractionGapAnalysis génère un rapport markdown d’écarts d’extraction/parsing.
func ExportExtractionGapAnalysis(results []ExtractionResult, outPath string) error {
	f, err := os.Create(outPath)
	if err != nil {
		return err
	}
	defer f.Close()
	f.WriteString("# EXTRACTION_PARSING_GAP_ANALYSIS.md\n\n| Fichier | Type | Taille | Statut Parsing |\n|---|---|---|---|\n")
	for _, r := range results {
		f.WriteString(fmt.Sprintf("| %s | %s | %d | %s |\n", r.File, r.Type, r.Size, r.ParseStatus))
	}
	return nil
}
