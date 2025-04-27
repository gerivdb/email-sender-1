# RegistryACLAnalyzer

RegistryACLAnalyzer est un module PowerShell pour analyser, comparer, visualiser et gÃ©rer les listes de contrÃ´le d'accÃ¨s (ACL) sur les clÃ©s de registre Windows.

## FonctionnalitÃ©s

- **Analyse des permissions de registre** : Obtenir des informations dÃ©taillÃ©es sur les permissions des clÃ©s de registre
- **DÃ©tection d'anomalies** : Identifier les configurations de permissions potentiellement risquÃ©es ou problÃ©matiques
- **Analyse d'hÃ©ritage** : Examiner la structure d'hÃ©ritage des permissions et dÃ©tecter les interruptions
- **Analyse de propriÃ©tÃ©** : Obtenir des informations sur les propriÃ©taires des clÃ©s de registre
- **GÃ©nÃ©ration de rapports** : CrÃ©er des rapports dÃ©taillÃ©s sur les permissions de registre dans diffÃ©rents formats
- **Correction d'anomalies** : Corriger automatiquement les problÃ¨mes de permissions dÃ©tectÃ©s
- **Comparaison de permissions** : Comparer les permissions entre deux clÃ©s de registre et identifier les diffÃ©rences
- **Exportation/Importation** : Sauvegarder et restaurer des configurations de permissions

## Installation

1. TÃ©lÃ©chargez le fichier `RegistryACLAnalyzer.ps1`
2. Importez le module dans votre script PowerShell :

```powershell
. "C:\chemin\vers\RegistryACLAnalyzer.ps1"
```

## Fonctions principales

### Get-RegistryPermission

Analyse les permissions d'une clÃ© de registre.

```powershell
Get-RegistryPermission -Path "HKLM:\SOFTWARE" -Recurse $true -IncludeInherited $true
```

### Find-RegistryPermissionAnomaly

DÃ©tecte les anomalies dans les permissions de registre.

```powershell
Find-RegistryPermissionAnomaly -Path "HKLM:\SOFTWARE" -Recurse $true
```

### Get-RegistryPermissionInheritance

Analyse l'hÃ©ritage des permissions d'une clÃ© de registre.

```powershell
Get-RegistryPermissionInheritance -Path "HKLM:\SOFTWARE" -Recurse $false
```

### Get-RegistryOwnershipInfo

Analyse les propriÃ©taires des clÃ©s de registre.

```powershell
Get-RegistryOwnershipInfo -Path "HKLM:\SOFTWARE" -Recurse $true
```

### New-RegistryPermissionReport

GÃ©nÃ¨re un rapport dÃ©taillÃ© des permissions de registre.

```powershell
New-RegistryPermissionReport -Path "HKLM:\SOFTWARE" -OutputFormat "HTML"
```

### Repair-RegistryPermissionAnomaly

Corrige automatiquement les anomalies de permissions de registre dÃ©tectÃ©es.

```powershell
Repair-RegistryPermissionAnomaly -Path "HKLM:\SOFTWARE" -AnomalyType "HighRiskPermission" -WhatIf
```

### Compare-RegistryPermission

Compare les permissions entre deux clÃ©s de registre.

```powershell
Compare-RegistryPermission -ReferencePath "HKLM:\SOFTWARE\Microsoft" -DifferencePath "HKLM:\SOFTWARE\Classes" -IncludeInherited $true
```

### Export-RegistryPermission

Exporte les permissions d'une clÃ© de registre vers un fichier.

```powershell
Export-RegistryPermission -Path "HKLM:\SOFTWARE\Microsoft" -OutputPath "C:\Backup\RegistryPermissions.json" -Format "JSON" -Recurse $true
```

### Import-RegistryPermission

Importe les permissions de registre depuis un fichier et les applique Ã  une clÃ© de registre.

```powershell
Import-RegistryPermission -InputPath "C:\Backup\RegistryPermissions.json" -TargetPath "HKLM:\SOFTWARE\Test" -Format "JSON" -WhatIf
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

### Analyser les permissions d'une clÃ© de registre sensible

```powershell
# Obtenir les permissions
$permissions = Get-RegistryPermission -Path "HKLM:\SYSTEM\CurrentControlSet\Services" -Recurse $true

