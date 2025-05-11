<#
.SYNOPSIS
    Gestionnaire de partage des vues pour l'application.

.DESCRIPTION
    Ce module implémente le gestionnaire de partage des vues qui permet
    d'exporter et d'importer des vues entre différentes instances de l'application.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer le module de format d'échange
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$exchangeFormatPath = Join-Path -Path $scriptDir -ChildPath "ExchangeFormat.ps1"

if (Test-Path -Path $exchangeFormatPath) {
    . $exchangeFormatPath
} else {
    throw "Le module ExchangeFormat.ps1 est requis mais n'a pas été trouvé à l'emplacement: $exchangeFormatPath"
}

# Classe pour représenter le gestionnaire de partage des vues
class ViewSharingManager {
    # Propriétés
    [string]$InstanceId
    [string]$DefaultExportPath
    [hashtable]$SupportedFormats
    [bool]$EnableCompression
    [bool]$EnableEncryption
    [bool]$Debug

    # Constructeur par défaut
    ViewSharingManager() {
        $this.InstanceId = [guid]::NewGuid().ToString()
        $this.DefaultExportPath = Join-Path -Path $env:TEMP -ChildPath "ViewExports"
        $this.SupportedFormats = @{
            "JSON" = @{
                Extension   = ".json"
                ContentType = "application/json"
            }
            "XML"  = @{
                Extension   = ".xml"
                ContentType = "application/xml"
            }
            "YAML" = @{
                Extension   = ".yaml"
                ContentType = "application/yaml"
            }
        }
        $this.EnableCompression = $true
        $this.EnableEncryption = $false
        $this.Debug = $false
    }

    # Constructeur avec paramètres
    ViewSharingManager([hashtable]$options) {
        $this.InstanceId = if ($options.ContainsKey("InstanceId")) { $options.InstanceId } else { [guid]::NewGuid().ToString() }
        $this.DefaultExportPath = if ($options.ContainsKey("DefaultExportPath")) { $options.DefaultExportPath } else { Join-Path -Path $env:TEMP -ChildPath "ViewExports" }
        $this.SupportedFormats = @{
            "JSON" = @{
                Extension   = ".json"
                ContentType = "application/json"
            }
            "XML"  = @{
                Extension   = ".xml"
                ContentType = "application/xml"
            }
            "YAML" = @{
                Extension   = ".yaml"
                ContentType = "application/yaml"
            }
        }
        $this.EnableCompression = if ($options.ContainsKey("EnableCompression")) { $options.EnableCompression } else { $true }
        $this.EnableEncryption = if ($options.ContainsKey("EnableEncryption")) { $options.EnableEncryption } else { $false }
        $this.Debug = if ($options.ContainsKey("Debug")) { $options.Debug } else { $false }

        # Créer le répertoire d'exportation s'il n'existe pas
        if (-not (Test-Path -Path $this.DefaultExportPath)) {
            New-Item -Path $this.DefaultExportPath -ItemType Directory -Force | Out-Null
        }
    }

    # Méthode pour écrire des messages de débogage
    [void] WriteDebug([string]$message) {
        if ($this.Debug) {
            Write-Host "[DEBUG] [ViewSharingManager] $message" -ForegroundColor Cyan
        }
    }

    # Méthode pour exporter une vue
    [string] ExportView([object]$view, [string]$formatType, [hashtable]$metadata, [string]$outputPath) {
        $this.WriteDebug("Exportation de la vue au format $formatType")

        # Vérifier si le format est supporté
        if (-not $this.SupportedFormats.ContainsKey($formatType)) {
            throw "Format non supporté: $formatType. Formats supportés: $($this.SupportedFormats.Keys -join ', ')"
        }

        # Créer l'objet d'échange
        $exchangeFormat = New-ExchangeFormat -FormatType $formatType -Content $view -Metadata $metadata

        # Ajouter des métadonnées supplémentaires
        $exchangeFormat.AddMetadata("ExportedBy", $this.InstanceId)
        $exchangeFormat.AddMetadata("ExportDate", (Get-Date).ToString('o'))

        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($outputPath)) {
            $extension = $this.SupportedFormats[$formatType].Extension
            $fileName = "View_$((Get-Date).ToString('yyyyMMdd_HHmmss'))$extension"
            $outputPath = Join-Path -Path $this.DefaultExportPath -ChildPath $fileName
        }

