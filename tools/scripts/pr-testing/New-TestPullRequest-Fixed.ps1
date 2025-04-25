#Requires -Version 5.1
<#
.SYNOPSIS
    Génère des pull requests de test avec différents types de modifications.

.DESCRIPTION
    Ce script crée des pull requests de test dans le dépôt spécifié avec
    différents types de modifications (ajouts, modifications, suppressions)
    et injecte des erreurs connues pour tester le système d'analyse.

.PARAMETER RepositoryPath
    Le chemin du dépôt de test.
    Par défaut: "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo"

.PARAMETER BranchName
    Le nom de la branche à créer pour la pull request.
    Par défaut: "feature/test-pr-{timestamp}"

.PARAMETER BaseBranch
    La branche de base à partir de laquelle créer la nouvelle branche.
    Par défaut: "develop"

.PARAMETER FileCount
    Le nombre de fichiers à modifier.
    Par défaut: 5

.PARAMETER ErrorCount
    Le nombre d'erreurs à injecter par fichier.
    Par défaut: 3

.PARAMETER ErrorTypes
    Les types d'erreurs à injecter.
    Valeurs possibles: Syntax, Style, Performance, Security, All
    Par défaut: "All"

.PARAMETER ModificationTypes
    Les types de modifications à effectuer.
    Valeurs possibles: Add, Modify, Delete, Mixed
    Par défaut: "Mixed"

.PARAMETER CreatePR
    Indique s'il faut créer une pull request sur GitHub.
    Par défaut: $false

.EXAMPLE
    .\New-TestPullRequest.ps1
    Génère une pull request de test avec les paramètres par défaut.

.EXAMPLE
    .\New-TestPullRequest.ps1 -FileCount 10 -ErrorCount 5 -ErrorTypes "Syntax,Style"
    Génère une pull request avec 10 fichiers modifiés, 5 erreurs par fichier, de types syntaxe et style.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-14
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$RepositoryPath = "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo",

    [Parameter()]
    [string]$BranchName = "feature/test-pr-$(Get-Date -Format 'yyyyMMdd-HHmmss')",

    [Parameter()]
    [string]$BaseBranch = "develop",

    [Parameter()]
    [int]$FileCount = 5,

    [Parameter()]
    [int]$ErrorCount = 3,

    [Parameter()]
    [ValidateSet("Syntax", "Style", "Performance", "Security", "All")]
    [string]$ErrorTypes = "All",

    [Parameter()]
    [ValidateSet("Add", "Modify", "Delete", "Mixed")]
    [string]$ModificationTypes = "Mixed",

    [Parameter()]
    [switch]$CreatePR
)

# Fonction pour créer une nouvelle branche
function New-GitBranch {
    param (
        [string]$RepositoryPath,
        [string]$BranchName,
        [string]$BaseBranch
    )

    Write-Host "Création de la branche $BranchName à partir de $BaseBranch..." -ForegroundColor Cyan

    Push-Location $RepositoryPath
    try {
        # S'assurer que nous sommes sur la branche de base
        git checkout $BaseBranch
        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors du checkout de la branche $BaseBranch."
        }

        # Créer la nouvelle branche
        git checkout -b $BranchName
        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors de la création de la branche $BranchName."
        }

        Write-Host "Branche $BranchName créée avec succès." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Erreur lors de la création de la branche: $_"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour générer un script PowerShell avec des erreurs
