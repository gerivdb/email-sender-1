# Script de test simple pour Wait-ForCompletedRunspace
# Ce script teste la fonction Wait-ForCompletedRunspace de manière isolée

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel

Write-Host "Test 1: Vérification du type de retour avec un seul runspace" -ForegroundColor Cyan

# Créer un pool de runspaces
$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 2, $sessionState, $Host)
$runspacePool.Open()

# Créer une liste pour stocker les runspaces
$runspaces = New-Object System.Collections.ArrayList

# Créer un runspace rapide
$powershell = [powershell]::Create()
$powershell.RunspacePool = $runspacePool

# Ajouter un script simple
[void]$powershell.AddScript({
        Start-Sleep -Milliseconds 50
        return "Test type"
    })

# Démarrer l'exécution asynchrone
$handle = $powershell.BeginInvoke()

# Ajouter à la liste des runspaces
[void]$runspaces.Add([PSCustomObject]@{
        PowerShell = $powershell
        Handle     = $handle
        Item       = 1
    })

# Créer une copie de la liste des runspaces pour le test
$runspacesCopy = [System.Collections.Generic.List[PSObject]]::new()
foreach ($runspace in $runspaces) {
    $runspacesCopy.Add($runspace)
}

# Attendre le runspace
Write-Host "Attente du runspace..."
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -NoProgress -Verbose

# Vérifier le type de retour
Write-Host "Type de retour: $($completedRunspaces.GetType().FullName)"
Write-Host "Nombre d'éléments: $($completedRunspaces.Count)"
Write-Host "Type de Results: $($completedRunspaces.Results.GetType().FullName)"

if ($completedRunspaces.Count -eq 1) {
    Write-Host "Test réussi: Le nombre d'éléments est correct" -ForegroundColor Green
} else {
    Write-Host "Test échoué: Le nombre d'éléments est incorrect (attendu: 1, obtenu: $($completedRunspaces.Count))" -ForegroundColor Red
}

if ($completedRunspaces -is [PSCustomObject]) {
    Write-Host "Test réussi: Le type de retour est PSCustomObject" -ForegroundColor Green
} else {
    Write-Host "Test échoué: Le type de retour n'est pas PSCustomObject (obtenu: $($completedRunspaces.GetType().FullName))" -ForegroundColor Red
}

if ($completedRunspaces.Results -is [System.Collections.ArrayList]) {
    Write-Host "Test réussi: Le type de Results est ArrayList" -ForegroundColor Green
} else {
    Write-Host "Test échoué: Le type de Results n'est pas ArrayList (obtenu: $($completedRunspaces.Results.GetType().FullName))" -ForegroundColor Red
}

# Tester les méthodes
$firstRunspace = $completedRunspaces.GetFirst()
if ($null -ne $firstRunspace -and $null -ne $firstRunspace.PowerShell) {
    Write-Host "Test réussi: La méthode GetFirst() fonctionne correctement" -ForegroundColor Green
} else {
    Write-Host "Test échoué: La méthode GetFirst() ne fonctionne pas correctement" -ForegroundColor Red
}

$arrayList = $completedRunspaces.GetArrayList()
if ($arrayList -is [System.Collections.ArrayList]) {
    Write-Host "Test réussi: La méthode GetArrayList() fonctionne correctement" -ForegroundColor Green
} else {
    Write-Host "Test échoué: La méthode GetArrayList() ne fonctionne pas correctement" -ForegroundColor Red
}

# Tester l'indexeur
$indexedRunspace = $completedRunspaces[0]
if ($null -ne $indexedRunspace -and $null -ne $indexedRunspace.PowerShell) {
    Write-Host "Test réussi: L'indexeur fonctionne correctement" -ForegroundColor Green
} else {
    Write-Host "Test échoué: L'indexeur ne fonctionne pas correctement" -ForegroundColor Red
}

# Nettoyer
foreach ($runspace in $completedRunspaces.Results) {
    if ($null -ne $runspace -and $null -ne $runspace.PowerShell) {
        $runspace.PowerShell.Dispose()
    }
}
$runspacePool.Close()
$runspacePool.Dispose()

Write-Host "Test 2: Vérification du comportement avec WaitForAll=false" -ForegroundColor Cyan

# Créer un nouveau pool de runspaces
$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 2, $sessionState, $Host)
$runspacePool.Open()

# Créer une liste pour stocker les runspaces
$runspaces = New-Object System.Collections.ArrayList

