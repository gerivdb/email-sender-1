# Stratégie de gestion des erreurs pour le module CycleDetector

## Introduction

Ce document définit la stratégie de gestion des erreurs pour le module `CycleDetector.psm1`. Une gestion efficace des erreurs est essentielle pour assurer la robustesse et la fiabilité du module, ainsi que pour fournir des informations utiles aux utilisateurs en cas de problème.

## Principes généraux

La stratégie de gestion des erreurs du module `CycleDetector.psm1` repose sur les principes suivants :

1. **Fail-fast** : Détecter et signaler les erreurs le plus tôt possible.
2. **Messages clairs** : Fournir des messages d'erreur explicites et informatifs.
3. **Récupération gracieuse** : Permettre au module de continuer à fonctionner dans la mesure du possible.
4. **Journalisation** : Enregistrer les erreurs pour faciliter le débogage.
5. **Respect des conventions PowerShell** : Utiliser les mécanismes standard de PowerShell pour la gestion des erreurs.

## Types d'erreurs

### 1. Erreurs de validation des paramètres

Ces erreurs se produisent lorsque les paramètres fournis aux fonctions du module sont invalides.

#### Exemples
- Graphe null ou vide
- Chemin de fichier inexistant
- Profondeur maximale négative

#### Stratégie
- Utiliser les attributs de validation PowerShell (`[ValidateNotNull]`, `[ValidateNotNullOrEmpty]`, etc.)
- Effectuer des validations supplémentaires au début des fonctions
- Générer des erreurs de terminaison avec `Write-Error -ErrorAction Stop`

#### Exemple de code
```powershell
function Detect-Cycle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [hashtable]$Graph,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$MaxDepth = 1000
    )
    
    if ($Graph.Count -eq 0) {
        Write-Error -Message "Le graphe ne peut pas être vide." -ErrorAction Stop
    }
    
    # Suite de la fonction...
}
```

### 2. Erreurs d'exécution

Ces erreurs se produisent pendant l'exécution des fonctions du module.

#### Exemples
- Dépassement de la profondeur maximale
- Débordement de pile
- Erreur lors de la lecture d'un fichier

#### Stratégie
- Utiliser des blocs try/catch pour capturer les exceptions
- Journaliser les erreurs avec `Write-Verbose`
- Retourner des résultats partiels ou par défaut si possible

#### Exemple de code
```powershell
function Find-DependencyCycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [switch]$Recursive
    )
    
    try {
        # Vérifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error -Message "Le chemin '$Path' n'existe pas." -ErrorAction Stop
        }
        
        # Analyser les dépendances
        $dependencies = @{}
        
        # Traitement des fichiers...
    }
    catch [System.IO.FileNotFoundException] {
        Write-Error -Message "Fichier non trouvé: $($_.Exception.FileName)" -ErrorAction Continue
        return [PSCustomObject]@{
            HasCycles = $false
            Cycles = @()
            DependencyGraph = @{}
            NonCyclicScripts = @()
        }
    }
    catch [System.OutOfMemoryException] {
        Write-Error -Message "Mémoire insuffisante pour analyser les dépendances." -ErrorAction Continue
        return [PSCustomObject]@{
            HasCycles = $false
            Cycles = @()
            DependencyGraph = @{}
            NonCyclicScripts = @()
        }
    }
    catch {
        Write-Error -Message "Erreur lors de l'analyse des dépendances: $_" -ErrorAction Continue
        return [PSCustomObject]@{
            HasCycles = $false
            Cycles = @()
            DependencyGraph = @{}
            NonCyclicScripts = @()
        }
    }
    
    # Suite de la fonction...
}
```

### 3. Erreurs de limite

Ces erreurs se produisent lorsque le module atteint ses limites de performance ou de capacité.

#### Exemples
- Graphe trop grand
- Trop de cycles détectés
- Temps d'exécution trop long

#### Stratégie
- Implémenter des mécanismes de timeout
- Limiter la taille des résultats
- Fournir des avertissements avec `Write-Warning`