function New-PowerShellScriptWithErrors {
    param (
        [string]$Path,
        [int]$ErrorCount,
        [string[]]$ErrorTypes
    )

    # Modèles de fonctions PowerShell correctes
    $scriptFunctions = @(
        @{
            Name    = "Get-SystemInfo"
            Content = @"
function Get-SystemInfo {
    [CmdletBinding()]
    param()

    `$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    `$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem

    [PSCustomObject]@{
        ComputerName = `$env:COMPUTERNAME
        OSName = `$osInfo.Caption
        OSVersion = `$osInfo.Version
        Manufacturer = `$computerSystem.Manufacturer
        Model = `$computerSystem.Model
        Processor = (Get-CimInstance -ClassName Win32_Processor).Name
        Memory = [math]::Round(`$computerSystem.TotalPhysicalMemory / 1GB, 2)
        LastBootTime = `$osInfo.LastBootUpTime
    }
}
"@
        },
        @{
            Name    = "Test-NetworkConnection"
            Content = @"
function Test-NetworkConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [string]`$ComputerName,

        [Parameter()]
        [int]`$Count = 4,

        [Parameter()]
        [switch]`$Detailed
    )

    `$results = Test-Connection -ComputerName `$ComputerName -Count `$Count -ErrorAction SilentlyContinue

    if (`$Detailed) {
        return `$results
    } else {
        return `$results -ne `$null -and `$results.Count -gt 0
    }
}
"@
        },
        @{
            Name    = "Convert-Size"
            Content = @"
function Convert-Size {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [long]`$Size,

        [Parameter()]
        [ValidateSet("Bytes", "KB", "MB", "GB", "TB")]
        [string]`$From = "Bytes",

        [Parameter()]
        [ValidateSet("Bytes", "KB", "MB", "GB", "TB")]
        [string]`$To = "MB"
    )

    `$units = @{
        "Bytes" = 0
        "KB" = 1
        "MB" = 2
        "GB" = 3
        "TB" = 4
    }

    `$fromIndex = `$units[`$From]
    `$toIndex = `$units[`$To]

    `$difference = `$fromIndex - `$toIndex

    if (`$difference -eq 0) {
        return `$Size
    } elseif (`$difference -gt 0) {
        return `$Size * [Math]::Pow(1024, `$difference)
    } else {
        return `$Size / [Math]::Pow(1024, [Math]::Abs(`$difference))
    }
}
"@
        }
    )

    # Modèles d'erreurs à injecter
    $errorPatterns = @{
        Syntax      = @(
            @{
                Description = "Parenthèse manquante"
                Pattern     = 'param\(([^)]+)\)'
                Replacement = 'param($1'
            },
            @{
                Description = "Accolade manquante"
                Pattern     = '\{([^}]+)\}'
                Replacement = '{$1'
            },
            @{
                Description = "Virgule manquante entre paramètres"
                Pattern     = '(\[Parameter\(\)\])\s+(\[.+?\])'
                Replacement = '$1$2'
            },
            @{
                Description = "Guillemet non fermé"
                Pattern     = '"([^"]+)"'
                Replacement = '"$1'
            }
        )
        Style       = @(
            @{
                Description = "Verbe non approuvé"
                Pattern     = 'function (Get|Test|Convert)-'
                Replacement = 'function Do-'
            },
            @{
                Description = "Variable non utilisée"
                Pattern     = '(\s+)\$([a-zA-Z0-9]+) = .+\r?\n'
                Replacement = '$1$unusedVar = Get-Random`r`n$1$$2 = .+`r`n'
            },
            @{
                Description = "Nom de variable trop court"
                Pattern     = '\$([a-zA-Z]{3,})'
                Replacement = '$x'
            }
        )
        Performance = @(
            @{
                Description = "Appel inutile à Select-Object"
                Pattern     = '(Get-CimInstance .+)'
                Replacement = '$1 | Select-Object -Property *'
            },
            @{
                Description = "Utilisation de ForEach au lieu de pipeline"
                Pattern     = 'return \$results'
                Replacement = '$output = @()`r`n    foreach ($item in $results) { $output += $item }`r`n    return $output'
            },
            @{
                Description = "Appel répété à une commande coûteuse"
                Pattern     = '\$computerSystem = (Get-CimInstance .+)'
                Replacement = '$computerSystem = (Get-CimInstance -ClassName Win32_ComputerSystem)`r`n    $computerSystem2 = (Get-CimInstance -ClassName Win32_ComputerSystem)`r`n    $computerSystem3 = (Get-CimInstance -ClassName Win32_ComputerSystem)'
            }
        )
        Security    = @(
            @{
                Description = "Utilisation de plaintext password"
                Pattern     = 'param\(([^)]+)\)'
                Replacement = 'param($1,`r`n        [string]$Password = ''P@ssw0rd''`r`n    '
            },
            @{
                Description = "Désactivation de la validation de certificat"
                Pattern     = '(Invoke-WebRequest|Invoke-RestMethod)'
                Replacement = '$1 -SkipCertificateCheck'
            },
            @{
                Description = "Exécution de code à partir d'une entrée utilisateur"
                Pattern     = 'return \$results'
                Replacement = '    $userInput = Read-Host ''Enter command to execute''`r`n    Invoke-Expression $userInput`r`n    return $results'
            }
        )
    }

    # Sélectionner une fonction aléatoire comme base
    $selectedFunction = $scriptFunctions | Get-Random
    $scriptContent = $selectedFunction.Content

    # Déterminer les types d'erreurs à injecter
    $errorTypesToUse = @()
    if ($ErrorTypes -eq "All") {
        $errorTypesToUse = @("Syntax", "Style", "Performance", "Security")
    } else {
        $errorTypesToUse = $ErrorTypes -split ","
    }

    # Injecter les erreurs
    for ($i = 0; $i -lt $ErrorCount; $i++) {
        # Sélectionner un type d'erreur aléatoire parmi ceux spécifiés
        $errorType = $errorTypesToUse | Get-Random

        # Sélectionner une erreur aléatoire de ce type
        $errorToInject = $errorPatterns[$errorType] | Get-Random

        # Appliquer l'erreur au contenu du script
        $regexMatches = [regex]::Matches($scriptContent, $errorToInject.Pattern)
        if ($regexMatches.Count -gt 0) {
            $randomMatch = $regexMatches | Get-Random
            # Utiliser une approche compatible avec PowerShell 5.1 pour remplacer la première occurrence
            $beforeMatch = $scriptContent.Substring(0, $randomMatch.Index)
            $afterMatch = $scriptContent.Substring($randomMatch.Index + $randomMatch.Length)
            $scriptContent = $beforeMatch + $randomMatch.Value.Replace($randomMatch.Value, $errorToInject.Replacement) + $afterMatch

            # Ajouter un commentaire pour identifier l'erreur
            $scriptContent = $scriptContent.Replace(
                $errorToInject.Replacement,
                "$($errorToInject.Replacement) # Erreur injectée: $($errorToInject.Description)"
            )
        }
    }

    # Ajouter un en-tête au script
    $header = @"
