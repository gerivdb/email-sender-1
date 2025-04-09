<#
.SYNOPSIS
    Exécute un traitement parallèle optimisé en utilisant des Runspace Pools.
.DESCRIPTION
    Ce script fournit une fonction pour exécuter un traitement parallèle optimisé
    en utilisant des Runspace Pools, qui sont plus performants que les Jobs PowerShell
    traditionnels. Compatible avec PowerShell 5.1.
.PARAMETER ScriptBlock
    Le bloc de script à exécuter pour chaque élément d'entrée.
.PARAMETER InputObject
    Les objets à traiter en parallèle.
.PARAMETER MaxThreads
    Le nombre maximum de threads à utiliser. Par défaut, utilise le nombre de processeurs + 1.
.PARAMETER ThrottleLimit
    Limite le nombre de tâches soumises simultanément pour éviter de surcharger le système.
.PARAMETER BatchSize
    Traite les éléments par lots de cette taille pour réduire les frais généraux.
.PARAMETER SharedVariables
    Hashtable de variables à partager avec tous les runspaces.
.EXAMPLE
    $files = Get-ChildItem -Path C:\Scripts -Filter *.ps1
    $results = $files | Invoke-OptimizedParallel -ScriptBlock {
        param($file)
        # Analyser le fichier
        $content = Get-Content -Path $file.FullName -Raw
        $lineCount = ($content -split "`n").Length
        return [PSCustomObject]@{
            File = $file.Name
            Lines = $lineCount
            Size = $file.Length
        }
    }
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Compatibilité: PowerShell 5.1 et supérieur
#>
function Invoke-OptimizedParallel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$InputObject,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$ThrottleLimit = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$BatchSize = 0,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$SharedVariables = @{}
    )
    
    begin {
        # Déterminer le nombre optimal de threads si non spécifié
        if ($MaxThreads -le 0) {
            $processorCount = [Environment]::ProcessorCount
            $MaxThreads = $processorCount + 1
            Write-Verbose "Nombre de threads automatiquement défini à $MaxThreads (processeurs + 1)"
        }
        
        # Définir la limite d'étranglement si non spécifiée
        if ($ThrottleLimit -le 0) {
            $ThrottleLimit = $MaxThreads * 2
            Write-Verbose "Limite d'étranglement automatiquement définie à $ThrottleLimit"
        }
        
        # Définir la taille de lot si non spécifiée
        if ($BatchSize -le 0) {
            # Taille de lot par défaut basée sur le nombre d'éléments et de threads
            $BatchSize = 1
            Write-Verbose "Taille de lot automatiquement définie à $BatchSize"
        }
        
        # Créer l'état de session initial pour partager des variables
        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        
        # Ajouter les variables partagées à l'état de session initial
        foreach ($key in $SharedVariables.Keys) {
            $value = $SharedVariables[$key]
            $variable = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new(
                $key, $value, "Variable partagée: $key"
            )
            $iss.Variables.Add($variable)
        }
        
        # Créer et ouvrir le pool de runspaces
        $runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(
            1,                  # Nombre minimum de runspaces
            $MaxThreads,        # Nombre maximum de runspaces
            $iss,               # État de session initial
            $Host               # Hôte PowerShell actuel
        )
        $runspacePool.Open()
        
        # Initialiser les collections pour stocker les tâches et les résultats
        $runspaces = [System.Collections.Generic.List[hashtable]]::new()
        $allItems = [System.Collections.Generic.List[object]]::new()
        $results = [System.Collections.Generic.List[object]]::new()
        
        # Compteurs pour le suivi
        $totalItems = 0
        $processedItems = 0
        $startTime = Get-Date
        
        Write-Verbose "Pool de runspaces initialisé avec $MaxThreads threads maximum"
    }
    
    process {
        # Collecter tous les éléments d'entrée
        foreach ($item in $InputObject) {
            $allItems.Add($item)
            $totalItems++
        }
    }
    
    end {
        try {
            # Traiter les éléments par lots
            for ($i = 0; $i -lt $allItems.Count; $i += $BatchSize) {
                # Créer un lot d'éléments
                $batch = $allItems | Select-Object -Skip $i -First $BatchSize
                
                # Attendre si nous avons atteint la limite d'étranglement
                while ($runspaces.Count -ge $ThrottleLimit) {
                    # Vérifier si des tâches sont terminées
                    for ($j = $runspaces.Count - 1; $j -ge 0; $j--) {
                        $handle = $runspaces[$j].Handle
                        
                        if ($handle.IsCompleted) {
                            # Récupérer les résultats
                            $powershell = $runspaces[$j].PowerShell
                            
                            try {
                                $batchResults = $powershell.EndInvoke($handle)
                                
                                if ($null -ne $batchResults) {
                                    foreach ($result in $batchResults) {
                                        $results.Add($result)
                                    }
                                }
                                
                                $processedItems += $runspaces[$j].Count
                            }
                            catch {
                                Write-Error "Erreur lors de la récupération des résultats: $_"
                            }
                            finally {
                                # Nettoyer les ressources
                                $powershell.Dispose()
                                $runspaces.RemoveAt($j)
                            }
                        }
                    }
                    
                    if ($runspaces.Count -ge $ThrottleLimit) {
                        Start-Sleep -Milliseconds 100
                    }
                }
                
                # Créer un nouveau PowerShell pour ce lot
                $powershell = [powershell]::Create()
                $powershell.RunspacePool = $runspacePool
                
                # Ajouter le script et les paramètres
                [void]$powershell.AddScript({
                    param($batch, $scriptBlock)
                    
                    $results = @()
                    
                    foreach ($item in $batch) {
                        try {
                            $result = & $scriptBlock $item
                            if ($null -ne $result) {
                                $results += $result
                            }
                        }
                        catch {
                            Write-Error "Erreur lors du traitement de l'élément: $_"
                        }
                    }
                    
                    return $results
                })
                [void]$powershell.AddParameter("batch", $batch)
                [void]$powershell.AddParameter("scriptBlock", $ScriptBlock)
                
                # Démarrer l'exécution asynchrone
                $handle = $powershell.BeginInvoke()
                
                # Stocker les informations sur cette tâche
                $runspaces.Add(@{
                    PowerShell = $powershell
                    Handle = $handle
                    Count = $batch.Count
                })
                
                # Afficher la progression
                $percentComplete = [math]::Min(100, [math]::Floor(($processedItems / $totalItems) * 100))
                Write-Progress -Activity "Traitement parallèle" -Status "$processedItems / $totalItems éléments traités" -PercentComplete $percentComplete
            }
            
            # Attendre que toutes les tâches soient terminées
            while ($runspaces.Count -gt 0) {
                for ($j = $runspaces.Count - 1; $j -ge 0; $j--) {
                    $handle = $runspaces[$j].Handle
                    
                    if ($handle.IsCompleted) {
                        # Récupérer les résultats
                        $powershell = $runspaces[$j].PowerShell
                        
                        try {
                            $batchResults = $powershell.EndInvoke($handle)
                            
                            if ($null -ne $batchResults) {
                                foreach ($result in $batchResults) {
                                    $results.Add($result)
                                }
                            }
                            
                            $processedItems += $runspaces[$j].Count
                        }
                        catch {
                            Write-Error "Erreur lors de la récupération des résultats: $_"
                        }
                        finally {
                            # Nettoyer les ressources
                            $powershell.Dispose()
                            $runspaces.RemoveAt($j)
                        }
                    }
                }
                
                if ($runspaces.Count -gt 0) {
                    Start-Sleep -Milliseconds 100
                }
                
                # Afficher la progression
                $percentComplete = [math]::Min(100, [math]::Floor(($processedItems / $totalItems) * 100))
                Write-Progress -Activity "Traitement parallèle" -Status "$processedItems / $totalItems éléments traités" -PercentComplete $percentComplete
            }
            
            # Terminer la barre de progression
            Write-Progress -Activity "Traitement parallèle" -Completed
            
            # Calculer les statistiques
            $endTime = Get-Date
            $duration = $endTime - $startTime
            
            Write-Verbose "Traitement terminé en $($duration.TotalSeconds) secondes"
            Write-Verbose "Éléments traités: $processedItems"
            Write-Verbose "Résultats obtenus: $($results.Count)"
            
            # Retourner les résultats
            return $results
        }
        finally {
            # Nettoyer les ressources
            if ($null -ne $runspacePool) {
                $runspacePool.Close()
                $runspacePool.Dispose()
            }
            
            foreach ($rs in $runspaces) {
                if ($null -ne $rs.PowerShell) {
                    $rs.PowerShell.Dispose()
                }
            }
        }
    }
}

# Exemple d'utilisation
<#
# Analyser tous les fichiers PowerShell dans un répertoire
$files = Get-ChildItem -Path "C:\Scripts" -Filter "*.ps1" -Recurse
$results = $files | Invoke-OptimizedParallel -ScriptBlock {
    param($file)
    
    # Analyser le fichier
    $content = Get-Content -Path $file.FullName -Raw
    $lineCount = ($content -split "`n").Length
    
    return [PSCustomObject]@{
        File = $file.Name
        Path = $file.FullName
        Lines = $lineCount
        Size = $file.Length
    }
} -MaxThreads 8 -Verbose

# Afficher les résultats
$results | Format-Table -AutoSize
#>

# Exporter la fonction
Export-ModuleMember -Function Invoke-OptimizedParallel
