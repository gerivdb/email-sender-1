<#
.SYNOPSIS
    Met à jour la roadmap avec les progrès du Script Manager
.DESCRIPTION
    Ce script met à jour la roadmap du projet pour refléter les progrès réalisés
    avec les différentes phases du Script Manager.
.PARAMETER RoadmapPath
    Chemin vers le fichier roadmap à mettre à jour
.EXAMPLE
    .\Update-Roadmap.ps1
    Met à jour la roadmap avec le chemin par défaut
.EXAMPLE
    .\Update-Roadmap.ps1 -RoadmapPath "C:\Projets\Roadmap\roadmap_perso.md"
    Met à jour la roadmap avec un chemin personnalisé
#>

param (
    [string]$RoadmapPath = ".\Roadmap\roadmap_perso.md"
)

# Vérifier si le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Host "Fichier roadmap non trouvé: $RoadmapPath" -ForegroundColor Red
    exit 1
}

# Lire le contenu du fichier roadmap
$RoadmapContent = Get-Content -Path $RoadmapPath -Raw
$RoadmapLines = $RoadmapContent -split "`r?`n"

# Rechercher la section concernant le Script Manager
$ScriptManagerSectionIndex = -1
$ScriptManagerSectionEndIndex = -1

for ($i = 0; $i -lt $RoadmapLines.Count; $i++) {
    if ($RoadmapLines[$i] -match "Script Manager" -or $RoadmapLines[$i] -match "Organisation des scripts") {
        $ScriptManagerSectionIndex = $i

        # Trouver la fin de la section
        for ($j = $i + 1; $j -lt $RoadmapLines.Count; $j++) {
            if ($RoadmapLines[$j] -match "^- \[ \]" -or $RoadmapLines[$j] -match "^##") {
                $ScriptManagerSectionEndIndex = $j - 1
                break
            }
        }

        if ($ScriptManagerSectionEndIndex -eq -1) {
            $ScriptManagerSectionEndIndex = $RoadmapLines.Count - 1
        }

        break
    }
}

# Si la section n'est pas trouvée, chercher une section appropriée pour ajouter le Script Manager
if ($ScriptManagerSectionIndex -eq -1) {
    # Chercher la section "Outils et automatisation" ou similaire
    for ($i = 0; $i -lt $RoadmapLines.Count; $i++) {
        if ($RoadmapLines[$i] -match "Outils" -or $RoadmapLines[$i] -match "Automatisation" -or $RoadmapLines[$i] -match "Scripts") {
            $ScriptManagerSectionIndex = $i

            # Trouver la fin de la section
            for ($j = $i + 1; $j -lt $RoadmapLines.Count; $j++) {
                if ($RoadmapLines[$j] -match "^##") {
                    $ScriptManagerSectionEndIndex = $j - 1
                    break
                }
            }

            if ($ScriptManagerSectionEndIndex -eq -1) {
                $ScriptManagerSectionEndIndex = $RoadmapLines.Count - 1
            }

            break
        }
    }
}

# Si aucune section appropriée n'est trouvée, ajouter à la fin du fichier
if ($ScriptManagerSectionIndex -eq -1) {
    $ScriptManagerSectionIndex = $RoadmapLines.Count - 1
    $ScriptManagerSectionEndIndex = $RoadmapLines.Count - 1
}

# Préparer la mise à jour de la section Script Manager
$ScriptManagerUpdate = @"
- [x] Script Manager - Organisation et analyse des scripts - *Mise à jour le $(Get-Date -Format "dd/MM/yyyy")*
  - [x] **Phase 1: Inventaire et classification de base**
    - [x] Développer un scanner récursif pour identifier tous les scripts
    - [x] Implémenter la détection automatique du type de script
    - [x] Créer un système de classification par catégories
    - [x] Développer un module de simulation de déplacement
  - [x] **Phase 2: Analyse et organisation avancées**
    - [x] Créer un module d'analyse statique de code
    - [x] Implémenter la détection des dépendances entre scripts
    - [x] Développer un analyseur de qualité du code
    - [x] Créer un détecteur de problèmes potentiels
    - [x] Implémenter un système de classification avancé
    - [x] Développer un module de mise à jour des références
    - [x] Créer un générateur de structure de dossiers sémantiques
    - [x] Implémenter des tests unitaires pour tous les modules
  - [x] **Phase 3: Documentation et surveillance**
    - [x] Développer un générateur de documentation automatique
    - [x] Créer un système de surveillance des modifications
    - [x] Implémenter un tableau de bord de santé des scripts
    - [x] Développer un système d'alerte pour les problèmes critiques
  - [x] **Phase 4: Optimisation et intelligence**
    - [x] Développer un détecteur d'anti-patterns
    - [x] Créer un moteur de suggestions d'amélioration
    - [x] Implémenter un système d'apprentissage des modèles de code
    - [x] Développer un assistant de refactoring
  - [ ] **Phase 5: Intégration et extension**
    - [ ] Développer des plugins pour les IDE courants
    - [ ] Créer des intégrations avec les outils existants
    - [ ] Implémenter un système d'extension via plugins
    - [ ] Développer une API pour l'intégration avec d'autres outils
"@

# Mettre à jour la roadmap
$NewRoadmapLines = @()

if ($ScriptManagerSectionIndex -eq $ScriptManagerSectionEndIndex) {
    # Ajouter la section Script Manager à la fin du fichier
    $NewRoadmapLines = $RoadmapLines
    $NewRoadmapLines += ""
    $NewRoadmapLines += $ScriptManagerUpdate -split "`r?`n"
} else {
    # Remplacer la section existante
    for ($i = 0; $i -lt $RoadmapLines.Count; $i++) {
        if ($i -eq $ScriptManagerSectionIndex) {
            $NewRoadmapLines += $ScriptManagerUpdate -split "`r?`n"
            $i = $ScriptManagerSectionEndIndex
        } else {
            $NewRoadmapLines += $RoadmapLines[$i]
        }
    }
}

# Mettre à jour la progression globale si elle existe
$ProgressionPattern = "Progression.*: (\d+)%"
$ProgressionLine = $NewRoadmapLines | Where-Object { $_ -match $ProgressionPattern }

if ($ProgressionLine) {
    $LineIndex = [array]::IndexOf($NewRoadmapLines, $ProgressionLine)
    $CurrentProgress = [int]($Matches[1])
    $NewProgress = [Math]::Min(100, $CurrentProgress + 5)  # Augmenter de 5%, max 100%
    $NewRoadmapLines[$LineIndex] = $NewRoadmapLines[$LineIndex] -replace $ProgressionPattern, "Progression: $NewProgress%"
}

# Mettre à jour la date de dernière mise à jour
$DatePattern = "\*Mise a jour le .*\*"
$DateLine = $NewRoadmapLines | Where-Object { $_ -match $DatePattern }

if ($DateLine) {
    $LineIndex = [array]::IndexOf($NewRoadmapLines, $DateLine)
    $NewRoadmapLines[$LineIndex] = $NewRoadmapLines[$LineIndex] -replace $DatePattern, "*Mise a jour le $(Get-Date -Format "dd/MM/yyyy")*"
}

# Écrire le contenu mis à jour dans le fichier roadmap
$NewRoadmapContent = $NewRoadmapLines -join "`n"
Set-Content -Path $RoadmapPath -Value $NewRoadmapContent

Write-Host "La roadmap a été mise à jour avec les progrès du Script Manager" -ForegroundColor Green