#### Exemple de code
```powershell
function Find-GraphCycle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 1000,
        
        [Parameter(Mandatory = $false)]
        [int]$Timeout = 30 # secondes
    )
    
    $startTime = Get-Date
    $timeoutReached = $false
    
    # Initialiser le résultat
    $result = [PSCustomObject]@{
        HasCycle = $false
        CyclePath = @()
    }
    
    # Traitement du graphe...
    
    foreach ($node in $Graph.Keys) {
        # Vérifier le timeout
        if ((New-TimeSpan -Start $startTime -End (Get-Date)).TotalSeconds -gt $Timeout) {
            $timeoutReached = $true
            Write-Warning "Timeout atteint après $Timeout secondes. L'analyse est incomplète."
            break
        }
        
        # Traitement du nœud...
    }
    
    if ($timeoutReached) {
        $result.HasCycle = $null # Indique un résultat incertain
    }
    
    return $result
}
```

### 4. Erreurs de format

Ces erreurs se produisent lorsque les données d'entrée ne sont pas dans le format attendu.

#### Exemples
- Format de fichier JSON invalide
- Structure de graphe incorrecte
- Encodage de fichier non supporté

#### Stratégie
- Valider le format des données avant traitement
- Fournir des messages d'erreur détaillés
- Suggérer des corrections si possible

#### Exemple de code
```powershell
function Test-WorkflowCycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowPath
    )
    
    try {
        # Lire le fichier JSON
        $workflowJson = Get-Content -Path $WorkflowPath -Raw | ConvertFrom-Json -ErrorAction Stop
        
        # Valider la structure du workflow
        if (-not $workflowJson.nodes -or -not $workflowJson.connections) {
            Write-Error -Message "Format de workflow invalide. Les propriétés 'nodes' et 'connections' sont requises." -ErrorAction Stop
        }
        
        # Traitement du workflow...
    }
    catch [System.ArgumentException] {
        Write-Error -Message "Format JSON invalide: $_" -ErrorAction Continue
        return [PSCustomObject]@{
            HasCycles = $false
            Cycles = @()
            WorkflowName = [System.IO.Path]::GetFileNameWithoutExtension($WorkflowPath)
        }
    }
    catch {
        Write-Error -Message "Erreur lors de l'analyse du workflow: $_" -ErrorAction Continue
        return [PSCustomObject]@{
            HasCycles = $false
            Cycles = @()
            WorkflowName = [System.IO.Path]::GetFileNameWithoutExtension($WorkflowPath)
        }
    }
    
    # Suite de la fonction...
}
```

## Niveaux de gravité

Le module utilise les niveaux de gravité suivants pour les erreurs et avertissements :

### 1. Erreurs fatales (Terminating Errors)

Ces erreurs arrêtent l'exécution de la fonction et sont générées avec `Write-Error -ErrorAction Stop`.

#### Exemples
- Paramètres obligatoires manquants ou invalides
- Ressources essentielles inaccessibles
- Conditions préalables non remplies

### 2. Erreurs non fatales (Non-Terminating Errors)

Ces erreurs sont signalées mais n'arrêtent pas l'exécution de la fonction. Elles sont générées avec `Write-Error -ErrorAction Continue`.

#### Exemples
- Échec du traitement d'un fichier spécifique
- Timeout lors de l'analyse
- Erreurs récupérables

### 3. Avertissements (Warnings)

Ces messages signalent des conditions potentiellement problématiques mais qui n'empêchent pas le fonctionnement du module. Ils sont générés avec `Write-Warning`.

#### Exemples
- Performance dégradée
- Utilisation de fonctionnalités obsolètes
- Résultats potentiellement incomplets

### 4. Informations verboses (Verbose)

Ces messages fournissent des informations détaillées sur le fonctionnement interne du module. Ils sont générés avec `Write-Verbose`.

#### Exemples
- Progression de l'analyse
- Détails des calculs
- Informations de débogage

## Codes d'erreur

Le module utilise les codes d'erreur suivants pour faciliter l'identification des problèmes :

| Code | Description | Type |
|------|-------------|------|
| CD001 | Paramètre invalide | Erreur fatale |
| CD002 | Ressource inaccessible | Erreur fatale |
| CD003 | Format invalide | Erreur non fatale |
| CD004 | Timeout | Erreur non fatale |
| CD005 | Mémoire insuffisante | Erreur non fatale |
| CD006 | Limite de profondeur atteinte | Avertissement |
| CD007 | Performance dégradée | Avertissement |
| CD008 | Résultat incomplet | Avertissement |

## Journalisation des erreurs

Le module journalise les erreurs pour faciliter le débogage et l'analyse des problèmes.

### Stratégie de journalisation

