# Package docsupport

Package docsupport fournit des fonctions pour analyser la documentation, supports et générer des rapports associés.

Fonctions principales :
- ScanDocSupports : détecte les fichiers de documentation/support.
- ExportDocSupportsJSON : exporte la liste au format JSON.
- ExportDocGapAnalysis : génère un rapport markdown d’écarts de documentation.

Utilisation typique :
docs, err := docsupport.ScanDocSupports("chemin/du/projet")
err := docsupport.ExportDocSupportsJSON(docs, "doc-supports-scan.json")
err := docsupport.ExportDocGapAnalysis(docs, "DOC_GAP_ANALYSIS.md")


## Types

### DocSupport

## Functions

### ExportDocGapAnalysis

ExportDocGapAnalysis génère un rapport markdown d’écarts de documentation.


```go
func ExportDocGapAnalysis(docs []DocSupport, outPath string) error
```

### ExportDocSupportsJSON

ExportDocSupportsJSON exporte la liste des supports au format JSON.


```go
func ExportDocSupportsJSON(docs []DocSupport, outPath string) error
```

