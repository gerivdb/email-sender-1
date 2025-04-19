# Patterns d'erreurs PowerShell courants

Ce document répertorie les patterns d'erreurs PowerShell courants identifiés dans nos scripts, leurs causes et les meilleures pratiques pour les éviter.

## Erreurs de syntaxe PowerShell

### PSUseApprovedVerbs
**Description**: Utilisation d'un verbe non approuvé dans le nom d'une fonction PowerShell.

**Exemple d'erreur**:
```powershell
function Parse-Data { ... }
```

**Correction**:
```powershell
function Get-Data { ... }
```

**Meilleure pratique**: Toujours utiliser les verbes approuvés par PowerShell pour nommer les fonctions. Consultez la liste des verbes approuvés avec `Get-Verb`.

### PSPossibleIncorrectComparisonWithNull
**Description**: Comparaison incorrecte avec $null où $null est placé à droite de l'opérateur de comparaison.

**Exemple d'erreur**:
```powershell
if ($variable -eq $null) { ... }
```

**Correction**:
```powershell
if ($null -eq $variable) { ... }
```

**Meilleure pratique**: Toujours placer $null à gauche de l'opérateur de comparaison pour éviter les erreurs d'évaluation si $variable est un tableau.

### PSAvoidDefaultValueSwitchParameter
**Description**: Paramètre switch avec une valeur par défaut explicite.

**Exemple d'erreur**:
```powershell
param (
    [switch]$Force = $true
)
```

**Correction**:
```powershell
param (
    [switch]$Force
)

# Définir la valeur par défaut si nécessaire
if (-not $PSBoundParameters.ContainsKey('Force')) {
    $Force = $true
}
```

**Meilleure pratique**: Ne pas définir de valeur par défaut pour les paramètres switch dans la déclaration param. Utiliser $PSBoundParameters pour vérifier si le paramètre a été fourni.

### PSUseDeclaredVarsMoreThanAssignments
**Description**: Variable déclarée mais non utilisée ailleurs dans le script.

**Exemple d'erreur**:
```powershell
$result = Get-Something
# $result n'est jamais utilisé après cette ligne
```

**Correction**:
```powershell
# Option 1: Utiliser la variable
$result = Get-Something
Write-Output $result

# Option 2: Utiliser [void] ou $null = pour supprimer l'avertissement
[void](Get-Something)
# ou
$null = Get-Something
```

**Meilleure pratique**: Éviter de déclarer des variables qui ne sont pas utilisées. Si l'appel de fonction est nécessaire mais le résultat non, utiliser [void] ou $null =.

## Problèmes de gestion des chemins

### Espaces dans les noms de fichiers/dossiers
**Description**: Problèmes avec les chemins contenant des espaces.

**Exemple d'erreur**:
```powershell
$path = D:\Mes Documents\script.ps1
```

**Correction**:
```powershell
$path = "D:\Mes Documents\script.ps1"
# ou
$path = 'D:\Mes Documents\script.ps1'
```

**Meilleure pratique**: Toujours mettre les chemins entre guillemets, surtout s'ils contiennent des espaces ou des caractères spéciaux.

### Confusion entre chemins relatifs et absolus
**Description**: Utilisation incorrecte de chemins relatifs ou absolus.

**Exemple d'erreur**:
```powershell
$file = ".\data.txt"  # Relatif au répertoire courant
Set-Location "C:\Temp"
Get-Content $file  # Erreur: le fichier n'est plus dans le répertoire courant
```

**Correction**:
```powershell
$file = Join-Path -Path $PSScriptRoot -ChildPath "data.txt"  # Relatif au répertoire du script
Set-Location "C:\Temp"
Get-Content $file  # Fonctionne car le chemin est absolu
```

**Meilleure pratique**: Utiliser $PSScriptRoot pour les chemins relatifs au script. Utiliser Join-Path pour construire des chemins de manière portable.

## Problèmes d'automatisation

### Problèmes d'encodage des caractères
**Description**: Problèmes liés à l'encodage des fichiers, notamment avec les caractères accentués.

**Exemple d'erreur**:
```powershell
Set-Content -Path "fichier.txt" -Value "Contenu avec des caractères accentués: é à ç"
# Le fichier peut être illisible dans certains éditeurs
```

**Correction**:
```powershell
Set-Content -Path "fichier.txt" -Value "Contenu avec des caractères accentués: é à ç" -Encoding UTF8
```

**Meilleure pratique**: Toujours spécifier l'encodage UTF8 lors de la lecture/écriture de fichiers contenant des caractères non-ASCII.

### Difficultés à localiser les fichiers exacts
**Description**: Problèmes pour trouver les fichiers dans une structure de dossiers complexe.

**Exemple d'erreur**:
```powershell
$files = Get-ChildItem -Path "C:\Project" -Filter "*.ps1"
# Peut manquer des fichiers dans les sous-dossiers
```

**Correction**:
```powershell
$files = Get-ChildItem -Path "C:\Project" -Filter "*.ps1" -Recurse
```

**Meilleure pratique**: Utiliser -Recurse avec Get-ChildItem pour rechercher dans tous les sous-dossiers. Utiliser des filtres précis pour limiter les résultats.

## Lacunes dans la coordination des scripts

### Duplication de fichiers entre dossiers
**Description**: Mêmes fichiers présents dans plusieurs dossiers, causant des problèmes de synchronisation.

**Exemple d'erreur**:
```powershell
# Script1.ps1 dans le dossier parent
# Copie de Script1.ps1 dans un sous-dossier
# Les deux fichiers divergent au fil du temps
```

**Correction**:
```powershell
# Garder une seule version du fichier
# Utiliser des liens symboliques si nécessaire
New-Item -ItemType SymbolicLink -Path "Sous-dossier\Script1.ps1" -Target "Script1.ps1"
```

**Meilleure pratique**: Éviter la duplication de fichiers. Utiliser des modules PowerShell pour partager du code entre scripts.

## Pistes pour un système d'apprentissage des erreurs

1. **Collecte automatique des erreurs**:
   - Développer un wrapper pour les commandes PowerShell qui capture les erreurs
   - Stocker les erreurs dans une base de données structurée

2. **Analyse des patterns**:
   - Implémenter des algorithmes pour identifier les patterns récurrents
   - Utiliser des techniques de clustering pour regrouper les erreurs similaires

3. **Suggestions proactives**:
   - Développer un système qui suggère des corrections basées sur l'historique
   - Intégrer ce système avec les éditeurs de code

4. **Validation automatique**:
   - Créer des tests automatiques pour valider les corrections
   - Mettre en place un système de feedback pour améliorer les suggestions
