# Système d''Analyse Unifié

Ce répertoire contient des scripts pour l''analyse de code, de performance et de données, ainsi que des outils d''intégration et de reporting.

## Structure

- **code/** - Scripts d''analyse de code source
- **performance/** - Scripts d''analyse de performance
- **data/** - Scripts d''analyse de données
- **reporting/** - Scripts de génération de rapports
- **integration/** - Scripts d''intégration avec des outils tiers
- **roadmap/** - Scripts de mise à jour de la roadmap
- **common/** - Modules et outils communs
- **docs/** - Documentation

## Utilisation

### Analyse de Code

```powershell
.\code\Start-CodeAnalysis.ps1 -Path ".\development\scripts" -Tools PSScriptAnalyzer -GenerateHtmlReport -Recurse
```

### Analyse de Performance

```powershell
.\performance\Calculate-SystemKPIs.ps1 -DataPath "data/performance" -OutputPath "data/analysis"
```

### Analyse de Données

```powershell
.\data\Detect-Anomalies.ps1 -DataPath "data/performance" -OutputPath "data/analysis"
```

### Mise à Jour de la Roadmap

```powershell
.\roadmap\Update-RoadmapProgress.ps1 -Path ".\projet\roadmaps\roadmap_complete_converted.md"
```

## Documentation

Consultez le dossier `docs/` pour plus d''informations sur l''utilisation des différents scripts et outils.
