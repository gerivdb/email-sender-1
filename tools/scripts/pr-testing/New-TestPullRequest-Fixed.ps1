#Requires -Version 5.1
<#
.SYNOPSIS
    GÃ©nÃ¨re des pull requests de test avec diffÃ©rents types de modifications.

.DESCRIPTION
    Ce script crÃ©e des pull requests de test dans le dÃ©pÃ´t spÃ©cifiÃ© avec
    diffÃ©rents types de modifications (ajouts, modifications, suppressions)
    et injecte des erreurs connues pour tester le systÃ¨me d'analyse.

.PARAMETER RepositoryPath
    Le chemin du dÃ©pÃ´t de test.
    Par dÃ©faut: "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo"

.PARAMETER BranchName
    Le nom de la branche Ã  crÃ©er pour la pull request.
    Par dÃ©faut: "feature/test-pr-{timestamp}"

.PARAMETER BaseBranch
    La branche de base Ã  partir de laquelle crÃ©er la nouvelle branche.
    Par dÃ©faut: "develop"

.PARAMETER FileCount
    Le nombre de fichiers Ã  modifier.
    Par dÃ©faut: 5

.PARAMETER ErrorCount
    Le nombre d'erreurs Ã  injecter par fichier.
    Par dÃ©faut: 3

.PARAMETER ErrorTypes
    Les types d'erreurs Ã  injecter.
    Valeurs possibles: Syntax, Style, Performance, Security, All
    Par dÃ©faut: "All"

.PARAMETER ModificationTypes
    Les types de modifications Ã  effectuer.
    Valeurs possibles: Add, Modify, Delete, Mixed
    Par dÃ©faut: "Mixed"

.PARAMETER CreatePR
    Indique s'il faut crÃ©er une pull request sur GitHub.
    Par dÃ©faut: $false

.EXAMPLE
    .\New-TestPullRequest.ps1
    GÃ©nÃ¨re une pull request de test avec les paramÃ¨tres par dÃ©faut.

.EXAMPLE
    .\New-TestPullRequest.ps1 -FileCount 10 -ErrorCount 5 -ErrorTypes "Syntax,Style"
    GÃ©nÃ¨re une pull request avec 10 fichiers modifiÃ©s, 5 erreurs par fichier, de types syntaxe et style.

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

# Fonction pour crÃ©er une nouvelle branche
function New-GitBranch {
    param (
        [string]$RepositoryPath,
        [string]$BranchName,
        [string]$BaseBranch
    )

    Write-Host "CrÃ©ation de la branche $BranchName Ã  partir de $BaseBranch..." -ForegroundColor Cyan

    Push-Location $RepositoryPath
    try {
        # S'assurer que nous sommes sur la branche de base
        git checkout $BaseBranch
        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors du checkout de la branche $BaseBranch."
        }

        # CrÃ©er la nouvelle branche
        git checkout -b $BranchName
        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors de la crÃ©ation de la branche $BranchName."
        }

        Write-Host "Branche $BranchName crÃ©Ã©e avec succÃ¨s." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Erreur lors de la crÃ©ation de la branche: $_"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour gÃ©nÃ©rer un script PowerShell avec des erreurs
