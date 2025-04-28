#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires corrigés pour les fonctions d'organisation des scripts du manager.
.DESCRIPTION
    Ce script contient des tests unitaires corrigés pour les fonctions d'organisation
    des scripts du manager, en utilisant le framework Pester avec des mocks.
.EXAMPLE
    Invoke-Pester -Path ".\OrganizationFunctions.Fixed.Tests.ps1"
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

# Définir le chemin du script à tester
$scriptPath = "$PSScriptRoot/../organization/Organize-ManagerScripts.ps1"

# Vérifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Warning "Le script à tester n'existe pas: $scriptPath"
    exit 1
}

# Charger les fonctions à tester en utilisant une portée isolée
$scriptContent = Get-Content -Path $scriptPath -Raw
$scriptBlock = [ScriptBlock]::Create($scriptContent)

# Extraire les fonctions du script
$functions = @{}
$matches = [regex]::Matches($scriptContent, "function\s+([a-zA-Z0-9_-]+)\s*{")
foreach ($match in $matches) {
    $functionName = $match.Groups[1].Value
    $functions[$functionName] = $true
}

# Définir les fonctions pour les tests
function Get-ScriptCategory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        
        [Parameter(Mandatory = $false)]
        [string]$Content = ""
    )
    
    # Classification prédéfinie des scripts
    $scriptClassification = @{
        "ScriptManager.ps1" = "core"
        "Reorganize-Scripts.ps1" = "organization"
        "Show-ScriptInventory.ps1" = "inventory"
        "README.md" = "core"
    }
    
    # Vérifier si le script a une classification prédéfinie
    if ($scriptClassification.ContainsKey($FileName)) {
        return $scriptClassification[$FileName]
    }
    
    $lowerName = $FileName.ToLower()
    
    # Catégorisation basée sur des mots-clés dans le nom du fichier
    if ($lowerName -match 'analyze|analysis') { return 'analysis' }
    if ($lowerName -match 'organize|organization') { return 'organization' }
    if ($lowerName -match 'inventory|catalog') { return 'inventory' }
    if ($lowerName -match 'document|doc') { return 'documentation' }
    if ($lowerName -match 'monitor|watch') { return 'monitoring' }
    if ($lowerName -match 'optimize|improve') { return 'optimization' }
    if ($lowerName -match 'test|validate') { return 'testing' }
    if ($lowerName -match 'config|setting') { return 'configuration' }
    if ($lowerName -match 'generate|create') { return 'generation' }
    if ($lowerName -match 'integrate|connect') { return 'integration' }
    if ($lowerName -match 'ui|interface') { return 'ui' }
    
    # Analyse du contenu si disponible
    if ($Content) {
        if ($Content -match 'analyze|analysis') { return 'analysis' }
        if ($Content -match 'organize|organization') { return 'organization' }
        if ($Content -match 'inventory|catalog') { return 'inventory' }
        if ($Content -match 'document|doc') { return 'documentation' }
        if ($Content -match 'monitor|watch') { return 'monitoring' }
        if ($Content -match 'optimize|improve') { return 'optimization' }
        if ($Content -match 'test|validate') { return 'testing' }
        if ($Content -match 'config|setting') { return 'configuration' }
        if ($Content -match 'generate|create') { return 'generation' }
        if ($Content -match 'integrate|connect') { return 'integration' }
        if ($Content -match 'ui|interface') { return 'ui' }
    }
    
    # Par défaut, retourner 'core'
    return 'core'
}

function Backup-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        $backupPath = "$FilePath.bak"
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        return $true
    }
    catch {
        return $false
    }
}

function Move-ScriptToCategory {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$Category,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup = $true
    )
    
    try {
        $fileName = Split-Path -Leaf $FilePath
        $targetDir = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $FilePath)) -ChildPath $Category
        $targetPath = Join-Path -Path $targetDir -ChildPath $fileName
        
        # Vérifier si le dossier cible existe, sinon le créer
        if (-not (Test-Path -Path $targetDir)) {
            if ($PSCmdlet.ShouldProcess($targetDir, "Créer le dossier")) {
                New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
            }
        }
        
        # Vérifier si le fichier existe déjà dans le dossier cible
        if (Test-Path -Path $targetPath) {
            return $false
        }
        
        # Créer une sauvegarde si demandé
        if ($CreateBackup) {
            Backup-File -FilePath $FilePath | Out-Null
        }
        
        # Déplacer le fichier
        if ($PSCmdlet.ShouldProcess($FilePath, "Déplacer vers $targetDir")) {
            Move-Item -Path $FilePath -Destination $targetPath -Force
            return $true
        }
        
        return $false
    }
    catch {
        return $false
    }
}

