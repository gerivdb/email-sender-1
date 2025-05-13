#Requires -Version 5.1
<#
.SYNOPSIS
    Helpers pour les tests unitaires PowerShell.
.DESCRIPTION
    Ce module fournit des helpers pour les tests unitaires PowerShell dans le projet EMAIL_SENDER_1.
    Il s'intègre avec le module TestFramework et fournit des fonctionnalités supplémentaires
    pour faciliter l'écriture de tests pour des cas communs.
.EXAMPLE
    Import-Module TestHelpers
    Test-FileContent -Path "test.txt" -ExpectedContent "Test content"
.NOTES
    Version: 1.0.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

#region Variables globales
$script:ModuleName = 'TestHelpers'
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = '1.0.0'
$script:ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "config\$script:ModuleName.config.json"
$script:LogPath = Join-Path -Path $PSScriptRoot -ChildPath "logs\$script:ModuleName.log"
#endregion

#region Fonctions privées
# Importer toutes les fonctions privées
$PrivateFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)
foreach ($Function in $PrivateFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Fonction privée importée : $($Function.BaseName)"
    } catch {
        Write-Error "Échec de l'importation de la fonction privée $($Function.FullName): $_"
    }
}
#endregion

#region Fonctions publiques
# Importer toutes les fonctions publiques
$PublicFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue)
foreach ($Function in $PublicFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Fonction publique importée : $($Function.BaseName)"
    } catch {
        Write-Error "Échec de l'importation de la fonction publique $($Function.FullName): $_"
    }
}
#endregion

#region Fonctions principales du module

function Test-FileContent {
    <#
    .SYNOPSIS
        Vérifie le contenu d'un fichier.
    .DESCRIPTION
        Vérifie si le contenu d'un fichier correspond au contenu attendu.
    .PARAMETER Path
        Chemin du fichier à vérifier.
    .PARAMETER ExpectedContent
        Contenu attendu du fichier.
    .PARAMETER Contains
        Indique si le fichier doit contenir le contenu attendu (au lieu de correspondre exactement).
    .PARAMETER CaseSensitive
        Indique si la comparaison doit être sensible à la casse.
    .EXAMPLE
        Test-FileContent -Path "test.txt" -ExpectedContent "Test content"
    .EXAMPLE
        Test-FileContent -Path "test.txt" -ExpectedContent "Test" -Contains
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedContent,

        [Parameter(Mandatory = $false)]
        [switch]$Contains,

        [Parameter(Mandatory = $false)]
        [switch]$CaseSensitive
    )

    if (-not (Test-Path -Path $Path)) {
        return $false
    }

    $content = Get-Content -Path $Path -Raw

    if ($Contains) {
        if ($CaseSensitive) {
            return $content -clike "*$ExpectedContent*"
        } else {
            return $content -like "*$ExpectedContent*"
        }
    } else {
        if ($CaseSensitive) {
            return $content -ceq $ExpectedContent
        } else {
            return $content -eq $ExpectedContent
        }
    }
}

