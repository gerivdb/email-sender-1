# Create-SampleRoadmap.ps1
# Script pour créer un exemple de roadmap avec des tags
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "projet\roadmaps\plans\sample-roadmap.md",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer les modules nécessaires
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsDir = Join-Path -Path (Split-Path -Parent $scriptDir) -ChildPath "utils"

# Importer les modules
. (Join-Path -Path $utilsDir -ChildPath "Write-Log.ps1")

# Fonction pour créer un exemple de roadmap
function New-SampleRoadmap {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si le fichier existe déjà
    if (Test-Path -Path $OutputPath) {
        if ($Force) {
            Remove-Item -Path $OutputPath -Force
            Write-Log "Fichier existant supprimé: $OutputPath" -Level Warning
        } else {
            Write-Log "Le fichier existe déjà: $OutputPath. Utilisez -Force pour le remplacer." -Level Error
            return $false
        }
    }
    
    # Créer le répertoire parent si nécessaire
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -Path $outputDir -PathType Container)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        Write-Log "Répertoire créé: $outputDir" -Level Info
    }
    
    # Créer le contenu de la roadmap
    $content = @"
# Roadmap d'exemple avec tags

Cette roadmap est un exemple pour tester le système de tags.

## 1. Intégration avec Qdrant

- [ ] **1.1** Configurer le conteneur Docker pour Qdrant #priority:high #category:devops #time:2h
- [ ] **1.2** Créer une collection pour les tags #category:database #time:1h
- [ ] **1.3** Développer l'API pour l'indexation des tags #category:backend #time:4h
- [ ] **1.4** Implémenter la recherche sémantique #category:backend #priority:medium #time:6h
- [ ] **1.5** Créer une interface utilisateur pour la recherche #category:frontend #priority:low #time:8h #depends:1.4

## 2. Gestion des tags

- [ ] **2.1** Définir les formats de tags standard #category:documentation #priority:high #time:2h
- [ ] **2.2** Implémenter la validation des tags #category:backend #time:3h #depends:2.1
- [ ] **2.3** Créer un éditeur de tags #category:ui #priority:medium #time:5h
- [ ] **2.4** Développer la visualisation des tags #category:ui #priority:medium #time:4h
- [ ] **2.5** Implémenter l'extraction automatique de tags #category:backend #priority:high #time:8h

## 3. Intégration avec le système de roadmap

- [ ] **3.1** Synchroniser les tags avec les tâches #category:backend #priority:high #time:3h
- [ ] **3.2** Implémenter le filtrage par tag #category:backend #priority:medium #time:4h
- [ ] **3.3** Créer des rapports basés sur les tags #category:reporting #priority:low #time:6h
- [ ] **3.4** Développer des alertes basées sur les tags #category:backend #priority:low #time:5h
- [ ] **3.5** Intégrer avec le système de notification #category:backend #priority:medium #time:4h #depends:3.4

## 4. Tests et déploiement

- [ ] **4.1** Écrire des tests unitaires #category:testing #priority:high #time:8h
- [ ] **4.2** Réaliser des tests d'intégration #category:testing #priority:high #time:6h #depends:4.1
- [ ] **4.3** Optimiser les performances #category:performance #priority:medium #time:5h
- [ ] **4.4** Déployer en environnement de test #category:devops #priority:medium #time:3h #depends:4.2
- [ ] **4.5** Déployer en production #category:devops #priority:high #time:2h #depends:4.4 #status:blocked

## 5. Documentation et formation

- [ ] **5.1** Rédiger la documentation technique #category:documentation #priority:medium #time:8h
- [ ] **5.2** Créer des guides utilisateur #category:documentation #priority:medium #time:6h
- [ ] **5.3** Préparer des sessions de formation #category:documentation #priority:low #time:4h
- [ ] **5.4** Mettre à jour le wiki #category:documentation #priority:low #time:3h
- [ ] **5.5** Créer des vidéos tutorielles #category:documentation #priority:low #time:8h
"@
    
    # Enregistrer le contenu dans le fichier
    Set-Content -Path $OutputPath -Value $content -Encoding UTF8
    
    Write-Log "Roadmap d'exemple créée: $OutputPath" -Level Success
    
    return $true
}

# Fonction principale
function Main {
    # Créer un exemple de roadmap
    if (New-SampleRoadmap -OutputPath $OutputPath -Force:$Force) {
        Write-Log "Exemple de roadmap créé avec succès" -Level Success
        return $true
    } else {
        Write-Log "Échec de création de l'exemple de roadmap" -Level Error
        return $false
    }
}

# Exécuter la fonction principale
Main
