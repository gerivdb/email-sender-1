<#
.SYNOPSIS
    Façade pour le traitement de fichiers.
.DESCRIPTION
    Ce module fournit une façade pour le traitement de fichiers dans différents formats.
.NOTES
    Version: 1.0
    Auteur: Équipe de développement
#>

# Variables globales
$script:IsInitialized = $false
$script:availableProcessors = @{}
$script:formatDetectors = @{}
$script:validators = @{}

function Initialize-FileProcessingFacade {
    <#
    .SYNOPSIS
        Initialise la façade de traitement de fichiers.
    .DESCRIPTION
        Initialise la façade de traitement de fichiers en chargeant les processeurs disponibles.
    .EXAMPLE
        Initialize-FileProcessingFacade
    .OUTPUTS
        [bool] - $true si l'initialisation a réussi, $false sinon.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    # Vérifier si la façade est déjà initialisée
    if ($script:IsInitialized) {
        Write-Verbose "La façade de traitement de fichiers est déjà initialisée."
        return $true
    }

    try {
        # Initialiser les processeurs de fichiers
        $script:availableProcessors = @{
            "JSON" = @{
                "ToXML"  = ${function:ConvertFrom-JsonToXml}
                "ToCSV"  = ${function:ConvertFrom-JsonToCsv}
                "ToYAML" = ${function:ConvertFrom-JsonToYaml}
                "ToTEXT" = ${function:ConvertFrom-JsonToText}
            }
            "XML"  = @{
                "ToJSON" = ${function:ConvertFrom-XmlToJson}
                "ToCSV"  = ${function:ConvertFrom-XmlToCsv}
                "ToYAML" = ${function:ConvertFrom-XmlToYaml}
                "ToTEXT" = ${function:ConvertFrom-XmlToText}
            }
            "CSV"  = @{
                "ToJSON" = ${function:ConvertFrom-CsvToJson}
                "ToXML"  = ${function:ConvertFrom-CsvToXml}
                "ToYAML" = ${function:ConvertFrom-CsvToYaml}
                "ToTEXT" = ${function:ConvertFrom-CsvToText}
            }
            "YAML" = @{
                "ToJSON" = ${function:ConvertFrom-YamlToJson}
                "ToXML"  = ${function:ConvertFrom-YamlToXml}
                "ToCSV"  = ${function:ConvertFrom-YamlToCsv}
                "ToTEXT" = ${function:ConvertFrom-YamlToText}
            }
            "TEXT" = @{
                "ToJSON" = ${function:ConvertFrom-TextToJson}
                "ToXML"  = ${function:ConvertFrom-TextToXml}
                "ToCSV"  = ${function:ConvertFrom-TextToCsv}
                "ToYAML" = ${function:ConvertFrom-TextToYaml}
            }
        }

        # Initialiser les détecteurs de format
        $script:formatDetectors = @{
            "JSON" = ${function:Test-JsonFormat}
            "XML"  = ${function:Test-XmlFormat}
            "CSV"  = ${function:Test-CsvFormat}
            "YAML" = ${function:Test-YamlFormat}
            "TEXT" = ${function:Test-TextFormat}
        }

        # Initialiser les validateurs
        $script:validators = @{
            "JSON" = ${function:Test-JsonValidity}
            "XML"  = ${function:Test-XmlValidity}
            "CSV"  = ${function:Test-CsvValidity}
            "YAML" = ${function:Test-YamlValidity}
            "TEXT" = ${function:Test-TextValidity}
        }

        $script:IsInitialized = $true
        Write-Verbose "La façade de traitement de fichiers a été initialisée avec succès."
        return $true
    } catch {
        Write-Error "Erreur lors de l'initialisation de la façade de traitement de fichiers : $_"
        return $false
    }
}

function Get-FileFormat {
    <#
    .SYNOPSIS
        Détecte le format d'un fichier.
    .DESCRIPTION
        Détecte le format d'un fichier en utilisant les détecteurs de format disponibles.
    .PARAMETER FilePath
        Chemin du fichier à analyser.
    .EXAMPLE
        Get-FileFormat -FilePath "C:\temp\data.json"
    .OUTPUTS
        [string] - Le format détecté (JSON, XML, CSV, YAML, TEXT).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Vérifier que la façade est initialisée
    if (-not $script:IsInitialized) {
        $initialized = Initialize-FileProcessingFacade
        if (-not $initialized) {
            Write-Error "La façade de traitement de fichiers n'est pas initialisée."
            return "UNKNOWN"
        }
    }

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        return "UNKNOWN"
    }

    # Détecter le format du fichier
    foreach ($format in $script:formatDetectors.Keys) {
        $detector = $script:formatDetectors[$format]
        if (& $detector -FilePath $FilePath) {
            Write-Verbose "Format détecté : $format"
            return $format
        }
    }

    # Si aucun format n'est détecté, retourner TEXT par défaut
    Write-Verbose "Aucun format spécifique détecté, utilisation de TEXT par défaut."
    return "TEXT"
}

