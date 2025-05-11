# Test-TaskFieldImplementation.ps1
# Script de test pour vérifier l'implémentation des champs de tâches
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Teste l'implémentation des champs obligatoires et optionnels pour les tâches de roadmap.

.DESCRIPTION
    Ce script exécute une série de tests pour vérifier le bon fonctionnement des scripts
    TaskFieldDefinitions.ps1, Initialize-TaskDefaults.ps1 et Normalize-TaskFields.ps1.

.PARAMETER Verbose
    Affiche des informations détaillées sur les tests exécutés.

.EXAMPLE
    .\Test-TaskFieldImplementation.ps1 -Verbose

.NOTES
    Auteur: Équipe DevOps
    Date: 2025-05-15
    Version: 1.0
#>

[CmdletBinding()]
param()

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$taskFieldDefinitionsPath = Join-Path -Path $scriptPath -ChildPath "TaskFieldDefinitions.ps1"
$initializeTaskDefaultsPath = Join-Path -Path $scriptPath -ChildPath "Initialize-TaskDefaults.ps1"
$normalizeTaskFieldsPath = Join-Path -Path $scriptPath -ChildPath "Normalize-TaskFields.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $taskFieldDefinitionsPath)) {
    Write-Error "Le fichier TaskFieldDefinitions.ps1 est introuvable."
    exit 1
}

if (-not (Test-Path -Path $initializeTaskDefaultsPath)) {
    Write-Error "Le fichier Initialize-TaskDefaults.ps1 est introuvable."
    exit 1
}

if (-not (Test-Path -Path $normalizeTaskFieldsPath)) {
    Write-Error "Le fichier Normalize-TaskFields.ps1 est introuvable."
    exit 1
}

# Importer les scripts
. $taskFieldDefinitionsPath
. $initializeTaskDefaultsPath
. $normalizeTaskFieldsPath

# Fonction pour exécuter un test
function Invoke-Test {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$Test
    )
    
    Write-Verbose "Exécution du test: $Name"
    
    try {
        $result = & $Test
        
        if ($result) {
            Write-Host "[SUCCÈS] $Name" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "[ÉCHEC] $Name" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "[ERREUR] $Name : $_" -ForegroundColor Red
        return $false
    }
}

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Test 1: Vérifier que les fonctions de TaskFieldDefinitions.ps1 sont disponibles
$totalTests++
$result = Invoke-Test -Name "Vérification des fonctions de TaskFieldDefinitions.ps1" -Test {
    $functions = @(
        "Get-AllTaskFields",
        "Get-RequiredTaskFields",
        "Get-OptionalTaskFields",
        "Test-TaskAgainstFieldDefinitions"
    )
    
    $allFunctionsAvailable = $true
    
    foreach ($function in $functions) {
        if (-not (Get-Command -Name $function -ErrorAction SilentlyContinue)) {
            Write-Verbose "Fonction non disponible: $function"
            $allFunctionsAvailable = $false
        }
    }
    
    return $allFunctionsAvailable
}
if ($result) { $passedTests++ }

# Test 2: Vérifier que les champs obligatoires sont correctement définis
$totalTests++
$result = Invoke-Test -Name "Vérification des champs obligatoires" -Test {
    $requiredFields = Get-RequiredTaskFields
    
    $expectedFields = @("Id", "Title", "Status", "CreatedAt", "UpdatedAt")
    
    $allFieldsPresent = $true
    
    foreach ($field in $expectedFields) {
        if (-not $requiredFields.ContainsKey($field)) {
            Write-Verbose "Champ obligatoire manquant: $field"
            $allFieldsPresent = $false
        }
    }
    
    return $allFieldsPresent
}
if ($result) { $passedTests++ }

# Test 3: Vérifier que les champs optionnels sont correctement définis
$totalTests++
$result = Invoke-Test -Name "Vérification des champs optionnels" -Test {
    $optionalFields = Get-OptionalTaskFields
    
    $expectedFields = @(
        "ParentId", "Description", "DueDate", "StartDate", "CompletionDate",
        "Dependencies", "SubTasks", "Owner", "Assignees", "Progress",
        "Priority", "Complexity", "Tags", "Category", "EstimatedHours"
    )
    
    $allFieldsPresent = $true
    
    foreach ($field in $expectedFields) {
        if (-not $optionalFields.ContainsKey($field)) {
            Write-Verbose "Champ optionnel manquant: $field"
            $allFieldsPresent = $false
        }
    }
    
    return $allFieldsPresent
}
if ($result) { $passedTests++ }

# Test 4: Vérifier la validation d'une tâche valide
$totalTests++
$result = Invoke-Test -Name "Validation d'une tâche valide" -Test {
    $task = @{
        id = "1.2.3"
        title = "Implémenter la validation de schéma"
        status = "InProgress"
        createdAt = (Get-Date).ToUniversalTime().ToString("o")
        updatedAt = (Get-Date).ToUniversalTime().ToString("o")
    }
    
    return Test-TaskAgainstFieldDefinitions -Task $task
}
if ($result) { $passedTests++ }

