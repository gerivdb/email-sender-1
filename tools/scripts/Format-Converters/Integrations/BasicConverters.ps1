#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre les convertisseurs de base pour les formats courants.

.DESCRIPTION
    Ce script enregistre les convertisseurs de base pour les formats courants tels que
    JSON, XML, HTML, CSV, YAML, Markdown, etc.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Enregistrer le convertisseur JSON
Register-FormatConverter -Format "json" -ConverterInfo @{
    Name = "JSON"
    Description = "JavaScript Object Notation"
    Extensions = @(".json")
    DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
    ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw | ConvertFrom-Json }
    ExportFunction = { param($Data, $FilePath) $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $FilePath -Encoding UTF8 }
    AnalyzeFunction = {
        param($FilePath)
        
        $content = Get-Content -Path $FilePath -Raw
        $isValid = $false
        
        try {
            $null = $content | ConvertFrom-Json
            $isValid = $true
        }
        catch {
            $isValid = $false
        }
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Format = "JSON"
            IsValid = $isValid
            Properties = if ($isValid) {
                ($content | ConvertFrom-Json).PSObject.Properties.Name
            }
            else {
                @()
            }
        }
    }
    ValidateFunction = {
        param($Content)
        
        try {
            $null = $Content | ConvertFrom-Json
            return $true
        }
        catch {
            return $false
        }
    }
}

# Enregistrer le convertisseur XML
Register-FormatConverter -Format "xml" -ConverterInfo @{
    Name = "XML"
    Description = "eXtensible Markup Language"
    Extensions = @(".xml", ".svg", ".xhtml")
    DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
    ImportFunction = { param($FilePath) [xml](Get-Content -Path $FilePath -Raw) }
    ExportFunction = { param($Data, $FilePath) $Data.Save($FilePath) }
    AnalyzeFunction = {
        param($FilePath)
        
        $content = Get-Content -Path $FilePath -Raw
        $isValid = $false
        
        try {
            $xml = [xml]$content
            $isValid = $true
        }
        catch {
            $isValid = $false
        }
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Format = "XML"
            IsValid = $isValid
            RootElement = if ($isValid) { $xml.DocumentElement.Name } else { $null }
            Elements = if ($isValid) {
                $xml.DocumentElement.ChildNodes | ForEach-Object { $_.Name }
            }
            else {
                @()
            }
        }
    }
    ValidateFunction = {
        param($Content)
        
        try {
            $null = [xml]$Content
            return $true
        }
        catch {
            return $false
        }
    }
}

# Enregistrer le convertisseur HTML
Register-FormatConverter -Format "html" -ConverterInfo @{
    Name = "HTML"
    Description = "HyperText Markup Language"
    Extensions = @(".html", ".htm")
    DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
    ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
    ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
    AnalyzeFunction = {
        param($FilePath)
        
        $content = Get-Content -Path $FilePath -Raw
        $isValid = $false
        
        try {
            $html = [xml]$content
            $isValid = $true
        }
        catch {
            $isValid = $false
        }
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Format = "HTML"
            IsValid = $isValid
            Title = if ($isValid -and $html.html.head.title) {
                $html.html.head.title
            }
            else {
                $null
            }
            Elements = if ($isValid) {
                $html.html.body.ChildNodes | ForEach-Object { $_.Name }
            }
            else {
                @()
            }
        }
    }
    ValidateFunction = {
        param($Content)
        
        return $Content -match "<html|<!DOCTYPE html"
    }
}

# Enregistrer le convertisseur CSV
Register-FormatConverter -Format "csv" -ConverterInfo @{
    Name = "CSV"
    Description = "Comma-Separated Values"
    Extensions = @(".csv")
    DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
    ImportFunction = { param($FilePath) Import-Csv -Path $FilePath }
    ExportFunction = { param($Data, $FilePath) $Data | Export-Csv -Path $FilePath -NoTypeInformation -Encoding UTF8 }
    AnalyzeFunction = {
        param($FilePath)
        
        $isValid = $false
        $headers = @()
        $rowCount = 0
        
        try {
            $csv = Import-Csv -Path $FilePath
            $isValid = $true
            $headers = $csv[0].PSObject.Properties.Name
            $rowCount = $csv.Count
        }
        catch {
            $isValid = $false
        }
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Format = "CSV"
            IsValid = $isValid
            Headers = $headers
            RowCount = $rowCount
        }
    }
    ValidateFunction = {
        param($Content)
        
        try {
            $null = $Content | ConvertFrom-Csv
            return $true
        }
        catch {
            return $false
        }
    }
}

# Enregistrer le convertisseur YAML
Register-FormatConverter -Format "yaml" -ConverterInfo @{
    Name = "YAML"
    Description = "YAML Ain't Markup Language"
    Extensions = @(".yaml", ".yml")
    DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
    ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
    ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
    AnalyzeFunction = {
        param($FilePath)
        
        $content = Get-Content -Path $FilePath -Raw
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Format = "YAML"
            IsValid = $content -match "^---\s*$"
        }
    }
    ValidateFunction = {
        param($Content)
        
        return $Content -match "^---\s*$"
    }
}

