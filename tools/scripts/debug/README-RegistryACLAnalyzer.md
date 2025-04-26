# RegistryACLAnalyzer

RegistryACLAnalyzer est un module PowerShell pour analyser, comparer, visualiser et gérer les listes de contrôle d'accès (ACL) sur les clés de registre Windows.

## Fonctionnalités

- **Analyse des permissions de registre** : Obtenir des informations détaillées sur les permissions des clés de registre
- **Détection d'anomalies** : Identifier les configurations de permissions potentiellement risquées ou problématiques
- **Analyse d'héritage** : Examiner la structure d'héritage des permissions et détecter les interruptions
- **Analyse de propriété** : Obtenir des informations sur les propriétaires des clés de registre
- **Génération de rapports** : Créer des rapports détaillés sur les permissions de registre dans différents formats
- **Correction d'anomalies** : Corriger automatiquement les problèmes de permissions détectés
- **Comparaison de permissions** : Comparer les permissions entre deux clés de registre et identifier les différences
- **Exportation/Importation** : Sauvegarder et restaurer des configurations de permissions

## Installation

1. Téléchargez le fichier `RegistryACLAnalyzer.ps1`
2. Importez le module dans votre script PowerShell :

```powershell
. "C:\chemin\vers\RegistryACLAnalyzer.ps1"
```

## Fonctions principales

### Get-RegistryPermission

Analyse les permissions d'une clé de registre.

```powershell
Get-RegistryPermission -Path "HKLM:\SOFTWARE" -Recurse $true -IncludeInherited $true
```

### Find-RegistryPermissionAnomaly

Détecte les anomalies dans les permissions de registre.

```powershell
Find-RegistryPermissionAnomaly -Path "HKLM:\SOFTWARE" -Recurse $true
```

### Get-RegistryPermissionInheritance

Analyse l'héritage des permissions d'une clé de registre.

```powershell
Get-RegistryPermissionInheritance -Path "HKLM:\SOFTWARE" -Recurse $false
```

### Get-RegistryOwnershipInfo

Analyse les propriétaires des clés de registre.

```powershell
Get-RegistryOwnershipInfo -Path "HKLM:\SOFTWARE" -Recurse $true
```

### New-RegistryPermissionReport

Génère un rapport détaillé des permissions de registre.

```powershell
New-RegistryPermissionReport -Path "HKLM:\SOFTWARE" -OutputFormat "HTML"
```

### Repair-RegistryPermissionAnomaly

Corrige automatiquement les anomalies de permissions de registre détectées.

```powershell
Repair-RegistryPermissionAnomaly -Path "HKLM:\SOFTWARE" -AnomalyType "HighRiskPermission" -WhatIf
```

### Compare-RegistryPermission

Compare les permissions entre deux clés de registre.

```powershell
Compare-RegistryPermission -ReferencePath "HKLM:\SOFTWARE\Microsoft" -DifferencePath "HKLM:\SOFTWARE\Classes" -IncludeInherited $true
```

### Export-RegistryPermission

Exporte les permissions d'une clé de registre vers un fichier.

```powershell
Export-RegistryPermission -Path "HKLM:\SOFTWARE\Microsoft" -OutputPath "C:\Backup\RegistryPermissions.json" -Format "JSON" -Recurse $true
```

### Import-RegistryPermission

Importe les permissions de registre depuis un fichier et les applique à une clé de registre.

```powershell
Import-RegistryPermission -InputPath "C:\Backup\RegistryPermissions.json" -TargetPath "HKLM:\SOFTWARE\Test" -Format "JSON" -WhatIf
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

### Analyser les permissions d'une clé de registre sensible

```powershell
# Obtenir les permissions
$permissions = Get-RegistryPermission -Path "HKLM:\SYSTEM\CurrentControlSet\Services" -Recurse $true

# Afficher les permissions à risque élevé
$permissions | Where-Object { $_.RiskLevel -eq "Élevé" } | Format-Table -AutoSize
```

### Détecter et analyser les anomalies

```powershell
# Détecter les anomalies
$anomalies = Find-RegistryPermissionAnomaly -Path "HKLM:\SOFTWARE" -Recurse $true

# Afficher les anomalies à risque élevé
$anomalies | Where-Object { $_.Severity -eq "Élevée" } | Format-Table -AutoSize
```

### Générer un rapport complet

```powershell
# Générer un rapport HTML
$report = New-RegistryPermissionReport -Path "HKLM:\SOFTWARE\Microsoft" -OutputFormat "HTML"

# Enregistrer le rapport dans un fichier
$report | Out-File -FilePath "C:\Rapports\RegistryPermissions.html" -Encoding utf8
```

### Analyser l'héritage des permissions

```powershell
# Obtenir les informations d'héritage
$inheritance = Get-RegistryPermissionInheritance -Path "HKLM:\SOFTWARE" -Recurse $true

# Afficher les points d'interruption d'héritage
$inheritance | Where-Object { $_.InheritanceEnabled -eq $false } | Format-Table -AutoSize
```

### Analyser les propriétaires des clés de registre

```powershell
# Obtenir les informations de propriété
$ownership = Get-RegistryOwnershipInfo -Path "HKLM:\SOFTWARE" -Recurse $true

# Afficher les clés avec des risques de sécurité
$ownership | Where-Object { $_.SecurityRisk -eq $true } | Format-Table -AutoSize
```

### Corriger les anomalies de permissions

```powershell
# Détecter les anomalies
$anomalies = Find-RegistryPermissionAnomaly -Path "HKLM:\SOFTWARE" -Recurse $true

# Afficher les anomalies à risque élevé
$anomalies | Where-Object { $_.Severity -eq "Élevée" } | Format-Table -AutoSize

# Corriger les anomalies à risque élevé
Repair-RegistryPermissionAnomaly -Path "HKLM:\SOFTWARE" -AnomalyType "HighRiskPermission" -WhatIf
```

### Comparer les permissions entre deux clés de registre

```powershell
# Comparer les permissions
$comparison = Compare-RegistryPermission -ReferencePath "HKLM:\SOFTWARE\Microsoft" -DifferencePath "HKLM:\SOFTWARE\Classes"

# Afficher les permissions manquantes
$comparison.MissingPermissions | Format-Table -AutoSize

# Afficher les permissions supplémentaires
$comparison.AdditionalPermissions | Format-Table -AutoSize

# Afficher les permissions modifiées
$comparison.ModifiedPermissions | Format-Table -AutoSize
```

### Sauvegarder et restaurer des permissions

```powershell
# Sauvegarder les permissions
Export-RegistryPermission -Path "HKLM:\SOFTWARE\Microsoft" -OutputPath "C:\Backup\RegistryPermissions.json" -Format "JSON" -Recurse $true

# Restaurer les permissions sur une autre clé
Import-RegistryPermission -InputPath "C:\Backup\RegistryPermissions.json" -TargetPath "HKLM:\SOFTWARE\Test" -Format "JSON" -WhatIf
```

## Remarques

- Certaines fonctions nécessitent des privilèges d'administrateur pour fonctionner correctement
- Les fonctions récursives sont limitées en profondeur pour éviter les boucles infinies
- L'analyse des clés de registre système peut prendre du temps, utilisez la récursivité avec précaution
- Les fonctions de correction et d'importation supportent les paramètres `-WhatIf` et `-Force`

## Licence

Ce module est distribué sous licence MIT.

## Auteur

Augment Code
