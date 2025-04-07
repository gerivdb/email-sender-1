# Module de validation XML
# Ce script implémente les fonctionnalités pour valider les fichiers XML

# Configuration
$XmlValidatorConfig = @{
    # Paramètres par défaut pour la validation XML
    DefaultValidationSettings = @{
        CheckWellFormedness = $true
        ValidateAgainstSchema = $false
        SchemaPath = $null
        MaxErrors = 100
        IgnoreWarnings = $false
        IgnoreComments = $true
        IgnoreProcessingInstructions = $true
        IgnoreWhitespace = $true
    }
}

# Classe pour représenter une erreur de validation XML
class XmlValidationError {
    [string]$Message
    [string]$Type
    [int]$LineNumber
    [int]$LinePosition
    [string]$Source
    
    XmlValidationError([string]$message, [string]$type, [int]$lineNumber, [int]$linePosition, [string]$source) {
        $this.Message = $message
        $this.Type = $type
        $this.LineNumber = $lineNumber
        $this.LinePosition = $linePosition
        $this.Source = $source
    }
    
    [string] ToString() {
        return "$($this.Type) à la ligne $($this.LineNumber), position $($this.LinePosition): $($this.Message)"
    }
}

# Classe pour représenter le résultat d'une validation XML
class XmlValidationResult {
    [bool]$IsValid
    [System.Collections.ArrayList]$Errors
    [System.Collections.ArrayList]$Warnings
    [string]$XmlVersion
    [string]$Encoding
    [bool]$Standalone
    
    XmlValidationResult() {
        $this.IsValid = $true
        $this.Errors = New-Object System.Collections.ArrayList
        $this.Warnings = New-Object System.Collections.ArrayList
        $this.XmlVersion = ""
        $this.Encoding = ""
        $this.Standalone = $false
    }
    
    [string] ToString() {
        $result = "Validation XML: " + $(if ($this.IsValid) { "Réussie" } else { "Échouée" })
        $result += "`nVersion XML: $($this.XmlVersion)"
        $result += "`nEncodage: $($this.Encoding)"
        $result += "`nAutonome: $($this.Standalone)"
        $result += "`nErreurs: $($this.Errors.Count)"
        $result += "`nAvertissements: $($this.Warnings.Count)"
        
        return $result
    }
}

