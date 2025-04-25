<#
.SYNOPSIS
    Tests unitaires basiques pour les fonctions de tokenization markdown.

.DESCRIPTION
    Ce script contient des tests unitaires basiques pour les fonctions de tokenization markdown
    du module RoadmapParser.

.NOTES
    Version:        1.0
    Author:         RoadmapParser Team
    Creation Date:  2023-08-18
#>

# Importer le module Pester s'il n'est pas déjà chargé
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Créer des versions temporaires des fichiers sans les instructions Export-ModuleMember
$modulePath = (Split-Path -Parent $PSScriptRoot)
$parsingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Parsing\MarkdownParsingFunctions.ps1"
$tokenizationFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Parsing\MarkdownTokenizationFunctions.ps1"

# Vérifier que les fichiers existent
if (-not (Test-Path -Path $parsingFunctionsPath)) {
    throw "Le fichier de fonctions de parsing n'existe pas: $parsingFunctionsPath"
}
if (-not (Test-Path -Path $tokenizationFunctionsPath)) {
    throw "Le fichier de fonctions de tokenization n'existe pas: $tokenizationFunctionsPath"
}

# Créer des versions temporaires des fichiers sans les instructions Export-ModuleMember
$parsingContent = Get-Content -Path $parsingFunctionsPath -Raw
$tokenizationContent = Get-Content -Path $tokenizationFunctionsPath -Raw

$parsingContent = $parsingContent -replace 'Export-ModuleMember.*', ''
$tokenizationContent = $tokenizationContent -replace 'Export-ModuleMember.*', ''

$tempParsingPath = Join-Path -Path $env:TEMP -ChildPath "TempMarkdownParsingFunctions.ps1"
$tempTokenizationPath = Join-Path -Path $env:TEMP -ChildPath "TempMarkdownTokenizationFunctions.ps1"

$parsingContent | Set-Content -Path $tempParsingPath -Force
$tokenizationContent | Set-Content -Path $tempTokenizationPath -Force

# Charger les fonctions à partir des fichiers temporaires
. $tempParsingPath
. $tempTokenizationPath

Describe "Markdown Tokenization Functions" {
    Context "Get-IndentationLevel" {
        It "Should return 0 for a line without indentation" {
            $level = Get-IndentationLevel -Line "No indentation"
            $level | Should -Be 0
        }

        It "Should return correct level for a line with spaces" {
            $level = Get-IndentationLevel -Line "  Two spaces"
            $level | Should -Be 1

            $level = Get-IndentationLevel -Line "    Four spaces"
            $level | Should -Be 2
        }

        It "Should handle tabs correctly" {
            $level = Get-IndentationLevel -Line "`tOne tab"
            $level | Should -Be 2
        }

        It "Should handle mixed tabs and spaces" {
            $level = Get-IndentationLevel -Line "`t  Tab and two spaces"
            $level | Should -Be 3
        }

        It "Should handle empty lines" {
            $level = Get-IndentationLevel -Line " "
            $level | Should -Be 0
        }
    }

    Context "Get-MarkdownLineTokens" {
        It "Should tokenize a header correctly" {
            $tokens = Get-MarkdownLineTokens -Line "# Header 1" -LineNumber 1
            $tokens | Should -Not -BeNullOrEmpty
            $tokens.Count | Should -Be 1
        }

        It "Should tokenize a blank line correctly" {
            $tokens = Get-MarkdownLineTokens -Line " " -LineNumber 1
            $tokens | Should -Not -BeNullOrEmpty
            $tokens.Count | Should -Be 1
        }

        It "Should tokenize an unordered list item correctly" {
            $tokens = Get-MarkdownLineTokens -Line "- Item 1" -LineNumber 1
            $tokens | Should -Not -BeNullOrEmpty
            $tokens.Count | Should -Be 1
        }

        It "Should tokenize an ordered list item correctly" {
            $tokens = Get-MarkdownLineTokens -Line "1. Item 1" -LineNumber 1
            $tokens | Should -Not -BeNullOrEmpty
            $tokens.Count | Should -Be 1
        }

        It "Should tokenize a task item correctly" {
            $tokens = Get-MarkdownLineTokens -Line "- [ ] Task 1" -LineNumber 1
            $tokens | Should -Not -BeNullOrEmpty
            $tokens.Count | Should -Be 1
        }
    }

    Context "ConvertFrom-MarkdownToTokens" {
        It "Should tokenize a simple markdown string correctly" {
            $markdown = "# Header 1"
            $tokens = ConvertFrom-MarkdownToTokens -MarkdownText $markdown
            $tokens | Should -Not -BeNullOrEmpty
        }

        It "Should handle empty markdown gracefully" {
            $tokens = ConvertFrom-MarkdownToTokens -MarkdownText " "
            $tokens | Should -Not -BeNullOrEmpty
        }
    }

    Context "Build-MarkdownTokenTree" {
        It "Should handle token list correctly" {
            $token = New-Object -TypeName PSObject
            $token | Add-Member -MemberType NoteProperty -Name "Type" -Value "Header"
            $token | Add-Member -MemberType NoteProperty -Name "Value" -Value "Header 1"
            $token | Add-Member -MemberType NoteProperty -Name "LineNumber" -Value 1
            $token | Add-Member -MemberType NoteProperty -Name "StartPosition" -Value 0
            $token | Add-Member -MemberType NoteProperty -Name "EndPosition" -Value 10
            $token | Add-Member -MemberType NoteProperty -Name "IndentationLevel" -Value 0
            $token | Add-Member -MemberType NoteProperty -Name "Children" -Value @()
            $token | Add-Member -MemberType NoteProperty -Name "Metadata" -Value @{}

            $tokens = @($token)
            $tree = Build-MarkdownTokenTree -Tokens $tokens
            $tree | Should -Not -BeNullOrEmpty
        }
    }

    Context "Test-MarkdownTokenTree" {
        It "Should handle token list correctly" {
            $token = New-Object -TypeName PSObject
            $token | Add-Member -MemberType NoteProperty -Name "Type" -Value "Header"
            $token | Add-Member -MemberType NoteProperty -Name "Value" -Value "Header 1"
            $token | Add-Member -MemberType NoteProperty -Name "LineNumber" -Value 1
            $token | Add-Member -MemberType NoteProperty -Name "StartPosition" -Value 0
            $token | Add-Member -MemberType NoteProperty -Name "EndPosition" -Value 10
            $token | Add-Member -MemberType NoteProperty -Name "IndentationLevel" -Value 0
            $token | Add-Member -MemberType NoteProperty -Name "Children" -Value @()
            $token | Add-Member -MemberType NoteProperty -Name "Metadata" -Value @{}

            $tokens = @($token)
            $validationResult = Test-MarkdownTokenTree -Tokens $tokens
            $validationResult | Should -Not -BeNullOrEmpty
        }
    }
}
