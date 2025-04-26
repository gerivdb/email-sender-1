# ACLAnalyzer

ACLAnalyzer est un module PowerShell pour analyser, comparer, visualiser et gérer les listes de contrôle d'accès (ACL) sur différentes ressources du système, principalement les fichiers et dossiers NTFS.

## Fonctionnalités

- **Analyse des permissions NTFS** : Obtenir des informations détaillées sur les permissions NTFS des fichiers et dossiers
- **Détection d'anomalies** : Identifier les configurations de permissions potentiellement risquées ou problématiques
- **Analyse d'héritage** : Examiner la structure d'héritage des permissions et détecter les interruptions
- **Analyse de propriété** : Obtenir des informations sur les propriétaires des fichiers et dossiers
- **Génération de rapports** : Créer des rapports détaillés sur les permissions NTFS dans différents formats
- **Correction d'anomalies** : Corriger automatiquement les problèmes de permissions détectés
- **Comparaison de permissions** : Comparer les permissions entre deux chemins et identifier les différences
- **Exportation/Importation** : Sauvegarder et restaurer des configurations de permissions

## Installation

1. Téléchargez le fichier `ACLAnalyzer.ps1`
2. Importez le module dans votre script PowerShell :

```powershell
. "C:\chemin\vers\ACLAnalyzer.ps1"
```

## Fonctions principales

### Get-NTFSPermission

Analyse les permissions NTFS d'un fichier ou dossier.

```powershell
Get-NTFSPermission -Path "C:\Data" -Recurse $true -IncludeInherited $true
```

### Find-NTFSPermissionAnomaly

Détecte les anomalies dans les permissions NTFS.

```powershell
Find-NTFSPermissionAnomaly -Path "C:\Data" -Recurse $true
```

### Get-NTFSPermissionInheritance

Analyse l'héritage des permissions NTFS pour un fichier ou dossier.

```powershell
Get-NTFSPermissionInheritance -Path "C:\Data" -Recurse $false
```

### Get-NTFSOwnershipInfo

Analyse les propriétaires et groupes principaux des fichiers et dossiers.

```powershell
Get-NTFSOwnershipInfo -Path "C:\Data" -Recurse $true
```

### New-NTFSPermissionReport

Génère un rapport détaillé des permissions NTFS.

```powershell
New-NTFSPermissionReport -Path "C:\Data" -OutputFormat "HTML"
```

### Repair-NTFSPermissionAnomaly

Corrige automatiquement les anomalies de permissions NTFS détectées.

```powershell
Repair-NTFSPermissionAnomaly -Path "C:\Data" -AnomalyType "HighRiskPermission" -WhatIf
```

### Compare-NTFSPermission

Compare les permissions NTFS entre deux chemins.

```powershell
Compare-NTFSPermission -ReferencePath "C:\Data\Reference" -DifferencePath "C:\Data\Target" -IncludeInherited $true
```

### Export-NTFSPermission

Exporte les permissions NTFS d'un chemin vers un fichier.

```powershell
Export-NTFSPermission -Path "C:\Data" -OutputPath "C:\Backup\DataPermissions.json" -Format "JSON" -Recurse $true
```

### Import-NTFSPermission

Importe les permissions NTFS depuis un fichier et les applique à un chemin.

```powershell
Import-NTFSPermission -InputPath "C:\Backup\DataPermissions.json" -TargetPath "D:\Data" -Format "JSON" -WhatIf
```

## Types d'anomalies détectées

- **HighRiskPermission** : Permissions à risque élevé accordées à des groupes à risque élevé
- **PermissionConflict** : Conflits entre les permissions Allow et Deny
- **RedundantPermission** : Permissions redondantes pour le même utilisateur ou groupe
- **InheritanceBreak** : Interruptions dans l'héritage des permissions

## Formats de rapport pris en charge

- **Text** : Rapport au format texte simple
- **HTML** : Rapport au format HTML avec mise en forme et coloration
- **JSON** : Rapport au format JSON pour l'intégration avec d'autres outils

## Formats d'exportation/importation pris en charge

- **JSON** : Format JSON pour une exportation complète avec métadonnées
- **XML** : Format XML pour une exportation complète avec métadonnées
- **CSV** : Format CSV pour une exportation simplifiée et compatible avec Excel

## Exemples d'utilisation

### Analyser et corriger les permissions à risque élevé

```powershell
# Détecter les anomalies
$anomalies = Find-NTFSPermissionAnomaly -Path "C:\Data" -Recurse $true

# Afficher les anomalies à risque élevé
$anomalies | Where-Object { $_.Severity -eq "Élevée" } | Format-Table -AutoSize

# Corriger les anomalies à risque élevé
Repair-NTFSPermissionAnomaly -Path "C:\Data" -AnomalyType "HighRiskPermission" -WhatIf
```

### Sauvegarder et restaurer des permissions

```powershell
# Sauvegarder les permissions
Export-NTFSPermission -Path "C:\Data" -OutputPath "C:\Backup\DataPermissions.json" -Format "JSON" -Recurse $true

# Restaurer les permissions sur un autre chemin
Import-NTFSPermission -InputPath "C:\Backup\DataPermissions.json" -TargetPath "D:\Data" -Format "JSON"
```

### Comparer les permissions entre deux dossiers

```powershell
$comparison = Compare-NTFSPermission -ReferencePath "C:\Data\Reference" -DifferencePath "C:\Data\Target"

# Afficher les permissions manquantes
$comparison.MissingPermissions | Format-Table -AutoSize

# Afficher les permissions supplémentaires
$comparison.AdditionalPermissions | Format-Table -AutoSize

# Afficher les permissions modifiées
$comparison.ModifiedPermissions | Format-Table -AutoSize
```

## Remarques

- Certaines fonctions nécessitent des privilèges d'administrateur pour fonctionner correctement
- Les fonctions récursives sont limitées en profondeur pour éviter les boucles infinies
- Les fonctions de correction et d'importation supportent les paramètres `-WhatIf` et `-Force`

## Licence

Ce module est distribué sous licence MIT.

## Auteur

Augment Code
