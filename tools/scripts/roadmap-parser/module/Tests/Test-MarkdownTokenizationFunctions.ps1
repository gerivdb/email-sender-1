<#
.SYNOPSIS
    Tests unitaires pour les fonctions de tokenization markdown.

.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions de tokenization markdown
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

# Créer un module temporaire pour les tests
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

# Charger directement les fonctions
. $parsingFunctionsPath
. $tokenizationFunctionsPath

# Définir l'énumération MarkdownTokenType et la classe MarkdownToken
Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;

public enum MarkdownTokenType {
    Header,
    Paragraph,
    BlankLine,
    HorizontalRule,
    UnorderedListItem,
    OrderedListItem,
    TaskItem,
    Bold,
    Italic,
    Code,
    CodeBlock,
    Link,
    Image,
    Reference,
    TaskId,
    TaskStatus,
    TaskAssignment,
    TaskTag,
    TaskPriority,
    TaskDate,
    Comment,
    Quote,
    Table,
    FrontMatter,
    Unknown
}

public class MarkdownToken {
    public MarkdownTokenType Type { get; set; }
    public string Value { get; set; }
    public int LineNumber { get; set; }
    public int StartPosition { get; set; }
    public int EndPosition { get; set; }
    public int IndentationLevel { get; set; }
    public List<MarkdownToken> Children { get; set; }
    public Dictionary<string, object> Metadata { get; set; }

    public MarkdownToken() {
        this.Type = MarkdownTokenType.Unknown;
        this.Value = "";
        this.LineNumber = 0;
        this.StartPosition = 0;
        this.EndPosition = 0;
        this.IndentationLevel = 0;
        this.Children = new List<MarkdownToken>();
        this.Metadata = new Dictionary<string, object>();
    }

    public MarkdownToken(MarkdownTokenType type, string value, int lineNumber, int startPosition, int endPosition) {
        this.Type = type;
        this.Value = value;
        this.LineNumber = lineNumber;
        this.StartPosition = startPosition;
        this.EndPosition = endPosition;
        this.IndentationLevel = 0;
        this.Children = new List<MarkdownToken>();
        this.Metadata = new Dictionary<string, object>();
    }

    public MarkdownToken(MarkdownTokenType type, string value, int lineNumber, int startPosition, int endPosition, int indentationLevel) {
        this.Type = type;
        this.Value = value;
        this.LineNumber = lineNumber;
        this.StartPosition = startPosition;
        this.EndPosition = endPosition;
        this.IndentationLevel = indentationLevel;
        this.Children = new List<MarkdownToken>();
        this.Metadata = new Dictionary<string, object>();
    }

    public void AddChild(MarkdownToken child) {
        this.Children.Add(child);
    }

    public void AddMetadata(string key, object value) {
        this.Metadata[key] = value;
    }

    public override string ToString() {
        return string.Format("[{0}] Line {1}: {2}", this.Type, this.LineNumber, this.Value);
    }
}
"@ -ErrorAction SilentlyContinue

Describe "Markdown Tokenization Functions" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $testDir = Join-Path -Path $env:TEMP -ChildPath "MarkdownTokenizationTests_$(Get-Random)"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null

        # Créer un fichier markdown de test
        $markdownContent = @"
# Test Markdown File

This is a test markdown file with various elements.

## Section 1

- Item 1
- Item 2
  - Nested item 1
  - Nested item 2
- Item 3

## Section 2

1. Numbered item 1
2. Numbered item 2
   1. Nested numbered item 1
   2. Nested numbered item 2
3. Numbered item 3

## Tasks

- [ ] Task 1
- [x] Task 2
  - [ ] Subtask 2.1
  - [x] Subtask 2.2
- [ ] **1.2.3** Task with ID
- [ ] Task with @assignment
- [ ] Task with #tag
"@
        $markdownFile = Join-Path -Path $testDir -ChildPath "test.md"
        $markdownContent | Out-File -FilePath $markdownFile -Encoding utf8

        # Créer un fichier markdown de roadmap de test
        $roadmapContent = @"
