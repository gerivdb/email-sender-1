# JsonSchemaValidator.psm1
# Module pour la validation et la documentation des schémas JSON

<#
.SYNOPSIS
    Valide un document JSON par rapport à un schéma JSON.

.DESCRIPTION
    Cette fonction valide un document JSON par rapport à un schéma JSON spécifié.
    Elle utilise la bibliothèque .NET pour effectuer la validation.

.PARAMETER JsonContent
    Le contenu JSON à valider sous forme de chaîne.

.PARAMETER SchemaContent
    Le contenu du schéma JSON sous forme de chaîne.

.PARAMETER JsonPath
    Le chemin du fichier JSON à valider (alternatif à JsonContent).

.PARAMETER SchemaPath
    Le chemin du fichier de schéma JSON (alternatif à SchemaContent).

.PARAMETER Detailed
    Indique si des informations détaillées sur les erreurs doivent être retournées.

.EXAMPLE
    Test-JsonSchema -JsonPath "data.json" -SchemaPath "schema.json"
    Valide le fichier JSON "data.json" par rapport au schéma "schema.json".

.OUTPUTS
    System.Boolean ou PSObject
#>
function Test-JsonSchema {
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = "Content")]
        [string]$JsonContent,

        [Parameter(Mandatory = $false, ParameterSetName = "Content")]
        [string]$SchemaContent,

        [Parameter(Mandatory = $false, ParameterSetName = "Path")]
        [string]$JsonPath,

        [Parameter(Mandatory = $false, ParameterSetName = "Path")]
        [string]$SchemaPath,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    # Charger les contenus à partir des fichiers si nécessaire
    if ($PSCmdlet.ParameterSetName -eq "Path") {
        if (-not (Test-Path -Path $JsonPath)) {
            Write-Error "Le fichier JSON n'existe pas: $JsonPath"
            return $false
        }

        if (-not (Test-Path -Path $SchemaPath)) {
            Write-Error "Le fichier de schéma n'existe pas: $SchemaPath"
            return $false
        }

        $JsonContent = Get-Content -Path $JsonPath -Raw -Encoding UTF8
        $SchemaContent = Get-Content -Path $SchemaPath -Raw -Encoding UTF8
    }

    # Vérifier que les contenus ne sont pas vides
    if ([string]::IsNullOrWhiteSpace($JsonContent)) {
        Write-Error "Le contenu JSON est vide."
        return $false
    }

    if ([string]::IsNullOrWhiteSpace($SchemaContent)) {
        Write-Error "Le contenu du schéma est vide."
        return $false
    }

    try {
        # Utiliser .NET pour valider le JSON par rapport au schéma
        Add-Type -AssemblyName System.Web.Extensions

        $jsonSerializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
        $jsonObject = $jsonSerializer.DeserializeObject($JsonContent)
        $schemaObject = $jsonSerializer.DeserializeObject($SchemaContent)

        # Validation simple (sans bibliothèque spécifique de validation de schéma)
        $isValid = $true
        $errors = @()

        # Vérifier les propriétés requises de premier niveau
        $requiredProperties = $schemaObject.required
        
        foreach ($prop in $requiredProperties) {
            if (-not $jsonObject.ContainsKey($prop)) {
                $isValid = $false
                $errors += "Propriété requise manquante: $prop"
            }
        }

        # Vérifier les types des propriétés
        $properties = $schemaObject.properties
        foreach ($propName in $properties.Keys) {
            if ($jsonObject.ContainsKey($propName)) {
                $propValue = $jsonObject[$propName]
                $propSchema = $properties[$propName]
                
                # Vérifier le type
                $expectedType = $propSchema.type
                if ($expectedType -eq "object" -and $propValue -isnot [System.Collections.IDictionary]) {
                    $isValid = $false
                    $errors += "Type invalide pour la propriété '$propName': attendu 'object', reçu '$($propValue.GetType().Name)'"
                }
                elseif ($expectedType -eq "array" -and $propValue -isnot [System.Collections.IList]) {
                    $isValid = $false
                    $errors += "Type invalide pour la propriété '$propName': attendu 'array', reçu '$($propValue.GetType().Name)'"
                }
                elseif ($expectedType -eq "string" -and $propValue -isnot [string]) {
                    $isValid = $false
                    $errors += "Type invalide pour la propriété '$propName': attendu 'string', reçu '$($propValue.GetType().Name)'"
                }
                elseif ($expectedType -eq "number" -and $propValue -isnot [int] -and $propValue -isnot [double]) {
                    $isValid = $false
                    $errors += "Type invalide pour la propriété '$propName': attendu 'number', reçu '$($propValue.GetType().Name)'"
                }
                elseif ($expectedType -eq "boolean" -and $propValue -isnot [bool]) {
                    $isValid = $false
                    $errors += "Type invalide pour la propriété '$propName': attendu 'boolean', reçu '$($propValue.GetType().Name)'"
                }
                
                # Vérifier les propriétés requises des objets imbriqués
                if ($expectedType -eq "object" -and $propSchema.ContainsKey("required")) {
                    foreach ($requiredProp in $propSchema.required) {
                        if (-not $propValue.ContainsKey($requiredProp)) {
                            $isValid = $false
                            $errors += "Propriété requise manquante dans l'objet '$propName': $requiredProp"
                        }
                    }
                }
            }
        }

        # Retourner le résultat
        if ($Detailed) {
            return [PSCustomObject]@{
                IsValid = $isValid
                Errors = $errors
            }
        } else {
            if (-not $isValid) {
                foreach ($error in $errors) {
                    Write-Warning $error
                }
            }
            return $isValid
        }
    } catch {
        Write-Error "Erreur lors de la validation du JSON: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Génère une documentation HTML pour un schéma JSON.

.DESCRIPTION
    Cette fonction génère une documentation HTML pour un schéma JSON spécifié.
    La documentation inclut les propriétés, les types, les descriptions et les exemples.

.PARAMETER SchemaContent
    Le contenu du schéma JSON sous forme de chaîne.

.PARAMETER SchemaPath
    Le chemin du fichier de schéma JSON (alternatif à SchemaContent).

.PARAMETER OutputPath
    Le chemin du fichier de sortie HTML.

.PARAMETER Title
    Le titre de la documentation (par défaut "Documentation du schéma JSON").

.EXAMPLE
    New-JsonSchemaDocumentation -SchemaPath "schema.json" -OutputPath "schema_doc.html"
    Génère une documentation HTML pour le schéma "schema.json" et l'enregistre dans "schema_doc.html".

.OUTPUTS
    System.String
#>
function New-JsonSchemaDocumentation {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = "Content")]
        [string]$SchemaContent,

        [Parameter(Mandatory = $false, ParameterSetName = "Path")]
        [string]$SchemaPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [string]$Title = "Documentation du schéma JSON"
    )

    # Charger le contenu à partir du fichier si nécessaire
    if ($PSCmdlet.ParameterSetName -eq "Path") {
        if (-not (Test-Path -Path $SchemaPath)) {
            Write-Error "Le fichier de schéma n'existe pas: $SchemaPath"
            return $null
        }

        $SchemaContent = Get-Content -Path $SchemaPath -Raw -Encoding UTF8
    }

    # Vérifier que le contenu n'est pas vide
    if ([string]::IsNullOrWhiteSpace($SchemaContent)) {
        Write-Error "Le contenu du schéma est vide."
        return $null
    }

    try {
        # Utiliser .NET pour désérialiser le schéma JSON
        Add-Type -AssemblyName System.Web.Extensions

        $jsonSerializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
        $schemaObject = $jsonSerializer.DeserializeObject($SchemaContent)

        # Générer le HTML
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2, h3, h4 {
            color: #2c3e50;
        }
        .property {
            margin-bottom: 20px;
            padding: 15px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        .property-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        .property-name {
            font-weight: bold;
            color: #3498db;
        }
        .property-type {
            font-family: monospace;
            background-color: #f8f9fa;
            padding: 2px 6px;
            border-radius: 3px;
        }
        .property-required {
            color: #e74c3c;
            font-weight: bold;
        }
        .property-description {
            margin-bottom: 10px;
        }
        .nested-properties {
            margin-left: 20px;
        }
        .schema-info {
            margin-bottom: 30px;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 4px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
        }
        table th, table td {
            padding: 8px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        table th {
            background-color: #f2f2f2;
        }
        code {
            font-family: monospace;
            background-color: #f8f9fa;
            padding: 2px 4px;
            border-radius: 3px;
        }
        .toc {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 4px;
            margin-bottom: 20px;
        }
        .toc ul {
            list-style-type: none;
            padding-left: 20px;
        }
        .toc a {
            text-decoration: none;
            color: #3498db;
        }
        .toc a:hover {
            text-decoration: underline;
        }
        @media (max-width: 768px) {
            body {
                padding: 10px;
            }
            .property {
                padding: 10px;
            }
        }
    </style>
</head>
<body>
    <h1>$Title</h1>
"@

        # Ajouter les informations générales du schéma
        $html += @"
    <div class="schema-info">
        <h2>Informations générales</h2>
        <table>
            <tr>
                <th>Titre</th>
                <td>$($schemaObject.title)</td>
            </tr>
            <tr>
                <th>Description</th>
                <td>$($schemaObject.description)</td>
            </tr>
            <tr>
                <th>Version du schéma</th>
                <td>$($schemaObject.'$schema')</td>
            </tr>
        </table>
    </div>
"@

        # Générer la table des matières
        $html += @"
    <div class="toc">
        <h2>Table des matières</h2>
        <ul>
"@

        foreach ($propName in $schemaObject.properties.Keys) {
            $html += @"
            <li><a href="#$propName">$propName</a></li>
"@
        }

        $html += @"
        </ul>
    </div>
"@

        # Fonction récursive pour générer la documentation des propriétés
        function Get-PropertyDocumentation {
            param (
                [string]$PropertyName,
                [PSObject]$PropertySchema,
                [string[]]$RequiredProperties,
                [int]$Level = 0
            )

            $indent = "    " * $Level
            $isRequired = $RequiredProperties -contains $PropertyName
            $requiredText = if ($isRequired) { '<span class="property-required">Requis</span>' } else { 'Optionnel' }
            
            $propHtml = @"
    <div class="property" id="$PropertyName">
        <div class="property-header">
            <span class="property-name">$PropertyName</span>
            <span class="property-type">$($PropertySchema.type)</span>
        </div>
        <div class="property-required">$requiredText</div>
        <div class="property-description">$($PropertySchema.description)</div>
"@

            # Ajouter des informations spécifiques selon le type
            if ($PropertySchema.type -eq "object" -and $PropertySchema.ContainsKey("properties")) {
                $propHtml += @"
        <h4>Propriétés</h4>
        <div class="nested-properties">
"@
                $nestedRequired = @()
                if ($PropertySchema.ContainsKey("required")) {
                    $nestedRequired = $PropertySchema.required
                }

                foreach ($nestedPropName in $PropertySchema.properties.Keys) {
                    $nestedPropSchema = $PropertySchema.properties[$nestedPropName]
                    $propHtml += Get-PropertyDocumentation -PropertyName $nestedPropName -PropertySchema $nestedPropSchema -RequiredProperties $nestedRequired -Level ($Level + 1)
                }

                $propHtml += @"
        </div>
"@
            }
            elseif ($PropertySchema.type -eq "array" -and $PropertySchema.ContainsKey("items")) {
                $propHtml += @"
        <h4>Éléments</h4>
        <div class="property-type">Type: $($PropertySchema.items.type)</div>
        <div class="property-description">$($PropertySchema.items.description)</div>
"@

                if ($PropertySchema.items.type -eq "object" -and $PropertySchema.items.ContainsKey("properties")) {
                    $propHtml += @"
        <div class="nested-properties">
"@
                    $nestedRequired = @()
                    if ($PropertySchema.items.ContainsKey("required")) {
                        $nestedRequired = $PropertySchema.items.required
                    }

                    foreach ($nestedPropName in $PropertySchema.items.properties.Keys) {
                        $nestedPropSchema = $PropertySchema.items.properties[$nestedPropName]
                        $propHtml += Get-PropertyDocumentation -PropertyName $nestedPropName -PropertySchema $nestedPropSchema -RequiredProperties $nestedRequired -Level ($Level + 1)
                    }

                    $propHtml += @"
        </div>
"@
                }
            }
            elseif ($PropertySchema.ContainsKey("enum")) {
                $propHtml += @"
        <h4>Valeurs possibles</h4>
        <ul>
"@
                foreach ($enumValue in $PropertySchema.enum) {
                    $propHtml += @"
            <li><code>$enumValue</code></li>
"@
                }
                $propHtml += @"
        </ul>
"@
            }

            $propHtml += @"
    </div>
"@

            return $propHtml
        }

        # Générer la documentation des propriétés de premier niveau
        $html += @"
    <h2>Propriétés</h2>
"@

        foreach ($propName in $schemaObject.properties.Keys) {
            $propSchema = $schemaObject.properties[$propName]
            $html += Get-PropertyDocumentation -PropertyName $propName -PropertySchema $propSchema -RequiredProperties $schemaObject.required
        }

        # Finaliser le HTML
        $html += @"
</body>
</html>
"@

        # Écrire le HTML dans un fichier si un chemin est spécifié
        if ($OutputPath -ne "") {
            try {
                $html | Out-File -FilePath $OutputPath -Encoding UTF8
                Write-Verbose "Documentation HTML écrite dans le fichier: $OutputPath"
            } catch {
                Write-Error "Erreur lors de l'écriture de la documentation HTML dans le fichier: $_"
            }
        }

        return $html
    } catch {
        Write-Error "Erreur lors de la génération de la documentation du schéma: $_"
        return $null
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Test-JsonSchema, New-JsonSchemaDocumentation
