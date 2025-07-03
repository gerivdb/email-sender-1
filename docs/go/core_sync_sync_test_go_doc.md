# Package sync

Package sync fournit des fonctions pour automatiser la synchronisation des fichiers et générer des rapports de synchronisation.

Fonctions principales :
- ScanSync : détecte les fichiers à synchroniser et leur statut.
- ExportSyncJSON : exporte les résultats de synchronisation au format JSON.
- ExportSyncGapAnalysis : génère un rapport markdown d’écarts de synchronisation.

Utilisation typique :
syncs, err := sync.ScanSync("chemin/du/projet")
err := sync.ExportSyncJSON(syncs, "sync-scan.json")
err := sync.ExportSyncGapAnalysis(syncs, "SYNC_GAP_ANALYSIS.md")


## Types

### SyncResult

## Functions

### ExportSyncGapAnalysis

ExportSyncGapAnalysis génère un rapport markdown d’écarts de synchronisation.


```go
func ExportSyncGapAnalysis(results []SyncResult, outPath string) error
```

### ExportSyncJSON

ExportSyncJSON exporte les résultats de synchronisation au format JSON.


```go
func ExportSyncJSON(results []SyncResult, outPath string) error
```