function Convert-FileFormat {
    <#
    .SYNOPSIS
        Convertit un fichier d'un format à un autre.
    .DESCRIPTION
        Convertit un fichier d'un format à un autre en utilisant les processeurs disponibles.
    .PARAMETER InputFile
        Chemin du fichier d'entrée.
    .PARAMETER OutputFile
        Chemin du fichier de sortie.
    .PARAMETER InputFormat
        Format du fichier d'entrée (AUTO, JSON, XML, CSV, YAML, TEXT).
    .PARAMETER OutputFormat
        Format du fichier de sortie (JSON, XML, CSV, YAML, TEXT).
    .EXAMPLE
        Convert-FileFormat -InputFile "C:\temp\data.json" -OutputFile "C:\temp\data.xml" -InputFormat "JSON" -OutputFormat "XML"
    .OUTPUTS
        [bool] - $true si la conversion a réussi, $false sinon.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "CSV", "YAML", "TEXT")]
        [string]$InputFormat = "AUTO",

        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "XML", "CSV", "YAML", "TEXT")]
        [string]$OutputFormat
    )

    # Vérifier que la façade est initialisée
    if (-not $script:IsInitialized) {
        $initialized = Initialize-FileProcessingFacade
        if (-not $initialized) {
            Write-Error "La façade de traitement de fichiers n'est pas initialisée."
            return $false
        }
    }

    # Vérifier que le fichier d'entrée existe
    if (-not (Test-Path -Path $InputFile -PathType Leaf)) {
        Write-Error "Le fichier d'entrée '$InputFile' n'existe pas."
        return $false
    }

    # Détecter le format d'entrée si nécessaire
    if ($InputFormat -eq "AUTO") {
        $InputFormat = Get-FileFormat -FilePath $InputFile
        Write-Verbose "Format d'entrée détecté : $InputFormat"
    }

    # Vérifier que le format d'entrée est supporté
    if (-not $script:availableProcessors.ContainsKey($InputFormat)) {
        Write-Error "Le format d'entrée '$InputFormat' n'est pas supporté."
        return $false
    }

    # Vérifier que la conversion est supportée
    $targetKey = "To$OutputFormat"
    if (-not $script:availableProcessors[$InputFormat].ContainsKey($targetKey)) {
        Write-Error "La conversion de '$InputFormat' vers '$OutputFormat' n'est pas supportée."
        return $false
    }

    try {
        # Obtenir le processeur de conversion
        $processor = $script:availableProcessors[$InputFormat][$targetKey]

        # Effectuer la conversion
        & $processor -InputFile $InputFile -OutputFile $OutputFile

        # Vérifier que le fichier de sortie a été créé
        if (Test-Path -Path $OutputFile -PathType Leaf) {
            Write-Verbose "Conversion réussie de '$InputFormat' vers '$OutputFormat'."
            return $true
        } else {
            Write-Error "La conversion a échoué. Le fichier de sortie n'a pas été créé."
            return $false
        }
    } catch {
        Write-Error "Erreur lors de la conversion du fichier : $_"
        return $false
    }
}

