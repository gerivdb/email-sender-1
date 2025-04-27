# Find-SqlServerContradictoryPermission-Example.ps1
# Exemple d'utilisation de la fonction Find-SqlServerContradictoryPermission

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\RoadmapParser.psm1"
Import-Module $modulePath -Force

# Paramètres de connexion à SQL Server
$serverInstance = "localhost\SQLEXPRESS" # Remplacer par votre instance SQL Server
$loginName = "sa" # Remplacer par le login à analyser (optionnel)

# Exemple 1: Rechercher toutes les permissions contradictoires
Write-Host "Exemple 1: Rechercher toutes les permissions contradictoires"
Write-Host "--------------------------------------------------------"
try {
    $contradictions = Find-SqlServerContradictoryPermission -ServerInstance $serverInstance -Verbose
    
    if ($contradictions.Count -gt 0) {
        Write-Host "Nombre de contradictions trouvées: $($contradictions.Count)"
        foreach ($contradiction in $contradictions) {
            Write-Host $contradiction.ToString()
        }
    } else {
        Write-Host "Aucune contradiction trouvée."
    }
} catch {
    Write-Host "Erreur lors de la recherche des contradictions: $_" -ForegroundColor Red
}

Write-Host ""

# Exemple 2: Rechercher les contradictions pour un login spécifique
Write-Host "Exemple 2: Rechercher les contradictions pour un login spécifique"
Write-Host "-------------------------------------------------------------"
try {
    $contradictions = Find-SqlServerContradictoryPermission -ServerInstance $serverInstance -LoginName $loginName -Verbose
    
    if ($contradictions.Count -gt 0) {
        Write-Host "Nombre de contradictions trouvées pour $loginName: $($contradictions.Count)"
        foreach ($contradiction in $contradictions) {
            Write-Host $contradiction.GetDetailedDescription()
        }
    } else {
        Write-Host "Aucune contradiction trouvée pour $loginName."
    }
} catch {
    Write-Host "Erreur lors de la recherche des contradictions: $_" -ForegroundColor Red
}

Write-Host ""

# Exemple 3: Générer un rapport HTML des contradictions
Write-Host "Exemple 3: Générer un rapport HTML des contradictions"
Write-Host "---------------------------------------------------"
try {
    $htmlReport = Find-SqlServerContradictoryPermission -ServerInstance $serverInstance -OutputFormat HTML -Verbose
    
    # Enregistrer le rapport HTML dans un fichier
    $reportPath = Join-Path -Path $PSScriptRoot -ChildPath "ContradictoryPermissionsReport.html"
    $htmlReport | Out-File -FilePath $reportPath -Encoding utf8
    
    Write-Host "Rapport HTML généré: $reportPath"
    
    # Ouvrir le rapport dans le navigateur par défaut
    if (Test-Path -Path $reportPath) {
        Start-Process $reportPath
    }
} catch {
    Write-Host "Erreur lors de la génération du rapport HTML: $_" -ForegroundColor Red
}

Write-Host ""

# Exemple 4: Générer un rapport JSON des contradictions
Write-Host "Exemple 4: Générer un rapport JSON des contradictions"
Write-Host "---------------------------------------------------"
try {
    $jsonReport = Find-SqlServerContradictoryPermission -ServerInstance $serverInstance -OutputFormat JSON -Verbose
    
    # Enregistrer le rapport JSON dans un fichier
    $reportPath = Join-Path -Path $PSScriptRoot -ChildPath "ContradictoryPermissionsReport.json"
    $jsonReport | Out-File -FilePath $reportPath -Encoding utf8
    
    Write-Host "Rapport JSON généré: $reportPath"
} catch {
    Write-Host "Erreur lors de la génération du rapport JSON: $_" -ForegroundColor Red
}

Write-Host ""

# Exemple 5: Rechercher les contradictions d'un type spécifique
Write-Host "Exemple 5: Rechercher les contradictions d'un type spécifique"
Write-Host "-----------------------------------------------------------"
try {
    $contradictions = Find-SqlServerContradictoryPermission -ServerInstance $serverInstance -ContradictionType "GRANT/DENY" -Verbose
    
    if ($contradictions.Count -gt 0) {
        Write-Host "Nombre de contradictions GRANT/DENY trouvées: $($contradictions.Count)"
        foreach ($contradiction in $contradictions) {
            Write-Host $contradiction.ToString()
        }
    } else {
        Write-Host "Aucune contradiction GRANT/DENY trouvée."
    }
} catch {
    Write-Host "Erreur lors de la recherche des contradictions: $_" -ForegroundColor Red
}

Write-Host ""

# Exemple 6: Rechercher les contradictions pour une permission spécifique
Write-Host "Exemple 6: Rechercher les contradictions pour une permission spécifique"
Write-Host "-------------------------------------------------------------------"
try {
    $permissionName = "CONNECT SQL" # Remplacer par la permission à analyser
    $contradictions = Find-SqlServerContradictoryPermission -ServerInstance $serverInstance -PermissionName $permissionName -Verbose
    
    if ($contradictions.Count -gt 0) {
        Write-Host "Nombre de contradictions pour la permission $permissionName: $($contradictions.Count)"
        foreach ($contradiction in $contradictions) {
            Write-Host $contradiction.ToString()
        }
    } else {
        Write-Host "Aucune contradiction trouvée pour la permission $permissionName."
    }
} catch {
    Write-Host "Erreur lors de la recherche des contradictions: $_" -ForegroundColor Red
}

Write-Host ""

Write-Host "Exemples terminés."