function Test-JsonContent {
    <#
    .SYNOPSIS
        Vérifie le contenu JSON d'un fichier ou d'une chaîne.
    .DESCRIPTION
        Vérifie si le contenu JSON d'un fichier ou d'une chaîne correspond à la structure attendue.
    .PARAMETER Path
        Chemin du fichier JSON à vérifier.
    .PARAMETER Json
        Chaîne JSON à vérifier.
    .PARAMETER ExpectedStructure
        Structure attendue du JSON (hashtable ou PSCustomObject).
    .PARAMETER StrictComparison
        Indique si la comparaison doit être stricte (toutes les propriétés doivent correspondre).
    .EXAMPLE
        Test-JsonContent -Path "test.json" -ExpectedStructure @{ name = "Test"; value = 123 }
    .EXAMPLE
        Test-JsonContent -Json '{"name":"Test","value":123}' -ExpectedStructure @{ name = "Test" }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "File")]
        [string]$Path,

        [Parameter(Mandatory = $true, ParameterSetName = "String")]
        [string]$Json,

        [Parameter(Mandatory = $true)]
        [object]$ExpectedStructure,

        [Parameter(Mandatory = $false)]
        [switch]$StrictComparison
    )

    try {
        if ($PSCmdlet.ParameterSetName -eq "File") {
            if (-not (Test-Path -Path $Path)) {
                return $false
            }
            $jsonContent = Get-Content -Path $Path -Raw
        } else {
            $jsonContent = $Json
        }

        $jsonObject = $jsonContent | ConvertFrom-Json

        # Convertir l'objet attendu en PSCustomObject s'il s'agit d'un hashtable
        if ($ExpectedStructure -is [hashtable]) {
            $ExpectedStructure = [PSCustomObject]$ExpectedStructure
        }

        # Comparer les propriétés
        $match = $true
        foreach ($property in $ExpectedStructure.PSObject.Properties) {
            $propertyName = $property.Name
            $expectedValue = $property.Value

            if (-not $jsonObject.PSObject.Properties.Name.Contains($propertyName)) {
                $match = $false
                break
            }

            $actualValue = $jsonObject.$propertyName

            # Comparer les valeurs
            if ($expectedValue -is [array] -and $actualValue -is [array]) {
                if ($expectedValue.Count -ne $actualValue.Count) {
                    $match = $false
                    break
                }

                for ($i = 0; $i -lt $expectedValue.Count; $i++) {
                    if ($expectedValue[$i] -ne $actualValue[$i]) {
                        $match = $false
                        break
                    }
                }
            } elseif ($expectedValue -is [PSCustomObject] -and $actualValue -is [PSCustomObject]) {
                $match = Test-JsonContent -Json ($actualValue | ConvertTo-Json) -ExpectedStructure $expectedValue -StrictComparison:$StrictComparison
                if (-not $match) {
                    break
                }
            } else {
                if ($expectedValue -ne $actualValue) {
                    $match = $false
                    break
                }
            }
        }

        # Si la comparaison est stricte, vérifier que toutes les propriétés de l'objet JSON sont présentes dans l'objet attendu
        if ($StrictComparison -and $match) {
            foreach ($property in $jsonObject.PSObject.Properties) {
                $propertyName = $property.Name
                if (-not $ExpectedStructure.PSObject.Properties.Name.Contains($propertyName)) {
                    $match = $false
                    break
                }
            }
        }

        return $match
    } catch {
        Write-Error "Erreur lors de la vérification du contenu JSON : $_"
        return $false
    }
}

function Test-XmlContent {
    <#
    .SYNOPSIS
        Vérifie le contenu XML d'un fichier ou d'une chaîne.
    .DESCRIPTION
        Vérifie si le contenu XML d'un fichier ou d'une chaîne correspond à la structure attendue.
    .PARAMETER Path
        Chemin du fichier XML à vérifier.
    .PARAMETER Xml
        Chaîne XML à vérifier.
    .PARAMETER XPath
        Expression XPath pour sélectionner les nœuds à vérifier.
    .PARAMETER ExpectedValue
        Valeur attendue pour les nœuds sélectionnés.
    .PARAMETER ExpectedCount
        Nombre attendu de nœuds sélectionnés.
    .EXAMPLE
        Test-XmlContent -Path "test.xml" -XPath "/root/item[@id='1']/name" -ExpectedValue "Item 1"
    .EXAMPLE
        Test-XmlContent -Xml '<root><item id="1"><name>Item 1</name></item></root>' -XPath "//item" -ExpectedCount 1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "File")]
        [string]$Path,

        [Parameter(Mandatory = $true, ParameterSetName = "String")]
        [string]$Xml,

        [Parameter(Mandatory = $true)]
        [string]$XPath,

        [Parameter(Mandatory = $false)]
        [string]$ExpectedValue,

        [Parameter(Mandatory = $false)]
        [int]$ExpectedCount
    )

    try {
        $xmlDocument = New-Object System.Xml.XmlDocument

        if ($PSCmdlet.ParameterSetName -eq "File") {
            if (-not (Test-Path -Path $Path)) {
                return $false
            }
            $xmlDocument.Load($Path)
        } else {
            $xmlDocument.LoadXml($Xml)
        }

        $nodes = $xmlDocument.SelectNodes($XPath)

        if ($PSBoundParameters.ContainsKey("ExpectedCount")) {
            return $nodes.Count -eq $ExpectedCount
        }

        if ($PSBoundParameters.ContainsKey("ExpectedValue")) {
            if ($nodes.Count -eq 0) {
                return $false
            }
            return $nodes[0].InnerText -eq $ExpectedValue
        }

        return $nodes.Count -gt 0
    } catch {
        Write-Error "Erreur lors de la vérification du contenu XML : $_"
        return $false
    }
}