<#
.SYNOPSIS
    Script de test avec erreurs injectées pour l'analyse des pull requests.

.DESCRIPTION
    Ce script contient des erreurs intentionnellement injectées pour tester
    le système d'analyse des pull requests. Il ne doit pas être utilisé en
    production.

.NOTES
    Erreurs injectées: $ErrorCount
    Types d'erreurs: $($errorTypesToUse -join ", ")
    Généré automatiquement par New-TestPullRequest.ps1
    Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
#>

"@

    $scriptContent = $header + $scriptContent

    # Écrire le contenu dans le fichier
    Set-Content -Path $Path -Value $scriptContent -Encoding UTF8

    Write-Host "  Script créé avec $ErrorCount erreurs: $Path" -ForegroundColor Yellow
}

# Fonction pour ajouter de nouveaux fichiers
function Add-NewFiles {
    param (
        [string]$RepositoryPath,
        [int]$Count,
        [int]$ErrorCount,
        [string[]]$ErrorTypes
    )

    Write-Host "Ajout de $Count nouveaux fichiers..." -ForegroundColor Cyan

    $scriptsFolder = Join-Path -Path $RepositoryPath -ChildPath "scripts\pr-testing\generated"

    if (-not (Test-Path -Path $scriptsFolder)) {
        New-Item -ItemType Directory -Path $scriptsFolder -Force | Out-Null
    }

    for ($i = 1; $i -le $Count; $i++) {
        $fileName = "Test-Script$i.ps1"
        $filePath = Join-Path -Path $scriptsFolder -ChildPath $fileName

        New-PowerShellScriptWithErrors -Path $filePath -ErrorCount $ErrorCount -ErrorTypes $ErrorTypes
    }

    # Ajouter les fichiers au Git
    Push-Location $RepositoryPath
    try {
        git add "scripts\pr-testing\generated\*.ps1"
        Write-Host "Nouveaux fichiers ajoutés avec succès." -ForegroundColor Green
    } catch {
        Write-Error "Erreur lors de l'ajout des fichiers: $_"
    } finally {
        Pop-Location
    }
}

