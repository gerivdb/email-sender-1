# SystÃ¨me d'Inventaire et de Classification des Scripts

## Objectifs
Ce systÃ¨me permet de :
- Centraliser l'inventaire de tous les scripts PowerShell et Python du projet
- DÃ©tecter les scripts redondants ou similaires
- Classifier automatiquement les scripts selon une taxonomie dÃ©finie
- GÃ©nÃ©rer des rapports d'analyse

## Composants principaux

### 1. Module ScriptInventoryManager
**Fichier**: `modules/ScriptInventoryManager.psm1`

FonctionnalitÃ©s :
- Scan des rÃ©pertoires pour trouver les scripts
- Extraction des mÃ©tadonnÃ©es (auteur, version, description, tags)
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
**Fichier**: `development/scripts/mode-manager/Show-ScriptInventory.ps1`

Affiche l'inventaire avec options de filtrage et d'export.

Exemple :
```powershell
.\Show-ScriptInventory.ps1 -Author "TestUser" -ExportFormat HTML
```

#### Find-RedundantScripts.ps1
**Fichier**: `development/scripts/analysis/Find-RedundantScripts.ps1`

DÃ©tecte les scripts similaires ou redondants.

Exemple :
```powershell
.\Find-RedundantScripts.ps1 -SimilarityThreshold 85 -ReportFormat HTML
```

#### Classify-Scripts.ps1
**Fichier**: `development/scripts/analysis/Classify-Scripts.ps1`

Classifie les scripts et peut rÃ©organiser la structure des dossiers.

Exemple :
```powershell
.\Classify-Scripts.ps1 -UpdateStructure -ReportFormat JSON
```

### 3. Tests
**Fichier**: `development/scripts/development/testing/tests/Test-ScriptInventory.ps1`

Tests unitaires et d'intÃ©gration pour valider le systÃ¨me.

ExÃ©cution :
```powershell
Invoke-Pester .\Test-ScriptInventory.ps1
```

## Workflow recommandÃ©

1. Mettre Ã  jour l'inventaire :
```powershell
Update-ScriptInventory
```

2. Analyser les scripts redondants :
```powershell
.\Find-RedundantScripts.ps1 -SimilarityThreshold 80
```

3. Classifier et rÃ©organiser les scripts :
```powershell
.\Classify-Scripts.ps1 -UpdateStructure
```

4. GÃ©nÃ©rer un rapport complet :
```powershell
.\Show-ScriptInventory.ps1 -ExportFormat HTML
```

## IntÃ©gration avec Git
Des hooks Git peuvent Ãªtre configurÃ©s pour :
- Mettre Ã  jour automatiquement l'inventaire aprÃ¨s un commit
- VÃ©rifier les mÃ©tadonnÃ©es des nouveaux scripts
- EmpÃªcher l'ajout de scripts sans mÃ©tadonnÃ©es minimales

Exemple de hook (Ã  placer dans `.git/hooks/post-commit`) :
```powershell
#!/usr/bin/env pwsh
Import-Module ./modules/ScriptInventoryManager.psm1
Update-ScriptInventory
```

## Bonnes pratiques

1. **MÃ©tadonnÃ©es** :
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
   Utiliser des noms explicites qui correspondent aux catÃ©gories dÃ©finies.

3. **Mises Ã  jour** :
   ExÃ©cuter `Update-ScriptInventory` aprÃ¨s des modifications importantes.

4. **Tests** :
   Lancer les tests avant de pousser des modifications sur le systÃ¨me d'inventaire.