function Test-CsvContent {
    <#
    .SYNOPSIS
        Vérifie le contenu CSV d'un fichier.
    .DESCRIPTION
        Vérifie si le contenu CSV d'un fichier correspond aux données attendues.
    .PARAMETER Path
        Chemin du fichier CSV à vérifier.
    .PARAMETER ExpectedHeaders
        En-têtes attendus dans le fichier CSV.
    .PARAMETER ExpectedRowCount
        Nombre de lignes attendu dans le fichier CSV.
    .PARAMETER RowFilter
        Filtre pour sélectionner les lignes à vérifier.
    .PARAMETER ExpectedValues
        Valeurs attendues pour les lignes sélectionnées.
    .EXAMPLE
        Test-CsvContent -Path "test.csv" -ExpectedHeaders "Id", "Name", "Value" -ExpectedRowCount 3
    .EXAMPLE
        Test-CsvContent -Path "test.csv" -RowFilter { $_.Id -eq 1 } -ExpectedValues @{ Name = "Item 1"; Value = "Value 1" }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string[]]$ExpectedHeaders,

        [Parameter(Mandatory = $false)]
        [int]$ExpectedRowCount,

        [Parameter(Mandatory = $false)]
        [scriptblock]$RowFilter,

        [Parameter(Mandatory = $false)]
        [hashtable]$ExpectedValues
    )

    try {
        if (-not (Test-Path -Path $Path)) {
            return $false
        }

        $csv = Import-Csv -Path $Path

        # Vérifier les en-têtes
        if ($PSBoundParameters.ContainsKey("ExpectedHeaders")) {
            $headers = $csv[0].PSObject.Properties.Name
            if ($headers.Count -ne $ExpectedHeaders.Count) {
                return $false
            }

            foreach ($header in $ExpectedHeaders) {
                if (-not $headers.Contains($header)) {
                    return $false
                }
            }
        }

        # Vérifier le nombre de lignes
        if ($PSBoundParameters.ContainsKey("ExpectedRowCount")) {
            if ($csv.Count -ne $ExpectedRowCount) {
                return $false
            }
        }

        # Vérifier les valeurs des lignes
        if ($PSBoundParameters.ContainsKey("RowFilter") -and $PSBoundParameters.ContainsKey("ExpectedValues")) {
            $filteredRows = $csv | Where-Object -FilterScript $RowFilter

            if ($filteredRows.Count -eq 0) {
                return $false
            }

            $row = $filteredRows[0]
            foreach ($key in $ExpectedValues.Keys) {
                if ($row.$key -ne $ExpectedValues[$key]) {
                    return $false
                }
            }
        }

        return $true
    } catch {
        Write-Error "Erreur lors de la vérification du contenu CSV : $_"
        return $false
    }
}

