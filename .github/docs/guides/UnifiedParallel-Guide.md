# Guide d'utilisation du module UnifiedParallel

## 1. Introduction

Le module UnifiedParallel est une solution complète pour la parallélisation des tâches en PowerShell, conçue pour offrir une interface standardisée et performante tout en respectant les principes SOLID, DRY et KISS. Ce module permet d'exécuter efficacement des opérations en parallèle sur des collections de données, optimisant ainsi les performances des scripts PowerShell.

### 1.1 Objectifs du module

- Fournir une interface unifiée pour la parallélisation en PowerShell
- Assurer la compatibilité entre PowerShell 5.1 et PowerShell 7.x
- Optimiser l'utilisation des ressources système
- Offrir des mécanismes avancés de gestion des erreurs
- Faciliter le développement de scripts parallèles robustes

### 1.2 Architecture

Le module UnifiedParallel est structuré autour de plusieurs composants clés :

- **Gestionnaire de runspaces** : Crée et gère les runspaces pour l'exécution parallèle
- **Cache de pools de runspaces** : Optimise la réutilisation des runspaces
- **Moniteur de ressources** : Surveille l'utilisation des ressources système
- **Gestionnaire de backpressure** : Contrôle le flux des tâches en fonction de la charge
- **Gestionnaire de throttling** : Ajuste dynamiquement le nombre de threads
- **Gestionnaire d'erreurs standardisé** : Uniformise la gestion des erreurs

### 1.3 Principes de conception

Le module adhère aux principes suivants :

