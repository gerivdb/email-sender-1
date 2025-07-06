# Package architecture

Package architecture fournit des fonctions pour analyser la structure cible du projet et générer des rapports d’architecture.

Fonctions principales :
- ScanPatterns : détecte les patterns d’architecture dans le projet.
- ExportPatternsJSON : exporte les patterns détectés au format JSON.
- ExportGapAnalysis : génère un rapport markdown d’écarts d’architecture.

Utilisation typique :
patterns, err := architecture.ScanPatterns("chemin/du/projet")
err := architecture.ExportPatternsJSON(patterns, "architecture-patterns-scan.json")
err := architecture.ExportGapAnalysis(patterns, "ARCHITECTURE_GAP_ANALYSIS.md")


## Types

### Pattern

## Functions

### ExportGapAnalysis

ExportGapAnalysis génère un rapport markdown d’écarts d’architecture.


```go
func ExportGapAnalysis(patterns []Pattern, outPath string) error
```

### ExportPatternsJSON

ExportPatternsJSON exporte les patterns détectés au format JSON.


```go
func ExportPatternsJSON(patterns []Pattern, outPath string) error
```