# Fonction pour modifier des fichiers existants
function Update-ExistingFiles {
    param (
        [string]$RepositoryPath,
        [int]$Count,
        [int]$ErrorCount,
        [string[]]$ErrorTypes
    )

    Write-Host "Modification de $Count fichiers existants..." -ForegroundColor Cyan

    # Trouver des fichiers PowerShell existants
    $existingFiles = Get-ChildItem -Path $RepositoryPath -Filter "*.ps1" -Recurse |
        Where-Object { $_.FullName -notlike "*\.git\*" } |
        Select-Object -First $Count

    if ($existingFiles.Count -eq 0) {
        Write-Warning "Aucun fichier PowerShell existant trouvé. Création de nouveaux fichiers à la place."
        Add-NewFiles -RepositoryPath $RepositoryPath -Count $Count -ErrorCount $ErrorCount -ErrorTypes $ErrorTypes
        return
    }

    foreach ($file in $existingFiles) {
        # Lire le contenu actuel
        $content = Get-Content -Path $file.FullName -Raw

        # Ajouter une fonction avec des erreurs
        $tempFile = [System.IO.Path]::GetTempFileName()
        New-PowerShellScriptWithErrors -Path $tempFile -ErrorCount $ErrorCount -ErrorTypes $ErrorTypes
        $newFunction = Get-Content -Path $tempFile -Raw
        Remove-Item -Path $tempFile -Force

        # Combiner le contenu
        $updatedContent = @"
$content

# Fonction ajoutée pour les tests de pull requests
$newFunction
"@

        # Écrire le contenu mis à jour
        Set-Content -Path $file.FullName -Value $updatedContent -Encoding UTF8

        Write-Host "  Fichier modifié avec $ErrorCount erreurs: $($file.FullName)" -ForegroundColor Yellow
    }

    # Ajouter les fichiers modifiés au Git
    Push-Location $RepositoryPath
    try {
        git add -u
        Write-Host "Fichiers modifiés ajoutés avec succès." -ForegroundColor Green
    } catch {
        Write-Error "Erreur lors de l'ajout des fichiers modifiés: $_"
    } finally {
        Pop-Location
    }
}

# Fonction pour supprimer des fichiers
function Remove-ExistingFiles {
    param (
        [string]$RepositoryPath,
        [int]$Count
    )

    Write-Host "Suppression de $Count fichiers existants..." -ForegroundColor Cyan

    # Trouver des fichiers PowerShell existants
    $existingFiles = Get-ChildItem -Path $RepositoryPath -Filter "*.ps1" -Recurse |
        Where-Object { $_.FullName -notlike "*\.git\*" } |
        Select-Object -First $Count

    if ($existingFiles.Count -eq 0) {
        Write-Warning "Aucun fichier PowerShell existant trouvé à supprimer."
        return
    }

    foreach ($file in $existingFiles) {
        # Supprimer le fichier
        Remove-Item -Path $file.FullName -Force

        Write-Host "  Fichier supprimé: $($file.FullName)" -ForegroundColor Yellow
    }

    # Ajouter les suppressions au Git
    Push-Location $RepositoryPath
    try {
        git add -u
        Write-Host "Suppressions de fichiers ajoutées avec succès." -ForegroundColor Green
    } catch {
        Write-Error "Erreur lors de l'ajout des suppressions: $_"
    } finally {
        Pop-Location
    }
}

