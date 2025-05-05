#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les fonctions d'analyse des scripts du manager.
.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions d'analyse
    des scripts du manager, en utilisant le framework Pester.
.EXAMPLE
    Invoke-Pester -Path ".\AnalysisFunctions.Tests.ps1"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# CrÃ©er des fonctions de test pour l'analyse des scripts
function Get-ScriptInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        
        # Extraire les informations du script
        $info = @{
            Path = $FilePath
            Name = Split-Path -Leaf $FilePath
            Extension = [System.IO.Path]::GetExtension($FilePath)
            SizeBytes = (Get-Item -Path $FilePath).Length
            LineCount = ($content -split "`n").Count
            HasSynopsis = $content -match "\.SYNOPSIS"
            HasDescription = $content -match "\.DESCRIPTION"
            HasExample = $content -match "\.EXAMPLE"
            HasParameter = $content -match "\.PARAMETER"
            HasNotes = $content -match "\.NOTES"
            FunctionCount = ([regex]::Matches($content, "function\s+\w+[-\w]*\s*{")).Count
            ParameterCount = ([regex]::Matches($content, "\[Parameter\(")).Count
            CommentLineCount = ([regex]::Matches($content, "^\s*#")).Count
            EmptyLineCount = ([regex]::Matches($content, "^\s*$")).Count
        }
        
        return $info
    }
    catch {
        Write-Error "Erreur lors de l'analyse du script $FilePath : $_"
        return $null
    }
}

function Test-ScriptQuality {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$ScriptInfo
    )
    
    # DÃ©finir les seuils de qualitÃ©
    $thresholds = @{
        MinLineCount = 10
        MaxLineCount = 1000
        MinCommentRatio = 0.1
        MaxEmptyLineRatio = 0.3
        RequiredElements = @("HasSynopsis", "HasDescription", "HasExample")
    }
    
    # Calculer les mÃ©triques
    $metrics = @{
        CommentRatio = if ($ScriptInfo.LineCount -gt 0) { $ScriptInfo.CommentLineCount / $ScriptInfo.LineCount } else { 0 }
        EmptyLineRatio = if ($ScriptInfo.LineCount -gt 0) { $ScriptInfo.EmptyLineCount / $ScriptInfo.LineCount } else { 0 }
        MissingElements = @()
    }
    
    # VÃ©rifier les Ã©lÃ©ments requis
    foreach ($element in $thresholds.RequiredElements) {
        if (-not $ScriptInfo[$element]) {
            $metrics.MissingElements += $element
        }
    }
    
    # Ã‰valuer la qualitÃ©
    $quality = @{
        IsValid = $true
        Issues = @()
    }
    
    if ($ScriptInfo.LineCount -lt $thresholds.MinLineCount) {
        $quality.IsValid = $false
        $quality.Issues += "Le script est trop court (moins de $($thresholds.MinLineCount) lignes)"
    }
    
    if ($ScriptInfo.LineCount -gt $thresholds.MaxLineCount) {
        $quality.IsValid = $false
        $quality.Issues += "Le script est trop long (plus de $($thresholds.MaxLineCount) lignes)"
    }
    
    if ($metrics.CommentRatio -lt $thresholds.MinCommentRatio) {
        $quality.IsValid = $false
        $quality.Issues += "Le ratio de commentaires est trop faible (moins de $($thresholds.MinCommentRatio * 100)%)"
    }
    
    if ($metrics.EmptyLineRatio -gt $thresholds.MaxEmptyLineRatio) {
        $quality.IsValid = $false
        $quality.Issues += "Le ratio de lignes vides est trop Ã©levÃ© (plus de $($thresholds.MaxEmptyLineRatio * 100)%)"
    }
    
    if ($metrics.MissingElements.Count -gt 0) {
        $quality.IsValid = $false
        $quality.Issues += "Ã‰lÃ©ments manquants : $($metrics.MissingElements -join ', ')"
    }
    
    return $quality
}