# Afficher les permissions Ã  risque Ã©levÃ©
$permissions | Where-Object { $_.RiskLevel -eq "Ã‰levÃ©" } | Format-Table -AutoSize
```

### DÃ©tecter et analyser les anomalies

```powershell
# DÃ©tecter les anomalies
$anomalies = Find-RegistryPermissionAnomaly -Path "HKLM:\SOFTWARE" -Recurse $true

# Afficher les anomalies Ã  risque Ã©levÃ©
$anomalies | Where-Object { $_.Severity -eq "Ã‰levÃ©e" } | Format-Table -AutoSize
```

### GÃ©nÃ©rer un rapport complet

```powershell
# GÃ©nÃ©rer un rapport HTML
$report = New-RegistryPermissionReport -Path "HKLM:\SOFTWARE\Microsoft" -OutputFormat "HTML"

# Enregistrer le rapport dans un fichier
$report | Out-File -FilePath "C:\Rapports\RegistryPermissions.html" -Encoding utf8
```

### Analyser l'hÃ©ritage des permissions

```powershell
# Obtenir les informations d'hÃ©ritage
$inheritance = Get-RegistryPermissionInheritance -Path "HKLM:\SOFTWARE" -Recurse $true

# Afficher les points d'interruption d'hÃ©ritage
$inheritance | Where-Object { $_.InheritanceEnabled -eq $false } | Format-Table -AutoSize
```

### Analyser les propriÃ©taires des clÃ©s de registre

```powershell
# Obtenir les informations de propriÃ©tÃ©
$ownership = Get-RegistryOwnershipInfo -Path "HKLM:\SOFTWARE" -Recurse $true

# Afficher les clÃ©s avec des risques de sÃ©curitÃ©
$ownership | Where-Object { $_.SecurityRisk -eq $true } | Format-Table -AutoSize
```

### Corriger les anomalies de permissions

```powershell
# DÃ©tecter les anomalies
$anomalies = Find-RegistryPermissionAnomaly -Path "HKLM:\SOFTWARE" -Recurse $true

# Afficher les anomalies Ã  risque Ã©levÃ©
$anomalies | Where-Object { $_.Severity -eq "Ã‰levÃ©e" } | Format-Table -AutoSize

# Corriger les anomalies Ã  risque Ã©levÃ©
Repair-RegistryPermissionAnomaly -Path "HKLM:\SOFTWARE" -AnomalyType "HighRiskPermission" -WhatIf
```

### Comparer les permissions entre deux clÃ©s de registre

```powershell
# Comparer les permissions
$comparison = Compare-RegistryPermission -ReferencePath "HKLM:\SOFTWARE\Microsoft" -DifferencePath "HKLM:\SOFTWARE\Classes"

# Afficher les permissions manquantes
$comparison.MissingPermissions | Format-Table -AutoSize

# Afficher les permissions supplÃ©mentaires
$comparison.AdditionalPermissions | Format-Table -AutoSize

# Afficher les permissions modifiÃ©es
$comparison.ModifiedPermissions | Format-Table -AutoSize
```

### Sauvegarder et restaurer des permissions

```powershell
# Sauvegarder les permissions
Export-RegistryPermission -Path "HKLM:\SOFTWARE\Microsoft" -OutputPath "C:\Backup\RegistryPermissions.json" -Format "JSON" -Recurse $true

# Restaurer les permissions sur une autre clÃ©
Import-RegistryPermission -InputPath "C:\Backup\RegistryPermissions.json" -TargetPath "HKLM:\SOFTWARE\Test" -Format "JSON" -WhatIf
```

## Remarques

- Certaines fonctions nÃ©cessitent des privilÃ¨ges d'administrateur pour fonctionner correctement
- Les fonctions rÃ©cursives sont limitÃ©es en profondeur pour Ã©viter les boucles infinies
- L'analyse des clÃ©s de registre systÃ¨me peut prendre du temps, utilisez la rÃ©cursivitÃ© avec prÃ©caution
- Les fonctions de correction et d'importation supportent les paramÃ¨tres `-WhatIf` et `-Force`

## Licence

Ce module est distribuÃ© sous licence MIT.

## Auteur

Augment Code