- **SOLID** : Chaque composant a une responsabilité unique et bien définie
- **DRY (Don't Repeat Yourself)** : Évite la duplication de code
- **KISS (Keep It Simple, Stupid)** : Interfaces simples et intuitives

## 2. Installation et prérequis

### 2.1 Prérequis

- **PowerShell 5.1 ou supérieur** : Le module est compatible avec Windows PowerShell 5.1 et PowerShell 7.x
- **Systèmes d'exploitation** : Windows, Linux et macOS (avec PowerShell 7.x)

### 2.2 Installation

1. Téléchargez le module depuis le dépôt
2. Placez le fichier `UnifiedParallel.psm1` dans un répertoire de modules PowerShell
3. Importez le module avec la commande :

```powershell
Import-Module -Path "chemin\vers\UnifiedParallel.psm1"
```

Ou, pour une installation permanente, copiez le module dans un des répertoires de modules PowerShell :

```powershell
# Obtenir les chemins des modules
$env:PSModulePath -split ';'

# Copier le module dans un des répertoires (exemple)
Copy-Item -Path "UnifiedParallel.psm1" -Destination "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\UnifiedParallel\"
```

## 3. Utilisation de base

### 3.1 Initialisation du module

Avant d'utiliser le module, vous devez l'initialiser :

```powershell
Initialize-UnifiedParallel
```

Options d'initialisation courantes :

```powershell
# Initialisation avec options personnalisées
Initialize-UnifiedParallel -LogPath "C:\Logs\UnifiedParallel" -DefaultTimeout 600 -EnableBackpressure -EnableThrottling
```

### 3.2 Exécution de tâches en parallèle

La fonction principale du module est `Invoke-UnifiedParallel`, qui permet d'exécuter un script block en parallèle sur une collection d'objets :

```powershell
# Définir les données et le script block
$data = 1..100
$scriptBlock = {
    param($item)
    # Traitement de l'élément
    return $item * 2
}

# Exécuter en parallèle
$results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $data -MaxThreads 8
```

### 3.3 Récupération des résultats

Les résultats sont retournés sous forme de collection d'objets :

```powershell
# Afficher les résultats
$results | Format-Table

# Accéder aux valeurs
$values = $results | Select-Object -ExpandProperty Value
```

### 3.4 Nettoyage des ressources

Après utilisation, nettoyez les ressources pour libérer la mémoire :

```powershell
Clear-UnifiedParallel
```

## 4. Fonctionnalités avancées

### 4.1 Gestion des ressources système et backpressure

Le module surveille l'utilisation des ressources système et peut ajuster son comportement en conséquence :

```powershell
# Initialiser avec backpressure activé
Initialize-UnifiedParallel -EnableBackpressure

# Exécuter avec surveillance des ressources
$results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $data -TaskType 'CPU'
```

Le mécanisme de backpressure contrôle le flux des tâches en fonction de la charge du système :
- Limite le nombre de tâches en file d'attente
- Rejette les nouvelles tâches si la charge est trop élevée
- Émet des avertissements lorsque les seuils sont atteints

### 4.2 Throttling adaptatif

Le throttling adaptatif ajuste dynamiquement le nombre de threads en fonction de la charge système :

```powershell
# Initialiser avec throttling activé
Initialize-UnifiedParallel -EnableThrottling

# Exécuter avec throttling adaptatif
$results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $data -Dynamic
```

Avantages du throttling adaptatif :
- Optimise l'utilisation des ressources
- Évite la surcharge du système
- Améliore les performances globales

### 4.3 Gestion des erreurs standardisée

Le module offre une gestion des erreurs standardisée via la fonction `New-UnifiedError` :

```powershell
try {
    # Code qui peut générer une erreur
} catch {
    # Créer une erreur standardisée
    New-UnifiedError -Message "Une erreur s'est produite" -Source "MonScript" -ErrorRecord $_ -WriteError
}
```

Options de gestion des erreurs dans `Invoke-UnifiedParallel` :

```powershell
# Ignorer les erreurs et continuer
$results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $data -IgnoreErrors

# Obtenir des informations détaillées sur les erreurs
$detailedResults = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $data -PassThru
$errors = $detailedResults.Errors
```

### 4.4 Utilisation du cache de runspaces

Le module utilise un cache de pools de runspaces pour optimiser les performances :

```powershell
# Obtenir des informations sur le cache
$cacheInfo = Get-RunspacePoolCacheInfo -Detailed

# Nettoyer le cache
Clear-RunspacePoolCache -MaxIdleTimeMinutes 15 -MaxCacheSize 5
```

Avantages du cache de runspaces :
- Réduit le temps de création des runspaces
- Améliore les performances pour les exécutions répétées
- Optimise l'utilisation de la mémoire

## 5. Bonnes pratiques et pièges à éviter

### 5.1 Bonnes pratiques

- **Initialiser le module une seule fois** au début du script
- **Nettoyer les ressources** avec `Clear-UnifiedParallel` à la fin
- **Choisir le bon type de tâche** ('CPU', 'IO', 'Mixed') pour optimiser les performances
- **Limiter la taille des données** transmises aux runspaces
- **Utiliser le paramètre `-PassThru`** pour obtenir des informations détaillées sur l'exécution
- **Activer le throttling adaptatif** pour les scripts à longue durée d'exécution

### 5.2 Pièges à éviter

- **Variables de portée globale** : Évitez d'utiliser des variables globales dans les script blocks
- **Objets non sérialisables** : Certains objets complexes ne peuvent pas être transmis aux runspaces
- **Fonctions non importées** : Les fonctions définies dans le script principal ne sont pas disponibles dans les runspaces
- **Surcharge de mémoire** : Évitez de traiter trop de données en parallèle
- **Timeouts trop courts** : Définissez des timeouts appropriés pour vos tâches

### 5.3 Résolution des problèmes courants

- **Erreurs de sérialisation** : Utilisez des types simples ou sérialisables
- **Performances médiocres** : Ajustez le nombre de threads et le type de tâche
- **Fuites de mémoire** : Assurez-vous d'appeler `Clear-UnifiedParallel` après utilisation
- **Erreurs d'encodage** : Utilisez `Initialize-EncodingSettings` pour configurer l'encodage UTF-8

## 6. Exemples de cas d'utilisation

### 6.1 Traitement de fichiers

```powershell
# Obtenir la liste des fichiers
$files = Get-ChildItem -Path "C:\Data" -Filter "*.txt"

# Définir le script block
$scriptBlock = {
    param($file)
    $content = Get-Content -Path $file.FullName
    $wordCount = ($content | Measure-Object -Word).Words
    return [PSCustomObject]@{
        FileName = $file.Name
        WordCount = $wordCount
        Size = $file.Length
    }
}

# Exécuter en parallèle (optimisé pour les opérations I/O)
$results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $files -TaskType 'IO'
```

### 6.2 Requêtes API

```powershell
# Définir les URLs à interroger
$urls = @(
    "https://jsonplaceholder.typicode.com/posts/1",
    "https://jsonplaceholder.typicode.com/posts/2",
    "https://jsonplaceholder.typicode.com/posts/3",
    "https://jsonplaceholder.typicode.com/posts/4",
    "https://jsonplaceholder.typicode.com/posts/5"
)

# Définir le script block
$scriptBlock = {
    param($url)
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get
        return [PSCustomObject]@{
            Url = $url
            Title = $response.title
            Success = $true
            Data = $response
        }
    } catch {
        return [PSCustomObject]@{
            Url = $url
            Title = $null
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Exécuter en parallèle (optimisé pour les opérations I/O)
$results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $urls -TaskType 'IO' -MaxThreads 10
```

### 6.3 Calculs intensifs

```powershell
# Fonction pour vérifier si un nombre est premier
function Test-IsPrime {
    param([int]$number)
    if ($number -lt 2) { return $false }
    for ($i = 2; $i -le [Math]::Sqrt($number); $i++) {
        if ($number % $i -eq 0) { return $false }
    }
    return $true
}

# Définir les nombres à traiter
$numbers = 1..1000

# Définir le script block
$scriptBlock = {
    param($range)
    $primes = @()
    foreach ($number in $range) {
        if (Test-IsPrime -number $number) {
            $primes += $number
        }
    }
    return [PSCustomObject]@{
        RangeStart = $range[0]
        RangeEnd = $range[-1]
        PrimeCount = $primes.Count
        Primes = $primes
    }
}

# Diviser les nombres en segments
$segments = @()
$segmentSize = 100
for ($i = 0; $i -lt $numbers.Count; $i += $segmentSize) {
    $segment = $numbers[$i..([Math]::Min($i + $segmentSize - 1, $numbers.Count - 1))]
    $segments += ,$segment
}

# Exécuter en parallèle (optimisé pour les opérations CPU)
$results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $segments -TaskType 'CPU'
```

### 6.4 Gestion des erreurs

```powershell
# Définir les données
$data = 1..10

# Définir un script block qui génère des erreurs pour les nombres pairs
$scriptBlock = {
    param($item)
    if ($item % 2 -eq 0) {
        throw "Erreur pour l'élément $item (nombre pair)"
    }
    return "Succès pour l'élément $item (nombre impair)"
}

# Exécuter avec gestion des erreurs détaillée
$detailedResults = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $data -PassThru -IgnoreErrors

# Analyser les résultats
$successResults = $detailedResults.Results | Where-Object { $_.Success }
$errorResults = $detailedResults.Results | Where-Object { -not $_.Success }

Write-Host "Succès: $($successResults.Count) éléments"
Write-Host "Erreurs: $($errorResults.Count) éléments"

# Afficher les erreurs
foreach ($error in $detailedResults.Errors) {
    Write-Host "Erreur: $($error.Exception.Message)"
}
```

## 7. Compatibilité et différences entre PowerShell 5.1 et 7.x

### 7.1 Compatibilité

Le module UnifiedParallel est conçu pour fonctionner de manière identique sur PowerShell 5.1 et PowerShell 7.x, mais il existe quelques différences de comportement et de performance.

### 7.2 Différences de comportement

| Fonctionnalité | PowerShell 5.1 | PowerShell 7.x |
|----------------|----------------|----------------|
| Méthode de parallélisation | Runspace Pools uniquement | Runspace Pools et ForEach-Object -Parallel |
| Performance | Bonne | Excellente (20-30% plus rapide) |
| Encodage par défaut | Windows-1252 | UTF-8 |
| Gestion de la mémoire | Moins efficace | Plus efficace |
| Compatibilité .NET | .NET Framework | .NET Core / .NET 5+ |

### 7.3 Optimisations spécifiques

- **PowerShell 5.1** : Utilisez `Initialize-EncodingSettings` pour configurer l'encodage UTF-8
- **PowerShell 7.x** : Profitez des performances améliorées avec des valeurs de MaxThreads plus élevées

## 8. Référence des fonctions

### 8.1 Fonctions principales

| Fonction | Description |
|----------|-------------|
| `Initialize-UnifiedParallel` | Initialise le module avec les paramètres spécifiés |
| `Invoke-UnifiedParallel` | Exécute des tâches en parallèle sur une collection d'objets |
| `Clear-UnifiedParallel` | Nettoie les ressources utilisées par le module |
| `Get-OptimalThreadCount` | Détermine le nombre optimal de threads à utiliser |
| `New-UnifiedError` | Crée un objet d'erreur standardisé |

### 8.2 Fonctions de gestion du cache

| Fonction | Description |
|----------|-------------|
| `Get-RunspacePoolCacheInfo` | Affiche des informations sur le cache des pools de runspaces |
| `Clear-RunspacePoolCache` | Nettoie le cache des pools de runspaces |
| `Get-RunspacePoolFromCache` | Récupère un pool de runspaces du cache |
| `New-RunspaceBatch` | Crée un lot de runspaces pour l'exécution parallèle |

### 8.3 Fonctions utilitaires

| Fonction | Description |
|----------|-------------|
| `Get-ModuleInitialized` | Vérifie si le module est initialisé |
| `Set-ModuleInitialized` | Définit l'état d'initialisation du module |
| `Get-ModuleConfig` | Récupère la configuration du module |
| `Set-ModuleConfig` | Définit la configuration du module |
| `Initialize-EncodingSettings` | Configure l'encodage UTF-8 pour la console et les fichiers |

## 9. Conclusion

Le module UnifiedParallel offre une solution complète et performante pour la parallélisation des tâches en PowerShell. En suivant les bonnes pratiques et en utilisant les fonctionnalités avancées du module, vous pouvez améliorer considérablement les performances de vos scripts PowerShell tout en maintenant une gestion robuste des erreurs et une utilisation optimale des ressources système.

Pour plus d'informations et des exemples détaillés, consultez les exemples fournis avec le module et la documentation en ligne.
