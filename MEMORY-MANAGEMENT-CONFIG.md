# CONFIGURATION ANTI-CRASH MÉMOIRE - EMAIL_SENDER_1

# ===================================================

## ALLOCATION MÉMOIRE CIBLE

- **Total RAM**: 24 GB
- **Dev allocation**: 20 GB (VSCode + Docker + Python + Go)
- **System reserve**: 4 GB

## RÉPARTITION RECOMMANDÉE

- **VSCode**: Max 15 GB (instances multiples)
- **Docker**: Max 3 GB (tous containers)
- **Go/Python**: Max 2 GB (compilation + exécution)
- **Système**: 4 GB (Windows + antivirus + autres)

## SCRIPTS DE GESTION AUTOMATIQUE

### 1. Monitoring en temps réel

```powershell
.\Memory-Crash-Monitor.ps1
```

- Surveillance toutes les 30 secondes
- Alertes à 18GB (warning) et 20GB (critical)
- Actions automatiques si dépassement

### 2. Fix d'urgence

```powershell
.\Emergency-Memory-Fix.ps1
```

- Optimisation immédiate VSCode
- Fermeture processus non essentiels
- Garbage collection massif

### 3. Gestion intelligente

```powershell
.\Memory-Manager-Simple.ps1
```

- Analyse détaillée par catégorie
- Optimisations ciblées
- Recommandations personnalisées

## CONFIGURATION OPTIMISÉE

### Docker (3GB max)

- Utiliser: `docker-compose.memory-optimized.yml`
- API Server: 512MB
- PostgreSQL: 1GB
- Qdrant: 1GB
- Redis: 512MB

### VSCode (15GB max)

- Appliquer: `vscode-memory-optimized-settings.json`
- Limiter à 10 tabs max
- Désactiver extensions non critiques
- Optimiser IntelliSense

## PRÉVENTION DES CRASHS

### Signes d'alerte

- RAM > 18GB: Warning
- RAM > 20GB: Critical
- "Window not responding"
- Ralentissements fréquents

### Actions préventives

1. Monitoring automatique activé
2. Fermeture processus non essentiels
3. Garbage collection régulier
4. Redémarrage API Server si nécessaire

## COMMANDES D'URGENCE

### Diagnostic rapide

```powershell
Get-Process | Where-Object {$_.WorkingSet -gt 500MB} | Sort-Object WorkingSet -Descending
```

### Redémarrage API Server

```powershell
Start-Process "cmd\simple-api-server-fixed\api-server-fixed.exe" -WindowStyle Hidden
```

### Nettoyage VSCode

```powershell
Get-Process | Where-Object {$_.ProcessName -eq "Code" -and $_.WorkingSet -lt 200MB} | Stop-Process -Force
```

## STATUT ACTUEL

✅ RAM: 11.6 GB (dans les limites)
✅ Dev processes: 5 GB
✅ API Server: Fonctionnel
✅ Monitoring: Prêt
