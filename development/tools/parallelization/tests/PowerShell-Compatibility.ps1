# Test de compatibilité avec différentes versions de PowerShell (5.1 et 7.x)
# Ce script vérifie que Wait-ForCompletedRunspace fonctionne correctement sur PowerShell 5.1 et 7.x

# Paramètres
param(
    [switch]$Verbose,
    [switch]$NoCleanup
)

# Fonction pour afficher les messages
function Write-TestMessage {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )

    $color = switch ($Type) {
        "Info" { "White" }
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Header" { "Cyan" }
        default { "White" }
    }

    Write-Host $Message -ForegroundColor $color
}

# Fonction pour créer un script de test temporaire
function New-TestScript {
    param(
        [string]$ScriptPath
    )

    $scriptContent = @'
# Script de test pour Wait-ForCompletedRunspace
# Ce script est exécuté par PowerShell-Compatibility.ps1 pour tester la compatibilité

# Importer le module UnifiedParallel
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel -Verbose:$VerbosePreference

# Fonction pour créer des runspaces de test
function New-TestRunspaces {
    param(
        [int]$Count = 10
    )

    # Créer un pool de runspaces
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
    $runspacePool.Open()

    # Créer une liste pour stocker les runspaces
    $runspaces = [System.Collections.Generic.List[object]]::new($Count)

    # Créer les runspaces
    for ($i = 0; $i -lt $Count; $i++) {
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $runspacePool

        # Ajouter un script simple
        [void]$powershell.AddScript({
                param($Item)
                Start-Sleep -Milliseconds (10 * ($Item % 5 + 1))
                return [PSCustomObject]@{
                    Item = $Item
                    PSVersion = $PSVersionTable.PSVersion.ToString()
                    ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                    StartTime = Get-Date
                    EndTime = Get-Date
                }
            })

        # Ajouter les paramètres
        [void]$powershell.AddParameter('Item', $i)

        # Démarrer l'exécution asynchrone
        $handle = $powershell.BeginInvoke()

        # Ajouter à la liste des runspaces
        $runspaces.Add([PSCustomObject]@{
                PowerShell = $powershell
                Handle     = $handle
                Item       = $i
                StartTime  = [datetime]::Now
            })
    }

    return @{
        Runspaces = $runspaces
        Pool = $runspacePool
    }
}

# Exécuter le test
try {
    # Afficher la version de PowerShell
    Write-Host "Version de PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    
    # Créer des runspaces de test
    $testData = New-TestRunspaces -Count 10
    $runspaces = $testData.Runspaces
    $pool = $testData.Pool
    
    # Mesurer le temps d'exécution
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Exécuter Wait-ForCompletedRunspace
    $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 30 -Verbose
    
    $stopwatch.Stop()
    $elapsedMs = $stopwatch.ElapsedMilliseconds
    
    # Traiter les résultats
    $processedResults = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress
    
    # Afficher les résultats
    Write-Host "Test réussi sur PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Green
    Write-Host "Temps d'exécution: $elapsedMs ms" -ForegroundColor Cyan
    Write-Host "Runspaces complétés: $($completedRunspaces.Count) sur 10" -ForegroundColor Cyan
    
    # Vérifier que tous les runspaces ont été complétés
    if ($completedRunspaces.Count -eq 10) {
        Write-Host "Tous les runspaces ont été complétés avec succès." -ForegroundColor Green
        $success = $true
    } else {
        Write-Host "Certains runspaces n'ont pas été complétés." -ForegroundColor Red
        $success = $false
    }
    
    # Retourner le résultat
    return @{
        Success = $success
        ElapsedTime = $elapsedMs
        CompletedCount = $completedRunspaces.Count
        PSVersion = $PSVersionTable.PSVersion.ToString()
    }
} catch {
    Write-Host "Erreur lors de l'exécution du test: $_" -ForegroundColor Red
    return @{
        Success = $false
        Error = $_
        PSVersion = $PSVersionTable.PSVersion.ToString()
    }
} finally {
    # Nettoyer
    if ($pool) {
        $pool.Close()
        $pool.Dispose()
    }
    
    Clear-UnifiedParallel -Verbose:$VerbosePreference
}
'@

    # Écrire le script dans un fichier temporaire
    $scriptContent | Out-File -FilePath $ScriptPath -Encoding utf8 -Force
    
    return $ScriptPath
}

# Fonction pour exécuter le test sur une version spécifique de PowerShell
function Test-PowerShellVersion {
    param(
        [string]$Version,
        [string]$Command
    )

    Write-TestMessage "Test de compatibilité avec PowerShell $Version..." -Type "Header"
    
    try {
        # Exécuter le test
        $output = & $Command
        
        # Vérifier le résultat
        if ($LASTEXITCODE -eq 0) {
            Write-TestMessage "Test réussi sur PowerShell $Version." -Type "Success"
            return $true
        } else {
            Write-TestMessage "Test échoué sur PowerShell $Version (code de sortie: $LASTEXITCODE)." -Type "Error"
            return $false
        }
    } catch {
        Write-TestMessage "Erreur lors de l'exécution du test sur PowerShell $Version: $_" -Type "Error"
        return $false
    }
}

# Créer un script de test temporaire
$testScriptPath = Join-Path -Path $env:TEMP -ChildPath "PS-Compatibility-Test.ps1"
New-TestScript -ScriptPath $testScriptPath

# Afficher les informations sur le système
Write-TestMessage "Test de compatibilité avec différentes versions de PowerShell" -Type "Header"
Write-TestMessage "Version de PowerShell actuelle: $($PSVersionTable.PSVersion)" -Type "Info"
Write-TestMessage "Script de test: $testScriptPath" -Type "Info"

# Tester PowerShell 5.1
$ps51Result = Test-PowerShellVersion -Version "5.1" -Command "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$testScriptPath`""

# Tester PowerShell 7.x
$ps7Result = Test-PowerShellVersion -Version "7.x" -Command "pwsh -NoProfile -ExecutionPolicy Bypass -File `"$testScriptPath`""

# Afficher le résumé
Write-TestMessage "`nRésumé des tests de compatibilité:" -Type "Header"
Write-TestMessage "PowerShell 5.1: $(if ($ps51Result) { 'Compatible ✅' } else { 'Non compatible ❌' })" -Type $(if ($ps51Result) { "Success" } else { "Error" })
Write-TestMessage "PowerShell 7.x: $(if ($ps7Result) { 'Compatible ✅' } else { 'Non compatible ❌' })" -Type $(if ($ps7Result) { "Success" } else { "Error" })

# Nettoyer
if (-not $NoCleanup) {
    Remove-Item -Path $testScriptPath -Force -ErrorAction SilentlyContinue
    Write-TestMessage "Script de test supprimé." -Type "Info"
}

# Retourner le résultat global
$overallResult = $ps51Result -and $ps7Result
Write-TestMessage "`nRésultat global: $(if ($overallResult) { 'Compatible avec toutes les versions ✅' } else { 'Incompatible avec certaines versions ❌' })" -Type $(if ($overallResult) { "Success" } else { "Error" })

return $overallResult