function Get-FileAnalysisReport {
    <#
    .SYNOPSIS
        Génère un rapport d'analyse pour un fichier.
    .DESCRIPTION
        Génère un rapport d'analyse pour un fichier, incluant des statistiques et des informations sur la structure.
    .PARAMETER FilePath
        Chemin du fichier à analyser.
    .PARAMETER Format
        Format du fichier (AUTO, JSON, XML, CSV, YAML, TEXT).
    .PARAMETER AsHtml
        Indique si le rapport doit être généré au format HTML.
    .EXAMPLE
        Get-FileAnalysisReport -FilePath "C:\temp\data.json" -Format "JSON"
    .OUTPUTS
        [PSCustomObject] - Rapport d'analyse du fichier.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "CSV", "YAML", "TEXT")]
        [string]$Format = "AUTO",

        [Parameter(Mandatory = $false)]
        [switch]$AsHtml
    )

    # Vérifier que la façade est initialisée
    if (-not $script:IsInitialized) {
        $initialized = Initialize-FileProcessingFacade
        if (-not $initialized) {
            Write-Error "La façade de traitement de fichiers n'est pas initialisée."
            return $null
        }
    }

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        return $null
    }

    # Détecter le format si nécessaire
    if ($Format -eq "AUTO") {
        $Format = Get-FileFormat -FilePath $FilePath
        Write-Verbose "Format détecté : $Format"
    }

    # Analyser le fichier en fonction de son format
    $fileInfo = Get-Item -Path $FilePath
    $fileContent = Get-Content -Path $FilePath -Raw
    $fileSize = $fileInfo.Length
    $fileLines = ($fileContent -split "`n").Count
    $fileExtension = $fileInfo.Extension
    $fileCreationTime = $fileInfo.CreationTime
    $fileLastWriteTime = $fileInfo.LastWriteTime

    # Créer l'objet de rapport de base
    $report = [PSCustomObject]@{
        FilePath          = $FilePath
        FileName          = $fileInfo.Name
        FileExtension     = $fileExtension
        FileSize          = $fileSize
        FileSizeFormatted = "{0:N2} KB" -f ($fileSize / 1KB)
        LineCount         = $fileLines
        Format            = $Format
        CreationTime      = $fileCreationTime
        LastWriteTime     = $fileLastWriteTime
        Analysis          = $null
    }

    # Analyser le contenu en fonction du format
    switch -Regex ($Format) {
        "JSON" {
            try {
                $json = ConvertFrom-Json -InputObject $fileContent -ErrorAction Stop
                $jsonStructure = Get-JsonStructure -JsonObject $json
                $report.Analysis = [PSCustomObject]@{
                    structure = $jsonStructure
                    columns   = Get-JsonColumns -JsonObject $json
                }
            } catch {
                Write-Warning "Erreur lors de l'analyse du fichier JSON : $_"
                $report.Analysis = [PSCustomObject]@{
                    error = $_.Exception.Message
                }
            }
        }
        "XML" {
            try {
                $xml = [xml]$fileContent
                $xmlStructure = Get-XmlStructure -XmlObject $xml
                $report.Analysis = [PSCustomObject]@{
                    structure = $xmlStructure
                    elements  = Get-XmlElements -XmlObject $xml
                }
            } catch {
                Write-Warning "Erreur lors de l'analyse du fichier XML : $_"
                $report.Analysis = [PSCustomObject]@{
                    error = $_.Exception.Message
                }
            }
        }
        "CSV" {
            try {
                $csv = ConvertFrom-Csv -InputObject $fileContent
                $csvStructure = Get-CsvStructure -CsvObject $csv
                $report.Analysis = [PSCustomObject]@{
                    structure = $csvStructure
                    columns   = Get-CsvColumns -CsvObject $csv
                }
            } catch {
                Write-Warning "Erreur lors de l'analyse du fichier CSV : $_"
                $report.Analysis = [PSCustomObject]@{
                    error = $_.Exception.Message
                }
            }
        }
        "YAML" {
            try {
                # Utiliser un module YAML si disponible
                if (Get-Command -Name "ConvertFrom-Yaml" -ErrorAction SilentlyContinue) {
                    $yaml = ConvertFrom-Yaml -Yaml $fileContent
                    $yamlStructure = Get-YamlStructure -YamlObject $yaml
                    $report.Analysis = [PSCustomObject]@{
                        structure = $yamlStructure
                        elements  = Get-YamlElements -YamlObject $yaml
                    }
                } else {
                    Write-Warning "Module YAML non disponible. Analyse limitée."
                    $report.Analysis = [PSCustomObject]@{
                        warning = "Module YAML non disponible. Analyse limitée."
                    }
                }
            } catch {
                Write-Warning "Erreur lors de l'analyse du fichier YAML : $_"
                $report.Analysis = [PSCustomObject]@{
                    error = $_.Exception.Message
                }
            }
        }
        "TEXT" {
            try {
                $textAnalysis = Get-TextAnalysis -TextContent $fileContent
                $report.Analysis = $textAnalysis
            } catch {
                Write-Warning "Erreur lors de l'analyse du fichier texte : $_"
                $report.Analysis = [PSCustomObject]@{
                    error = $_.Exception.Message
                }
            }
        }
    }

    # Générer le rapport HTML si demandé
    if ($AsHtml) {
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'analyse de fichier - $($fileInfo.Name)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3, h4 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .section { margin-bottom: 30px; }
    </style>
</head>
<body>
    <h1>Rapport d'analyse de fichier</h1>

    <div class="section">
        <h2>Informations générales</h2>
        <table>
            <tr><th>Propriété</th><th>Valeur</th></tr>
            <tr><td>Nom du fichier</td><td>$($report.FileName)</td></tr>
            <tr><td>Chemin</td><td>$($report.FilePath)</td></tr>
            <tr><td>Extension</td><td>$($report.FileExtension)</td></tr>
            <tr><td>Taille</td><td>$($report.FileSizeFormatted)</td></tr>
            <tr><td>Nombre de lignes</td><td>$($report.LineCount)</td></tr>
            <tr><td>Format</td><td>$($report.Format)</td></tr>
            <tr><td>Date de création</td><td>$($report.CreationTime)</td></tr>
            <tr><td>Dernière modification</td><td>$($report.LastWriteTime)</td></tr>
        </table>
    </div>
"@

        # Ajouter les sections spécifiques au format
        switch -Regex ($Format) {
            "JSON" {
                $html += @"
    <div class="section">
        <h2>Structure JSON</h2>
"@

                function Add-StructureToHtml($structure, $level = 0) {
                    # $indent peut être utilisé pour l'indentation si nécessaire dans le futur
                    $html = ""

                    if ($structure.type -eq "dict") {
                        $html += @"
        <h$(3 + $level)>Dictionnaire: $($structure.path)</h$(3 + $level)>
        <table>
            <tr><th>Propriété</th><th>Valeur</th></tr>
            <tr><td>Nombre de clés</td><td>$($structure.key_count)</td></tr>
            <tr><td>Clés</td><td>$($structure.keys -join ", ")</td></tr>
        </table>
"@

                        if ($structure.nested) {
                            foreach ($key in $structure.keys) {
                                $html += Add-StructureToHtml $structure.nested.$key ($level + 1)
                            }
                        }
                    } elseif ($structure.type -eq "list") {
                        $html += @"
        <h$(3 + $level)>Liste: $($structure.path)</h$(3 + $level)>
        <table>
            <tr><th>Propriété</th><th>Valeur</th></tr>
            <tr><td>Nombre d'éléments</td><td>$($structure.count)</td></tr>
            <tr><td>Type d'éléments</td><td>$($structure.element_type)</td></tr>
        </table>
"@

                        if ($structure.sample) {
                            $html += @"
        <h$(4 + $level)>Échantillon</h$(4 + $level)>
        <pre>$($structure.sample | ConvertTo-Json -Depth 3)</pre>
"@
                        }

                        if ($structure.nested -and $structure.count -gt 0) {
                            $html += Add-StructureToHtml $structure.nested[0] ($level + 1)
                        }
                    } elseif ($structure.type -eq "string") {
                        $html += @"
        <h$(3 + $level)>Chaîne: $($structure.path)</h$(3 + $level)>
        <table>
            <tr><th>Propriété</th><th>Valeur</th></tr>
            <tr><td>Longueur</td><td>$($structure.length)</td></tr>
        </table>
"@
                    } elseif ($structure.type -eq "number") {
                        $html += @"
        <h$(3 + $level)>Nombre: $($structure.path)</h$(3 + $level)>
        <table>
            <tr><th>Propriété</th><th>Valeur</th></tr>
            <tr><td>Valeur</td><td>$($structure.value)</td></tr>
        </table>
"@
                    } elseif ($structure.type -eq "boolean") {
                        $html += @"
        <h$(3 + $level)>Booléen: $($structure.path)</h$(3 + $level)>
        <table>
            <tr><th>Propriété</th><th>Valeur</th></tr>
            <tr><td>Valeur</td><td>$($structure.value)</td></tr>
        </table>
"@
                    } else {
                        $html += @"
        <h$(3 + $level)>$($structure.type): $($structure.path)</h$(3 + $level)>
"@
                    }

                    return $html
                }

                $html += Add-StructureToHtml $report.Analysis.structure

                $html += @"
    </div>
"@
            }
        }

        $html += @"
    <div class="section">
        <h2>Statistiques</h2>
        <p>Analyse complétée le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
</body>
</html>
"@

        $report | Add-Member -MemberType NoteProperty -Name "HtmlReport" -Value $html
    }

    return $report
}

