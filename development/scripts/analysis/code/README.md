# Analyse de Code

Ce dossier contient des scripts pour l''analyse de code source avec différents outils.

## Scripts disponibles

- **Start-CodeAnalysis.ps1** - Script principal pour l''analyse de code
- **Start-CachedCodeAnalysis.ps1** - Version avec mise en cache des résultats
- **Invoke-CachedPSScriptAnalyzer.ps1** - Analyse avec PSScriptAnalyzer et mise en cache
- **Analyze-ScriptSimilarity.ps1** - Analyse de similarité entre scripts
- **Classify-Scripts.ps1** - Classification des scripts par fonctionnalité
- **Find-RedundantScripts.ps1** - Détection de scripts redondants

## Exemples d''utilisation

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\development\scripts" -Tools PSScriptAnalyzer -GenerateHtmlReport -Recurse
```