# Roadmap

## 1. Feature 1

- [ ] **1.1** Task 1.1
  - [ ] **1.1.1** Subtask 1.1.1
  - [x] **1.1.2** Subtask 1.1.2
- [ ] **1.2** Task 1.2
  - [ ] **1.2.1** Subtask 1.2.1
    - [ ] **1.2.1.1** Sub-subtask 1.2.1.1
    - [x] **1.2.1.2** Sub-subtask 1.2.1.2
  - [x] **1.2.2** Subtask 1.2.2

## 2. Feature 2

- [x] **2.1** Task 2.1
- [ ] **2.2** Task 2.2 @john
  - [ ] **2.2.1** Subtask 2.2.1 #important
  - [ ] **2.2.2** Subtask 2.2.2 #low-priority
"@
        $roadmapFile = Join-Path -Path $testDir -ChildPath "roadmap.md"
        $roadmapContent | Out-File -FilePath $roadmapFile -Encoding utf8
    }

    AfterAll {
        # Nettoyer le répertoire temporaire
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
    }

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
            $level = Get-IndentationLevel -Line $null
            $level | Should -Be 0
        }
    }

    Context "Get-MarkdownLineTokens" {
        It "Should tokenize a header correctly" {
            $tokens = Get-MarkdownLineTokens -Line "# Header 1" -LineNumber 1
            $tokens.Count | Should -Be 1
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::Header)
            $tokens[0].Value | Should -Be "Header 1"
            $tokens[0].Metadata["Level"] | Should -Be 1
        }

        It "Should tokenize a blank line correctly" {
            $tokens = Get-MarkdownLineTokens -Line " " -LineNumber 1
            $tokens.Count | Should -Be 1
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::BlankLine)
        }

        It "Should tokenize an unordered list item correctly" {
            $tokens = Get-MarkdownLineTokens -Line "- Item 1" -LineNumber 1
            $tokens.Count | Should -Be 1
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::UnorderedListItem)
            $tokens[0].Value | Should -Be "Item 1"
            $tokens[0].Metadata["Marker"] | Should -Be "-"
        }

        It "Should tokenize an ordered list item correctly" {
            $tokens = Get-MarkdownLineTokens -Line "1. Item 1" -LineNumber 1
            $tokens.Count | Should -Be 1
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::OrderedListItem)
            $tokens[0].Value | Should -Be "Item 1"
            $tokens[0].Metadata["Marker"] | Should -Be "1."
            $tokens[0].Metadata["Number"] | Should -Be 1
        }

        It "Should tokenize a task item correctly" {
            $tokens = Get-MarkdownLineTokens -Line "- [ ] Task 1" -LineNumber 1
            $tokens.Count | Should -Be 1
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::TaskItem)
            $tokens[0].Value | Should -Be "Task 1"
            $tokens[0].Metadata["Status"] | Should -Be " "
            $tokens[0].Metadata["Marker"] | Should -Be "-"
        }

        It "Should tokenize a completed task item correctly" {
            $tokens = Get-MarkdownLineTokens -Line "- [x] Task 2" -LineNumber 1
            $tokens.Count | Should -Be 1
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::TaskItem)
            $tokens[0].Value | Should -Be "Task 2"
            $tokens[0].Metadata["Status"] | Should -Be "x"
            $tokens[0].Metadata["Marker"] | Should -Be "-"
        }

        It "Should tokenize a task with ID correctly" {
            $tokens = Get-MarkdownLineTokens -Line "- [ ] **1.2.3** Task with ID" -LineNumber 1
            $tokens.Count | Should -Be 1
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::TaskItem)
            $tokens[0].Value | Should -Be "Task with ID"
            $tokens[0].Metadata["TaskId"] | Should -Be "1.2.3"
            $tokens[0].Children.Count | Should -Be 1
            $tokens[0].Children[0].Type | Should -Be ([MarkdownTokenType]::TaskId)
            $tokens[0].Children[0].Value | Should -Be "1.2.3"
        }

        It "Should tokenize a task with assignment correctly" {
            $tokens = Get-MarkdownLineTokens -Line "- [ ] Task with @assignment" -LineNumber 1
            $tokens.Count | Should -Be 1
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::TaskItem)
            $tokens[0].Value | Should -Be "Task with @assignment"
            $tokens[0].Metadata["Assignments"] | Should -Contain "assignment"
            $tokens[0].Children.Count | Should -Be 1
            $tokens[0].Children[0].Type | Should -Be ([MarkdownTokenType]::TaskAssignment)
            $tokens[0].Children[0].Value | Should -Be "assignment"
        }

        It "Should tokenize a task with tag correctly" {
            $tokens = Get-MarkdownLineTokens -Line "- [ ] Task with #tag" -LineNumber 1
            $tokens.Count | Should -Be 1
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::TaskItem)
            $tokens[0].Value | Should -Be "Task with #tag"
            $tokens[0].Metadata["Tags"] | Should -Contain "tag"
            $tokens[0].Children.Count | Should -Be 1
            $tokens[0].Children[0].Type | Should -Be ([MarkdownTokenType]::TaskTag)
            $tokens[0].Children[0].Value | Should -Be "tag"
        }

        It "Should tokenize a paragraph correctly" {
            $tokens = Get-MarkdownLineTokens -Line "This is a paragraph." -LineNumber 1
            $tokens.Count | Should -Be 1
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::Paragraph)
            $tokens[0].Value | Should -Be "This is a paragraph."
        }

        It "Should tokenize a horizontal rule correctly" {
            $tokens = Get-MarkdownLineTokens -Line "---" -LineNumber 1
            $tokens.Count | Should -Be 1
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::HorizontalRule)
            $tokens[0].Value | Should -Be "---"
        }

        It "Should tokenize a quote correctly" {
            $tokens = Get-MarkdownLineTokens -Line "> This is a quote" -LineNumber 1
            $tokens.Count | Should -Be 1
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::Quote)
            $tokens[0].Value | Should -Be "This is a quote"
        }

        It "Should tokenize a code block correctly" {
            $tokens = Get-MarkdownLineTokens -Line "```powershell" -LineNumber 1
            $tokens.Count | Should -Be 1
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::CodeBlock)
            $tokens[0].Value | Should -Be "powershell"
            $tokens[0].Metadata["Language"] | Should -Be "powershell"
        }
    }

    Context "ConvertFrom-MarkdownToTokens" {
        It "Should tokenize a simple markdown string correctly" {
            $markdown = @"
# Header 1

Paragraph 1

## Header 2

- Item 1
- Item 2
"@
            $tokens = ConvertFrom-MarkdownToTokens -MarkdownText $markdown
            $tokens.Count | Should -Be 5
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::Header)
            $tokens[0].Value | Should -Be "Header 1"
            $tokens[1].Type | Should -Be ([MarkdownTokenType]::BlankLine)
            $tokens[2].Type | Should -Be ([MarkdownTokenType]::Paragraph)
            $tokens[2].Value | Should -Be "Paragraph 1"
            $tokens[3].Type | Should -Be ([MarkdownTokenType]::BlankLine)
            $tokens[4].Type | Should -Be ([MarkdownTokenType]::Header)
            $tokens[4].Value | Should -Be "Header 2"
        }

        It "Should handle nested list items correctly" {
            $markdown = @"
- Item 1
  - Nested item 1
  - Nested item 2
- Item 2
"@
            $tokens = ConvertFrom-MarkdownToTokens -MarkdownText $markdown
            $tokens.Count | Should -Be 2
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::UnorderedListItem)
            $tokens[0].Value | Should -Be "Item 1"
            $tokens[0].Children.Count | Should -Be 2
            $tokens[0].Children[0].Type | Should -Be ([MarkdownTokenType]::UnorderedListItem)
            $tokens[0].Children[0].Value | Should -Be "Nested item 1"
            $tokens[0].Children[1].Type | Should -Be ([MarkdownTokenType]::UnorderedListItem)
            $tokens[0].Children[1].Value | Should -Be "Nested item 2"
            $tokens[1].Type | Should -Be ([MarkdownTokenType]::UnorderedListItem)
            $tokens[1].Value | Should -Be "Item 2"
        }

        It "Should handle nested tasks correctly" {
            $markdown = @"
- [ ] Task 1
  - [ ] Subtask 1.1
  - [x] Subtask 1.2
- [x] Task 2
"@
            $tokens = ConvertFrom-MarkdownToTokens -MarkdownText $markdown
            $tokens.Count | Should -Be 2
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::TaskItem)
            $tokens[0].Value | Should -Be "Task 1"
            $tokens[0].Metadata["Status"] | Should -Be " "
            $tokens[0].Children.Count | Should -Be 2
            $tokens[0].Children[0].Type | Should -Be ([MarkdownTokenType]::TaskItem)
            $tokens[0].Children[0].Value | Should -Be "Subtask 1.1"
            $tokens[0].Children[0].Metadata["Status"] | Should -Be " "
            $tokens[0].Children[1].Type | Should -Be ([MarkdownTokenType]::TaskItem)
            $tokens[0].Children[1].Value | Should -Be "Subtask 1.2"
            $tokens[0].Children[1].Metadata["Status"] | Should -Be "x"
            $tokens[1].Type | Should -Be ([MarkdownTokenType]::TaskItem)
            $tokens[1].Value | Should -Be "Task 2"
            $tokens[1].Metadata["Status"] | Should -Be "x"
        }
    }

    Context "ConvertFrom-MarkdownFileToTokens" {
        It "Should tokenize a markdown file correctly" {
            $tokens = ConvertFrom-MarkdownFileToTokens -FilePath $markdownFile
            $tokens | Should -Not -BeNullOrEmpty
            $tokens.Count | Should -BeGreaterThan 0
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::Header)
            $tokens[0].Value | Should -Be "Test Markdown File"
        }

        It "Should tokenize a roadmap file correctly" {
            $tokens = ConvertFrom-MarkdownFileToTokens -FilePath $roadmapFile
            $tokens | Should -Not -BeNullOrEmpty
            $tokens.Count | Should -BeGreaterThan 0
            $tokens[0].Type | Should -Be ([MarkdownTokenType]::Header)
            $tokens[0].Value | Should -Be "Roadmap"

            # Vérifier la structure de la roadmap
            $featureTokens = $tokens | Where-Object { $_.Type -eq [MarkdownTokenType]::Header -and $_.Metadata["Level"] -eq 2 }
            $featureTokens.Count | Should -Be 2
            $featureTokens[0].Value | Should -Be "1. Feature 1"
            $featureTokens[1].Value | Should -Be "2. Feature 2"

            # Vérifier les tâches
            $taskTokens = $tokens | Where-Object { $_.Type -eq [MarkdownTokenType]::TaskItem }
            $taskTokens | Should -Not -BeNullOrEmpty

            # Vérifier une tâche avec ID
            $taskWithId = $taskTokens | Where-Object { $_.Metadata.ContainsKey("TaskId") -and $_.Metadata["TaskId"] -eq "1.1" } | Select-Object -First 1
            $taskWithId | Should -Not -BeNullOrEmpty
            $taskWithId.Value | Should -Be "Task 1.1"
            $taskWithId.Metadata["Status"] | Should -Be " "

            # Vérifier une tâche avec assignation
            $taskWithAssignment = $taskTokens | Where-Object { $_.Metadata.ContainsKey("Assignments") } | Select-Object -First 1
            $taskWithAssignment | Should -Not -BeNullOrEmpty
            $taskWithAssignment.Metadata["Assignments"] | Should -Contain "john"

            # Vérifier une tâche avec tag
            $taskWithTag = $taskTokens | Where-Object { $_.Metadata.ContainsKey("Tags") } | Select-Object -First 1
            $taskWithTag | Should -Not -BeNullOrEmpty
            $taskWithTag.Metadata["Tags"] | Should -Contain "important"
        }

        It "Should handle non-existent files gracefully" {
            $nonExistentFile = Join-Path -Path $testDir -ChildPath "nonexistent.md"
            $tokens = ConvertFrom-MarkdownFileToTokens -FilePath $nonExistentFile
            $tokens | Should -BeNullOrEmpty
        }
    }

    Context "Build-MarkdownTokenTree" {
        It "Should build a tree from flat tokens correctly" {
            $tokens = @(
                [MarkdownToken]::new([MarkdownTokenType]::Header, "Header 1", 1, 0, 10, 0),
                [MarkdownToken]::new([MarkdownTokenType]::UnorderedListItem, "Item 1", 2, 0, 10, 0),
                [MarkdownToken]::new([MarkdownTokenType]::UnorderedListItem, "Nested item 1", 3, 0, 15, 1),
                [MarkdownToken]::new([MarkdownTokenType]::UnorderedListItem, "Nested item 2", 4, 0, 15, 1),
                [MarkdownToken]::new([MarkdownTokenType]::UnorderedListItem, "Item 2", 5, 0, 10, 0)
            )

            $tree = Build-MarkdownTokenTree -Tokens $tokens
            $tree.Count | Should -Be 3
            $tree[0].Type | Should -Be ([MarkdownTokenType]::Header)
            $tree[0].Value | Should -Be "Header 1"
            $tree[0].Children.Count | Should -Be 0

            $tree[1].Type | Should -Be ([MarkdownTokenType]::UnorderedListItem)
            $tree[1].Value | Should -Be "Item 1"
            $tree[1].Children.Count | Should -Be 2
            $tree[1].Children[0].Type | Should -Be ([MarkdownTokenType]::UnorderedListItem)
            $tree[1].Children[0].Value | Should -Be "Nested item 1"
            $tree[1].Children[1].Type | Should -Be ([MarkdownTokenType]::UnorderedListItem)
            $tree[1].Children[1].Value | Should -Be "Nested item 2"

            $tree[2].Type | Should -Be ([MarkdownTokenType]::UnorderedListItem)
            $tree[2].Value | Should -Be "Item 2"
            $tree[2].Children.Count | Should -Be 0
        }

        It "Should handle empty token list gracefully" {
            $tree = Build-MarkdownTokenTree -Tokens @()
            $tree | Should -BeNullOrEmpty
        }
    }

    Context "Test-MarkdownTokenTree" {
        It "Should validate a correct token tree" {
            $tokens = @(
                [MarkdownToken]::new([MarkdownTokenType]::Header, "Header 1", 1, 0, 10, 0),
                [MarkdownToken]::new([MarkdownTokenType]::UnorderedListItem, "Item 1", 2, 0, 10, 0)
            )

            $tokens[1].AddChild([MarkdownToken]::new([MarkdownTokenType]::UnorderedListItem, "Nested item 1", 3, 0, 15, 1))

            $validationResult = Test-MarkdownTokenTree -Tokens $tokens
            $validationResult.IsValid | Should -BeTrue
            $validationResult.Errors.Count | Should -Be 0
            $validationResult.Warnings.Count | Should -Be 0
        }

        It "Should detect indentation inconsistencies" {
            $tokens = @(
                [MarkdownToken]::new([MarkdownTokenType]::UnorderedListItem, "Item 1", 1, 0, 10, 0)
            )

            # Ajouter un enfant avec un niveau d'indentation incorrect
            $tokens[0].AddChild([MarkdownToken]::new([MarkdownTokenType]::UnorderedListItem, "Nested item 1", 2, 0, 15, 0))

            $validationResult = Test-MarkdownTokenTree -Tokens $tokens
            $validationResult.IsValid | Should -BeTrue  # Toujours valide, mais avec des avertissements
            $validationResult.Warnings.Count | Should -BeGreaterThan 0
        }

        It "Should handle empty token list gracefully" {
            $validationResult = Test-MarkdownTokenTree -Tokens @()
            $validationResult.IsValid | Should -BeTrue
            $validationResult.Errors.Count | Should -Be 0
            $validationResult.Warnings.Count | Should -Be 0
        }
    }
}