function Test-FileValidity {
    <#
    .SYNOPSIS
        Vérifie la validité d'un fichier.
    .DESCRIPTION
        Vérifie la validité d'un fichier en fonction de son format et éventuellement d'un schéma.
    .PARAMETER FilePath
        Chemin du fichier à vérifier.
    .PARAMETER Format
        Format du fichier (AUTO, JSON, XML, CSV, YAML, TEXT).
    .PARAMETER SchemaFile
        Chemin du fichier de schéma pour la validation.
    .EXAMPLE
        Test-FileValidity -FilePath "C:\temp\data.json" -Format "JSON" -SchemaFile "C:\temp\schema.json"
    .OUTPUTS
        [bool] - $true si le fichier est valide, $false sinon.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$Format = "AUTO",

        [Parameter(Mandatory = $false)]
        [string]$SchemaFile
    )

    # Vérifier que la façade est initialisée
    if (-not $script:IsInitialized) {
        $initialized = Initialize-FileProcessingFacade
        if (-not $initialized) {
            Write-Error "La façade de traitement de fichiers n'est pas initialisée."
            return $false
        }
    }

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        return $false
    }

    # Détecter le format si nécessaire
    if ($Format -eq "AUTO") {
        $Format = Get-FileFormat -FilePath $FilePath
        Write-Verbose "Format détecté : $Format"
    }

    # Valider le fichier selon son format
    if ($script:validators.ContainsKey($Format)) {
        $validator = $script:validators[$Format]
        $result = & $validator -FilePath $FilePath -SchemaFile $SchemaFile
        return $result
    } else {
        Write-Warning "Aucun validateur disponible pour le format '$Format'. Validation ignorée."
        return $true
    }
}

