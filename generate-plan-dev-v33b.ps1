# Script to generate a development plan using hygen with non-interactive arguments

# Ensure we're in the right directory
Set-Location -Path "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1"

# Prepare arguments
$version = "v33b"
$title = "MCP Manager Centralisé"
$description = "Ce plan vise à concevoir, développer et intégrer un MCP Manager centralisé pour orchestrer les serveurs MCP, gérer leurs capacités, et faciliter la communication avec le MCP Gateway."


# First write the version directly to the file (bypassing the generation with hygen)
$outputPath = "projet/roadmaps/plans/consolidated/plan-dev-$version-mcp-manager-centralis.md"
$date = Get-Date -Format "yyyy-MM-dd"

# Generate file content
$content = @"
# Plan de développement $version - $title
*Version 1.0 - $date - Progression globale : 0%*

$description

## Table des matières
- [1] Phase 1
- [2] Phase 2
- [3] Phase 3
- [4] Phase 4
- [5] Phase 5

## 1. Phase 1 (Phase 1)
  - [ ] **1.1** Tâche principale 1 - Phase d'analyse et de conception.
  - Étape 1 : Définir les objectifs
  - Étape 2 : Identifier les parties prenantes
  - Étape 3 : Documenter les résultats
  - Étape 4 : Valider les étapes avec l'équipe
  - Étape 5 : Ajouter des schémas ou diagrammes si nécessaire
  - Étape 6 : Vérifier les dépendances
  - Étape 7 : Finaliser et archiver
  - Étape 8 : Effectuer une revue par les pairs
  - Étape 9 : Planifier les prochaines actions
  - Entrées : commandes utilisateur, configurations système.
  - Sorties : états des serveurs, fichiers de logs.
  - Conditions préalables : serveurs MCP configurés, accès réseau disponible.

## 2. Phase 2 (Phase 2)
  - [ ] **2.1** Tâche principale 1 - Phase de développement des fonctionnalités principales.
  - Étape 1 : Définir les objectifs
  - Étape 2 : Identifier les parties prenantes
  - Étape 3 : Documenter les résultats
  - Étape 4 : Valider les étapes avec l'équipe
  - Étape 5 : Ajouter des schémas ou diagrammes si nécessaire
  - Étape 6 : Vérifier les dépendances
  - Étape 7 : Finaliser et archiver
  - Étape 8 : Effectuer une revue par les pairs
  - Étape 9 : Planifier les prochaines actions
  - Entrées : commandes utilisateur, configurations système.
  - Sorties : états des serveurs, fichiers de logs.
  - Conditions préalables : serveurs MCP configurés, accès réseau disponible.

## 3. Phase 3 (Phase 3)
  - [ ] **3.1** Tâche principale 1 - Phase de tests pour valider les modules.
  - Étape 1 : Définir les objectifs
  - Étape 2 : Identifier les parties prenantes
  - Étape 3 : Documenter les résultats
  - Étape 4 : Valider les étapes avec l'équipe
  - Étape 5 : Ajouter des schémas ou diagrammes si nécessaire
  - Étape 6 : Vérifier les dépendances
  - Étape 7 : Finaliser et archiver
  - Étape 8 : Effectuer une revue par les pairs
  - Étape 9 : Planifier les prochaines actions
  - Entrées : commandes utilisateur, configurations système.
  - Sorties : états des serveurs, fichiers de logs.
  - Conditions préalables : serveurs MCP configurés, accès réseau disponible.

## 4. Phase 4 (Phase 4)
  - [ ] **4.1** Tâche principale 1 - Phase de déploiement en production.
  - Étape 1 : Définir les objectifs
  - Étape 2 : Identifier les parties prenantes
  - Étape 3 : Documenter les résultats
  - Étape 4 : Valider les étapes avec l'équipe
  - Étape 5 : Ajouter des schémas ou diagrammes si nécessaire
  - Étape 6 : Vérifier les dépendances
  - Étape 7 : Finaliser et archiver
  - Étape 8 : Effectuer une revue par les pairs
  - Étape 9 : Planifier les prochaines actions
  - Entrées : commandes utilisateur, configurations système.
  - Sorties : états des serveurs, fichiers de logs.
  - Conditions préalables : serveurs MCP configurés, accès réseau disponible.

## 5. Phase 5 (Phase 5)
  - [ ] **5.1** Tâche principale 1 - Phase d'amélioration continue.
  - Étape 1 : Définir les objectifs
  - Étape 2 : Identifier les parties prenantes
  - Étape 3 : Documenter les résultats
  - Étape 4 : Valider les étapes avec l'équipe
  - Étape 5 : Ajouter des schémas ou diagrammes si nécessaire
  - Étape 6 : Vérifier les dépendances
  - Étape 7 : Finaliser et archiver
  - Étape 8 : Effectuer une revue par les pairs
  - Étape 9 : Planifier les prochaines actions
  - Entrées : commandes utilisateur, configurations système.
  - Sorties : états des serveurs, fichiers de logs.
  - Conditions préalables : serveurs MCP configurés, accès réseau disponible.
"@

# Write the content to the file
Write-Output "Creating file at $outputPath"
$outputPathFull = "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/$outputPath"
$content | Out-File -FilePath $outputPathFull -Encoding utf8

Write-Output "File created: $outputPathFull"
Write-Output "Content length: $($content.Length) characters"