# Fonction pour committer les changements (utilise un verbe approuvé)
function Submit-Changes {
    param (
        [string]$RepositoryPath,
        [string]$Message
    )

    Write-Host "Commit des changements..." -ForegroundColor Cyan

    Push-Location $RepositoryPath
    try {
        git commit -m $Message
        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors du commit des changements."
        }

        Write-Host "Changements committés avec succès." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Erreur lors du commit des changements: $_"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour pousser les changements
function Push-Changes {
    param (
        [string]$RepositoryPath,
        [string]$BranchName
    )

    Write-Host "Push des changements vers origin/$BranchName..." -ForegroundColor Cyan

    Push-Location $RepositoryPath
    try {
        git push -u origin $BranchName
        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors du push des changements."
        }

        Write-Host "Changements poussés avec succès." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Erreur lors du push des changements: $_"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour créer une pull request
function New-GithubPullRequest {
    param (
        [string]$RepositoryPath,
        [string]$BranchName,
        [string]$BaseBranch,
        [string]$Title,
        [string]$Body
    )

    Write-Host "Création d'une pull request..." -ForegroundColor Cyan

    Push-Location $RepositoryPath
    try {
        # Vérifier si gh CLI est installé
        $ghInstalled = $null -ne (Get-Command -Name gh -ErrorAction SilentlyContinue)

        if (-not $ghInstalled) {
            Write-Warning "GitHub CLI (gh) n'est pas installé. Impossible de créer une pull request automatiquement."
            Write-Host "Veuillez créer la pull request manuellement sur GitHub." -ForegroundColor Yellow
            return $false
        }

        # Créer la pull request
        $prResult = gh pr create --base $BaseBranch --head $BranchName --title $Title --body $Body

        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors de la création de la pull request."
        }

        Write-Host "Pull request créée avec succès: $prResult" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Erreur lors de la création de la pull request: $_"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction principale
function New-TestPullRequest {
    # Vérifier que le dépôt existe
    if (-not (Test-Path -Path $RepositoryPath)) {
        Write-Error "Le dépôt spécifié n'existe pas: $RepositoryPath"
        return
    }

    # Créer une nouvelle branche
    $branchResult = New-GitBranch -RepositoryPath $RepositoryPath -BranchName $BranchName -BaseBranch $BaseBranch
    if (-not $branchResult) {
        return
    }

    # Déterminer les types de modifications à effectuer
    switch ($ModificationTypes) {
        "Add" {
            Add-NewFiles -RepositoryPath $RepositoryPath -Count $FileCount -ErrorCount $ErrorCount -ErrorTypes $ErrorTypes
        }
        "Modify" {
            Update-ExistingFiles -RepositoryPath $RepositoryPath -Count $FileCount -ErrorCount $ErrorCount -ErrorTypes $ErrorTypes
        }
        "Delete" {
            Remove-ExistingFiles -RepositoryPath $RepositoryPath -Count $FileCount
        }
        "Mixed" {
            $addCount = [Math]::Max(1, [Math]::Floor($FileCount / 3))
            $modifyCount = [Math]::Max(1, [Math]::Floor($FileCount / 3))
            $deleteCount = [Math]::Max(1, $FileCount - $addCount - $modifyCount)

            Add-NewFiles -RepositoryPath $RepositoryPath -Count $addCount -ErrorCount $ErrorCount -ErrorTypes $ErrorTypes
            Update-ExistingFiles -RepositoryPath $RepositoryPath -Count $modifyCount -ErrorCount $ErrorCount -ErrorTypes $ErrorTypes
            Remove-ExistingFiles -RepositoryPath $RepositoryPath -Count $deleteCount
        }
    }

    # Committer les changements
    $commitMessage = "Test PR: $ModificationTypes modifications with $ErrorCount $ErrorTypes errors"
    $commitResult = Submit-Changes -RepositoryPath $RepositoryPath -Message $commitMessage
    if (-not $commitResult) {
        return
    }

    # Pousser les changements
    $pushResult = Push-Changes -RepositoryPath $RepositoryPath -BranchName $BranchName
    if (-not $pushResult) {
        return
    }

    # Créer une pull request si demandé
    if ($CreatePR) {
        $prTitle = "Test PR: $ModificationTypes modifications with $ErrorCount $ErrorTypes errors"
        $prBody = @"
# Test Pull Request

Cette pull request a été générée automatiquement pour tester le système d'analyse des pull requests.

## Détails

- **Type de modifications**: $ModificationTypes
- **Nombre de fichiers**: $FileCount
- **Nombre d'erreurs par fichier**: $ErrorCount
- **Types d'erreurs**: $ErrorTypes

## Notes

Les erreurs ont été intentionnellement injectées dans le code pour tester la détection.
Cette PR ne doit pas être fusionnée en production.
"@

        New-GithubPullRequest -RepositoryPath $RepositoryPath -BranchName $BranchName -BaseBranch $BaseBranch -Title $prTitle -Body $prBody
    }

    Write-Host "`nPull request de test créée avec succès:" -ForegroundColor Green
    Write-Host "  Branche: $BranchName" -ForegroundColor Cyan
    Write-Host "  Base: $BaseBranch" -ForegroundColor Cyan
    Write-Host "  Type de modifications: $ModificationTypes" -ForegroundColor Cyan
    Write-Host "  Nombre de fichiers: $FileCount" -ForegroundColor Cyan
    Write-Host "  Erreurs par fichier: $ErrorCount" -ForegroundColor Cyan
    Write-Host "  Types d'erreurs: $ErrorTypes" -ForegroundColor Cyan

    if (-not $CreatePR) {
        Write-Host "`nPour créer une pull request manuellement, visitez:" -ForegroundColor Yellow
        Write-Host "  https://github.com/VOTRE_UTILISATEUR/VOTRE_REPO/compare/$BaseBranch...$BranchName" -ForegroundColor Yellow
    }
}

# Exporter la fonction principale
Export-ModuleMember -Function New-TestPullRequest

# Si le script est exécuté directement (pas importé comme module)
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    # Exécuter la fonction principale
    New-TestPullRequest
}