# Test 5: Vérifier la validation d'une tâche invalide (champ obligatoire manquant)
$totalTests++
$result = Invoke-Test -Name "Validation d'une tâche invalide (champ obligatoire manquant)" -Test {
    $task = @{
        id = "1.2.3"
        title = "Implémenter la validation de schéma"
        # status manquant
        createdAt = (Get-Date).ToUniversalTime().ToString("o")
        updatedAt = (Get-Date).ToUniversalTime().ToString("o")
    }
    
    return -not (Test-TaskAgainstFieldDefinitions -Task $task -ErrorAction SilentlyContinue)
}
if ($result) { $passedTests++ }

# Test 6: Vérifier l'initialisation des valeurs par défaut
$totalTests++
$result = Invoke-Test -Name "Initialisation des valeurs par défaut" -Test {
    $task = @{
        id = "1.2.3"
        title = "Implémenter la validation de schéma"
        status = "InProgress"
        createdAt = (Get-Date).ToUniversalTime().ToString("o")
        updatedAt = (Get-Date).ToUniversalTime().ToString("o")
    }
    
    $initializedTask = Initialize-TaskDefaults -Task $task
    
    $allDefaultsSet = $true
    
    $optionalFields = Get-OptionalTaskFields
    foreach ($fieldKey in $optionalFields.Keys) {
        $field = $optionalFields[$fieldKey]
        $fieldName = $field.Name
        
        if (-not $initializedTask.ContainsKey($fieldName)) {
            Write-Verbose "Champ non initialisé: $fieldName"
            $allDefaultsSet = $false
        }
    }
    
    return $allDefaultsSet
}
if ($result) { $passedTests++ }

# Test 7: Vérifier la normalisation des champs
$totalTests++
$result = Invoke-Test -Name "Normalisation des champs" -Test {
    $task = @{
        id = "1.2.3"
        title = "  Implémenter la validation de schéma  "
        status = "inprogress"
        createdAt = "2025-05-15T10:00:00"
        updatedAt = "2025-05-15T10:00:00"
        priority = "h"
    }
    
    $normalizedTask = Normalize-TaskFields -Task $task
    
    $correctlyNormalized = $true
    
    if ($normalizedTask.title -ne "Implémenter la validation de schéma") {
        Write-Verbose "Titre non normalisé correctement: '$($normalizedTask.title)'"
        $correctlyNormalized = $false
    }
    
    if ($normalizedTask.status -ne "InProgress") {
        Write-Verbose "Statut non normalisé correctement: '$($normalizedTask.status)'"
        $correctlyNormalized = $false
    }
    
    if ($normalizedTask.priority -ne "High") {
        Write-Verbose "Priorité non normalisée correctement: '$($normalizedTask.priority)'"
        $correctlyNormalized = $false
    }
    
    return $correctlyNormalized
}
if ($result) { $passedTests++ }

# Test 8: Vérifier la création d'une nouvelle tâche avec New-DefaultTask
$totalTests++
$result = Invoke-Test -Name "Création d'une nouvelle tâche avec New-DefaultTask" -Test {
    $task = New-DefaultTask -Id "1.2.3" -Title "Nouvelle tâche" -Status "InProgress" -Description "Description de la tâche"
    
    $validTask = $true
    
    # Vérifier les champs obligatoires
    if ($task.id -ne "1.2.3") {
        Write-Verbose "ID incorrect: '$($task.id)'"
        $validTask = $false
    }
    
    if ($task.title -ne "Nouvelle tâche") {
        Write-Verbose "Titre incorrect: '$($task.title)'"
        $validTask = $false
    }
    
    if ($task.status -ne "InProgress") {
        Write-Verbose "Statut incorrect: '$($task.status)'"
        $validTask = $false
    }
    
    if ($task.description -ne "Description de la tâche") {
        Write-Verbose "Description incorrecte: '$($task.description)'"
        $validTask = $false
    }
    
    # Vérifier que les champs optionnels sont initialisés
    $optionalFields = Get-OptionalTaskFields
    foreach ($fieldKey in $optionalFields.Keys) {
        $field = $optionalFields[$fieldKey]
        $fieldName = $field.Name
        
        if (-not $task.ContainsKey($fieldName)) {
            Write-Verbose "Champ non initialisé: $fieldName"
            $validTask = $false
        }
    }
    
    return $validTask
}
if ($result) { $passedTests++ }

# Afficher le résumé des tests
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "Tests exécutés: $totalTests" -ForegroundColor Cyan
Write-Host "Tests réussis: $passedTests" -ForegroundColor Cyan
Write-Host "Tests échoués: $($totalTests - $passedTests)" -ForegroundColor Cyan

# Retourner le résultat global
return $passedTests -eq $totalTests
