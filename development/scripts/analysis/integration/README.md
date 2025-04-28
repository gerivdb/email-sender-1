# Intégration

Ce dossier contient des scripts pour l''intégration avec des outils tiers.

## Scripts disponibles

- **Integrate-ThirdPartyTools.ps1** - Intégration des résultats d''analyse avec des outils tiers
- **Register-AnalysisPlugin.ps1** - Enregistrement de plugins d''analyse

## Exemples d''utilisation

```powershell
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool SonarQube -ApiKey "your-api-key" -ApiUrl "https://sonarqube.example.com/api" -ProjectKey "your-project-key"
```
