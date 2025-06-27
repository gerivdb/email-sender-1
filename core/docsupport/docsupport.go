/*
Package docsupport fournit des fonctions pour analyser la documentation, supports et générer des rapports associés.

Fonctions principales :
- ScanDocSupports : détecte les fichiers de documentation/support.
- ExportDocSupportsJSON : exporte la liste au format JSON.
- ExportDocGapAnalysis : génère un rapport markdown d’écarts de documentation.

Utilisation typique :
docs, err := docsupport.ScanDocSupports("chemin/du/projet")
err := docsupport.ExportDocSupportsJSON(docs, "doc-supports-scan.json")
err := docsupport.ExportDocGapAnalysis(docs, "DOC_GAP_ANALYSIS.md")
*/
package docsupport

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

type DocSupport struct {
	File     string `json:"file"`
	Type     string `json:"type"`
	Size     int64  `json:"size"`
	Coverage string `json:"coverage"`
}

// ScanDocSupports détecte les fichiers de documentation/support dans le dossier root.
func ScanDocSupports(root string) ([]DocSupport, error) {
	var docs []DocSupport
	filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}
		typ := "autre"
		if strings.HasSuffix(path, ".md") {
			typ = "markdown"
		} else if strings.HasSuffix(path, ".pdf") {
			typ = "pdf"
		} else if strings.HasSuffix(path, ".docx") {
			typ = "docx"
		}
		coverage := "inconnu"
		if info.Size() > 0 {
			coverage = "présent"
		}
		docs = append(docs, DocSupport{
			File:     path,
			Type:     typ,
			Size:     info.Size(),
			Coverage: coverage,
		})
		return nil
	})
	return docs, nil
}

// ExportDocSupportsJSON exporte la liste des supports au format JSON.
func ExportDocSupportsJSON(docs []DocSupport, outPath string) error {
	data, err := json.MarshalIndent(docs, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(outPath, data, 0o644)
}

// ExportDocGapAnalysis génère un rapport markdown d’écarts de documentation.
func ExportDocGapAnalysis(docs []DocSupport, outPath string) error {
	f, err := os.Create(outPath)
	if err != nil {
		return err
	}
	defer f.Close()
	f.WriteString("# DOC_GAP_ANALYSIS.md\n\n| Fichier | Type | Taille | Couverture |\n|---|---|---|---|\n")
	for _, d := range docs {
		f.WriteString(fmt.Sprintf("| %s | %s | %d | %s |\n", d.File, d.Type, d.Size, d.Coverage))
	}
	return nil
}
