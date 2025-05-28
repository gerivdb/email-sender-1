<#
---
to: D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/roadmap/<%= category %>/<%= subcategory %>/<%= name %>.ps1
---
<#
.SYNOPSIS
    <%= description %>

.DESCRIPTION
    <%= longDescription || description %>

.PARAMETER InputPath
    Chemin vers le fichier d'entrée.

.PARAMETER OutputPath
    Chemin vers le fichier de sortie.

.EXAMPLE
    <%= name %> -InputPath "Roadmap/roadmap.md" -OutputPath "Roadmap/output.md"

.NOTES
    Auteur: <%= author || 'RoadmapTools Team' %>
    Version: 1.0
    Date de création: <%= new Date().toISOString().split('T')[0] %>
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

# Vérifier que le fichier d'entrée existe
if (-not (Test-Path -Path $InputPath)) {
    throw "Le fichier d'entrée spécifié n'existe pas : $InputPath"
}

# Fonction principale
function <%= h.changeCase.camel(name) %> {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Lire le contenu du fichier
    $content = Get-Content -Path $InputPath -Encoding UTF8 -Raw

    # Traitement principal
    # TODO: Implémenter la logique spécifique

    # Écrire le résultat si un chemin de sortie est spécifié
    if ($OutputPath) {
        if ($PSCmdlet.ShouldProcess($OutputPath, "Écrire le résultat")) {
            Set-Content -Path $OutputPath -Value $content -Encoding UTF8
            Write-Output "Résultat écrit dans $OutputPath"
        }
    } else {
        # Retourner le résultat
        return $content
    }
}

# Appeler la fonction principale
if ($PSCmdlet.ShouldProcess($InputPath, "<%= description %>")) {
    <%= h.changeCase.camel(name) %> -InputPath $InputPath -OutputPath $OutputPath
}