# Fonctions de conversion JSON
function ConvertFrom-JsonToCsv {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile
    )

    try {
        $json = Get-Content -Path $InputFile -Raw | ConvertFrom-Json
        $json | ConvertTo-Csv -NoTypeInformation | Set-Content -Path $OutputFile -Encoding UTF8
        return $true
    } catch {
        Write-Error "Erreur lors de la conversion de JSON vers CSV : $_"
        return $false
    }
}

function ConvertFrom-JsonToXml {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile
    )

    try {
        $json = Get-Content -Path $InputFile -Raw | ConvertFrom-Json
        $json | ConvertTo-Xml -NoTypeInformation | Out-File -FilePath $OutputFile -Encoding UTF8
        return $true
    } catch {
        Write-Error "Erreur lors de la conversion de JSON vers XML : $_"
        return $false
    }
}

# Fonctions de conversion CSV
function ConvertFrom-CsvToJson {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile
    )

    try {
        $csv = Import-Csv -Path $InputFile
        $csv | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputFile -Encoding UTF8
        return $true
    } catch {
        Write-Error "Erreur lors de la conversion de CSV vers JSON : $_"
        return $false
    }
}

# Fonctions de conversion par défaut pour les autres formats
function ConvertFrom-JsonToText {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile
    )

    try {
        $json = Get-Content -Path $InputFile -Raw | ConvertFrom-Json
        $json | Out-String | Set-Content -Path $OutputFile -Encoding UTF8
        return $true
    } catch {
        Write-Error "Erreur lors de la conversion de JSON vers TEXT : $_"
        return $false
    }
}

function ConvertFrom-JsonToYaml {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile
    )

    try {
        # Conversion simple (sans module YAML)
        $json = Get-Content -Path $InputFile -Raw | ConvertFrom-Json
        $yamlContent = "---`n"
        $yamlContent += ConvertTo-YamlString -InputObject $json -Indent 0
        Set-Content -Path $OutputFile -Value $yamlContent -Encoding UTF8
        return $true
    } catch {
        Write-Error "Erreur lors de la conversion de JSON vers YAML : $_"
        return $false
    }
}

# Fonction auxiliaire pour la conversion en YAML
function ConvertTo-YamlString {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $false)]
        [int]$Indent = 0
    )

    $indentString = " " * ($Indent * 2)
    $result = ""

    if ($InputObject -is [System.Collections.IDictionary] -or $InputObject -is [PSCustomObject]) {
        $properties = if ($InputObject -is [PSCustomObject]) {
            $InputObject | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
        } else {
            $InputObject.Keys
        }

        foreach ($key in $properties) {
            $value = if ($InputObject -is [PSCustomObject]) { $InputObject.$key } else { $InputObject[$key] }

            if ($value -is [Array]) {
                $result += "$indentString${key}: `n"
                foreach ($item in $value) {
                    $result += "$indentString- $(ConvertTo-YamlString -InputObject $item -Indent ($Indent + 1))`n"
                }
            } elseif ($value -is [System.Collections.IDictionary] -or $value -is [PSCustomObject]) {
                $result += "$indentString${key}: `n$(ConvertTo-YamlString -InputObject $value -Indent ($Indent + 1))"
            } else {
                $result += "$indentString${key}: $value`n"
            }
        }
    } elseif ($InputObject -is [Array]) {
        foreach ($item in $InputObject) {
            $result += "$indentString- $(ConvertTo-YamlString -InputObject $item -Indent ($Indent + 1))"
        }
    } else {
        $result = "$InputObject"
    }

    return $result
}

# Exporter les fonctions
# Export-ModuleMember est commenté pour permettre le chargement direct du script