function Test-ApiResponse {
    <#
    .SYNOPSIS
        Vérifie une réponse d'API.
    .DESCRIPTION
        Vérifie si une réponse d'API correspond à la structure attendue.
    .PARAMETER Uri
        URI de l'API à tester.
    .PARAMETER Method
        Méthode HTTP à utiliser (GET, POST, PUT, DELETE).
    .PARAMETER Headers
        En-têtes HTTP à inclure dans la requête.
    .PARAMETER Body
        Corps de la requête (pour les méthodes POST et PUT).
    .PARAMETER ExpectedStatusCode
        Code de statut HTTP attendu.
    .PARAMETER ExpectedContent
        Contenu attendu dans la réponse.
    .PARAMETER ContentType
        Type de contenu de la réponse (json, xml, text).
    .EXAMPLE
        Test-ApiResponse -Uri "https://api.example.com/data" -Method GET -ExpectedStatusCode 200 -ContentType json -ExpectedContent @{ status = "ok" }
    .EXAMPLE
        Test-ApiResponse -Uri "https://api.example.com/data" -Method POST -Body @{ name = "Test" } -ExpectedStatusCode 201
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $false)]
        [ValidateSet("GET", "POST", "PUT", "DELETE")]
        [string]$Method = "GET",

        [Parameter(Mandatory = $false)]
        [hashtable]$Headers,

        [Parameter(Mandatory = $false)]
        [object]$Body,

        [Parameter(Mandatory = $false)]
        [int]$ExpectedStatusCode,

        [Parameter(Mandatory = $false)]
        [object]$ExpectedContent,

        [Parameter(Mandatory = $false)]
        [ValidateSet("json", "xml", "text")]
        [string]$ContentType = "json"
    )

    try {
        $params = @{
            Uri             = $Uri
            Method          = $Method
            UseBasicParsing = $true
        }

        if ($Headers) {
            $params.Headers = $Headers
        }

        if ($Body) {
            if ($Body -is [hashtable] -or $Body -is [PSCustomObject]) {
                $params.Body = $Body | ConvertTo-Json -Depth 10
                $params.ContentType = "application/json"
            } else {
                $params.Body = $Body
            }
        }

        # Capturer la réponse complète
        $response = Invoke-WebRequest @params

        # Vérifier le code de statut
        if ($PSBoundParameters.ContainsKey("ExpectedStatusCode")) {
            if ($response.StatusCode -ne $ExpectedStatusCode) {
                return $false
            }
        }

        # Vérifier le contenu
        if ($PSBoundParameters.ContainsKey("ExpectedContent")) {
            $content = $response.Content

            switch ($ContentType) {
                "json" {
                    $jsonContent = $content | ConvertFrom-Json
                    return Test-JsonContent -Json $content -ExpectedStructure $ExpectedContent
                }
                "xml" {
                    return Test-XmlContent -Xml $content -XPath $ExpectedContent.XPath -ExpectedValue $ExpectedContent.Value
                }
                "text" {
                    return $content -eq $ExpectedContent
                }
            }
        }

        return $true
    } catch {
        Write-Error "Erreur lors de la vérification de la réponse de l'API : $_"
        return $false
    }
}

