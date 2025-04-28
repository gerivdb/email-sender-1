.. DependencyManager API documentation

Module DependencyManager
======================

Le module ``DependencyManager`` fournit des fonctionnalités pour gérer les dépendances entre les scripts, les modules et les workflows. Il permet de détecter, résoudre et optimiser les dépendances dans un projet.

Fonctions principales
--------------------

Initialize-DependencyManager
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Initialize-DependencyManager [-Enabled <Boolean>] [-CacheEnabled <Boolean>] [-MaxDepth <Int32>] [-ConfigPath <String>]

Initialise le gestionnaire de dépendances avec les paramètres spécifiés.

Paramètres:
    * **Enabled** (*Boolean*) - Active ou désactive le gestionnaire de dépendances. Valeur par défaut : $true
    * **CacheEnabled** (*Boolean*) - Active ou désactive la mise en cache des résultats. Valeur par défaut : $true
    * **MaxDepth** (*Int32*) - Profondeur maximale de recherche pour l'analyse des dépendances. Valeur par défaut : 100
    * **ConfigPath** (*String*) - Chemin du fichier de configuration. Valeur par défaut : ".\projet\config\dependency_manager.json"

Valeur de retour:
    Booléen indiquant si l'initialisation a réussi.

Exemple:

.. code-block:: powershell

    # Initialiser le gestionnaire de dépendances avec une profondeur maximale de 50
    Initialize-DependencyManager -Enabled $true -CacheEnabled $true -MaxDepth 50 -ConfigPath ".\projet\config\custom_dependency_config.json"

Get-ScriptDependencies
~~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Get-ScriptDependencies -Path <String> [-Recursive] [-IncludeExternal] [-ExcludePattern <String>]

Analyse les dépendances d'un script ou d'un dossier de scripts.

Paramètres:
    * **Path** (*String*) - Chemin du script ou du dossier à analyser.
    * **Recursive** (*Switch*) - Analyse récursivement les sous-dossiers.
    * **IncludeExternal** (*Switch*) - Inclut les dépendances externes (modules, assemblies, etc.).
    * **ExcludePattern** (*String*) - Expression régulière pour exclure certains fichiers ou dossiers.

Valeur de retour:
    Un objet avec les propriétés suivantes:
    
    * **ScriptPath** (*String*) - Chemin du script analysé.
    * **Dependencies** (*Array*) - Tableau des dépendances détectées.
    * **ExternalDependencies** (*Array*) - Tableau des dépendances externes (si IncludeExternal est spécifié).
    * **DependencyGraph** (*Hashtable*) - Graphe de dépendances complet.

Exemple:

.. code-block:: powershell

    # Analyser les dépendances d'un script
    $dependencies = Get-ScriptDependencies -Path ".\development\scripts\main.ps1" -IncludeExternal
    
    # Afficher les dépendances
    Write-Host "Dépendances du script $($dependencies.ScriptPath):"
    foreach ($dep in $dependencies.Dependencies) {
        Write-Host "- $dep"
    }
    
    Write-Host "`nDépendances externes:"
    foreach ($extDep in $dependencies.ExternalDependencies) {
        Write-Host "- $extDep"
    }

Resolve-DependencyOrder
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Resolve-DependencyOrder -Path <String> [-Recursive] [-OutputPath <String>] [-Format <String>]

Résout l'ordre d'exécution des scripts en fonction de leurs dépendances.

Paramètres:
    * **Path** (*String*) - Chemin du dossier contenant les scripts à analyser.
    * **Recursive** (*Switch*) - Analyse récursivement les sous-dossiers.
    * **OutputPath** (*String*) - Chemin de sortie pour le fichier d'ordre d'exécution.
    * **Format** (*String*) - Format de sortie (JSON, CSV, TXT). Par défaut : JSON.

Valeur de retour:
    Un objet avec les propriétés suivantes:
    
    * **ExecutionOrder** (*Array*) - Tableau des scripts dans l'ordre d'exécution.
    * **CyclicDependencies** (*Array*) - Tableau des dépendances cycliques détectées.
    * **OutputPath** (*String*) - Chemin du fichier de sortie (si spécifié).

Exemple:

.. code-block:: powershell

    # Résoudre l'ordre d'exécution des scripts
    $order = Resolve-DependencyOrder -Path ".\development\scripts" -Recursive -OutputPath ".\execution_order.json" -Format "JSON"
    
    # Afficher l'ordre d'exécution
    Write-Host "Ordre d'exécution des scripts:"
    foreach ($script in $order.ExecutionOrder) {
        Write-Host "- $script"
    }
    
    if ($order.CyclicDependencies.Count -gt 0) {
        Write-Host "`nAttention: Dépendances cycliques détectées:"
        foreach ($cycle in $order.CyclicDependencies) {
            Write-Host "- $($cycle -join ' -> ')"
        }
    }