# Enregistrer le convertisseur Markdown
Register-FormatConverter -Format "markdown" -ConverterInfo @{
    Name = "MARKDOWN"
    Description = "Markdown Text Format"
    Extensions = @(".md", ".markdown")
    DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
    ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
    ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
    AnalyzeFunction = {
        param($FilePath)
        
        $content = Get-Content -Path $FilePath -Raw
        $headers = [regex]::Matches($content, "^#{1,6}\s+(.+)$", "Multiline") | ForEach-Object { $_.Groups[1].Value }
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Format = "MARKDOWN"
            Headers = $headers
        }
    }
    ValidateFunction = {
        param($Content)
        
        return $Content -match "^#\s+|^##\s+|^\*\s+|^-\s+"
    }
}

# Enregistrer le convertisseur JavaScript
Register-FormatConverter -Format "javascript" -ConverterInfo @{
    Name = "JAVASCRIPT"
    Description = "JavaScript Code"
    Extensions = @(".js")
    DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
    ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
    ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
    AnalyzeFunction = {
        param($FilePath)
        
        $content = Get-Content -Path $FilePath -Raw
        $functions = [regex]::Matches($content, "function\s+(\w+)\s*\(", "Multiline") | ForEach-Object { $_.Groups[1].Value }
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Format = "JAVASCRIPT"
            Functions = $functions
        }
    }
    ValidateFunction = {
        param($Content)
        
        return $Content -match "function\s+\w+\s*\(|var\s+\w+\s*=|let\s+\w+\s*=|const\s+\w+\s*="
    }
}

# Enregistrer le convertisseur CSS
Register-FormatConverter -Format "css" -ConverterInfo @{
    Name = "CSS"
    Description = "Cascading Style Sheets"
    Extensions = @(".css")
    DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
    ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
    ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
    AnalyzeFunction = {
        param($FilePath)
        
        $content = Get-Content -Path $FilePath -Raw
        $selectors = [regex]::Matches($content, "([^{]+)\s*\{", "Multiline") | ForEach-Object { $_.Groups[1].Value.Trim() }
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Format = "CSS"
            Selectors = $selectors
        }
    }
    ValidateFunction = {
        param($Content)
        
        return $Content -match "\w+\s*\{|#\w+\s*\{|\.\w+\s*\{"
    }
}

# Enregistrer le convertisseur PowerShell
Register-FormatConverter -Format "powershell" -ConverterInfo @{
    Name = "POWERSHELL"
    Description = "PowerShell Script"
    Extensions = @(".ps1", ".psm1", ".psd1")
    DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
    ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
    ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
    AnalyzeFunction = {
        param($FilePath)
        
        $content = Get-Content -Path $FilePath -Raw
        $functions = [regex]::Matches($content, "function\s+(\w+-\w+)", "Multiline") | ForEach-Object { $_.Groups[1].Value }
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Format = "POWERSHELL"
            Functions = $functions
        }
    }
    ValidateFunction = {
        param($Content)
        
        return $Content -match "function\s+\w+-\w+|\$\w+\s*=|if\s*\(|foreach\s*\("
    }
}

# Enregistrer le convertisseur Python
Register-FormatConverter -Format "python" -ConverterInfo @{
    Name = "PYTHON"
    Description = "Python Script"
    Extensions = @(".py")
    DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
    ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
    ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
    AnalyzeFunction = {
        param($FilePath)
        
        $content = Get-Content -Path $FilePath -Raw
        $functions = [regex]::Matches($content, "def\s+(\w+)\s*\(", "Multiline") | ForEach-Object { $_.Groups[1].Value }
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Format = "PYTHON"
            Functions = $functions
        }
    }
    ValidateFunction = {
        param($Content)
        
        return $Content -match "def\s+\w+\s*\(|import\s+\w+|from\s+\w+\s+import"
    }
}

# Enregistrer le convertisseur INI
Register-FormatConverter -Format "ini" -ConverterInfo @{
    Name = "INI"
    Description = "Configuration File"
    Extensions = @(".ini", ".cfg", ".conf")
    DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
    ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
    ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
    AnalyzeFunction = {
        param($FilePath)
        
        $content = Get-Content -Path $FilePath -Raw
        $sections = [regex]::Matches($content, "^\[(\w+)\]", "Multiline") | ForEach-Object { $_.Groups[1].Value }
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Format = "INI"
            Sections = $sections
        }
    }
    ValidateFunction = {
        param($Content)
        
        return $Content -match "^\[\w+\]|^\w+\s*="
    }
}

# Enregistrer le convertisseur TEXT
Register-FormatConverter -Format "text" -ConverterInfo @{
    Name = "TEXT"
    Description = "Plain Text"
    Extensions = @(".txt", ".text", ".log")
    DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
    ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
    ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
    AnalyzeFunction = {
        param($FilePath)
        
        $content = Get-Content -Path $FilePath -Raw
        $lineCount = ($content -split "`n").Count
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Format = "TEXT"
            LineCount = $lineCount
        }
    }
    ValidateFunction = {
        param($Content)
        
        return $true
    }
}

