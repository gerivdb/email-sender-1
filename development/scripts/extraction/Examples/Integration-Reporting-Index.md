# Index des fichiers du module d'intégration pour le reporting

Ce document liste tous les fichiers du module d'intégration pour le reporting des informations extraites et décrit brièvement leur fonction.

## Fichiers principaux

| Fichier | Description | Lignes approximatives |
|---------|-------------|----------------------|
| **Integration-Reporting-Core.ps1** | Module principal avec les constantes et fonctions de base | 200 |
| **Integration-Reporting-Sections.ps1** | Fonctions pour gérer les sections du rapport | 200 |
| **Integration-Reporting-Charts.ps1** | Fonctions pour gérer les graphiques | 200 |
| **Integration-Reporting-Tables.ps1** | Fonctions pour gérer les tableaux | 200 |
| **Integration-Reporting-Export.ps1** | Fonctions pour l'exportation des rapports | 200 |
| **Integration-Reporting-Examples.ps1** | Exemples d'utilisation | 200 |
| **Integration-Reporting-Utils.ps1** | Fonctions utilitaires | 200 |
| **Integration-Reporting.ps1** | Fichier principal qui importe tous les autres modules | 200 |

## Fonctions par fichier

### Integration-Reporting-Core.ps1

- `New-ExtractedInfoReport` - Crée un nouveau rapport d'information extraite

### Integration-Reporting-Sections.ps1

- `Add-ExtractedInfoReportSection` - Ajoute une section à un rapport
- `Add-ExtractedInfoReportTextSection` - Ajoute une section de texte à un rapport
- `Add-ExtractedInfoReportListSection` - Ajoute une section de liste à un rapport

### Integration-Reporting-Charts.ps1

- `Add-ExtractedInfoReportChart` - Ajoute un graphique à un rapport
- `Add-ExtractedInfoReportBarChart` - Ajoute un graphique en barres à un rapport
- `Add-ExtractedInfoReportPieChart` - Ajoute un graphique en camembert à un rapport

### Integration-Reporting-Tables.ps1

- `Add-ExtractedInfoReportTable` - Ajoute un tableau à un rapport
- `Add-ExtractedInfoReportStatsTable` - Ajoute un tableau de statistiques à un rapport

### Integration-Reporting-Export.ps1

- `Export-ExtractedInfoReportToHtml` - Exporte un rapport au format HTML
- `Get-ExtractedInfoReportCss` - Obtient le code CSS pour les rapports
- `Get-ExtractedInfoReportJs` - Obtient le code JavaScript pour les rapports

### Integration-Reporting-Examples.ps1

- `Show-CollectionReport` - Génère un rapport de collection d'informations extraites
- `Show-ComparisonReport` - Génère un rapport de comparaison entre deux collections

### Integration-Reporting-Utils.ps1

- `ConvertTo-HtmlTable` - Convertit un objet en tableau HTML
- `ConvertTo-HtmlList` - Convertit un objet en liste HTML
- `ConvertTo-HtmlCode` - Convertit un objet en code HTML
- `ConvertTo-HtmlChart` - Convertit un objet en graphique HTML

### Integration-Reporting.ps1

- `Show-TimeAnalysisReport` - Génère un rapport d'analyse temporelle des informations extraites

## Variables globales

- `$REPORT_TYPES` - Types de rapport (Standard, Dashboard, Executive, Technical)
- `$SECTION_TYPES` - Types de section (Text, Table, Chart, List, Code)
- `$CHART_TYPES` - Types de graphique (Bar, Line, Pie, Scatter, Area, Histogram)
- `$EXPORT_FORMATS` - Formats d'exportation (HTML, PDF, Excel, Markdown, Text)

## Avantages de la division en modules

1. **Maintenabilité** - Chaque fichier a une responsabilité unique et bien définie
2. **Lisibilité** - Les fichiers plus petits sont plus faciles à lire et à comprendre
3. **Collaboration** - Plusieurs développeurs peuvent travailler sur différents fichiers sans conflits
4. **Testabilité** - Les fonctions peuvent être testées individuellement
5. **Réutilisabilité** - Les modules peuvent être importés séparément selon les besoins

## Comment utiliser les modules

Pour utiliser tous les modules, importez simplement le fichier principal :

```powershell
. ".\Integration-Reporting.ps1"
```

Pour utiliser un module spécifique, importez-le directement :

```powershell
. ".\Integration-Reporting-Core.ps1"
. ".\Integration-Reporting-Sections.ps1"
```

## Dépendances entre les modules

- **Integration-Reporting-Core.ps1** - Aucune dépendance
- **Integration-Reporting-Sections.ps1** - Dépend de Core
- **Integration-Reporting-Charts.ps1** - Dépend de Core et Sections
- **Integration-Reporting-Tables.ps1** - Dépend de Core et Sections
- **Integration-Reporting-Export.ps1** - Dépend de Core
- **Integration-Reporting-Examples.ps1** - Dépend de tous les autres modules
- **Integration-Reporting-Utils.ps1** - Aucune dépendance
- **Integration-Reporting.ps1** - Importe tous les autres modules