function Test-DatabaseQuery {
    <#
    .SYNOPSIS
        Vérifie le résultat d'une requête de base de données.
    .DESCRIPTION
        Vérifie si le résultat d'une requête de base de données correspond aux données attendues.
    .PARAMETER ConnectionString
        Chaîne de connexion à la base de données.
    .PARAMETER Query
        Requête SQL à exécuter.
    .PARAMETER Parameters
        Paramètres de la requête.
    .PARAMETER ExpectedRowCount
        Nombre de lignes attendu dans le résultat.
    .PARAMETER ExpectedValues
        Valeurs attendues dans le résultat.
    .PARAMETER RowFilter
        Filtre pour sélectionner les lignes à vérifier.
    .EXAMPLE
        Test-DatabaseQuery -ConnectionString "Server=localhost;Database=test;Integrated Security=True" -Query "SELECT * FROM Users" -ExpectedRowCount 3
    .EXAMPLE
        Test-DatabaseQuery -ConnectionString "Server=localhost;Database=test;Integrated Security=True" -Query "SELECT * FROM Users WHERE Id = @Id" -Parameters @{ Id = 1 } -ExpectedValues @{ Name = "Test"; Email = "test@example.com" }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString,

        [Parameter(Mandatory = $true)]
        [string]$Query,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory = $false)]
        [int]$ExpectedRowCount,

        [Parameter(Mandatory = $false)]
        [hashtable]$ExpectedValues,

        [Parameter(Mandatory = $false)]
        [scriptblock]$RowFilter
    )

    try {
        # Créer la connexion
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $ConnectionString
        $connection.Open()

        # Créer la commande
        $command = $connection.CreateCommand()
        $command.CommandText = $Query

        # Ajouter les paramètres
        if ($Parameters) {
            foreach ($key in $Parameters.Keys) {
                $parameter = $command.Parameters.AddWithValue("@$key", $Parameters[$key])
            }
        }

        # Exécuter la requête
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataset) | Out-Null

        # Fermer la connexion
        $connection.Close()

        # Récupérer les résultats
        $results = $dataset.Tables[0]

        # Vérifier le nombre de lignes
        if ($PSBoundParameters.ContainsKey("ExpectedRowCount")) {
            if ($results.Rows.Count -ne $ExpectedRowCount) {
                return $false
            }
        }

        # Vérifier les valeurs
        if ($PSBoundParameters.ContainsKey("ExpectedValues")) {
            $rows = $results.Rows

            if ($PSBoundParameters.ContainsKey("RowFilter")) {
                $rows = $rows | Where-Object -FilterScript $RowFilter
            }

            if ($rows.Count -eq 0) {
                return $false
            }

            $row = $rows[0]
            foreach ($key in $ExpectedValues.Keys) {
                if ($row[$key] -ne $ExpectedValues[$key]) {
                    return $false
                }
            }
        }

        return $true
    } catch {
        Write-Error "Erreur lors de la vérification de la requête de base de données : $_"
        return $false
    }
}

#endregion

#region Initialisation du module
function Initialize-TestHelpersModule {
    <#
    .SYNOPSIS
        Initialise le module TestHelpers.
    .DESCRIPTION
        Crée les dossiers nécessaires et initialise les configurations du module.
    .EXAMPLE
        Initialize-TestHelpersModule
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    # Créer les dossiers nécessaires s'ils n'existent pas
    $Folders = @(
        (Join-Path -Path $script:ModuleRoot -ChildPath "config"),
        (Join-Path -Path $script:ModuleRoot -ChildPath "logs")
    )

    foreach ($Folder in $Folders) {
        if (-not (Test-Path -Path $Folder)) {
            if ($PSCmdlet.ShouldProcess($Folder, "Créer le dossier")) {
                New-Item -Path $Folder -ItemType Directory -Force | Out-Null
                Write-Verbose "Dossier créé : $Folder"
            }
        }
    }

    # Initialiser le fichier de configuration s'il n'existe pas
    if (-not (Test-Path -Path $script:ConfigPath)) {
        if ($PSCmdlet.ShouldProcess($script:ConfigPath, "Créer le fichier de configuration")) {
            $DefaultConfig = @{
                ModuleName = $script:ModuleName
                Version    = $script:ModuleVersion
                LogLevel   = "Info"
                LogPath    = $script:LogPath
                Enabled    = $true
            }

            $DefaultConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath $script:ConfigPath -Encoding utf8
            Write-Verbose "Fichier de configuration créé : $script:ConfigPath"
        }
    }
}
#endregion

#region Exportation des fonctions
# Exporter uniquement les fonctions publiques
$FunctionsToExport = @(
    'Test-FileContent'
    'Test-JsonContent'
    'Test-XmlContent'
    'Test-CsvContent'
    'Test-ApiResponse'
    'Test-DatabaseQuery'
)

# Ajouter les fonctions publiques si elles existent
if ($PublicFunctions -and $PublicFunctions.Count -gt 0) {
    $FunctionsToExport += $PublicFunctions.BaseName
}

Export-ModuleMember -Function $FunctionsToExport -Variable @()
#endregion

# Initialiser le module lors du chargement
Initialize-TestHelpersModule