# Créer quelques runspaces avec des délais différents
for ($i = 1; $i -le 3; $i++) {
    $powershell = [powershell]::Create()
    $powershell.RunspacePool = $runspacePool

    # Ajouter un script avec délai croissant
    [void]$powershell.AddScript({
            param($Item)
            Start-Sleep -Milliseconds ($Item * 100)
            return "Test $Item"
        })

    # Ajouter le paramètre
    [void]$powershell.AddParameter('Item', $i)

    # Démarrer l'exécution asynchrone
    $handle = $powershell.BeginInvoke()

    # Ajouter à la liste des runspaces
    [void]$runspaces.Add([PSCustomObject]@{
            PowerShell = $powershell
            Handle     = $handle
            Item       = $i
        })
}

# Créer une copie de la liste des runspaces pour le test
$runspacesCopy = [System.Collections.Generic.List[PSObject]]::new()
foreach ($runspace in $runspaces) {
    $runspacesCopy.Add($runspace)
}

# Attendre le premier runspace complété
Write-Host "Attente du premier runspace complété..."
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -NoProgress -Verbose

# Vérifier le type de retour et le nombre d'éléments
Write-Host "Type de retour: $($completedRunspaces.GetType().FullName)"
Write-Host "Nombre d'éléments: $($completedRunspaces.Count)"
Write-Host "Type de Results: $($completedRunspaces.Results.GetType().FullName)"
Write-Host "Nombre de runspaces restants: $($runspacesCopy.Count)"

if ($completedRunspaces.Count -eq 1) {
    Write-Host "Test réussi: Le nombre d'éléments est correct" -ForegroundColor Green
} else {
    Write-Host "Test échoué: Le nombre d'éléments est incorrect (attendu: 1, obtenu: $($completedRunspaces.Count))" -ForegroundColor Red
}

if ($completedRunspaces -is [PSCustomObject]) {
    Write-Host "Test réussi: Le type de retour est PSCustomObject" -ForegroundColor Green
} else {
    Write-Host "Test échoué: Le type de retour n'est pas PSCustomObject (obtenu: $($completedRunspaces.GetType().FullName))" -ForegroundColor Red
}

if ($completedRunspaces.Results -is [System.Collections.ArrayList]) {
    Write-Host "Test réussi: Le type de Results est ArrayList" -ForegroundColor Green
} else {
    Write-Host "Test échoué: Le type de Results n'est pas ArrayList (obtenu: $($completedRunspaces.Results.GetType().FullName))" -ForegroundColor Red
}

if ($runspacesCopy.Count -eq 2) {
    Write-Host "Test réussi: Le nombre de runspaces restants est correct" -ForegroundColor Green
} else {
    Write-Host "Test échoué: Le nombre de runspaces restants est incorrect (attendu: 2, obtenu: $($runspacesCopy.Count))" -ForegroundColor Red
}

# Tester les méthodes
$firstRunspace = $completedRunspaces.GetFirst()
if ($null -ne $firstRunspace -and $null -ne $firstRunspace.PowerShell) {
    Write-Host "Test réussi: La méthode GetFirst() fonctionne correctement" -ForegroundColor Green
} else {
    Write-Host "Test échoué: La méthode GetFirst() ne fonctionne pas correctement" -ForegroundColor Red
}

$arrayList = $completedRunspaces.GetArrayList()
if ($arrayList -is [System.Collections.ArrayList]) {
    Write-Host "Test réussi: La méthode GetArrayList() fonctionne correctement" -ForegroundColor Green
} else {
    Write-Host "Test échoué: La méthode GetArrayList() ne fonctionne pas correctement" -ForegroundColor Red
}

# Tester l'indexeur
$indexedRunspace = $completedRunspaces[0]
if ($null -ne $indexedRunspace -and $null -ne $indexedRunspace.PowerShell) {
    Write-Host "Test réussi: L'indexeur fonctionne correctement" -ForegroundColor Green
} else {
    Write-Host "Test échoué: L'indexeur ne fonctionne pas correctement" -ForegroundColor Red
}

# Nettoyer
foreach ($runspace in $completedRunspaces.Results) {
    if ($null -ne $runspace -and $null -ne $runspace.PowerShell) {
        $runspace.PowerShell.Dispose()
    }
}
foreach ($runspace in $runspaces) {
    if ($null -ne $runspace -and $null -ne $runspace.PowerShell) {
        $runspace.PowerShell.Dispose()
    }
}
$runspacePool.Close()
$runspacePool.Dispose()

# Nettoyer le module
Clear-UnifiedParallel