# Tests Pester
Describe "Tests des fonctions d'analyse des scripts du manager" {
    Context "Tests de la fonction Get-ScriptInfo" {
        BeforeAll {
            # CrÃ©er un dossier temporaire pour les tests
            $testDir = Join-Path -Path $env:TEMP -ChildPath "ScriptInfoTests"
            if (Test-Path -Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null

            # CrÃ©er un script de test bien documentÃ©
            $goodScriptPath = Join-Path -Path $testDir -ChildPath "good-script.ps1"
            $goodScriptContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Un script bien documentÃ©.
.DESCRIPTION
    Ce script est bien documentÃ© avec tous les Ã©lÃ©ments requis.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de sortie.
.EXAMPLE
    .\good-script.ps1 -OutputPath ".\reports\output"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = `$false)]
    [string]`$OutputPath = ".\reports\output"
)

# Fonction pour Ã©crire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Message,
        
        [Parameter(Mandatory = `$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]`$Level = "INFO"
    )
    
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$logMessage = "[`$timestamp] [`$Level] `$Message"
    
    Write-Host `$logMessage
}

# Code principal
Write-Log "DÃ©marrage du script..." -Level "INFO"

# Votre code ici

Write-Log "OpÃ©ration terminÃ©e avec succÃ¨s." -Level "SUCCESS"
"@
            Set-Content -Path $goodScriptPath -Value $goodScriptContent -Encoding UTF8

            # CrÃ©er un script de test mal documentÃ©
            $badScriptPath = Join-Path -Path $testDir -ChildPath "bad-script.ps1"
            $badScriptContent = @"
# Un script mal documentÃ©

param (
    [string]`$OutputPath = ".\reports\output"
)

# Code principal
Write-Host "DÃ©marrage du script..."

# Votre code ici

Write-Host "OpÃ©ration terminÃ©e."
"@
            Set-Content -Path $badScriptPath -Value $badScriptContent -Encoding UTF8

            # Sauvegarder les chemins pour les tests
            $script:testDir = $testDir
            $script:goodScriptPath = $goodScriptPath
            $script:badScriptPath = $badScriptPath
        }

        AfterAll {
            # Nettoyer aprÃ¨s les tests
            if (Test-Path -Path $script:testDir) {
                Remove-Item -Path $script:testDir -Recurse -Force
            }
        }

        It "Devrait extraire les informations d'un script bien documentÃ©" {
            $info = Get-ScriptInfo -FilePath $script:goodScriptPath
            $info | Should -Not -BeNullOrEmpty
            $info.Name | Should -Be "good-script.ps1"
            $info.Extension | Should -Be ".ps1"
            $info.HasSynopsis | Should -Be $true
            $info.HasDescription | Should -Be $true
            $info.HasExample | Should -Be $true
            $info.HasParameter | Should -Be $true
            $info.HasNotes | Should -Be $true
            $info.FunctionCount | Should -Be 1
            $info.ParameterCount | Should -Be 2
        }

        It "Devrait extraire les informations d'un script mal documentÃ©" {
            $info = Get-ScriptInfo -FilePath $script:badScriptPath
            $info | Should -Not -BeNullOrEmpty
            $info.Name | Should -Be "bad-script.ps1"
            $info.Extension | Should -Be ".ps1"
            $info.HasSynopsis | Should -Be $false
            $info.HasDescription | Should -Be $false
            $info.HasExample | Should -Be $false
            $info.HasParameter | Should -Be $false
            $info.HasNotes | Should -Be $false
            $info.FunctionCount | Should -Be 0
            $info.ParameterCount | Should -Be 0
        }
    }

    Context "Tests de la fonction Test-ScriptQuality" {
        It "Devrait valider un script de bonne qualitÃ©" {
            $goodScriptInfo = @{
                LineCount = 50
                CommentLineCount = 10
                EmptyLineCount = 5
                HasSynopsis = $true
                HasDescription = $true
                HasExample = $true
            }
            
            $quality = Test-ScriptQuality -ScriptInfo $goodScriptInfo
            $quality.IsValid | Should -Be $true
            $quality.Issues.Count | Should -Be 0
        }

        It "Devrait dÃ©tecter un script trop court" {
            $shortScriptInfo = @{
                LineCount = 5
                CommentLineCount = 1
                EmptyLineCount = 1
                HasSynopsis = $true
                HasDescription = $true
                HasExample = $true
            }
            
            $quality = Test-ScriptQuality -ScriptInfo $shortScriptInfo
            $quality.IsValid | Should -Be $false
            $quality.Issues | Should -Contain "Le script est trop court (moins de 10 lignes)"
        }

        It "Devrait dÃ©tecter un script trop long" {
            $longScriptInfo = @{
                LineCount = 1500
                CommentLineCount = 200
                EmptyLineCount = 100
                HasSynopsis = $true
                HasDescription = $true
                HasExample = $true
            }
            
            $quality = Test-ScriptQuality -ScriptInfo $longScriptInfo
            $quality.IsValid | Should -Be $false
            $quality.Issues | Should -Contain "Le script est trop long (plus de 1000 lignes)"
        }

        It "Devrait dÃ©tecter un ratio de commentaires trop faible" {
            $lowCommentScriptInfo = @{
                LineCount = 100
                CommentLineCount = 5
                EmptyLineCount = 10
                HasSynopsis = $true
                HasDescription = $true
                HasExample = $true
            }
            
            $quality = Test-ScriptQuality -ScriptInfo $lowCommentScriptInfo
            $quality.IsValid | Should -Be $false
            $quality.Issues | Should -Contain "Le ratio de commentaires est trop faible (moins de 10%)"
        }

        It "Devrait dÃ©tecter un ratio de lignes vides trop Ã©levÃ©" {
            $highEmptyLineScriptInfo = @{
                LineCount = 100
                CommentLineCount = 20
                EmptyLineCount = 40
                HasSynopsis = $true
                HasDescription = $true
                HasExample = $true
            }
            
            $quality = Test-ScriptQuality -ScriptInfo $highEmptyLineScriptInfo
            $quality.IsValid | Should -Be $false
            $quality.Issues | Should -Contain "Le ratio de lignes vides est trop Ã©levÃ© (plus de 30%)"
        }

        It "Devrait dÃ©tecter des Ã©lÃ©ments manquants" {
            $missingElementsScriptInfo = @{
                LineCount = 100
                CommentLineCount = 20
                EmptyLineCount = 10
                HasSynopsis = $false
                HasDescription = $true
                HasExample = $false
            }
            
            $quality = Test-ScriptQuality -ScriptInfo $missingElementsScriptInfo
            $quality.IsValid | Should -Be $false
            $quality.Issues | Should -Contain "Ã‰lÃ©ments manquants : HasSynopsis, HasExample"
        }
    }
}
