/*
Package sync fournit des fonctions pour automatiser la synchronisation des fichiers et générer des rapports de synchronisation.

Fonctions principales :
- ScanSync : détecte les fichiers à synchroniser et leur statut.
- ExportSyncJSON : exporte les résultats de synchronisation au format JSON.
- ExportSyncGapAnalysis : génère un rapport markdown d’écarts de synchronisation.

Utilisation typique :
syncs, err := sync.ScanSync("chemin/du/projet")
err := sync.ExportSyncJSON(syncs, "sync-scan.json")
err := sync.ExportSyncGapAnalysis(syncs, "SYNC_GAP_ANALYSIS.md")
*/
package sync

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

type SyncResult struct {
	File      string `json:"file"`
	Status    string `json:"status"`
	SyncGroup string `json:"sync_group"`
}

// ScanSync détecte les fichiers à synchroniser et leur statut.
func ScanSync(root string) ([]SyncResult, error) {
	var results []SyncResult
	filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}
		status := "À jour"
		if info.Size() == 0 {
			status = "À synchroniser"
		}
		results = append(results, SyncResult{
			File:      path,
			Status:    status,
			SyncGroup: "default", // À spécialiser selon la logique métier
		})
		return nil
	})
	return results, nil
}

// ExportSyncJSON exporte les résultats de synchronisation au format JSON.
func ExportSyncJSON(results []SyncResult, outPath string) error {
	data, err := json.MarshalIndent(results, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(outPath, data, 0644)
}

// ExportSyncGapAnalysis génère un rapport markdown d’écarts de synchronisation.
func ExportSyncGapAnalysis(results []SyncResult, outPath string) error {
	f, err := os.Create(outPath)
	if err != nil {
		return err
	}
	defer f.Close()
	f.WriteString("# SYNC_GAP_ANALYSIS.md\n\n| Fichier | Statut | Groupe |\n|---|---|---|\n")
	for _, r := range results {
		f.WriteString(fmt.Sprintf("| %s | %s | %s |\n", r.File, r.Status, r.SyncGroup))
	}
	return nil
}
