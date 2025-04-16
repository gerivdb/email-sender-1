# Système d'Inventaire et de Classification des Scripts

## Objectifs
Ce système permet de :
- Centraliser l'inventaire de tous les scripts PowerShell et Python du projet
- Détecter les scripts redondants ou similaires
- Classifier automatiquement les scripts selon une taxonomie définie
- Générer des rapports d'analyse

## Composants principaux

### 1. Module ScriptInventoryManager
**Fichier**: `modules/ScriptInventoryManager.psm1`

Fonctionnalités :
- Scan des répertoires pour trouver les scripts
- Extraction des métadonnées (auteur, version, description, tags)
- Sauvegarde de l'inventaire dans un fichier JSON
- Recherche et filtrage des scripts

Commandes disponibles :
```powershell
Get-ScriptInventory [-Path] <string> [-ForceRescan]
Update-ScriptInventory [-Path] <string>
Find-Script [-Name] <string> [-Author] <string> [-Tag] <string> [-Language] <string>
```

### 2. Scripts d'analyse

#### Show-ScriptInventory.ps1
**Fichier**: `scripts/manager/Show-ScriptInventory.ps1`

Affiche l'inventaire avec options de filtrage et d'export.

Exemple :
```powershell
.\Show-ScriptInventory.ps1 -Author "TestUser" -ExportFormat HTML
```

#### Find-RedundantScripts.ps1
**Fichier**: `scripts/analysis/Find-RedundantScripts.ps1`

Détecte les scripts similaires ou redondants.

Exemple :
```powershell
.\Find-RedundantScripts.ps1 -SimilarityThreshold 85 -ReportFormat HTML
```

#### Classify-Scripts.ps1
**Fichier**: `scripts/analysis/Classify-Scripts.ps1`

Classifie les scripts et peut réorganiser la structure des dossiers.

Exemple :
```powershell
.\Classify-Scripts.ps1 -UpdateStructure -ReportFormat JSON
```

### 3. Tests
**Fichier**: `scripts/tests/Test-ScriptInventory.ps1`

Tests unitaires et d'intégration pour valider le système.

Exécution :
```powershell
Invoke-Pester .\Test-ScriptInventory.ps1
```

## Workflow recommandé

1. Mettre à jour l'inventaire :
```powershell
Update-ScriptInventory
```

2. Analyser les scripts redondants :
```powershell
.\Find-RedundantScripts.ps1 -SimilarityThreshold 80
```

3. Classifier et réorganiser les scripts :
```powershell
.\Classify-Scripts.ps1 -UpdateStructure
```

4. Générer un rapport complet :
```powershell
.\Show-ScriptInventory.ps1 -ExportFormat HTML
```

## Intégration avec Git
Des hooks Git peuvent être configurés pour :
- Mettre à jour automatiquement l'inventaire après un commit
- Vérifier les métadonnées des nouveaux scripts
- Empêcher l'ajout de scripts sans métadonnées minimales

Exemple de hook (à placer dans `.git/hooks/post-commit`) :
```powershell
#!/usr/bin/env pwsh
Import-Module ./modules/ScriptInventoryManager.psm1
Update-ScriptInventory
```

## Bonnes pratiques

1. **Métadonnées** :
   Toujours inclure dans les scripts :
   ```powershell
   <#
   .Author: VotreNom
   .Version: 1.0
   .Description: Description du script
   .Tags: tag1,tag2
   #>
   ```

2. **Classification** :
   Utiliser des noms explicites qui correspondent aux catégories définies.

3. **Mises à jour** :
   Exécuter `Update-ScriptInventory` après des modifications importantes.

4. **Tests** :
   Lancer les tests avant de pousser des modifications sur le système d'inventaire.
