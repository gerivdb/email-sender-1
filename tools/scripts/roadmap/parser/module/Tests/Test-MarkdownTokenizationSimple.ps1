<#
.SYNOPSIS
    Tests unitaires simplifiÃ©s pour les fonctions de tokenization markdown.

.DESCRIPTION
    Ce script contient des tests unitaires simplifiÃ©s pour les fonctions de tokenization markdown
    du module RoadmapParser.

.NOTES
    Version:        1.0
    Author:         RoadmapParser Team
    Creation Date:  2023-08-18
#>

# Importer le module Pester s'il n'est pas dÃ©jÃ  chargÃ©
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# CrÃ©er des versions temporaires des fichiers sans les instructions Export-ModuleMember
$modulePath = (Split-Path -Parent $PSScriptRoot)
$parsingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Parsing\MarkdownParsingFunctions.ps1"
$tokenizationFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Parsing\MarkdownTokenizationFunctions.ps1"

# VÃ©rifier que les fichiers existent
if (-not (Test-Path -Path $parsingFunctionsPath)) {
    throw "Le fichier de fonctions de parsing n'existe pas: $parsingFunctionsPath"
}
if (-not (Test-Path -Path $tokenizationFunctionsPath)) {
    throw "Le fichier de fonctions de tokenization n'existe pas: $tokenizationFunctionsPath"
}

# CrÃ©er des versions temporaires des fichiers sans les instructions Export-ModuleMember
$parsingContent = Get-Content -Path $parsingFunctionsPath -Raw
$tokenizationContent = Get-Content -Path $tokenizationFunctionsPath -Raw

$parsingContent = $parsingContent -replace 'Export-ModuleMember.*', ''
$tokenizationContent = $tokenizationContent -replace 'Export-ModuleMember.*', ''

$tempParsingPath = Join-Path -Path $env:TEMP -ChildPath "TempMarkdownParsingFunctions.ps1"
$tempTokenizationPath = Join-Path -Path $env:TEMP -ChildPath "TempMarkdownTokenizationFunctions.ps1"

$parsingContent | Set-Content -Path $tempParsingPath -Force
$tokenizationContent | Set-Content -Path $tempTokenizationPath -Force

# Charger les fonctions Ã  partir des fichiers temporaires
. $tempParsingPath
. $tempTokenizationPath

# DÃ©finir l'Ã©numÃ©ration MarkdownTokenType et la classe MarkdownToken
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
}
