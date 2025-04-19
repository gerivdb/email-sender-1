.. DependencyManager Examples documentation

Exemples d'utilisation du module DependencyManager
===============================================

Cette page contient des exemples concrets d'utilisation du module ``DependencyManager`` pour gérer les dépendances entre les scripts, les modules et les workflows.

Exemple 1: Analyse des dépendances d'un script
--------------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\DependencyManager.psm1" -Force
    
    # Initialiser le gestionnaire de dépendances
    Initialize-DependencyManager -Enabled $true -CacheEnabled $true -MaxDepth 100
    
    # Analyser les dépendances d'un script
    $dependencies = Get-ScriptDependencies -Path ".\scripts\main.ps1" -IncludeExternal
    
    # Afficher les dépendances
    Write-Host "Dépendances du script $($dependencies.ScriptPath):"
    foreach ($dep in $dependencies.Dependencies) {
        Write-Host "- $dep"
    }
    
    Write-Host "`nDépendances externes:"
    foreach ($extDep in $dependencies.ExternalDependencies) {
        Write-Host "- $extDep"
    }
    
    # Exporter le graphe de dépendances
    Export-DependencyGraph -Path ".\scripts\main.ps1" -OutputPath ".\main_dependencies.html" -Format "HTML" -IncludeExternal

Exemple 2: Résolution de l'ordre d'exécution des scripts
------------------------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\DependencyManager.psm1" -Force
    
    # Initialiser le gestionnaire de dépendances
    Initialize-DependencyManager -Enabled $true -CacheEnabled $true -MaxDepth 100
    
    # Résoudre l'ordre d'exécution des scripts
    $order = Resolve-DependencyOrder -Path ".\scripts" -Recursive -OutputPath ".\execution_order.json" -Format "JSON"
    
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
    
    # Créer un script d'exécution automatique
    $executionScript = @"
# Script d'exécution automatique généré par DependencyManager
# Date de génération: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Ordre d'exécution des scripts
$($order.ExecutionOrder | ForEach-Object { ". '$_'" })
"@
    
    Set-Content -Path ".\run_scripts.ps1" -Value $executionScript
    Write-Host "`nScript d'exécution automatique généré: .\run_scripts.ps1"

Exemple 3: Test des dépendances d'un module PowerShell
----------------------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\DependencyManager.psm1" -Force
    
    # Initialiser le gestionnaire de dépendances
    Initialize-DependencyManager -Enabled $true -CacheEnabled $true -MaxDepth 100
    
    # Tester les dépendances d'un module
    $moduleDeps = Test-ModuleDependencies -ModulePath ".\modules\MyModule" -IncludeVersion -CheckAvailability
    
    # Afficher les dépendances
    Write-Host "Dépendances du module $($moduleDeps.ModuleName):"
    foreach ($dep in $moduleDeps.Dependencies) {
        $status = if ($moduleDeps.MissingDependencies -contains $dep) { "Manquant" } else { "Disponible" }
        Write-Host "- $($dep.Name) $(if ($dep.Version) { "($($dep.Version))" }) - $status"
    }
    
    # Installer les dépendances manquantes
    if ($moduleDeps.MissingDependencies.Count -gt 0) {
        Write-Host "`nInstallation des dépendances manquantes..."
        $installResult = Install-Dependencies -Path ".\modules\MyModule" -Scope "CurrentUser"
        
        Write-Host "`nRésultat de l'installation:"
        Write-Host "Dépendances installées: $($installResult.InstalledDependencies.Count)"
        Write-Host "Dépendances déjà installées: $($installResult.AlreadyInstalledDependencies.Count)"
        Write-Host "Échecs d'installation: $($installResult.FailedDependencies.Count)"
    }

