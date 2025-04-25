#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'intÃ©gration de la dÃ©tection de format pour Format-Converters.

.DESCRIPTION
    Ce module intÃ¨gre le systÃ¨me de dÃ©tection de format amÃ©liorÃ© dans le module Format-Converters.
    Il enregistre les fonctions de dÃ©tection de format et les rend disponibles pour le module principal.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Fonction pour enregistrer les dÃ©tecteurs de format
function Register-FormatDetectors {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Enregistrement des dÃ©tecteurs de format..."
    
    # Enregistrer le dÃ©tecteur de format JSON
    Register-FormatConverter -Format "json" -ConverterInfo @{
        Name = "JSON"
        Description = "JavaScript Object Notation"
        Extensions = @(".json")
        DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
        ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw | ConvertFrom-Json }
        ExportFunction = { param($Data, $FilePath) $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $FilePath -Encoding UTF8 }
        ValidateFunction = { param($Content) 
            try {
                $null = $Content | ConvertFrom-Json
                return $true
            }
            catch {
                return $false
            }
        }
    }
    
    # Enregistrer le dÃ©tecteur de format XML
    Register-FormatConverter -Format "xml" -ConverterInfo @{
        Name = "XML"
        Description = "eXtensible Markup Language"
        Extensions = @(".xml", ".svg", ".xhtml")
        DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
        ImportFunction = { param($FilePath) [xml](Get-Content -Path $FilePath -Raw) }
        ExportFunction = { param($Data, $FilePath) $Data.Save($FilePath) }
        ValidateFunction = { param($Content) 
            try {
                $null = [xml]$Content
                return $true
            }
            catch {
                return $false
            }
        }
    }
    
    # Enregistrer le dÃ©tecteur de format HTML
    Register-FormatConverter -Format "html" -ConverterInfo @{
        Name = "HTML"
        Description = "HyperText Markup Language"
        Extensions = @(".html", ".htm")
        DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
        ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
        ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
        ValidateFunction = { param($Content) 
            return $Content -match "<html|<!DOCTYPE html"
        }
    }
    
    # Enregistrer le dÃ©tecteur de format CSV
    Register-FormatConverter -Format "csv" -ConverterInfo @{
        Name = "CSV"
        Description = "Comma-Separated Values"
        Extensions = @(".csv")
        DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
        ImportFunction = { param($FilePath) Import-Csv -Path $FilePath }
        ExportFunction = { param($Data, $FilePath) $Data | Export-Csv -Path $FilePath -NoTypeInformation -Encoding UTF8 }
        ValidateFunction = { param($Content) 
            try {
                $null = $Content | ConvertFrom-Csv
                return $true
            }
            catch {
                return $false
            }
        }
    }
    
    # Enregistrer le dÃ©tecteur de format YAML
    Register-FormatConverter -Format "yaml" -ConverterInfo @{
        Name = "YAML"
        Description = "YAML Ain't Markup Language"
        Extensions = @(".yaml", ".yml")
        DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
        ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
        ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
        ValidateFunction = { param($Content) 
            return $Content -match "^---\s*$"
        }
    }
    
    # Enregistrer le dÃ©tecteur de format Markdown
    Register-FormatConverter -Format "markdown" -ConverterInfo @{
        Name = "MARKDOWN"
        Description = "Markdown Text Format"
        Extensions = @(".md", ".markdown")
        DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
        ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
        ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
        ValidateFunction = { param($Content) 
            return $Content -match "^#\s+|^##\s+|^\*\s+|^-\s+"
        }
    }
    
    # Enregistrer le dÃ©tecteur de format JavaScript
    Register-FormatConverter -Format "javascript" -ConverterInfo @{
        Name = "JAVASCRIPT"
        Description = "JavaScript Code"
        Extensions = @(".js")
        DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
        ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
        ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
        ValidateFunction = { param($Content) 
            return $Content -match "function\s+\w+\s*\(|var\s+\w+\s*=|let\s+\w+\s*=|const\s+\w+\s*="
        }
    }
    
    # Enregistrer le dÃ©tecteur de format CSS
    Register-FormatConverter -Format "css" -ConverterInfo @{
        Name = "CSS"
        Description = "Cascading Style Sheets"
        Extensions = @(".css")
        DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
        ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
        ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
        ValidateFunction = { param($Content) 
            return $Content -match "\w+\s*\{|#\w+\s*\{|\.\w+\s*\{"
        }
    }
    
    # Enregistrer le dÃ©tecteur de format PowerShell
    Register-FormatConverter -Format "powershell" -ConverterInfo @{
        Name = "POWERSHELL"
        Description = "PowerShell Script"
        Extensions = @(".ps1", ".psm1", ".psd1")
        DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
        ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
        ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
        ValidateFunction = { param($Content) 
            return $Content -match "function\s+\w+-\w+|\$\w+\s*=|if\s*\(|foreach\s*\("
        }
    }
    
    # Enregistrer le dÃ©tecteur de format Python
    Register-FormatConverter -Format "python" -ConverterInfo @{
        Name = "PYTHON"
        Description = "Python Script"
        Extensions = @(".py")
        DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
        ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
        ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
        ValidateFunction = { param($Content) 
            return $Content -match "def\s+\w+\s*\(|import\s+\w+|from\s+\w+\s+import"
        }
    }
    
    # Enregistrer le dÃ©tecteur de format INI
    Register-FormatConverter -Format "ini" -ConverterInfo @{
        Name = "INI"
        Description = "Configuration File"
        Extensions = @(".ini", ".cfg", ".conf")
        DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
        ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
        ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
        ValidateFunction = { param($Content) 
            return $Content -match "^\[\w+\]|^\w+\s*="
        }
    }
    
    # Enregistrer le dÃ©tecteur de format texte
    Register-FormatConverter -Format "text" -ConverterInfo @{
        Name = "TEXT"
        Description = "Plain Text"
        Extensions = @(".txt", ".text", ".log")
        DetectFunction = { param($FilePath) Test-FileFormat -FilePath $FilePath }
        ImportFunction = { param($FilePath) Get-Content -Path $FilePath -Raw }
        ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
        ValidateFunction = { param($Content) 
            return $true
        }
    }
    
    Write-Verbose "DÃ©tecteurs de format enregistrÃ©s avec succÃ¨s."
}

# Exporter les fonctions
Export-ModuleMember -Function Register-FormatDetectors

