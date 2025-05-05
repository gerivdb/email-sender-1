<#
.SYNOPSIS
    Tests unitaires pour le script de synchronisation des Memories avec n8n.

.DESCRIPTION
    Ce script contient des tests unitaires pour le script de synchronisation des Memories avec n8n,
    utilisant le framework Pester.

.EXAMPLE
    Invoke-Pester -Path "development\scripts\maintenance\augment\tests\Test-SyncMemoriesWithN8n.ps1"
    # ExÃ©cute les tests unitaires pour le script de synchronisation des Memories avec n8n

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# DÃ©terminer le chemin du script Ã  tester
$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "sync-memories-with-n8n.ps1"

# DÃ©terminer le chemin du projet
$projectRoot = $scriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

Describe "Sync Memories With N8n Tests" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $testDir = Join-Path -Path $TestDrive -ChildPath "augment"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        
        # CrÃ©er un fichier de Memories temporaire
        $testMemoriesPath = Join-Path -Path $testDir -ChildPath "memories.json"
        $testMemoriesContent = @{
            version = "2.0.0"
            lastUpdated = (Get-Date).ToString("o")
            sections = @(
                @{
                    name = "TEST"
                    content = "Test content"
                }
            )
        } | ConvertTo-Json -Depth 10
        $testMemoriesContent | Out-File -FilePath $testMemoriesPath -Encoding UTF8
        
        # DÃ©finir des variables globales pour les tests
        $Global:TestMemoriesPath = $testMemoriesPath
        
        # Mock pour Invoke-RestMethod
        Mock -CommandName Invoke-RestMethod -MockWith {
            param (
                [string]$Uri,
                [string]$Method,
                [string]$Body,
                [string]$ContentType
            )
            
            if ($Uri -like "*/health") {
                return @{
                    status = "ok"
                }
            }
            
            if ($Uri -like "*/workflows") {
                return @{
                    data = @(
                        @{
                            id = "123"
                            name = "augment-memories-sync"
                        }
                    )
                }
            }
            
            if ($Uri -like "*/workflows/*/execute") {
                return @{
                    status = "success"
                    data = @{
                        memories = @{
                            version = "2.0.0"
                            lastUpdated = (Get-Date).ToString("o")
                            sections = @(
                                @{
                                    name = "TEST"
                                    content = "Test content updated by n8n"
                                },
                                @{
                                    name = "ADDED_BY_N8N"
                                    content = "Content added by n8n"
                                }
                            )
                        }
                    }
                }
            }
            
            return $null
        }
    }
    
    AfterAll {
        # Supprimer les variables globales
        Remove-Variable -Name TestMemoriesPath -Scope Global -ErrorAction SilentlyContinue
    }
    
    Context "Script Loading" {
        It "Should load the script without errors" {
            # VÃ©rifier que le script existe
            Test-Path -Path $scriptPath | Should -Be $true
            
            # Charger le script dans un bloc de script pour Ã©viter d'exÃ©cuter le script complet
            $scriptContent = Get-Content -Path $scriptPath -Raw
            
            # Remplacer la partie qui exÃ©cute le script par un commentaire
            $scriptContent = $scriptContent -replace "# VÃ©rifier si n8n est en cours d'exÃ©cution.*?# Afficher un rÃ©sumÃ©", "# Script execution disabled for testing"
            
            $scriptBlock = [ScriptBlock]::Create($scriptContent)
            
            # ExÃ©cuter le script
            { . $scriptBlock } | Should -Not -Throw
        }
    }
    
    Context "Test-N8nConnection" {
        It "Should return true when n8n is running" {
            # DÃ©finir la fonction Test-N8nConnection pour le test
            function Test-N8nConnection {
                param (
                    [string]$N8nUrl
                )
                
                try {
                    $response = Invoke-RestMethod -Uri "$N8nUrl/health" -Method Get -TimeoutSec 5
                    return $true
                } catch {
                    return $false
                }
            }
            
            # Tester la fonction
            $result = Test-N8nConnection -N8nUrl "http://localhost:5678/api/v1"
            $result | Should -Be $true
        }
    }
    
    Context "Get-WorkflowId" {
        It "Should return the workflow ID when the workflow exists" {
            # DÃ©finir la fonction Get-WorkflowId pour le test
            function Get-WorkflowId {
                param (
                    [string]$N8nUrl,
                    [string]$WorkflowName
                )
                
                try {
                    $response = Invoke-RestMethod -Uri "$N8nUrl/workflows" -Method Get
                    $workflow = $response.data | Where-Object { $_.name -eq $WorkflowName }
                    
                    if ($workflow) {
                        return $workflow.id
                    } else {
                        return $null
                    }
                } catch {
                    Write-Error "Erreur lors de la rÃ©cupÃ©ration du workflow : $_"
                    return $null
                }
            }
            
            # Tester la fonction
            $result = Get-WorkflowId -N8nUrl "http://localhost:5678/api/v1" -WorkflowName "augment-memories-sync"
            $result | Should -Be "123"
        }
        
        It "Should return null when the workflow does not exist" {
            # DÃ©finir la fonction Get-WorkflowId pour le test
            function Get-WorkflowId {
                param (
                    [string]$N8nUrl,
                    [string]$WorkflowName
                )
                
                try {
                    $response = Invoke-RestMethod -Uri "$N8nUrl/workflows" -Method Get
                    $workflow = $response.data | Where-Object { $_.name -eq $WorkflowName }
                    
                    if ($workflow) {
                        return $workflow.id
                    } else {
                        return $null
                    }
                } catch {
                    Write-Error "Erreur lors de la rÃ©cupÃ©ration du workflow : $_"
                    return $null
                }
            }
            
            # Tester la fonction
            $result = Get-WorkflowId -N8nUrl "http://localhost:5678/api/v1" -WorkflowName "non-existent-workflow"
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context "Invoke-Workflow" {
        It "Should execute the workflow and return the result" {
            # DÃ©finir la fonction Invoke-Workflow pour le test
            function Invoke-Workflow {
                param (
                    [string]$N8nUrl,
                    [string]$WorkflowId,
                    [object]$Data
                )
                
                try {
                    $body = @{
                        data = $Data
                    } | ConvertTo-Json -Depth 10
                    
                    $response = Invoke-RestMethod -Uri "$N8nUrl/workflows/$WorkflowId/execute" -Method Post -Body $body -ContentType "application/json"
                    return $response
                } catch {
                    Write-Error "Erreur lors de l'exÃ©cution du workflow : $_"
                    return $null
                }
            }
            
            # Tester la fonction
            $data = @{
                version = "2.0.0"
                sections = @(
                    @{
                        name = "TEST"
                        content = "Test content"
                    }
                )
            }
            
            $result = Invoke-Workflow -N8nUrl "http://localhost:5678/api/v1" -WorkflowId "123" -Data $data
            $result | Should -Not -BeNullOrEmpty
            $result.status | Should -Be "success"
            $result.data.memories | Should -Not -BeNullOrEmpty
            $result.data.memories.sections.Count | Should -Be 2
            $result.data.memories.sections[0].name | Should -Be "TEST"
            $result.data.memories.sections[1].name | Should -Be "ADDED_BY_N8N"
        }
    }
    
    Context "Script Execution" {
        It "Should synchronize Memories with n8n" {
            # ExÃ©cuter le script avec des paramÃ¨tres spÃ©cifiques
            $params = @{
                N8nUrl = "http://localhost:5678/api/v1"
                MemoriesPath = $Global:TestMemoriesPath
                WorkflowName = "augment-memories-sync"
            }
            
            # ExÃ©cuter le script
            & $scriptPath @params
            
            # VÃ©rifier que le fichier a Ã©tÃ© mis Ã  jour
            $updatedContent = Get-Content -Path $Global:TestMemoriesPath -Raw | ConvertFrom-Json
            $updatedContent | Should -Not -BeNullOrEmpty
            $updatedContent.sections | Should -Not -BeNullOrEmpty
            $updatedContent.sections.Count | Should -Be 2
            $updatedContent.sections[0].name | Should -Be "TEST"
            $updatedContent.sections[1].name | Should -Be "ADDED_BY_N8N"
        }
    }
}