# Fonction pour valider une chaîne XML
function Test-XmlContent {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$XmlContent,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Settings
    )
    
    process {
        # Utiliser les paramètres fournis ou les valeurs par défaut
        $config = if ($Settings) { 
            $mergedSettings = $XmlValidatorConfig.DefaultValidationSettings.Clone()
            foreach ($key in $Settings.Keys) {
                $mergedSettings[$key] = $Settings[$key]
            }
            $mergedSettings
        } else { 
            $XmlValidatorConfig.DefaultValidationSettings.Clone() 
        }
        
        # Créer un résultat de validation
        $result = [XmlValidationResult]::new()
        
        # Créer un gestionnaire d'événements de validation
        $validationEventHandler = {
            param($sender, $e)
            
            # Créer une erreur de validation
            $error = [XmlValidationError]::new(
                $e.Message,
                $(if ($e.Severity -eq [System.Xml.Schema.XmlSeverityType]::Error) { "Erreur" } else { "Avertissement" }),
                $e.Exception.LineNumber,
                $e.Exception.LinePosition,
                $e.Exception.SourceUri
            )
            
            # Ajouter l'erreur au résultat
            if ($e.Severity -eq [System.Xml.Schema.XmlSeverityType]::Error) {
                [void]$result.Errors.Add($error)
                $result.IsValid = $false
            }
            else {
                if (-not $config.IgnoreWarnings) {
                    [void]$result.Warnings.Add($error)
                }
            }
        }
        
        # Créer un lecteur XML
        $stringReader = New-Object System.IO.StringReader($XmlContent)
        
        try {
            # Créer les paramètres du lecteur XML
            $xmlReaderSettings = New-Object System.Xml.XmlReaderSettings
            $xmlReaderSettings.IgnoreComments = $config.IgnoreComments
            $xmlReaderSettings.IgnoreProcessingInstructions = $config.IgnoreProcessingInstructions
            $xmlReaderSettings.IgnoreWhitespace = $config.IgnoreWhitespace
            
            # Configurer la validation
            if ($config.ValidateAgainstSchema -and $config.SchemaPath) {
                $xmlReaderSettings.ValidationType = [System.Xml.ValidationType]::Schema
                $xmlReaderSettings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ReportValidationWarnings
                
                # Charger le schéma
                $schemaSet = New-Object System.Xml.Schema.XmlSchemaSet
                $schemaSet.Add($null, $config.SchemaPath) | Out-Null
                $xmlReaderSettings.Schemas = $schemaSet
            }
            elseif ($config.CheckWellFormedness) {
                $xmlReaderSettings.ValidationType = [System.Xml.ValidationType]::DTD
                $xmlReaderSettings.DtdProcessing = [System.Xml.DtdProcessing]::Parse
            }
            
            # Ajouter le gestionnaire d'événements de validation
            $xmlReaderSettings.ValidationEventHandler = $validationEventHandler
            
            # Créer le lecteur XML
            $xmlReader = [System.Xml.XmlReader]::Create($stringReader, $xmlReaderSettings)
            
            # Lire le document XML
            while ($xmlReader.Read()) {
                # Extraire les informations de la déclaration XML
                if ($xmlReader.NodeType -eq [System.Xml.XmlNodeType]::XmlDeclaration) {
                    $result.XmlVersion = $xmlReader.GetAttribute("version")
                    $result.Encoding = $xmlReader.GetAttribute("encoding")
                    $result.Standalone = $xmlReader.GetAttribute("standalone") -eq "yes"
                }
                
                # Arrêter la lecture si le nombre maximal d'erreurs est atteint
                if ($config.MaxErrors -gt 0 -and $result.Errors.Count -ge $config.MaxErrors) {
                    break
                }
            }
            
            # Fermer le lecteur
            $xmlReader.Close()
        }
        catch {
            # Ajouter l'erreur au résultat
            $error = [XmlValidationError]::new(
                $_.Exception.Message,
                "Erreur",
                0,
                0,
                ""
            )
            
            [void]$result.Errors.Add($error)
            $result.IsValid = $false
        }
        finally {
            # Fermer le lecteur de chaîne
            $stringReader.Close()
        }
        
        return $result
    }
}

# Fonction pour valider un fichier XML
function Test-XmlFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$XmlPath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Settings
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $XmlPath)) {
        throw "Le fichier XML n'existe pas: $XmlPath"
    }
    
    # Lire le contenu du fichier XML
    $xmlContent = Get-Content -Path $XmlPath -Raw
    
    # Valider le contenu XML
    $result = Test-XmlContent -XmlContent $xmlContent -Settings $Settings
    
    # Ajouter le chemin du fichier aux erreurs
    foreach ($error in $result.Errors) {
        $error.Source = $XmlPath
    }
    
    foreach ($warning in $result.Warnings) {
        $warning.Source = $XmlPath
    }
    
    return $result
}

