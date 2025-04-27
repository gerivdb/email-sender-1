<#
.SYNOPSIS
    Tests unitaires pour les fonctions de parsing markdown.

.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions de parsing markdown
    du module RoadmapParser.

.NOTES
    Version:        1.0
    Author:         RoadmapParser Team
    Creation Date:  2023-08-17
#>

# Importer le module Pester s'il n'est pas dÃ©jÃ  chargÃ©
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Importer le module de test
$moduleTestPath = Join-Path -Path $PSScriptRoot -ChildPath "MarkdownParsingTest.psm1"

# CrÃ©er le module de test s'il n'existe pas
if (-not (Test-Path -Path $moduleTestPath)) {
    $modulePath = (Split-Path -Parent $PSScriptRoot)
    $functionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Parsing\MarkdownParsingFunctions.ps1"

    @"
# Module temporaire pour les tests
`$functionsPath = "$functionsPath"

# Charger le contenu du fichier
`$content = Get-Content -Path `$functionsPath -Raw

# ExÃ©cuter le contenu
`$scriptBlock = [ScriptBlock]::Create(`$content)
. `$scriptBlock

# Exporter les fonctions
Export-ModuleMember -Function Get-FileEncoding, Read-MarkdownFile, Get-MarkdownContent, Test-FileBOM, ConvertFrom-YamlFrontMatter
"@ | Set-Content -Path $moduleTestPath -Encoding UTF8
}

# Importer le module de test
Import-Module $moduleTestPath -Force

Describe "Markdown Parsing Functions" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $testDir = Join-Path -Path $env:TEMP -ChildPath "MarkdownParsingTests_$(Get-Random)"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null

        # CrÃ©er un fichier markdown UTF-8 sans BOM
        $utf8Content = @"
# Test Markdown File

This is a test markdown file with UTF-8 encoding without BOM.

## Section 1

- Item 1
- Item 2
- Item 3

## Section 2

1. Numbered item 1
2. Numbered item 2
3. Numbered item 3
"@
        $utf8File = Join-Path -Path $testDir -ChildPath "utf8.md"
        $utf8Content | Out-File -FilePath $utf8File -Encoding utf8NoBOM

        # CrÃ©er un fichier markdown UTF-8 avec BOM
        $utf8BomFile = Join-Path -Path $testDir -ChildPath "utf8-bom.md"
        # Ã‰crire directement avec BOM
        $utf8Bom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($utf8BomFile, $utf8Content, $utf8Bom)

        # CrÃ©er un fichier markdown UTF-16 LE
        $utf16File = Join-Path -Path $testDir -ChildPath "utf16.md"
        $utf8Content | Out-File -FilePath $utf16File -Encoding unicode

        # CrÃ©er un fichier markdown avec YAML frontmatter
        $frontMatterContent = @"
---
title: Test Markdown with Frontmatter
author: RoadmapParser Team
date: 2023-08-17
tags: [markdown, test, frontmatter]
---

# Test Markdown File with Frontmatter

This file has YAML frontmatter at the beginning.
"@
        $frontMatterFile = Join-Path -Path $testDir -ChildPath "frontmatter.md"
        # Ã‰crire directement avec BOM
        $utf8Bom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($frontMatterFile, $frontMatterContent, $utf8Bom)
    }

    AfterAll {
        # Nettoyer le rÃ©pertoire temporaire
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
    }

    Context "Get-FileEncoding" {
        It "Should detect UTF-8 without BOM" {
            $encoding = Get-FileEncoding -FilePath $utf8File
            $encoding.WebName | Should -Be "utf-8"
        }

        It "Should detect UTF-8 with BOM" {
            $encoding = Get-FileEncoding -FilePath $utf8BomFile
            $encoding.WebName | Should -Be "utf-8"
        }

        It "Should detect UTF-16 LE" {
            $encoding = Get-FileEncoding -FilePath $utf16File
            $encoding.WebName | Should -Be "utf-16"
        }

        It "Should handle non-existent files gracefully" {
            $nonExistentFile = Join-Path -Path $testDir -ChildPath "nonexistent.md"
            $encoding = Get-FileEncoding -FilePath $nonExistentFile
            $encoding | Should -BeNullOrEmpty
        }
    }

    Context "Test-FileBOM" {
        It "Should detect BOM in UTF-8 with BOM file" {
            $hasBOM = Test-FileBOM -FilePath $utf8BomFile
            $hasBOM | Should -BeTrue
        }

        It "Should not detect BOM in UTF-8 without BOM file" {
            $hasBOM = Test-FileBOM -FilePath $utf8File
            $hasBOM | Should -BeFalse
        }

        It "Should detect BOM in UTF-16 LE file" {
            $hasBOM = Test-FileBOM -FilePath $utf16File
            $hasBOM | Should -BeTrue
        }

        It "Should handle non-existent files gracefully" {
            $nonExistentFile = Join-Path -Path $testDir -ChildPath "nonexistent.md"
            $hasBOM = Test-FileBOM -FilePath $nonExistentFile
            $hasBOM | Should -BeFalse
        }
    }

    Context "Read-MarkdownFile" {
        It "Should read UTF-8 without BOM file correctly" {
            $lines = Read-MarkdownFile -FilePath $utf8File
            $lines | Should -Not -BeNullOrEmpty
            $lines.Count | Should -BeGreaterThan 0
            $lines[0] | Should -Be "# Test Markdown File"
        }

        It "Should read UTF-8 with BOM file correctly" {
            $lines = Read-MarkdownFile -FilePath $utf8BomFile
            $lines | Should -Not -BeNullOrEmpty
            $lines.Count | Should -BeGreaterThan 0
            $lines[0] | Should -Be "# Test Markdown File"
        }

        It "Should read UTF-16 LE file correctly" {
            $lines = Read-MarkdownFile -FilePath $utf16File
            $lines | Should -Not -BeNullOrEmpty
            $lines.Count | Should -BeGreaterThan 0
            $lines[0] | Should -Be "# Test Markdown File"
        }

        It "Should handle non-existent files gracefully" {
            $nonExistentFile = Join-Path -Path $testDir -ChildPath "nonexistent.md"
            $lines = Read-MarkdownFile -FilePath $nonExistentFile
            $lines | Should -BeNullOrEmpty
        }
    }

    Context "ConvertFrom-YamlFrontMatter" {
        It "Should parse YAML frontmatter correctly" {
            $frontMatter = @(
                "title: Test Markdown with Frontmatter",
                "author: RoadmapParser Team",
                "date: 2023-08-17",
                'tags: [markdown, test, frontmatter]'
            )

            $metadata = ConvertFrom-YamlFrontMatter -FrontMatter $frontMatter
            $metadata | Should -Not -BeNullOrEmpty
            $metadata["title"] | Should -Be "Test Markdown with Frontmatter"
            $metadata["author"] | Should -Be "RoadmapParser Team"
            $metadata["date"] | Should -Be "2023-08-17"
            $metadata["tags"] | Should -Not -BeNullOrEmpty
            $metadata["tags"].Count | Should -Be 3
            $metadata["tags"][0] | Should -Be "markdown"
            $metadata["tags"][1] | Should -Be "test"
            $metadata["tags"][2] | Should -Be "frontmatter"
        }

        It "Should handle empty frontmatter gracefully" {
            $metadata = ConvertFrom-YamlFrontMatter -FrontMatter @("   ")
            $metadata | Should -BeOfType [System.Collections.Hashtable]
            $metadata.Count | Should -Be 0
        }
    }

    Context "Get-MarkdownContent" {
        It "Should get content from UTF-8 without BOM file correctly" {
            $content = Get-MarkdownContent -FilePath $utf8File
            $content | Should -Not -BeNullOrEmpty
            $content.FilePath | Should -Be $utf8File
            $content.Encoding.WebName | Should -Be "utf-8"
            $content.Lines | Should -Not -BeNullOrEmpty
            $content.LineCount | Should -BeGreaterThan 0
            $content.HasBOM | Should -BeFalse
            $content.Lines[0] | Should -Be "# Test Markdown File"
        }

        It "Should get content from UTF-8 with BOM file correctly" {
            $content = Get-MarkdownContent -FilePath $utf8BomFile
            $content | Should -Not -BeNullOrEmpty
            $content.FilePath | Should -Be $utf8BomFile
            $content.Encoding.WebName | Should -Be "utf-8"
            $content.Lines | Should -Not -BeNullOrEmpty
            $content.LineCount | Should -BeGreaterThan 0
            $content.HasBOM | Should -BeTrue
            $content.Lines[0] | Should -Be "# Test Markdown File"
        }

        It "Should get content from UTF-16 LE file correctly" {
            $content = Get-MarkdownContent -FilePath $utf16File
            $content | Should -Not -BeNullOrEmpty
            $content.FilePath | Should -Be $utf16File
            $content.Encoding.WebName | Should -Be "utf-16"
            $content.Lines | Should -Not -BeNullOrEmpty
            $content.LineCount | Should -BeGreaterThan 0
            $content.HasBOM | Should -BeTrue
            $content.Lines[0] | Should -Be "# Test Markdown File"
        }

        It "Should extract YAML frontmatter correctly" {
            $content = Get-MarkdownContent -FilePath $frontMatterFile
            $content | Should -Not -BeNullOrEmpty
            $content.Metadata | Should -Not -BeNullOrEmpty
            $content.Metadata["title"] | Should -Be "Test Markdown with Frontmatter"
            $content.Metadata["author"] | Should -Be "RoadmapParser Team"
            $content.Metadata["date"] | Should -Be "2023-08-17"
            $content.Metadata["tags"] | Should -Not -BeNullOrEmpty
        }

        It "Should handle non-existent files gracefully" {
            $nonExistentFile = Join-Path -Path $testDir -ChildPath "nonexistent.md"
            $content = Get-MarkdownContent -FilePath $nonExistentFile
            $content | Should -BeNullOrEmpty
        }
    }
}