function New-PowerShellScriptWithErrors {
    param (
        [string]$Path,
        [int]$ErrorCount,
        [string[]]$ErrorTypes
    )

    # ModÃ¨les de fonctions PowerShell correctes
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

    # ModÃ¨les d'erreurs Ã  injecter
    $errorPatterns = @{
        Syntax      = @(
            @{
                Description = "ParenthÃ¨se manquante"
                Pattern     = 'param\(([^)]+)\)'
                Replacement = 'param($1'
            },
            @{
                Description = "Accolade manquante"
                Pattern     = '\{([^}]+)\}'
                Replacement = '{$1'
            },
            @{
                Description = "Virgule manquante entre paramÃ¨tres"
                Pattern     = '(\[Parameter\(\)\])\s+(\[.+?\])'
                Replacement = '$1$2'
            },
            @{
                Description = "Guillemet non fermÃ©"
                Pattern     = '"([^"]+)"'
                Replacement = '"$1'
            }
        )
        Style       = @(
            @{
                Description = "Verbe non approuvÃ©"
                Pattern     = 'function (Get|Test|Convert)-'
                Replacement = 'function Do-'
            },
            @{
                Description = "Variable non utilisÃ©e"
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
                Description = "Appel inutile Ã  Select-Object"
                Pattern     = '(Get-CimInstance .+)'
                Replacement = '$1 | Select-Object -Property *'
            },
            @{
                Description = "Utilisation de ForEach au lieu de pipeline"
                Pattern     = 'return \$results'
                Replacement = '$output = @()`r`n    foreach ($item in $results) { $output += $item }`r`n    return $output'
            },
            @{
                Description = "Appel rÃ©pÃ©tÃ© Ã  une commande coÃ»teuse"
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
                Description = "DÃ©sactivation de la validation de certificat"
                Pattern     = '(Invoke-WebRequest|Invoke-RestMethod)'
                Replacement = '$1 -SkipCertificateCheck'
            },
            @{
                Description = "ExÃ©cution de code Ã  partir d'une entrÃ©e utilisateur"
                Pattern     = 'return \$results'
                Replacement = '    $userInput = Read-Host ''Enter command to execute''`r`n    Invoke-Expression $userInput`r`n    return $results'
            }
        )
    }

    # SÃ©lectionner une fonction alÃ©atoire comme base
    $selectedFunction = $scriptFunctions | Get-Random
    $scriptContent = $selectedFunction.Content

    # DÃ©terminer les types d'erreurs Ã  injecter
    $errorTypesToUse = @()
    if ($ErrorTypes -eq "All") {
        $errorTypesToUse = @("Syntax", "Style", "Performance", "Security")
    } else {
        $errorTypesToUse = $ErrorTypes -split ","
    }

    # Injecter les erreurs
    for ($i = 0; $i -lt $ErrorCount; $i++) {
        # SÃ©lectionner un type d'erreur alÃ©atoire parmi ceux spÃ©cifiÃ©s
        $errorType = $errorTypesToUse | Get-Random

        # SÃ©lectionner une erreur alÃ©atoire de ce type
        $errorToInject = $errorPatterns[$errorType] | Get-Random

        # Appliquer l'erreur au contenu du script
        $regexMatches = [regex]::Matches($scriptContent, $errorToInject.Pattern)
        if ($regexMatches.Count -gt 0) {
            $randomMatch = $regexMatches | Get-Random
            # Utiliser une approche compatible avec PowerShell 5.1 pour remplacer la premiÃ¨re occurrence
            $beforeMatch = $scriptContent.Substring(0, $randomMatch.Index)
            $afterMatch = $scriptContent.Substring($randomMatch.Index + $randomMatch.Length)
            $scriptContent = $beforeMatch + $randomMatch.Value.Replace($randomMatch.Value, $errorToInject.Replacement) + $afterMatch

            # Ajouter un commentaire pour identifier l'erreur
            $scriptContent = $scriptContent.Replace(
                $errorToInject.Replacement,
                "$($errorToInject.Replacement) # Erreur injectÃ©e: $($errorToInject.Description)"
            )
        }
    }

    # Ajouter un en-tÃªte au script
    $header = @"
<#
.SYNOPSIS
    Script de test avec erreurs injectÃ©es pour l'analyse des pull requests.

.DESCRIPTION
    Ce script contient des erreurs intentionnellement injectÃ©es pour tester
    le systÃ¨me d'analyse des pull requests. Il ne doit pas Ãªtre utilisÃ© en
    production.

.NOTES
    Erreurs injectÃ©es: $ErrorCount
    Types d'erreurs: $($errorTypesToUse -join ", ")
    GÃ©nÃ©rÃ© automatiquement par New-TestPullRequest.ps1
    Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
#>

"@

    $scriptContent = $header + $scriptContent

    # Ã‰crire le contenu dans le fichier
    Set-Content -Path $Path -Value $scriptContent -Encoding UTF8

    Write-Host "  Script crÃ©Ã© avec $ErrorCount erreurs: $Path" -ForegroundColor Yellow
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
        Write-Host "Nouveaux fichiers ajoutÃ©s avec succÃ¨s." -ForegroundColor Green
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
        Write-Warning "Aucun fichier PowerShell existant trouvÃ©. CrÃ©ation de nouveaux fichiers Ã  la place."
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

# Fonction ajoutÃ©e pour les tests de pull requests
$newFunction
"@

        # Ã‰crire le contenu mis Ã  jour
        Set-Content -Path $file.FullName -Value $updatedContent -Encoding UTF8

        Write-Host "  Fichier modifiÃ© avec $ErrorCount erreurs: $($file.FullName)" -ForegroundColor Yellow
    }

    # Ajouter les fichiers modifiÃ©s au Git
    Push-Location $RepositoryPath
    try {
        git add -u
        Write-Host "Fichiers modifiÃ©s ajoutÃ©s avec succÃ¨s." -ForegroundColor Green
    } catch {
        Write-Error "Erreur lors de l'ajout des fichiers modifiÃ©s: $_"
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
        Write-Warning "Aucun fichier PowerShell existant trouvÃ© Ã  supprimer."
        return
    }

    foreach ($file in $existingFiles) {
        # Supprimer le fichier
        Remove-Item -Path $file.FullName -Force

        Write-Host "  Fichier supprimÃ©: $($file.FullName)" -ForegroundColor Yellow
    }

    # Ajouter les suppressions au Git
    Push-Location $RepositoryPath
    try {
        git add -u
        Write-Host "Suppressions de fichiers ajoutÃ©es avec succÃ¨s." -ForegroundColor Green
    } catch {
        Write-Error "Erreur lors de l'ajout des suppressions: $_"
    } finally {
        Pop-Location
    }
}