# Fonction pour générer un rapport de validation XML
function Get-XmlValidationReport {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [XmlValidationResult]$ValidationResult,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsHtml
    )
    
    process {
        if ($AsHtml) {
            # Générer un rapport HTML
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de validation XML</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        h2 { color: #666; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
    </style>
</head>
<body>
    <h1>Rapport de validation XML</h1>
    
    <h2>Résumé</h2>
    <p>Validation: <span class="$($ValidationResult.IsValid ? "success" : "error")">$($ValidationResult.IsValid ? "Réussie" : "Échouée")</span></p>
    <p>Version XML: $($ValidationResult.XmlVersion)</p>
    <p>Encodage: $($ValidationResult.Encoding)</p>
    <p>Autonome: $($ValidationResult.Standalone)</p>
    <p>Erreurs: $($ValidationResult.Errors.Count)</p>
    <p>Avertissements: $($ValidationResult.Warnings.Count)</p>
    
"@
            
            if ($ValidationResult.Errors.Count -gt 0) {
                $html += @"
    <h2>Erreurs</h2>
    <table>
        <tr>
            <th>Ligne</th>
            <th>Position</th>
            <th>Message</th>
            <th>Source</th>
        </tr>
"@
                
                foreach ($error in $ValidationResult.Errors) {
                    $html += @"
        <tr>
            <td>$($error.LineNumber)</td>
            <td>$($error.LinePosition)</td>
            <td class="error">$($error.Message)</td>
            <td>$($error.Source)</td>
        </tr>
"@
                }
                
                $html += @"
    </table>
"@
            }
            
            if ($ValidationResult.Warnings.Count -gt 0) {
                $html += @"
    <h2>Avertissements</h2>
    <table>
        <tr>
            <th>Ligne</th>
            <th>Position</th>
            <th>Message</th>
            <th>Source</th>
        </tr>
"@
                
                foreach ($warning in $ValidationResult.Warnings) {
                    $html += @"
        <tr>
            <td>$($warning.LineNumber)</td>
            <td>$($warning.LinePosition)</td>
            <td class="warning">$($warning.Message)</td>
            <td>$($warning.Source)</td>
        </tr>
"@
                }
                
                $html += @"
    </table>
"@
            }
            
            $html += @"
</body>
</html>
"@
            
            return $html
        }
        else {
            # Générer un rapport texte
            $report = "Rapport de validation XML`n"
            $report += "========================`n`n"
            
            $report += "Résumé`n"
            $report += "------`n"
            $report += "Validation: $($ValidationResult.IsValid ? "Réussie" : "Échouée")`n"
            $report += "Version XML: $($ValidationResult.XmlVersion)`n"
            $report += "Encodage: $($ValidationResult.Encoding)`n"
            $report += "Autonome: $($ValidationResult.Standalone)`n"
            $report += "Erreurs: $($ValidationResult.Errors.Count)`n"
            $report += "Avertissements: $($ValidationResult.Warnings.Count)`n`n"
            
            if ($ValidationResult.Errors.Count -gt 0) {
                $report += "Erreurs`n"
                $report += "-------`n"
                
                foreach ($error in $ValidationResult.Errors) {
                    $report += "- Ligne $($error.LineNumber), position $($error.LinePosition): $($error.Message)`n"
                    if ($error.Source) {
                        $report += "  Source: $($error.Source)`n"
                    }
                }
                
                $report += "`n"
            }
            
            if ($ValidationResult.Warnings.Count -gt 0) {
                $report += "Avertissements`n"
                $report += "-------------`n"
                
                foreach ($warning in $ValidationResult.Warnings) {
                    $report += "- Ligne $($warning.LineNumber), position $($warning.LinePosition): $($warning.Message)`n"
                    if ($warning.Source) {
                        $report += "  Source: $($warning.Source)`n"
                    }
                }
                
                $report += "`n"
            }
            
            return $report
        }
    }
}

# Fonction pour valider un fichier XML et générer un rapport
function Test-XmlFileWithReport {
    param (
        [Parameter(Mandatory = $true)]
        [string]$XmlPath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Settings,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsHtml,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )
    
    # Valider le fichier XML
    $result = Test-XmlFile -XmlPath $XmlPath -Settings $Settings
    
    # Générer le rapport
    $report = Get-XmlValidationReport -ValidationResult $result -AsHtml:$AsHtml
    
    # Enregistrer le rapport si un chemin de sortie est spécifié
    if ($OutputPath) {
        # Créer le répertoire de destination si nécessaire
        $outputDir = Split-Path -Path $OutputPath -Parent
        
        if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Déterminer l'encodage en fonction du format
        $encoding = if ($AsHtml) { "UTF8" } else { "ASCII" }
        
        # Enregistrer le rapport
        Set-Content -Path $OutputPath -Value $report -Encoding $encoding
        
        return @{
            Result = $result
            ReportPath = $OutputPath
        }
    }
    
    return @{
        Result = $result
        Report = $report
    }
}

