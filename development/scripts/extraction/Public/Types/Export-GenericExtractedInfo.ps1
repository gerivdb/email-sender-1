#Requires -Version 5.1
function Export-GenericExtractedInfo {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("Json")]
        [string]$Format = "Json",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Vérifier que l'objet est valide
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "L'objet fourni n'est pas un objet d'information extraite valide."
    }

    # Exporter selon le format demandé
    $result = $null

    # Créer une copie de l'objet pour l'exportation
    $exportObject = @{}

    # Copier toutes les propriétés sauf les métadonnées si non demandées
    foreach ($key in $Info.Keys) {
        if ($key -ne "Metadata" -or $IncludeMetadata) {
            $exportObject[$key] = $Info[$key]
        }
    }

    # Convertir en JSON
    $result = ConvertTo-Json -InputObject $exportObject -Depth 10

    # Écrire dans un fichier si un chemin est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $result | Out-File -FilePath $OutputPath -Encoding utf8
        return $null
    }

    return $result
}
