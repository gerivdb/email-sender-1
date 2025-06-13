# Analyse de Performance

Ce dossier contient des scripts pour l''analyse de performance et le calcul de KPIs.

## Scripts disponibles

- **Calculate-ApplicationKPIs.ps1** - Calcul des KPIs d''application
- **Calculate-BusinessKPIs.ps1** - Calcul des KPIs métier
- **Calculate-SystemKPIs.ps1** - Calcul des KPIs système
- **Manage-AlertConfigurations.ps1** - Gestion des configurations d''alerte
- **Manage-AlertThresholds.ps1** - Gestion des seuils d''alerte

## Exemples d''utilisation

```powershell
.\Calculate-SystemKPIs.ps1 -DataPath "data/performance" -OutputPath "data/analysis"
```plaintext