Test-ModuleDependencies
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Test-ModuleDependencies -ModulePath <String> [-IncludeVersion] [-CheckAvailability]

Teste les dépendances d'un module PowerShell.

Paramètres:
    * **ModulePath** (*String*) - Chemin du module à analyser.
    * **IncludeVersion** (*Switch*) - Inclut les informations de version des dépendances.
    * **CheckAvailability** (*Switch*) - Vérifie la disponibilité des dépendances.

Valeur de retour:
    Un objet avec les propriétés suivantes:
    
    * **ModuleName** (*String*) - Nom du module analysé.
    * **ModulePath** (*String*) - Chemin du module analysé.
    * **Dependencies** (*Array*) - Tableau des dépendances détectées.
    * **MissingDependencies** (*Array*) - Tableau des dépendances manquantes (si CheckAvailability est spécifié).
    * **IsValid** (*Boolean*) - Indique si toutes les dépendances sont disponibles (si CheckAvailability est spécifié).

Exemple:

.. code-block:: powershell

    # Tester les dépendances d'un module
    $moduleDeps = Test-ModuleDependencies -ModulePath ".\modules\MyModule" -IncludeVersion -CheckAvailability
    
    # Afficher les dépendances
    Write-Host "Dépendances du module $($moduleDeps.ModuleName):"
    foreach ($dep in $moduleDeps.Dependencies) {
        Write-Host "- $($dep.Name) $(if ($dep.Version) { "($($dep.Version))" })"
    }
    
    if ($moduleDeps.MissingDependencies.Count -gt 0) {
        Write-Host "`nDépendances manquantes:"
        foreach ($missingDep in $moduleDeps.MissingDependencies) {
            Write-Host "- $($missingDep.Name) $(if ($missingDep.Version) { "($($missingDep.Version))" })"
        }
    }

Install-Dependencies
~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Install-Dependencies -Path <String> [-Scope <String>] [-Force]

Installe les dépendances manquantes d'un script ou d'un module.

Paramètres:
    * **Path** (*String*) - Chemin du script ou du module.
    * **Scope** (*String*) - Portée de l'installation (CurrentUser, AllUsers). Par défaut : CurrentUser.
    * **Force** (*Switch*) - Force l'installation des dépendances même si elles sont déjà installées.

Valeur de retour:
    Un objet avec les propriétés suivantes:
    
    * **InstalledDependencies** (*Array*) - Tableau des dépendances installées.
    * **FailedDependencies** (*Array*) - Tableau des dépendances dont l'installation a échoué.
    * **AlreadyInstalledDependencies** (*Array*) - Tableau des dépendances déjà installées.

Exemple:

.. code-block:: powershell

    # Installer les dépendances d'un script
    $result = Install-Dependencies -Path ".\development\scripts\main.ps1" -Scope "CurrentUser"
    
    # Afficher les résultats
    Write-Host "Dépendances installées:"
    foreach ($dep in $result.InstalledDependencies) {
        Write-Host "- $($dep.Name) $($dep.Version)"
    }
    
    if ($result.FailedDependencies.Count -gt 0) {
        Write-Host "`nDépendances dont l'installation a échoué:"
        foreach ($failedDep in $result.FailedDependencies) {
            Write-Host "- $($failedDep.Name) : $($failedDep.Error)"
        }
    }

Export-DependencyGraph
~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Export-DependencyGraph -Path <String> -OutputPath <String> [-Format <String>] [-IncludeExternal] [-Recursive]

Exporte le graphe de dépendances d'un script ou d'un dossier de scripts.

Paramètres:
    * **Path** (*String*) - Chemin du script ou du dossier à analyser.
    * **OutputPath** (*String*) - Chemin de sortie pour le graphe de dépendances.
    * **Format** (*String*) - Format de sortie (HTML, DOT, PNG, JSON). Par défaut : HTML.
    * **IncludeExternal** (*Switch*) - Inclut les dépendances externes.
    * **Recursive** (*Switch*) - Analyse récursivement les sous-dossiers.

Valeur de retour:
    Un objet avec les propriétés suivantes:
    
    * **OutputPath** (*String*) - Chemin du fichier de sortie.
    * **Format** (*String*) - Format de sortie.
    * **NodeCount** (*Int32*) - Nombre de nœuds dans le graphe.
    * **EdgeCount** (*Int32*) - Nombre d'arêtes dans le graphe.

Exemple:

.. code-block:: powershell

    # Exporter le graphe de dépendances
    $graph = Export-DependencyGraph -Path ".\development\scripts" -OutputPath ".\dependency_graph.html" -Format "HTML" -IncludeExternal -Recursive
    
    # Afficher les informations sur le graphe
    Write-Host "Graphe de dépendances exporté: $($graph.OutputPath)"
    Write-Host "Format: $($graph.Format)"
    Write-Host "Nombre de nœuds: $($graph.NodeCount)"
    Write-Host "Nombre d'arêtes: $($graph.EdgeCount)"

Get-DependencyStatistics
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Get-DependencyStatistics -Path <String> [-Recursive] [-IncludeExternal]

Génère des statistiques sur les dépendances d'un script ou d'un dossier de scripts.

Paramètres:
    * **Path** (*String*) - Chemin du script ou du dossier à analyser.
    * **Recursive** (*Switch*) - Analyse récursivement les sous-dossiers.
    * **IncludeExternal** (*Switch*) - Inclut les dépendances externes.

Valeur de retour:
    Un objet avec les propriétés suivantes:
    
    * **ScriptCount** (*Int32*) - Nombre de scripts analysés.
    * **TotalDependencies** (*Int32*) - Nombre total de dépendances.
    * **AverageDependenciesPerScript** (*Double*) - Nombre moyen de dépendances par script.
    * **MaxDependencies** (*Object*) - Script avec le plus de dépendances.
    * **MinDependencies** (*Object*) - Script avec le moins de dépendances.
    * **ExternalDependencies** (*Array*) - Tableau des dépendances externes (si IncludeExternal est spécifié).
    * **CyclicDependencies** (*Array*) - Tableau des dépendances cycliques détectées.

Exemple:

.. code-block:: powershell

    # Générer des statistiques sur les dépendances
    $stats = Get-DependencyStatistics -Path ".\development\scripts" -Recursive -IncludeExternal
    
    # Afficher les statistiques
    Write-Host "Statistiques de dépendances:"
    Write-Host "Nombre de scripts: $($stats.ScriptCount)"
    Write-Host "Nombre total de dépendances: $($stats.TotalDependencies)"
    Write-Host "Nombre moyen de dépendances par script: $($stats.AverageDependenciesPerScript)"
    Write-Host "Script avec le plus de dépendances: $($stats.MaxDependencies.Script) ($($stats.MaxDependencies.Count) dépendances)"
    Write-Host "Script avec le moins de dépendances: $($stats.MinDependencies.Script) ($($stats.MinDependencies.Count) dépendances)"
    
    if ($stats.CyclicDependencies.Count -gt 0) {
        Write-Host "`nDépendances cycliques détectées:"
        foreach ($cycle in $stats.CyclicDependencies) {
            Write-Host "- $($cycle -join ' -> ')"
        }
    }

Optimize-Dependencies
~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Optimize-Dependencies -Path <String> [-Recursive] [-OutputPath <String>] [-ApplyChanges]

Optimise les dépendances d'un script ou d'un dossier de scripts.

Paramètres:
    * **Path** (*String*) - Chemin du script ou du dossier à analyser.
    * **Recursive** (*Switch*) - Analyse récursivement les sous-dossiers.
    * **OutputPath** (*String*) - Chemin de sortie pour le rapport d'optimisation.
    * **ApplyChanges** (*Switch*) - Applique les changements recommandés.

Valeur de retour:
    Un objet avec les propriétés suivantes:
    
    * **ScriptsAnalyzed** (*Int32*) - Nombre de scripts analysés.
    * **OptimizationSuggestions** (*Array*) - Tableau des suggestions d'optimisation.
    * **AppliedChanges** (*Array*) - Tableau des changements appliqués (si ApplyChanges est spécifié).
    * **OutputPath** (*String*) - Chemin du fichier de rapport (si spécifié).

Exemple:

.. code-block:: powershell

    # Optimiser les dépendances
    $optimization = Optimize-Dependencies -Path ".\development\scripts" -Recursive -OutputPath ".\optimization_report.json"
    
    # Afficher les suggestions d'optimisation
    Write-Host "Nombre de scripts analysés: $($optimization.ScriptsAnalyzed)"
    Write-Host "Suggestions d'optimisation:"
    foreach ($suggestion in $optimization.OptimizationSuggestions) {
        Write-Host "- $($suggestion.Script): $($suggestion.Description)"
    }
    
    # Appliquer les changements recommandés
    $appliedOptimization = Optimize-Dependencies -Path ".\development\scripts" -Recursive -ApplyChanges
    
    # Afficher les changements appliqués
    Write-Host "`nChangements appliqués:"
    foreach ($change in $appliedOptimization.AppliedChanges) {
        Write-Host "- $($change.Script): $($change.Description)"
    }