Exemple 4: Génération de statistiques sur les dépendances
-------------------------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\DependencyManager.psm1" -Force
    
    # Initialiser le gestionnaire de dépendances
    Initialize-DependencyManager -Enabled $true -CacheEnabled $true -MaxDepth 100
    
    # Générer des statistiques sur les dépendances
    $stats = Get-DependencyStatistics -Path ".\scripts" -Recursive -IncludeExternal
    
    # Afficher les statistiques
    Write-Host "Statistiques de dépendances:"
    Write-Host "Nombre de scripts: $($stats.ScriptCount)"
    Write-Host "Nombre total de dépendances: $($stats.TotalDependencies)"
    Write-Host "Nombre moyen de dépendances par script: $($stats.AverageDependenciesPerScript)"
    
    if ($stats.MaxDependencies) {
        Write-Host "Script avec le plus de dépendances: $($stats.MaxDependencies.Script) ($($stats.MaxDependencies.Count) dépendances)"
    }
    
    if ($stats.MinDependencies) {
        Write-Host "Script avec le moins de dépendances: $($stats.MinDependencies.Script) ($($stats.MinDependencies.Count) dépendances)"
    }
    
    if ($stats.CyclicDependencies.Count -gt 0) {
        Write-Host "`nDépendances cycliques détectées:"
        foreach ($cycle in $stats.CyclicDependencies) {
            Write-Host "- $($cycle -join ' -> ')"
        }
    }
    
    # Exporter les statistiques au format JSON
    $stats | ConvertTo-Json -Depth 5 | Set-Content -Path ".\dependency_statistics.json"
    Write-Host "`nStatistiques exportées: .\dependency_statistics.json"

Exemple 5: Optimisation des dépendances
-------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\DependencyManager.psm1" -Force
    
    # Initialiser le gestionnaire de dépendances
    Initialize-DependencyManager -Enabled $true -CacheEnabled $true -MaxDepth 100
    
    # Analyser et obtenir des suggestions d'optimisation
    $optimization = Optimize-Dependencies -Path ".\scripts" -Recursive -OutputPath ".\optimization_report.json"
    
    # Afficher les suggestions d'optimisation
    Write-Host "Nombre de scripts analysés: $($optimization.ScriptsAnalyzed)"
    Write-Host "Suggestions d'optimisation:"
    foreach ($suggestion in $optimization.OptimizationSuggestions) {
        Write-Host "- $($suggestion.Script): $($suggestion.Description)"
    }
    
    # Demander confirmation pour appliquer les changements
    $confirmation = Read-Host "Voulez-vous appliquer les changements recommandés? (O/N)"
    if ($confirmation -eq "O") {
        # Appliquer les changements recommandés
        $appliedOptimization = Optimize-Dependencies -Path ".\scripts" -Recursive -ApplyChanges
        
        # Afficher les changements appliqués
        Write-Host "`nChangements appliqués:"
        foreach ($change in $appliedOptimization.AppliedChanges) {
            Write-Host "- $($change.Script): $($change.Description)"
        }
    }

Exemple 6: Intégration avec le module CycleDetector
-------------------------------------------------

.. code-block:: powershell

    # Importer les modules
    Import-Module -Path ".\modules\CycleDetector.psm1" -Force
    Import-Module -Path ".\modules\DependencyManager.psm1" -Force
    
    # Initialiser les modules
    Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
    Initialize-DependencyManager -Enabled $true -CacheEnabled $true -MaxDepth 100
    
    # Analyser les dépendances dans un dossier de scripts
    $dependencies = Get-ScriptDependencies -Path ".\scripts" -Recursive
    
    # Détecter les cycles dans le graphe de dépendances
    $cycleResult = Find-Cycle -Graph $dependencies.DependencyGraph
    
    if ($cycleResult.HasCycle) {
        Write-Host "Cycle détecté dans les dépendances: $($cycleResult.CyclePath -join ' -> ')"
        
        # Résoudre l'ordre d'exécution en tenant compte des cycles
        $order = Resolve-DependencyOrder -Path ".\scripts" -Recursive -OutputPath ".\execution_order.json" -Format "JSON"
        
        Write-Host "`nOrdre d'exécution résolu:"
        foreach ($script in $order.ExecutionOrder) {
            Write-Host "- $script"
        }
        
        # Optimiser les dépendances pour éliminer les cycles
        Write-Host "`nOptimisation des dépendances pour éliminer les cycles..."
        $optimization = Optimize-Dependencies -Path ".\scripts" -Recursive -ApplyChanges
        
        # Vérifier si les cycles ont été éliminés
        $newDependencies = Get-ScriptDependencies -Path ".\scripts" -Recursive
        $newCycleResult = Find-Cycle -Graph $newDependencies.DependencyGraph
        
        if (-not $newCycleResult.HasCycle) {
            Write-Host "Les cycles ont été éliminés avec succès!"
        } else {
            Write-Host "Des cycles persistent dans les dépendances: $($newCycleResult.CyclePath -join ' -> ')"
        }
    } else {
        Write-Host "Aucun cycle détecté dans les dépendances."
    }
