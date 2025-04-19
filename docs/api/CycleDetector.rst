.. CycleDetector API documentation

Module CycleDetector
===================

Le module ``CycleDetector`` fournit des fonctionnalités pour détecter et corriger les cycles dans différents types de graphes, notamment les dépendances de scripts et les workflows n8n.

Fonctions principales
--------------------

Initialize-CycleDetector
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Initialize-CycleDetector [-Enabled <Boolean>] [-MaxDepth <Int32>] [-CacheEnabled <Boolean>]

Initialise le détecteur de cycles avec les paramètres spécifiés.

Paramètres:
    * **Enabled** (*Boolean*) - Active ou désactive le détecteur de cycles. Valeur par défaut : $true
    * **MaxDepth** (*Int32*) - Profondeur maximale de recherche pour la détection de cycles. Valeur par défaut : 100
    * **CacheEnabled** (*Boolean*) - Active ou désactive la mise en cache des résultats. Valeur par défaut : $true

Valeur de retour:
    Booléen indiquant si l'initialisation a réussi.

Exemple:

.. code-block:: powershell

    # Initialiser le détecteur de cycles avec une profondeur maximale de 50
    Initialize-CycleDetector -Enabled $true -MaxDepth 50 -CacheEnabled $true

Find-Cycle
~~~~~~~~~

.. code-block:: powershell

    Find-Cycle -Graph <Hashtable> [-MaxDepth <Int32>] [-SkipCache]

Détecte les cycles dans un graphe générique.

Paramètres:
    * **Graph** (*Hashtable*) - Le graphe à analyser, représenté sous forme de table de hachage où les clés sont les nœuds et les valeurs sont des tableaux de nœuds adjacents.
    * **MaxDepth** (*Int32*) - Profondeur maximale de recherche pour la détection de cycles. Si non spécifié, utilise la valeur définie lors de l'initialisation.
    * **SkipCache** (*Switch*) - Ignore la mise en cache des résultats.

Valeur de retour:
    Un objet avec les propriétés suivantes:
    
    * **HasCycle** (*Boolean*) - Indique si un cycle a été détecté.
    * **CyclePath** (*Array*) - Le chemin du cycle détecté, ou un tableau vide si aucun cycle n'a été détecté.

Exemple:

.. code-block:: powershell

    # Créer un graphe avec un cycle
    $graph = @{
        "A" = @("B")
        "B" = @("C")
        "C" = @("A")
    }
    
    # Détecter les cycles
    $result = Find-Cycle -Graph $graph
    
    if ($result.HasCycle) {
        Write-Host "Cycle détecté: $($result.CyclePath -join ' -> ')"
    }

Find-ScriptDependencyCycles
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Find-ScriptDependencyCycles -Path <String> [-Recursive] [-GenerateGraph] [-GraphOutputPath <String>] [-SkipCache]

Analyse les dépendances entre les scripts PowerShell pour détecter les cycles.

Paramètres:
    * **Path** (*String*) - Chemin du dossier ou fichier à analyser.
    * **Recursive** (*Switch*) - Analyse récursivement les sous-dossiers.
    * **GenerateGraph** (*Switch*) - Génère une visualisation du graphe de dépendances.
    * **GraphOutputPath** (*String*) - Chemin de sortie pour la visualisation du graphe.
    * **SkipCache** (*Switch*) - Ignore la mise en cache des résultats.

Valeur de retour:
    Un objet avec les propriétés suivantes:
    
    * **HasCycles** (*Boolean*) - Indique si des cycles ont été détectés.
    * **Cycles** (*Array*) - Tableau des cycles détectés.
    * **NonCyclicScripts** (*Array*) - Scripts sans dépendances cycliques.
    * **DependencyGraph** (*Hashtable*) - Graphe de dépendances complet.
    * **ScriptFiles** (*Array*) - Liste des fichiers de scripts analysés.

Exemple:

.. code-block:: powershell

    # Analyser les dépendances dans un dossier de scripts
    $result = Find-ScriptDependencyCycles -Path ".\scripts" -Recursive -GenerateGraph -GraphOutputPath ".\dependency_graph.html"
    
    if ($result.HasCycles) {
        Write-Host "Cycles détectés dans les scripts suivants:"
        foreach ($cycle in $result.Cycles) {
            Write-Host "- $($cycle -join ' -> ')"
        }
    }

Test-WorkflowCycles
~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Test-WorkflowCycles -WorkflowPath <String> [-SkipCache]

Teste les workflows n8n pour détecter les cycles.

Paramètres:
    * **WorkflowPath** (*String*) - Chemin du fichier de workflow n8n à analyser.
    * **SkipCache** (*Switch*) - Ignore la mise en cache des résultats.

Valeur de retour:
    Un objet avec les propriétés suivantes:
    
    * **HasCycle** (*Boolean*) - Indique si un cycle a été détecté.
    * **WorkflowPath** (*String*) - Chemin du fichier de workflow analysé.
    * **CyclePath** (*Array*) - Le chemin du cycle détecté, ou un tableau vide si aucun cycle n'a été détecté.

Exemple:

.. code-block:: powershell

    # Tester un workflow n8n pour détecter les cycles
    $result = Test-WorkflowCycles -WorkflowPath ".\workflows\my_workflow.json"
    
    if ($result.HasCycle) {
        Write-Host "Cycle détecté dans le workflow: $($result.CyclePath -join ' -> ')"
    }

Remove-Cycle
~~~~~~~~~~

.. code-block:: powershell

    Remove-Cycle -CycleResult <Object> [-Force]

Supprime un cycle détecté en supprimant une connexion.

Paramètres:
    * **CycleResult** (*Object*) - Le résultat de la détection de cycle (objet retourné par Find-Cycle, Find-ScriptDependencyCycles ou Test-WorkflowCycles).
    * **Force** (*Switch*) - Force la suppression du cycle sans confirmation.

Valeur de retour:
    Booléen indiquant si le cycle a été supprimé avec succès.

Exemple:

.. code-block:: powershell

    # Détecter les cycles dans un graphe
    $graph = @{
        "A" = @("B")
        "B" = @("C")
        "C" = @("A")
    }
    $cycleResult = Find-Cycle -Graph $graph
    
    # Supprimer le cycle
    if ($cycleResult.HasCycle) {
        $removed = Remove-Cycle -CycleResult $cycleResult -Force
        if ($removed) {
            Write-Host "Cycle supprimé avec succès"
        }
    }

Get-CycleDetectionStatistics
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Get-CycleDetectionStatistics

Récupère les statistiques de détection de cycles.

Valeur de retour:
    Un objet avec les propriétés suivantes:
    
    * **TotalCalls** (*Int32*) - Nombre total d'appels à Find-Cycle.
    * **TotalCycles** (*Int32*) - Nombre total de cycles détectés.
    * **CacheHits** (*Int32*) - Nombre de fois où un résultat a été récupéré du cache.
    * **CacheMisses** (*Int32*) - Nombre de fois où un résultat n'a pas été trouvé dans le cache.
    * **AverageExecutionTime** (*Double*) - Temps d'exécution moyen en millisecondes.

Exemple:

.. code-block:: powershell

    # Récupérer les statistiques de détection de cycles
    $stats = Get-CycleDetectionStatistics
    Write-Host "Nombre total d'appels: $($stats.TotalCalls)"
    Write-Host "Nombre total de cycles détectés: $($stats.TotalCycles)"
    Write-Host "Taux de succès du cache: $(($stats.CacheHits / ($stats.CacheHits + $stats.CacheMisses)) * 100)%"

Clear-CycleDetectionCache
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Clear-CycleDetectionCache

Vide le cache de détection de cycles.

Valeur de retour:
    Booléen indiquant si le cache a été vidé avec succès.

Exemple:

.. code-block:: powershell

    # Vider le cache de détection de cycles
    Clear-CycleDetectionCache

Export-CycleVisualization
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Export-CycleVisualization -Graph <Hashtable> -OutputPath <String> [-Format <String>]

Exporte une visualisation du graphe de dépendances.

Paramètres:
    * **Graph** (*Hashtable*) - Le graphe à visualiser.
    * **OutputPath** (*String*) - Chemin de sortie pour la visualisation.
    * **Format** (*String*) - Format de sortie (HTML, DOT, PNG). Par défaut : HTML.

Valeur de retour:
    Booléen indiquant si la visualisation a été exportée avec succès.

Exemple:

.. code-block:: powershell

    # Créer un graphe
    $graph = @{
        "A" = @("B", "C")
        "B" = @("D")
        "C" = @("D")
        "D" = @()
    }
    
    # Exporter la visualisation
    Export-CycleVisualization -Graph $graph -OutputPath ".\graph.html" -Format "HTML"

Get-ScriptDependencyReport
~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Get-ScriptDependencyReport -Path <String> [-Recursive] [-GenerateGraph] [-GraphOutputPath <String>] [-SkipCache]

Génère un rapport détaillé sur les dépendances entre les scripts.

Paramètres:
    * **Path** (*String*) - Chemin du dossier ou fichier à analyser.
    * **Recursive** (*Switch*) - Analyse récursivement les sous-dossiers.
    * **GenerateGraph** (*Switch*) - Génère une visualisation du graphe de dépendances.
    * **GraphOutputPath** (*String*) - Chemin de sortie pour la visualisation du graphe.
    * **SkipCache** (*Switch*) - Ignore la mise en cache des résultats.

Valeur de retour:
    Un objet avec les propriétés suivantes:
    
    * **Result** (*Object*) - Résultat de l'analyse des dépendances (même format que Find-ScriptDependencyCycles).
    * **Statistics** (*Object*) - Statistiques sur les dépendances (nombre de dépendances par script, script avec le plus de dépendances, etc.).

Exemple:

.. code-block:: powershell

    # Générer un rapport de dépendances
    $report = Get-ScriptDependencyReport -Path ".\scripts" -Recursive -GenerateGraph -GraphOutputPath ".\dependency_graph.html"
    
    # Afficher les statistiques
    Write-Host "Nombre total de scripts: $($report.Result.ScriptFiles.Count)"
    Write-Host "Nombre de scripts avec des cycles: $($report.Result.Cycles.Count)"
    Write-Host "Script avec le plus de dépendances: $($report.Statistics.MostDependencies.Script) ($($report.Statistics.MostDependencies.Count) dépendances)"