1. **Journalisation interne** : Les erreurs sont enregistrées dans une variable interne du module.
2. **Journalisation dans le flux d'erreurs** : Les erreurs sont écrites dans le flux d'erreurs de PowerShell.
3. **Journalisation dans un fichier** : Les erreurs peuvent être écrites dans un fichier de journal si configuré.

### Exemple de code

```powershell
$script:ErrorLog = @()

function Write-CycleDetectorLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("ERROR", "WARNING", "INFO", "VERBOSE")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorCode = ""
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = [PSCustomObject]@{
        Timestamp = $timestamp
        Level = $Level
        ErrorCode = $ErrorCode
        Message = $Message
    }
    
    $script:ErrorLog += $logEntry
    
    switch ($Level) {
        "ERROR" {
            if ($ErrorCode) {
                Write-Error -Message "[$ErrorCode] $Message"
            }
            else {
                Write-Error -Message $Message
            }
        }
        "WARNING" {
            if ($ErrorCode) {
                Write-Warning -Message "[$ErrorCode] $Message"
            }
            else {
                Write-Warning -Message $Message
            }
        }
        "INFO" {
            Write-Host $Message
        }
        "VERBOSE" {
            Write-Verbose $Message
        }
    }
    
    # Si la journalisation dans un fichier est configurée
    if ($script:LogFilePath) {
        "$timestamp [$Level] $ErrorCode $Message" | Out-File -FilePath $script:LogFilePath -Append
    }
}

function Get-CycleDetectorErrorLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("ERROR", "WARNING", "INFO", "VERBOSE")]
        [string[]]$Levels = @("ERROR", "WARNING", "INFO", "VERBOSE"),
        
        [Parameter(Mandatory = $false)]
        [int]$Last = 0
    )
    
    $filteredLog = $script:ErrorLog | Where-Object { $Levels -contains $_.Level }
    
    if ($Last -gt 0) {
        $filteredLog = $filteredLog | Select-Object -Last $Last
    }
    
    return $filteredLog
}

function Clear-CycleDetectorErrorLog {
    [CmdletBinding()]
    param ()
    
    $script:ErrorLog = @()
}
```

## Cas limites et leur gestion

### 1. Graphes vides

```powershell
if ($Graph.Count -eq 0) {
    Write-CycleDetectorLog -Message "Le graphe est vide." -Level "WARNING" -ErrorCode "CD001"
    return [PSCustomObject]@{
        HasCycle = $false
        CyclePath = @()
    }
}
```

### 2. Graphes déconnectés

```powershell
$connectedComponents = 0
$visited = @{}

foreach ($node in $Graph.Keys) {
    if (-not $visited.ContainsKey($node)) {
        $connectedComponents++
        # Marquer tous les nœuds accessibles depuis ce nœud comme visités
        # ...
    }
}

if ($connectedComponents -gt 1) {
    Write-CycleDetectorLog -Message "Le graphe contient $connectedComponents composantes connexes." -Level "VERBOSE"
}
```

### 3. Boucles sur un seul nœud

```powershell
foreach ($node in $Graph.Keys) {
    if ($Graph[$node] -contains $node) {
        Write-CycleDetectorLog -Message "Boucle détectée sur le nœud '$node'." -Level "INFO"
        return [PSCustomObject]@{
            HasCycle = $true
            CyclePath = @($node, $node)
        }
    }
}
```

### 4. Nœuds manquants

```powershell
foreach ($node in $Graph.Keys) {
    foreach ($neighbor in $Graph[$node]) {
        if (-not $Graph.ContainsKey($neighbor)) {
            Write-CycleDetectorLog -Message "Le nœud '$neighbor' est référencé mais n'existe pas dans le graphe." -Level "WARNING" -ErrorCode "CD003"
            # Ajouter le nœud manquant au graphe
            $Graph[$neighbor] = @()
        }
    }
}
```

### 5. Graphes très grands

```powershell
if ($Graph.Keys.Count -gt 10000) {
    Write-CycleDetectorLog -Message "Le graphe est très grand ($($Graph.Keys.Count) nœuds). L'analyse peut prendre du temps." -Level "WARNING" -ErrorCode "CD007"
    
    # Utiliser l'implémentation itérative optimisée
    $useIterative = $true
}
```

## Conclusion

Cette stratégie de gestion des erreurs fournit un cadre robuste pour détecter, signaler et gérer les erreurs dans le module `CycleDetector.psm1`. En suivant ces principes et en utilisant les mécanismes décrits, le module sera plus fiable, plus facile à déboguer et offrira une meilleure expérience utilisateur.
