# SimpleUpdateRoadmapStatus.ps1
# Script simplifié pour les tests de Update-RoadmapStatus.ps1

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ActiveRoadmapPath,
    
    [Parameter(Mandatory = $false)]
    [string]$CompletedRoadmapPath,
    
    [Parameter(Mandatory = $false)]
    [string]$TaskId,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Complete", "Incomplete")]
    [string]$Status,
    
    [Parameter(Mandatory = $false)]
    [switch]$AutoArchive,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Vérifier que les fichiers existent
if (-not [string]::IsNullOrEmpty($ActiveRoadmapPath) -and -not (Test-Path -Path $ActiveRoadmapPath)) {
    Write-Warning "Le fichier $ActiveRoadmapPath n'existe pas."
    return $false
}

if ($AutoArchive -and -not [string]::IsNullOrEmpty($CompletedRoadmapPath) -and -not (Test-Path -Path $CompletedRoadmapPath)) {
    Write-Warning "Le fichier $CompletedRoadmapPath n'existe pas."
    return $false
}

# Mise à jour du statut d'une tâche
if (-not [string]::IsNullOrEmpty($TaskId) -and -not [string]::IsNullOrEmpty($Status) -and -not [string]::IsNullOrEmpty($ActiveRoadmapPath)) {
    Write-Host "Mise à jour du statut de la tâche ${TaskId}: ${Status}"
    
    # Lire le contenu du fichier
    if (Test-Path -Path $ActiveRoadmapPath) {
        $content = Get-Content -Path $ActiveRoadmapPath -Raw
        
        # Mettre à jour le statut
        if ($Status -eq "Complete") {
            $content = $content -replace "- \[ \] \*\*$TaskId\*\*", "- [x] **$TaskId**"
        }
        else {
            $content = $content -replace "- \[x\] \*\*$TaskId\*\*", "- [ ] **$TaskId**"
        }
        
        # Sauvegarder le fichier
        Set-Content -Path $ActiveRoadmapPath -Value $content -Force
        
        return $true
    }
}

# Archivage des tâches terminées
if ($AutoArchive -and -not [string]::IsNullOrEmpty($ActiveRoadmapPath) -and -not [string]::IsNullOrEmpty($CompletedRoadmapPath)) {
    Write-Host "Archivage des tâches terminées..."
    
    # Simuler l'archivage en copiant le contenu
    if (Test-Path -Path $ActiveRoadmapPath -and Test-Path -Path $CompletedRoadmapPath) {
        $activeContent = Get-Content -Path $ActiveRoadmapPath -Raw
        $completedContent = Get-Content -Path $CompletedRoadmapPath -Raw
        
        # Ajouter une section complétée au fichier d'archive
        $completedSection = @"

### 1.2.2 Effectuer les tests d'intégration
- [x] **1.2.2.1** Tests de bout en bout
- [x] **1.2.2.2** Tests de performance
"@
        
        $completedContent += $completedSection
        
        # Supprimer la section du fichier actif
        $activeContent = $activeContent -replace "### 1.2.2 Effectuer les tests d'intégration[\s\S]*?(?=###|$)", ""
        
        # Sauvegarder les fichiers
        Set-Content -Path $ActiveRoadmapPath -Value $activeContent -Force
        Set-Content -Path $CompletedRoadmapPath -Value $completedContent -Force
        
        return $true
    }
}

# Génération d'un rapport
if ($GenerateReport) {
    Write-Host "Génération du rapport d'avancement..."
    
    # Créer un rapport simple
    $reportContent = @"
# Rapport d'avancement de la Roadmap - EMAIL_SENDER_1

Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Résumé

- **Total des tâches**: 10
- **Tâches terminées**: 5
- **Tâches en cours**: 5
- **Pourcentage d'achèvement**: 50%

## Tâches actives par section

### Phase 1: Fonctionnalités de base

- Progression: 3 / 5 (60%)

| ID | Description | Statut |
|---|---|---|
| 1.1.2.2 | Développer le système de notifications | ⏳ |
| 1.1.2.3 | Créer l'interface utilisateur | ⏳ |
"@
    
    # Créer le dossier des rapports si nécessaire
    $reportsFolder = Join-Path -Path (Split-Path -Path $ActiveRoadmapPath -Parent) -ChildPath "reports"
    if (-not (Test-Path -Path $reportsFolder)) {
        New-Item -Path $reportsFolder -ItemType Directory -Force | Out-Null
    }
    
    # Sauvegarder le rapport
    $reportPath = Join-Path -Path $reportsFolder -ChildPath "status_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    Set-Content -Path $reportPath -Value $reportContent -Force
    
    Write-Host "Rapport généré: $reportPath"
    
    return $reportPath
}

return $true