# Fonction pour committer les changements (utilise un verbe approuvÃ©)
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

        Write-Host "Changements committÃ©s avec succÃ¨s." -ForegroundColor Green
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

        Write-Host "Changements poussÃ©s avec succÃ¨s." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Erreur lors du push des changements: $_"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour crÃ©er une pull request
function New-GithubPullRequest {
    param (
        [string]$RepositoryPath,
        [string]$BranchName,
        [string]$BaseBranch,
        [string]$Title,
        [string]$Body
    )

    Write-Host "CrÃ©ation d'une pull request..." -ForegroundColor Cyan

    Push-Location $RepositoryPath
    try {
        # VÃ©rifier si gh CLI est installÃ©
        $ghInstalled = $null -ne (Get-Command -Name gh -ErrorAction SilentlyContinue)

        if (-not $ghInstalled) {
            Write-Warning "GitHub CLI (gh) n'est pas installÃ©. Impossible de crÃ©er une pull request automatiquement."
            Write-Host "Veuillez crÃ©er la pull request manuellement sur GitHub." -ForegroundColor Yellow
            return $false
        }

        # CrÃ©er la pull request
        $prResult = gh pr create --base $BaseBranch --head $BranchName --title $Title --body $Body

        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors de la crÃ©ation de la pull request."
        }

        Write-Host "Pull request crÃ©Ã©e avec succÃ¨s: $prResult" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Erreur lors de la crÃ©ation de la pull request: $_"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction principale
function New-TestPullRequest {
    # VÃ©rifier que le dÃ©pÃ´t existe
    if (-not (Test-Path -Path $RepositoryPath)) {
        Write-Error "Le dÃ©pÃ´t spÃ©cifiÃ© n'existe pas: $RepositoryPath"
        return
    }

    # CrÃ©er une nouvelle branche
    $branchResult = New-GitBranch -RepositoryPath $RepositoryPath -BranchName $BranchName -BaseBranch $BaseBranch
    if (-not $branchResult) {
        return
    }

    # DÃ©terminer les types de modifications Ã  effectuer
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

    # CrÃ©er une pull request si demandÃ©
    if ($CreatePR) {
        $prTitle = "Test PR: $ModificationTypes modifications with $ErrorCount $ErrorTypes errors"
        $prBody = @"
# Test Pull Request

Cette pull request a Ã©tÃ© gÃ©nÃ©rÃ©e automatiquement pour tester le systÃ¨me d'analyse des pull requests.

## DÃ©tails

- **Type de modifications**: $ModificationTypes
- **Nombre de fichiers**: $FileCount
- **Nombre d'erreurs par fichier**: $ErrorCount
- **Types d'erreurs**: $ErrorTypes

## Notes

Les erreurs ont Ã©tÃ© intentionnellement injectÃ©es dans le code pour tester la dÃ©tection.
Cette PR ne doit pas Ãªtre fusionnÃ©e en production.
"@

        New-GithubPullRequest -RepositoryPath $RepositoryPath -BranchName $BranchName -BaseBranch $BaseBranch -Title $prTitle -Body $prBody
    }

    Write-Host "`nPull request de test crÃ©Ã©e avec succÃ¨s:" -ForegroundColor Green
    Write-Host "  Branche: $BranchName" -ForegroundColor Cyan
    Write-Host "  Base: $BaseBranch" -ForegroundColor Cyan
    Write-Host "  Type de modifications: $ModificationTypes" -ForegroundColor Cyan
    Write-Host "  Nombre de fichiers: $FileCount" -ForegroundColor Cyan
    Write-Host "  Erreurs par fichier: $ErrorCount" -ForegroundColor Cyan
    Write-Host "  Types d'erreurs: $ErrorTypes" -ForegroundColor Cyan

    if (-not $CreatePR) {
        Write-Host "`nPour crÃ©er une pull request manuellement, visitez:" -ForegroundColor Yellow
        Write-Host "  https://github.com/VOTRE_UTILISATEUR/VOTRE_REPO/compare/$BaseBranch...$BranchName" -ForegroundColor Yellow
    }
}

# Exporter la fonction principale
Export-ModuleMember -Function New-TestPullRequest

# Si le script est exÃ©cutÃ© directement (pas importÃ© comme module)
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    # ExÃ©cuter la fonction principale
    New-TestPullRequest
}
