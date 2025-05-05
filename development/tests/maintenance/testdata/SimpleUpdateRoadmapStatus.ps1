# SimpleUpdateRoadmapStatus.ps1
# Script simplifiÃ© pour les tests de Update-RoadmapStatus.ps1

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

# VÃ©rifier que les fichiers existent
if (-not [string]::IsNullOrEmpty($ActiveRoadmapPath) -and -not (Test-Path -Path $ActiveRoadmapPath)) {
    Write-Warning "Le fichier $ActiveRoadmapPath n'existe pas."
    return $false
}

if ($AutoArchive -and -not [string]::IsNullOrEmpty($CompletedRoadmapPath) -and -not (Test-Path -Path $CompletedRoadmapPath)) {
    Write-Warning "Le fichier $CompletedRoadmapPath n'existe pas."
    return $false
}

# Mise Ã  jour du statut d'une tÃ¢che
if (-not [string]::IsNullOrEmpty($TaskId) -and -not [string]::IsNullOrEmpty($Status) -and -not [string]::IsNullOrEmpty($ActiveRoadmapPath)) {
    Write-Host "Mise Ã  jour du statut de la tÃ¢che ${TaskId}: ${Status}"
    
    # Lire le contenu du fichier
    if (Test-Path -Path $ActiveRoadmapPath) {
        $content = Get-Content -Path $ActiveRoadmapPath -Raw
        
        # Mettre Ã  jour le statut
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

# Archivage des tÃ¢ches terminÃ©es
if ($AutoArchive -and -not [string]::IsNullOrEmpty($ActiveRoadmapPath) -and -not [string]::IsNullOrEmpty($CompletedRoadmapPath)) {
    Write-Host "Archivage des tÃ¢ches terminÃ©es..."
    
    # Simuler l'archivage en copiant le contenu
    if (Test-Path -Path $ActiveRoadmapPath -and Test-Path -Path $CompletedRoadmapPath) {
        $activeContent = Get-Content -Path $ActiveRoadmapPath -Raw
        $completedContent = Get-Content -Path $CompletedRoadmapPath -Raw
        
        # Ajouter une section complÃ©tÃ©e au fichier d'archive
        $completedSection = @"

### 1.2.2 Effectuer les tests d'intÃ©gration
- [x] **1.2.2.1** Tests de bout en bout
- [x] **1.2.2.2** Tests de performance
"@
        
        $completedContent += $completedSection
        
        # Supprimer la section du fichier actif
        $activeContent = $activeContent -replace "### 1.2.2 Effectuer les tests d'intÃ©gration[\s\S]*?(?=###|$)", ""
        
        # Sauvegarder les fichiers
        Set-Content -Path $ActiveRoadmapPath -Value $activeContent -Force
        Set-Content -Path $CompletedRoadmapPath -Value $completedContent -Force
        
        return $true
    }
}

# GÃ©nÃ©ration d'un rapport
if ($GenerateReport) {
    Write-Host "GÃ©nÃ©ration du rapport d'avancement..."
    
    # CrÃ©er un rapport simple
    $reportContent = @"
# Rapport d'avancement de la Roadmap - EMAIL_SENDER_1

GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## RÃ©sumÃ©

- **Total des tÃ¢ches**: 10
- **TÃ¢ches terminÃ©es**: 5
- **TÃ¢ches en cours**: 5
- **Pourcentage d'achÃ¨vement**: 50%

## TÃ¢ches actives par section

### Phase 1: FonctionnalitÃ©s de base

- Progression: 3 / 5 (60%)

| ID | Description | Statut |
|---|---|---|
| 1.1.2.2 | DÃ©velopper le systÃ¨me de notifications | â³ |
| 1.1.2.3 | CrÃ©er l'interface utilisateur | â³ |
"@
    
    # CrÃ©er le dossier des rapports si nÃ©cessaire
    $reportsFolder = Join-Path -Path (Split-Path -Path $ActiveRoadmapPath -Parent) -ChildPath "reports"
    if (-not (Test-Path -Path $reportsFolder)) {
        New-Item -Path $reportsFolder -ItemType Directory -Force | Out-Null
    }
    
    # Sauvegarder le rapport
    $reportPath = Join-Path -Path $reportsFolder -ChildPath "status_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    Set-Content -Path $reportPath -Value $reportContent -Force
    
    Write-Host "Rapport gÃ©nÃ©rÃ©: $reportPath"
    
    return $reportPath
}

return $true
