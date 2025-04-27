# ACLAnalyzer

ACLAnalyzer est un module PowerShell pour analyser, comparer, visualiser et gÃ©rer les listes de contrÃ´le d'accÃ¨s (ACL) sur diffÃ©rentes ressources du systÃ¨me, principalement les fichiers et dossiers NTFS.

## FonctionnalitÃ©s

- **Analyse des permissions NTFS** : Obtenir des informations dÃ©taillÃ©es sur les permissions NTFS des fichiers et dossiers
- **DÃ©tection d'anomalies** : Identifier les configurations de permissions potentiellement risquÃ©es ou problÃ©matiques
- **Analyse d'hÃ©ritage** : Examiner la structure d'hÃ©ritage des permissions et dÃ©tecter les interruptions
- **Analyse de propriÃ©tÃ©** : Obtenir des informations sur les propriÃ©taires des fichiers et dossiers
- **GÃ©nÃ©ration de rapports** : CrÃ©er des rapports dÃ©taillÃ©s sur les permissions NTFS dans diffÃ©rents formats
- **Correction d'anomalies** : Corriger automatiquement les problÃ¨mes de permissions dÃ©tectÃ©s
- **Comparaison de permissions** : Comparer les permissions entre deux chemins et identifier les diffÃ©rences
- **Exportation/Importation** : Sauvegarder et restaurer des configurations de permissions

## Installation

1. TÃ©lÃ©chargez le fichier `ACLAnalyzer.ps1`
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

DÃ©tecte les anomalies dans les permissions NTFS.

```powershell
Find-NTFSPermissionAnomaly -Path "C:\Data" -Recurse $true
```

### Get-NTFSPermissionInheritance

Analyse l'hÃ©ritage des permissions NTFS pour un fichier ou dossier.

```powershell
Get-NTFSPermissionInheritance -Path "C:\Data" -Recurse $false
```

### Get-NTFSOwnershipInfo

Analyse les propriÃ©taires et groupes principaux des fichiers et dossiers.

```powershell
Get-NTFSOwnershipInfo -Path "C:\Data" -Recurse $true
```

### New-NTFSPermissionReport

GÃ©nÃ¨re un rapport dÃ©taillÃ© des permissions NTFS.

```powershell
New-NTFSPermissionReport -Path "C:\Data" -OutputFormat "HTML"
```

### Repair-NTFSPermissionAnomaly

Corrige automatiquement les anomalies de permissions NTFS dÃ©tectÃ©es.

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

Importe les permissions NTFS depuis un fichier et les applique Ã  un chemin.

```powershell
Import-NTFSPermission -InputPath "C:\Backup\DataPermissions.json" -TargetPath "D:\Data" -Format "JSON" -WhatIf
```

## Types d'anomalies dÃ©tectÃ©es

- **HighRiskPermission** : Permissions Ã  risque Ã©levÃ© accordÃ©es Ã  des groupes Ã  risque Ã©levÃ©
- **PermissionConflict** : Conflits entre les permissions Allow et Deny
- **RedundantPermission** : Permissions redondantes pour le mÃªme utilisateur ou groupe
- **InheritanceBreak** : Interruptions dans l'hÃ©ritage des permissions

## Formats de rapport pris en charge

- **Text** : Rapport au format texte simple
- **HTML** : Rapport au format HTML avec mise en forme et coloration
- **JSON** : Rapport au format JSON pour l'intÃ©gration avec d'autres outils

## Formats d'exportation/importation pris en charge

- **JSON** : Format JSON pour une exportation complÃ¨te avec mÃ©tadonnÃ©es
- **XML** : Format XML pour une exportation complÃ¨te avec mÃ©tadonnÃ©es
- **CSV** : Format CSV pour une exportation simplifiÃ©e et compatible avec Excel

## Exemples d'utilisation

### Analyser et corriger les permissions Ã  risque Ã©levÃ©

```powershell
# DÃ©tecter les anomalies
$anomalies = Find-NTFSPermissionAnomaly -Path "C:\Data" -Recurse $true

# Afficher les anomalies Ã  risque Ã©levÃ©
$anomalies | Where-Object { $_.Severity -eq "Ã‰levÃ©e" } | Format-Table -AutoSize

# Corriger les anomalies Ã  risque Ã©levÃ©
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

# Afficher les permissions supplÃ©mentaires
$comparison.AdditionalPermissions | Format-Table -AutoSize

# Afficher les permissions modifiÃ©es
$comparison.ModifiedPermissions | Format-Table -AutoSize
```

## Remarques

- Certaines fonctions nÃ©cessitent des privilÃ¨ges d'administrateur pour fonctionner correctement
- Les fonctions rÃ©cursives sont limitÃ©es en profondeur pour Ã©viter les boucles infinies
- Les fonctions de correction et d'importation supportent les paramÃ¨tres `-WhatIf` et `-Force`

## Licence

Ce module est distribuÃ© sous licence MIT.

## Auteur

Augment Code
