# Module temporaire pour les tests
$modulePath = (Split-Path -Parent $PSScriptRoot)
$parsingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Parsing\MarkdownParsingFunctions.ps1"
$tokenizationFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Parsing\MarkdownTokenizationFunctions.ps1"

# DÃ©finir l'Ã©numÃ©ration MarkdownTokenType
Add-Type -TypeDefinition @"
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
"@ -ErrorAction SilentlyContinue

# DÃ©finir la classe MarkdownToken
Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;

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

# Charger le contenu des fichiers
$parsingContent = Get-Content -Path $parsingFunctionsPath -Raw
$tokenizationContent = Get-Content -Path $tokenizationFunctionsPath -Raw

# ExÃ©cuter le contenu
$parsingScriptBlock = [ScriptBlock]::Create($parsingContent)
$tokenizationScriptBlock = [ScriptBlock]::Create($tokenizationContent)
. $parsingScriptBlock
. $tokenizationScriptBlock

# Exporter les fonctions
Export-ModuleMember -Function Get-FileEncoding, Read-MarkdownFile, Get-MarkdownContent, Test-FileBOM, ConvertFrom-YamlFrontMatter
Export-ModuleMember -Function ConvertFrom-MarkdownToTokens, ConvertFrom-MarkdownFileToTokens, Get-MarkdownLineTokens, Get-IndentationLevel, Build-MarkdownTokenTree, Test-MarkdownTokenTree