        # Créer le répertoire de sortie s'il n'existe pas
        $outputDir = Split-Path -Path $outputPath -Parent
        if (-not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Sauvegarder l'objet d'échange
        $result = Save-ExchangeFormat -ExchangeFormat $exchangeFormat -FilePath $outputPath -Compress:$this.EnableCompression

        if ($result) {
            $this.WriteDebug("Vue exportée avec succès vers: $outputPath")
            return $outputPath
        } else {
            $this.WriteDebug("Échec de l'exportation de la vue")
            return $null
        }
    }

    # Méthode pour importer une vue
    [object] ImportView([string]$filePath) {
        $this.WriteDebug("Importation de la vue depuis: $filePath")

        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $filePath)) {
            throw "Le fichier spécifié n'existe pas: $filePath"
        }

        # Charger l'objet d'échange
        $exchangeFormat = Import-ExchangeFormat -FilePath $filePath

        if ($null -eq $exchangeFormat) {
            $this.WriteDebug("Échec du chargement du format d'échange")
            return $null
        }

        # Vérifier si le format est supporté
        if (-not $this.SupportedFormats.ContainsKey($exchangeFormat.FormatType)) {
            $this.WriteDebug("Format non supporté: $($exchangeFormat.FormatType)")
            return $null
        }

        # Vérifier le checksum
        if (-not $exchangeFormat.ValidateChecksum()) {
            $this.WriteDebug("Le checksum ne correspond pas. Les données peuvent être corrompues.")
            return $null
        }

        $this.WriteDebug("Vue importée avec succès")
        return $exchangeFormat.Content
    }

    # Méthode pour obtenir les métadonnées d'une vue
    [hashtable] GetViewMetadata([string]$filePath) {
        $this.WriteDebug("Récupération des métadonnées depuis: $filePath")

        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $filePath)) {
            throw "Le fichier spécifié n'existe pas: $filePath"
        }

        # Charger l'objet d'échange
        $exchangeFormat = Import-ExchangeFormat -FilePath $filePath

        if ($null -eq $exchangeFormat) {
            $this.WriteDebug("Échec du chargement du format d'échange")
            return @{}
        }

        return $exchangeFormat.Metadata
    }

    # Méthode pour lister les vues exportées
    [array] ListExportedViews() {
        $this.WriteDebug("Listage des vues exportées dans: $($this.DefaultExportPath)")

        if (-not (Test-Path -Path $this.DefaultExportPath)) {
            return @()
        }

        $files = @()

        foreach ($format in $this.SupportedFormats.Keys) {
            $extension = $this.SupportedFormats[$format].Extension
            $formatFiles = Get-ChildItem -Path $this.DefaultExportPath -Filter "*$extension" -File

            foreach ($file in $formatFiles) {
                try {
                    $metadata = $this.GetViewMetadata($file.FullName)
                    $files += [PSCustomObject]@{
                        Path         = $file.FullName
                        Format       = $format
                        CreationDate = $file.CreationTime
                        Metadata     = $metadata
                    }
                } catch {
                    $this.WriteDebug("Erreur lors de la récupération des métadonnées pour $($file.FullName): $_")
                }
            }
        }

        return $files
    }
}

# Fonction pour créer un nouveau gestionnaire de partage des vues
function New-ViewSharingManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [hashtable]$Options = @{}
    )

    return [ViewSharingManager]::new($Options)
}

# Exporter les fonctions
# Export-ModuleMember -Function New-ViewSharingManager
