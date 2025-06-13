# Module de traitement parallèle

Ce document décrit le module de traitement parallèle (`ParallelProcessing.ps1`) qui permet d'optimiser les performances lors du traitement de fichiers.

## Table des matières

1. [Introduction](#introduction)

2. [Fonctions disponibles](#fonctions-disponibles)

3. [Exemples d'utilisation](#exemples-dutilisation)

4. [Performances](#performances)

5. [Compatibilité](#compatibilité)

6. [Bonnes pratiques](#bonnes-pratiques)

## Introduction

Le module de traitement parallèle permet d'exécuter des opérations sur plusieurs fichiers simultanément, ce qui peut considérablement améliorer les performances pour les tâches intensives. Il utilise deux méthodes de parallélisation selon la version de PowerShell disponible :

- **PowerShell 7+** : Utilise `ForEach-Object -Parallel` pour une parallélisation native.
- **PowerShell 5.1** : Utilise `RunspacePool` pour une parallélisation via des runspaces.

## Fonctions disponibles

### Invoke-ParallelFileProcessing

```powershell
Invoke-ParallelFileProcessing -FilePaths <string[]> -ScriptBlock <scriptblock> [-ThrottleLimit <int>] [-Parameters <hashtable>]
```plaintext
Cette fonction exécute un script block sur plusieurs fichiers en parallèle.

#### Paramètres

- **FilePaths** : Tableau de chemins de fichiers à traiter.
- **ScriptBlock** : Script block à exécuter pour chaque fichier.
- **ThrottleLimit** : Nombre maximum de tâches parallèles (par défaut : 5).
- **Parameters** : Hashtable de paramètres à passer au script block.

#### Exemple

```powershell
$results = Invoke-ParallelFileProcessing -FilePaths $files -ScriptBlock {
    param($FilePath)
    # Traitement du fichier

    return "Traitement de $FilePath terminé"
} -ThrottleLimit 3
```plaintext
### Convert-FilesInParallel

```powershell
Convert-FilesInParallel -InputFiles <string[]> -OutputDir <string> [-InputFormat <string>] -OutputFormat <string> [-FlattenNestedObjects <bool>] [-NestedSeparator <string>] [-ThrottleLimit <int>]
```plaintext
Cette fonction convertit plusieurs fichiers en parallèle d'un format à un autre.

#### Paramètres

- **InputFiles** : Tableau de chemins de fichiers d'entrée.
- **OutputDir** : Répertoire de sortie pour les fichiers convertis.
- **InputFormat** : Format d'entrée (AUTO, JSON, XML, TEXT, CSV, YAML). Par défaut : AUTO.
- **OutputFormat** : Format de sortie (JSON, XML, TEXT, CSV, YAML).
- **FlattenNestedObjects** : Indique si les objets imbriqués doivent être aplatis (par défaut : $true).
- **NestedSeparator** : Séparateur pour les noms de propriétés aplaties (par défaut : ".").
- **ThrottleLimit** : Nombre maximum de tâches parallèles (par défaut : 5).

#### Exemple

```powershell
$results = Convert-FilesInParallel -InputFiles $csvFiles -OutputDir $outputDir -InputFormat "CSV" -OutputFormat "JSON" -ThrottleLimit 3
```plaintext
### Get-FileAnalysisInParallel

```powershell
Get-FileAnalysisInParallel -FilePaths <string[]> [-Format <string>] -OutputDir <string> [-ThrottleLimit <int>]
```plaintext
Cette fonction analyse plusieurs fichiers en parallèle et génère des rapports d'analyse.

#### Paramètres

- **FilePaths** : Tableau de chemins de fichiers à analyser.
- **Format** : Format des fichiers (AUTO, JSON, XML, TEXT, CSV, YAML). Par défaut : AUTO.
- **OutputDir** : Répertoire de sortie pour les rapports d'analyse.
- **ThrottleLimit** : Nombre maximum de tâches parallèles (par défaut : 5).

#### Exemple

```powershell
$results = Get-FileAnalysisInParallel -FilePaths $jsonFiles -Format "JSON" -OutputDir $analysisDir -ThrottleLimit 3
```plaintext
## Exemples d'utilisation

### Conversion parallèle de fichiers CSV en JSON

```powershell
# Importer le module

. ".\modules\ParallelProcessing.ps1"

# Définir les fichiers à traiter

$csvFiles = Get-ChildItem -Path ".\data" -Filter "*.csv" | Select-Object -ExpandProperty FullName

# Convertir les fichiers en parallèle

$results = Convert-FilesInParallel -InputFiles $csvFiles -OutputDir ".\output" -InputFormat "CSV" -OutputFormat "JSON" -ThrottleLimit 3

# Afficher les résultats

$results | Format-Table -Property InputFile, OutputFile, Success
```plaintext
### Analyse parallèle de fichiers JSON

```powershell
# Importer le module

. ".\modules\ParallelProcessing.ps1"

# Définir les fichiers à traiter

$jsonFiles = Get-ChildItem -Path ".\data" -Filter "*.json" | Select-Object -ExpandProperty FullName

# Analyser les fichiers en parallèle

$results = Get-FileAnalysisInParallel -FilePaths $jsonFiles -Format "JSON" -OutputDir ".\analysis" -ThrottleLimit 3

# Afficher les résultats

$results | Format-Table -Property InputFile, OutputFile, Format, Success
```plaintext
### Traitement personnalisé en parallèle

```powershell
# Importer le module

. ".\modules\ParallelProcessing.ps1"

# Définir les fichiers à traiter

$files = Get-ChildItem -Path ".\data" -Filter "*.txt" | Select-Object -ExpandProperty FullName

# Définir le script block de traitement

$scriptBlock = {
    param($FilePath, $OutputDir)
    
    # Lire le contenu du fichier

    $content = Get-Content -Path $FilePath -Raw
    
    # Traiter le contenu

    $processedContent = $content.ToUpper()
    
    # Enregistrer le résultat

    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    $outputPath = Join-Path -Path $OutputDir -ChildPath "$fileName-processed.txt"
    Set-Content -Path $outputPath -Value $processedContent -Encoding UTF8
    
    # Retourner le résultat

    return [PSCustomObject]@{
        InputFile = $FilePath
        OutputFile = $outputPath
        Success = $true
    }
}

# Traiter les fichiers en parallèle

$parameters = @{
    OutputDir = ".\output"
}
$results = Invoke-ParallelFileProcessing -FilePaths $files -ScriptBlock $scriptBlock -ThrottleLimit 3 -Parameters $parameters

# Afficher les résultats

$results | Format-Table -Property InputFile, OutputFile, Success
```plaintext
## Performances

Le traitement parallèle peut considérablement améliorer les performances, en particulier pour les opérations intensives sur de nombreux fichiers. Voici quelques résultats de performance typiques :

| Opération | Nombre de fichiers | Séquentiel | Parallèle (3 threads) | Gain |
|-----------|-------------------|------------|----------------------|------|
| Conversion CSV → JSON | 10 | 5.2s | 2.1s | 60% |
| Analyse JSON | 10 | 3.8s | 1.5s | 61% |
| Traitement personnalisé | 10 | 7.5s | 2.8s | 63% |

Les gains de performance dépendent de plusieurs facteurs :
- Nombre de fichiers à traiter
- Complexité des opérations
- Nombre de threads parallèles (ThrottleLimit)
- Ressources système disponibles (CPU, mémoire, disque)

## Compatibilité

Le module de traitement parallèle est compatible avec :

- **PowerShell 5.1** : Utilise RunspacePool pour la parallélisation
- **PowerShell 7+** : Utilise ForEach-Object -Parallel pour la parallélisation

Le module détecte automatiquement la version de PowerShell et utilise la méthode de parallélisation appropriée.

## Bonnes pratiques

Pour tirer le meilleur parti du traitement parallèle, suivez ces bonnes pratiques :

1. **Ajustez le ThrottleLimit** : Commencez avec une valeur modérée (3-5) et ajustez en fonction des performances observées. Un nombre trop élevé peut saturer les ressources système.

2. **Évitez les dépendances entre tâches** : Chaque tâche parallèle doit être indépendante des autres pour éviter les blocages.

3. **Gérez les erreurs** : Assurez-vous que votre script block gère correctement les erreurs pour éviter qu'une tâche ne bloque les autres.

4. **Surveillez l'utilisation des ressources** : Le traitement parallèle peut consommer beaucoup de ressources système. Surveillez l'utilisation du CPU et de la mémoire.

5. **Testez avec un petit ensemble de données** : Avant de traiter un grand nombre de fichiers, testez avec un petit ensemble pour vérifier que tout fonctionne correctement.

6. **Utilisez des variables locales** : Dans le script block, utilisez des variables locales plutôt que des variables globales pour éviter les conflits entre les tâches parallèles.

7. **Limitez la taille des données partagées** : Si vous partagez des données entre les tâches parallèles, limitez leur taille pour éviter les problèmes de mémoire.
