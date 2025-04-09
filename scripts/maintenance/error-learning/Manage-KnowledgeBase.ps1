<#
.SYNOPSIS
    Script pour gérer la base de connaissances des erreurs PowerShell.
.DESCRIPTION
    Ce script permet de gérer la base de connaissances des erreurs PowerShell,
    y compris l'ajout, la modification et la recherche d'erreurs.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Add", "Update", "Search", "Export", "Import")]
    [string]$Action = "Search",
    
    [Parameter(Mandatory = $false)]
    [string]$ErrorId = "",
    
    [Parameter(Mandatory = $false)]
    [string]$ErrorMessage = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Category = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Solution = "",
    
    [Parameter(Mandatory = $false)]
    [string]$FilePath = ""
)

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorLearningSystem.psm1"
Import-Module $modulePath -Force

# Initialiser le système
Initialize-ErrorLearningSystem

# Fonction pour ajouter une erreur à la base de connaissances
function Add-ErrorToKnowledgeBase {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage,
        
        [Parameter(Mandatory = $true)]
        [string]$Category,
        
        [Parameter(Mandatory = $true)]
        [string]$Solution
    )
    
    # Créer un ErrorRecord factice
    $exception = New-Object System.Exception($ErrorMessage)
    $errorRecord = New-Object System.Management.Automation.ErrorRecord(
        $exception,
        "KnowledgeBaseEntry",
        [System.Management.Automation.ErrorCategory]::NotSpecified,
        $null
    )
    
    # Ajouter des informations supplémentaires
    $additionalInfo = @{
        IsKnowledgeBaseEntry = $true
        ManuallyAdded = $true
    }
    
    # Enregistrer l'erreur
    $errorId = Register-PowerShellError -ErrorRecord $errorRecord -Source "KnowledgeBase" -Category $Category -Solution $Solution -AdditionalInfo $additionalInfo
    
    return $errorId
}

# Fonction pour mettre à jour une erreur dans la base de connaissances
function Update-ErrorInKnowledgeBase {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ErrorId,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Solution = ""
    )
    
    # Vérifier si le système est initialisé
    if (-not $script:IsInitialized) {
        Initialize-ErrorLearningSystem
    }
    
    # Rechercher l'erreur dans la base de données
    $errorIndex = -1
    for ($i = 0; $i -lt $script:ErrorDatabase.Errors.Count; $i++) {
        if ($script:ErrorDatabase.Errors[$i].Id -eq $ErrorId) {
            $errorIndex = $i
            break
        }
    }
    
    if ($errorIndex -eq -1) {
        Write-Error "Erreur non trouvée dans la base de connaissances : $ErrorId"
        return $false
    }
    
    # Mettre à jour l'erreur
    if ($Category) {
        $script:ErrorDatabase.Errors[$errorIndex].Category = $Category
    }
    
    if ($Solution) {
        $script:ErrorDatabase.Errors[$errorIndex].Solution = $Solution
    }
    
    # Mettre à jour la date de dernière mise à jour
    $script:ErrorDatabase.Statistics.LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Sauvegarder la base de données
    $script:ErrorDatabase | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ErrorDatabasePath -Force
    
    return $true
}

# Fonction pour rechercher des erreurs dans la base de connaissances
function Search-ErrorsInKnowledgeBase {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Category = ""
    )
    
    # Vérifier si le système est initialisé
    if (-not $script:IsInitialized) {
        Initialize-ErrorLearningSystem
    }
    
    # Filtrer les erreurs
    $filteredErrors = $script:ErrorDatabase.Errors
    
    if ($ErrorMessage) {
        $filteredErrors = $filteredErrors | Where-Object { $_.ErrorMessage -like "*$ErrorMessage*" }
    }
    
    if ($Category) {
        $filteredErrors = $filteredErrors | Where-Object { $_.Category -eq $Category }
    }
    
    return $filteredErrors
}

# Fonction pour exporter la base de connaissances
function Export-KnowledgeBase {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    # Vérifier si le système est initialisé
    if (-not $script:IsInitialized) {
        Initialize-ErrorLearningSystem
    }
    
    # Exporter la base de données
    $script:ErrorDatabase | ConvertTo-Json -Depth 10 | Set-Content -Path $FilePath -Force
    
    return $true
}

# Fonction pour importer la base de connaissances
function Import-KnowledgeBase {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier spécifié n'existe pas : $FilePath"
        return $false
    }
    
    # Importer la base de données
    try {
        $importedDatabase = Get-Content -Path $FilePath -Raw | ConvertFrom-Json -AsHashtable
        
        # Vérifier la structure de la base de données
        if (-not $importedDatabase.ContainsKey("Errors") -or -not $importedDatabase.ContainsKey("Statistics")) {
            Write-Error "Le fichier importé n'a pas la structure attendue."
            return $false
        }
        
        # Sauvegarder la base de données actuelle
        $backupPath = "$script:ErrorDatabasePath.bak"
        Copy-Item -Path $script:ErrorDatabasePath -Destination $backupPath -Force
        
        # Remplacer la base de données
        $script:ErrorDatabase = $importedDatabase
        
        # Mettre à jour la date de dernière mise à jour
        $script:ErrorDatabase.Statistics.LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Sauvegarder la base de données
        $script:ErrorDatabase | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ErrorDatabasePath -Force
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'importation de la base de connaissances : $_"
        return $false
    }
}

# Exécuter l'action demandée
switch ($Action) {
    "Add" {
        if (-not $ErrorMessage -or -not $Category -or -not $Solution) {
            Write-Error "Pour ajouter une erreur, vous devez spécifier ErrorMessage, Category et Solution."
            exit 1
        }
        
        $errorId = Add-ErrorToKnowledgeBase -ErrorMessage $ErrorMessage -Category $Category -Solution $Solution
        Write-Host "Erreur ajoutée à la base de connaissances avec l'ID : $errorId"
    }
    "Update" {
        if (-not $ErrorId) {
            Write-Error "Pour mettre à jour une erreur, vous devez spécifier ErrorId."
            exit 1
        }
        
        $result = Update-ErrorInKnowledgeBase -ErrorId $ErrorId -Category $Category -Solution $Solution
        if ($result) {
            Write-Host "Erreur mise à jour dans la base de connaissances : $ErrorId"
        }
    }
    "Search" {
        $results = Search-ErrorsInKnowledgeBase -ErrorMessage $ErrorMessage -Category $Category
        
        Write-Host "Résultats de la recherche : $($results.Count) erreurs trouvées."
        
        foreach ($error in $results) {
            Write-Host "`nID : $($error.Id)"
            Write-Host "Timestamp : $($error.Timestamp)"
            Write-Host "Source : $($error.Source)"
            Write-Host "Catégorie : $($error.Category)"
            Write-Host "Message : $($error.ErrorMessage)"
            
            if ($error.Solution) {
                Write-Host "Solution : $($error.Solution)"
            }
        }
    }
    "Export" {
        if (-not $FilePath) {
            Write-Error "Pour exporter la base de connaissances, vous devez spécifier FilePath."
            exit 1
        }
        
        $result = Export-KnowledgeBase -FilePath $FilePath
        if ($result) {
            Write-Host "Base de connaissances exportée vers : $FilePath"
        }
    }
    "Import" {
        if (-not $FilePath) {
            Write-Error "Pour importer la base de connaissances, vous devez spécifier FilePath."
            exit 1
        }
        
        $result = Import-KnowledgeBase -FilePath $FilePath
        if ($result) {
            Write-Host "Base de connaissances importée depuis : $FilePath"
        }
    }
}