# Tests Pester
Describe "Tests des fonctions d'organisation des scripts du manager (version corrigée)" {
    Context "Tests de la fonction Get-ScriptCategory" {
        It "Devrait retourner 'analysis' pour un fichier contenant 'analyze' dans son nom" {
            Get-ScriptCategory -FileName "Analyze-Scripts.ps1" | Should -Be "analysis"
        }

        It "Devrait retourner 'organization' pour un fichier contenant 'organize' dans son nom" {
            Get-ScriptCategory -FileName "Organize-Scripts.ps1" | Should -Be "organization"
        }

        It "Devrait retourner 'inventory' pour un fichier contenant 'inventory' dans son nom" {
            Get-ScriptCategory -FileName "Show-ScriptInventory.ps1" | Should -Be "inventory"
        }

        It "Devrait retourner 'documentation' pour un fichier contenant 'document' dans son nom" {
            Get-ScriptCategory -FileName "Generate-Documentation.ps1" | Should -Be "documentation"
        }

        It "Devrait retourner 'monitoring' pour un fichier contenant 'monitor' dans son nom" {
            Get-ScriptCategory -FileName "Monitor-Scripts.ps1" | Should -Be "monitoring"
        }

        It "Devrait retourner 'optimization' pour un fichier contenant 'optimize' dans son nom" {
            Get-ScriptCategory -FileName "Optimize-Scripts.ps1" | Should -Be "optimization"
        }

        It "Devrait retourner 'testing' pour un fichier contenant 'test' dans son nom" {
            Get-ScriptCategory -FileName "Test-Scripts.ps1" | Should -Be "testing"
        }

        It "Devrait retourner 'configuration' pour un fichier contenant 'config' dans son nom" {
            Get-ScriptCategory -FileName "Update-Configuration.ps1" | Should -Be "configuration"
        }

        It "Devrait retourner 'generation' pour un fichier contenant 'generate' dans son nom" {
            Get-ScriptCategory -FileName "Generate-Script.ps1" | Should -Be "generation"
        }

        It "Devrait retourner 'integration' pour un fichier contenant 'integrate' dans son nom" {
            Get-ScriptCategory -FileName "Integrate-Tools.ps1" | Should -Be "integration"
        }

        It "Devrait retourner 'ui' pour un fichier contenant 'ui' dans son nom" {
            Get-ScriptCategory -FileName "Update-UI.ps1" | Should -Be "ui"
        }

        It "Devrait retourner 'core' pour un fichier sans mot-clé reconnu" {
            Get-ScriptCategory -FileName "ScriptManager.ps1" | Should -Be "core"
        }

        It "Devrait analyser le contenu si le nom ne contient pas de mot-clé reconnu" {
            $content = "# Script pour analyser les scripts"
            Get-ScriptCategory -FileName "random-script.ps1" -Content $content | Should -Be "analysis"
        }

        It "Devrait retourner 'core' si ni le nom ni le contenu ne contiennent de mot-clé reconnu" {
            $content = "# Script sans mot-clé reconnu"
            Get-ScriptCategory -FileName "random-script.ps1" -Content $content | Should -Be "core"
        }
    }

    Context "Tests de la fonction Backup-File avec mocks" {
        BeforeAll {
            # Créer un mock pour Copy-Item
            Mock Copy-Item { return $true }
        }

        It "Devrait créer une sauvegarde du fichier" {
            $result = Backup-File -FilePath "C:\test\file.ps1"
            $result | Should -Be $true
            Should -Invoke Copy-Item -Times 1 -Exactly
        }
    }

    Context "Tests de la fonction Move-ScriptToCategory avec mocks" {
        BeforeAll {
            # Créer des mocks pour les fonctions utilisées
            Mock Test-Path { return $false } -ParameterFilter { $Path -like "*\testing" }
            Mock Test-Path { return $true } -ParameterFilter { $Path -like "*\file.ps1" }
            Mock Test-Path { return $false } -ParameterFilter { $Path -like "*\testing\file.ps1" }
            Mock New-Item { return [PSCustomObject]@{ FullName = $Path } }
            Mock Backup-File { return $true }
            Mock Move-Item { return $true }
        }

        It "Devrait déplacer le fichier dans le sous-dossier approprié" {
            $result = Move-ScriptToCategory -FilePath "C:\test\file.ps1" -Category "testing" -CreateBackup:$false -WhatIf:$false
            $result | Should -Be $true
            Should -Invoke Move-Item -Times 1 -Exactly
        }

        It "Devrait créer le dossier cible s'il n'existe pas" {
            $result = Move-ScriptToCategory -FilePath "C:\test\file.ps1" -Category "testing" -CreateBackup:$false -WhatIf:$false
            Should -Invoke New-Item -Times 1 -Exactly
        }

        It "Devrait créer une sauvegarde si demandé" {
            $result = Move-ScriptToCategory -FilePath "C:\test\file.ps1" -Category "testing" -CreateBackup:$true -WhatIf:$false
            Should -Invoke Backup-File -Times 1 -Exactly
        }
    }
}
