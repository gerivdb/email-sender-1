# Modules et Outils Communs

Ce dossier contient des modules et outils communs utilisés par les différents scripts d''analyse.

## Contenu

- **modules/** - Modules PowerShell réutilisables
- **tools/** - Outils d''intégration avec des outils tiers
- **plugins/** - Plugins d''analyse

## Scripts disponibles

- **Start-CachedAnalysis.ps1** - Script générique pour l''analyse avec mise en cache

## Exemples d''utilisation

```powershell
.\Start-CachedAnalysis.ps1 -Path ".\development\scripts" -Tool "PSScriptAnalyzer" -CachePath ".\cache"
```plaintext