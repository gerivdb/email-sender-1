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
    Date de création: 2023-06-15
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Créer des fonctions de test pour l'analyse des scripts
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
    
    # Définir les seuils de qualité
    $thresholds = @{
        MinLineCount = 10
        MaxLineCount = 1000
        MinCommentRatio = 0.1
        MaxEmptyLineRatio = 0.3
        RequiredElements = @("HasSynopsis", "HasDescription", "HasExample")
    }
    
    # Calculer les métriques
    $metrics = @{
        CommentRatio = if ($ScriptInfo.LineCount -gt 0) { $ScriptInfo.CommentLineCount / $ScriptInfo.LineCount } else { 0 }
        EmptyLineRatio = if ($ScriptInfo.LineCount -gt 0) { $ScriptInfo.EmptyLineCount / $ScriptInfo.LineCount } else { 0 }
        MissingElements = @()
    }
    
    # Vérifier les éléments requis
    foreach ($element in $thresholds.RequiredElements) {
        if (-not $ScriptInfo[$element]) {
            $metrics.MissingElements += $element
        }
    }
    
    # Évaluer la qualité
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
        $quality.Issues += "Le ratio de lignes vides est trop élevé (plus de $($thresholds.MaxEmptyLineRatio * 100)%)"
    }
    
    if ($metrics.MissingElements.Count -gt 0) {
        $quality.IsValid = $false
        $quality.Issues += "Éléments manquants : $($metrics.MissingElements -join ', ')"
    }
    
    return $quality
}

# Tests Pester
Describe "Tests des fonctions d'analyse des scripts du manager" {
    Context "Tests de la fonction Get-ScriptInfo" {
        BeforeAll {
            # Créer un dossier temporaire pour les tests
            $testDir = Join-Path -Path $env:TEMP -ChildPath "ScriptInfoTests"
            if (Test-Path -Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null

            # Créer un script de test bien documenté
            $goodScriptPath = Join-Path -Path $testDir -ChildPath "good-script.ps1"
            $goodScriptContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Un script bien documenté.
.DESCRIPTION
    Ce script est bien documenté avec tous les éléments requis.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de sortie.
.EXAMPLE
    .\good-script.ps1 -OutputPath ".\reports\output"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = `$false)]
    [string]`$OutputPath = ".\reports\output"
)

# Fonction pour écrire dans le journal
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
Write-Log "Démarrage du script..." -Level "INFO"

# Votre code ici

Write-Log "Opération terminée avec succès." -Level "SUCCESS"
"@
            Set-Content -Path $goodScriptPath -Value $goodScriptContent -Encoding UTF8

            # Créer un script de test mal documenté
            $badScriptPath = Join-Path -Path $testDir -ChildPath "bad-script.ps1"
            $badScriptContent = @"
# Un script mal documenté

param (
    [string]`$OutputPath = ".\reports\output"
)

# Code principal
Write-Host "Démarrage du script..."

# Votre code ici

Write-Host "Opération terminée."
"@
            Set-Content -Path $badScriptPath -Value $badScriptContent -Encoding UTF8

            # Sauvegarder les chemins pour les tests
            $script:testDir = $testDir
            $script:goodScriptPath = $goodScriptPath
            $script:badScriptPath = $badScriptPath
        }

        AfterAll {
            # Nettoyer après les tests
            if (Test-Path -Path $script:testDir) {
                Remove-Item -Path $script:testDir -Recurse -Force
            }
        }

        It "Devrait extraire les informations d'un script bien documenté" {
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

        It "Devrait extraire les informations d'un script mal documenté" {
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
        It "Devrait valider un script de bonne qualité" {
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

        It "Devrait détecter un script trop court" {
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

        It "Devrait détecter un script trop long" {
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

        It "Devrait détecter un ratio de commentaires trop faible" {
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

        It "Devrait détecter un ratio de lignes vides trop élevé" {
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
            $quality.Issues | Should -Contain "Le ratio de lignes vides est trop élevé (plus de 30%)"
        }

        It "Devrait détecter des éléments manquants" {
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
            $quality.Issues | Should -Contain "Éléments manquants : HasSynopsis, HasExample"
        }
    }
}
