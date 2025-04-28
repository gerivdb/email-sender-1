.. CycleDetector Examples documentation

Exemples d'utilisation du module CycleDetector
============================================

Cette page contient des exemples concrets d'utilisation du module ``CycleDetector`` pour détecter et corriger les cycles dans différents types de graphes.

Exemple 1: Détection de cycles dans un graphe simple
--------------------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\CycleDetector.psm1" -Force
    
    # Initialiser le détecteur de cycles
    Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
    
    # Créer un graphe avec un cycle
    $graph = @{
        "A" = @("B")
        "B" = @("C")
        "C" = @("A")
    }
    
    # Détecter les cycles
    $result = Find-Cycle -Graph $graph
    
    # Afficher le résultat
    if ($result.HasCycle) {
        Write-Host "Cycle détecté: $($result.CyclePath -join ' -> ')"
    } else {
        Write-Host "Aucun cycle détecté"
    }
    
    # Supprimer le cycle
    if ($result.HasCycle) {
        $removed = Remove-Cycle -CycleResult $result -Force
        if ($removed) {
            Write-Host "Cycle supprimé avec succès"
            
            # Vérifier que le cycle a bien été supprimé
            $newResult = Find-Cycle -Graph $graph
            if (-not $newResult.HasCycle) {
                Write-Host "Le graphe ne contient plus de cycle"
            }
        }
    }

Exemple 2: Analyse des dépendances entre scripts PowerShell
---------------------------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\CycleDetector.psm1" -Force
    
    # Initialiser le détecteur de cycles
    Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
    
    # Analyser les dépendances dans un dossier de scripts
    $result = Find-ScriptDependencyCycles -Path ".\development\scripts" -Recursive -GenerateGraph -GraphOutputPath ".\dependency_graph.html"
    
    # Afficher le résultat
    if ($result.HasCycles) {
        Write-Host "Cycles détectés dans les scripts suivants:"
        foreach ($cycle in $result.Cycles) {
            Write-Host "- $($cycle -join ' -> ')"
        }
        
        Write-Host "`nScripts sans dépendances cycliques:"
        foreach ($script in $result.NonCyclicScripts) {
            Write-Host "- $script"
        }
    } else {
        Write-Host "Aucun cycle détecté dans les scripts"
        Write-Host "`nListe des scripts analysés:"
        foreach ($script in $result.ScriptFiles) {
            Write-Host "- $script"
        }
    }
    
    # Générer un rapport détaillé
    $report = Get-ScriptDependencyReport -Path ".\development\scripts" -Recursive
    
    # Afficher les statistiques
    Write-Host "`nStatistiques:"
    Write-Host "Nombre total de scripts: $($report.Result.ScriptFiles.Count)"
    if ($report.Statistics.MostDependencies) {
        Write-Host "Script avec le plus de dépendances: $($report.Statistics.MostDependencies.Script) ($($report.Statistics.MostDependencies.Count) dépendances)"
    }

Exemple 3: Détection de cycles dans un workflow n8n
-------------------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\CycleDetector.psm1" -Force
    
    # Initialiser le détecteur de cycles
    Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
    
    # Tester un workflow n8n pour détecter les cycles
    $result = Test-WorkflowCycles -WorkflowPath ".\workflows\my_workflow.json"
    
    # Afficher le résultat
    if ($result.HasCycle) {
        Write-Host "Cycle détecté dans le workflow: $($result.CyclePath -join ' -> ')"
    } else {
        Write-Host "Aucun cycle détecté dans le workflow"
    }

Exemple 4: Utilisation du cache pour améliorer les performances
------------------------------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\CycleDetector.psm1" -Force
    
    # Initialiser le détecteur de cycles avec cache activé
    Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
    
    # Créer un graphe complexe
    $graph = @{}
    for ($i = 1; $i -le 100; $i++) {
        $graph["Node$i"] = @()
        for ($j = 1; $j -le 5; $j++) {
            $target = "Node$((($i + $j) % 100) + 1)"
            $graph["Node$i"] += $target
        }
    }
    
    # Ajouter un cycle
    $graph["Node50"] += "Node25"
    $graph["Node25"] += "Node10"
    $graph["Node10"] += "Node50"
    
    # Mesurer le temps d'exécution sans cache
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result1 = Find-Cycle -Graph $graph -SkipCache
    $stopwatch.Stop()
    $timeWithoutCache = $stopwatch.ElapsedMilliseconds
    
    # Mesurer le temps d'exécution avec cache
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result2 = Find-Cycle -Graph $graph  # Utilise le cache
    $stopwatch.Stop()
    $timeWithCache = $stopwatch.ElapsedMilliseconds
    
    # Afficher les résultats
    Write-Host "Temps d'exécution sans cache: $timeWithoutCache ms"
    Write-Host "Temps d'exécution avec cache: $timeWithCache ms"
    Write-Host "Amélioration des performances: $(100 - ($timeWithCache / $timeWithoutCache * 100))%"
    
    # Afficher les statistiques du cache
    $stats = Get-CycleDetectionStatistics
    Write-Host "`nStatistiques du cache:"
    Write-Host "Nombre total d'appels: $($stats.TotalCalls)"
    Write-Host "Nombre de hits du cache: $($stats.CacheHits)"
    Write-Host "Nombre de misses du cache: $($stats.CacheMisses)"
    Write-Host "Taux de succès du cache: $(($stats.CacheHits / ($stats.CacheHits + $stats.CacheMisses)) * 100)%"
    
    # Vider le cache
    Clear-CycleDetectionCache
    Write-Host "`nCache vidé"

Exemple 5: Visualisation des graphes de dépendances
-------------------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\CycleDetector.psm1" -Force
    
    # Initialiser le détecteur de cycles
    Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
    
    # Créer un graphe
    $graph = @{
        "Module A" = @("Module B", "Module C")
        "Module B" = @("Module D", "Module E")
        "Module C" = @("Module F")
        "Module D" = @("Module G")
        "Module E" = @("Module G")
        "Module F" = @("Module G")
        "Module G" = @()
    }
    
    # Exporter la visualisation au format HTML
    Export-CycleVisualization -Graph $graph -OutputPath ".\graph.html" -Format "HTML"
    Write-Host "Visualisation HTML exportée avec succès: .\graph.html"
    
    # Exporter la visualisation au format DOT (pour Graphviz)
    Export-CycleVisualization -Graph $graph -OutputPath ".\graph.dot" -Format "DOT"
    Write-Host "Visualisation DOT exportée avec succès: .\graph.dot"
    
    # Si Graphviz est installé, convertir le fichier DOT en PNG
    if (Get-Command "dot" -ErrorAction SilentlyContinue) {
        dot -Tpng -o ".\graph.png" ".\graph.dot"
        Write-Host "Visualisation PNG exportée avec succès: .\graph.png"
    }