# Fonction pour valider un fichier XML par rapport à un schéma XSD
function Test-XmlFileAgainstSchema {
    param (
        [Parameter(Mandatory = $true)]
        [string]$XmlPath,
        
        [Parameter(Mandatory = $true)]
        [string]$SchemaPath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Settings
    )
    
    # Vérifier si les fichiers existent
    if (-not (Test-Path -Path $XmlPath)) {
        throw "Le fichier XML n'existe pas: $XmlPath"
    }
    
    if (-not (Test-Path -Path $SchemaPath)) {
        throw "Le fichier de schéma n'existe pas: $SchemaPath"
    }
    
    # Créer les paramètres de validation
    $validationSettings = if ($Settings) { 
        $mergedSettings = $XmlValidatorConfig.DefaultValidationSettings.Clone()
        foreach ($key in $Settings.Keys) {
            $mergedSettings[$key] = $Settings[$key]
        }
        $mergedSettings
    } else { 
        $XmlValidatorConfig.DefaultValidationSettings.Clone() 
    }
    
    # Configurer la validation par rapport au schéma
    $validationSettings.ValidateAgainstSchema = $true
    $validationSettings.SchemaPath = $SchemaPath
    
    # Valider le fichier XML
    return Test-XmlFile -XmlPath $XmlPath -Settings $validationSettings
}

# Fonction pour générer un schéma XSD à partir d'un fichier XML
function New-XsdSchemaFromXml {
    param (
        [Parameter(Mandatory = $true)]
        [string]$XmlPath,
        
        [Parameter(Mandatory = $true)]
        [string]$SchemaPath
    )
    
    # Vérifier si le fichier XML existe
    if (-not (Test-Path -Path $XmlPath)) {
        throw "Le fichier XML n'existe pas: $XmlPath"
    }
    
    # Créer le répertoire de destination si nécessaire
    $schemaDir = Split-Path -Path $SchemaPath -Parent
    
    if (-not [string]::IsNullOrEmpty($schemaDir) -and -not (Test-Path -Path $schemaDir)) {
        New-Item -Path $schemaDir -ItemType Directory -Force | Out-Null
    }
    
    try {
        # Charger le document XML
        $xmlDoc = New-Object System.Xml.XmlDocument
        $xmlDoc.Load($XmlPath)
        
        # Créer l'inférence de schéma
        $inference = New-Object System.Xml.Schema.XmlSchemaInference
        $inference.Occurrence = [System.Xml.Schema.XmlSchemaInference+InferenceOption]::Relaxed
        $inference.TypeInference = [System.Xml.Schema.XmlSchemaInference+InferenceOption]::Relaxed
        
        # Créer un lecteur XML
        $xmlReader = [System.Xml.XmlReader]::Create($XmlPath)
        
        # Inférer le schéma
        $schemas = $inference.InferSchema($xmlReader)
        
        # Fermer le lecteur
        $xmlReader.Close()
        
        # Créer un ensemble de schémas
        $schemaSet = New-Object System.Xml.Schema.XmlSchemaSet
        
        # Ajouter les schémas inférés
        foreach ($schema in $schemas) {
            $schemaSet.Add($schema) | Out-Null
        }
        
        # Compiler les schémas
        $schemaSet.Compile()
        
        # Créer un écrivain XML
        $writerSettings = New-Object System.Xml.XmlWriterSettings
        $writerSettings.Indent = $true
        $writerSettings.IndentChars = "  "
        $writerSettings.Encoding = [System.Text.Encoding]::UTF8
        
        $writer = [System.Xml.XmlWriter]::Create($SchemaPath, $writerSettings)
        
        # Écrire le schéma
        foreach ($schema in $schemaSet.Schemas()) {
            $schema.Write($writer)
        }
        
        # Fermer l'écrivain
        $writer.Close()
        
        return $SchemaPath
    }
    catch {
        throw "Erreur lors de la génération du schéma XSD: $_"
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Test-XmlContent, Test-XmlFile
Export-ModuleMember -Function Get-XmlValidationReport, Test-XmlFileWithReport
Export-ModuleMember -Function Test-XmlFileAgainstSchema, New-XsdSchemaFromXml
