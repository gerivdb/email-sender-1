# MetadataManager.ps1
# Module de gestion des metadonnees pour les documents indexes
# Version: 1.0
# Date: 2025-05-15

# Fonction pour extraire les metadonnees d'un document
function Get-DocumentMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Document,

        [Parameter(Mandatory = $false)]
        [string[]]$IncludeFields = @(),

        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeFields = @("content")
    )

    process {
        # Creer un objet pour stocker les metadonnees
        $metadata = @{}

        # Recuperer toutes les proprietes du document
        $properties = $Document.PSObject.Properties.Name

        # Filtrer les proprietes selon les parametres
        $filteredProperties = if ($IncludeFields.Count -gt 0) {
            $properties | Where-Object { $IncludeFields -contains $_ }
        } else {
            $properties | Where-Object { $ExcludeFields -notcontains $_ }
        }

        # Ajouter les proprietes filtrees aux metadonnees
        foreach ($property in $filteredProperties) {
            $metadata[$property] = $Document.$property
        }

        return $metadata
    }
}

# Fonction pour ajouter des metadonnees a un document
function Add-DocumentMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Document,

        [Parameter(Mandatory = $true)]
        [hashtable]$Metadata,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    process {
        # Creer une copie du document pour ne pas modifier l'original
        $updatedDocument = $Document.PSObject.Copy()

        # Ajouter ou mettre a jour les metadonnees
        foreach ($key in $Metadata.Keys) {
            # Verifier si la propriete existe deja
            if ($updatedDocument.PSObject.Properties.Match($key).Count -gt 0) {
                # Si la propriete existe et que Force n'est pas specifie, ignorer
                if ($Force) {
                    $updatedDocument.$key = $Metadata[$key]
                }
            } else {
                # Ajouter la nouvelle propriete
                $updatedDocument | Add-Member -MemberType NoteProperty -Name $key -Value $Metadata[$key]
            }
        }

        return $updatedDocument
    }
}

# Fonction pour supprimer des metadonnees d'un document
function Remove-DocumentMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Document,

        [Parameter(Mandatory = $true)]
        [string[]]$Fields
    )

    process {
        # Creer une copie du document pour ne pas modifier l'original
        $updatedDocument = $Document.PSObject.Copy()

        # Supprimer les proprietes specifiees
        foreach ($field in $Fields) {
            if ($updatedDocument.PSObject.Properties.Match($field).Count -gt 0) {
                $updatedDocument.PSObject.Properties.Remove($field)
            }
        }

        return $updatedDocument
    }
}

# Fonction pour extraire les metadonnees d'un fichier markdown
function Get-MarkdownMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Verifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return $null
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw

    # Extraire les metadonnees YAML frontmatter
    $yamlMetadata = @{}
    if ($content -match "^---\s*\n([\s\S]*?)\n---") {
        $yamlContent = $matches[1]

        # Parser le YAML
        $yamlLines = $yamlContent -split "`n"
        foreach ($line in $yamlLines) {
            if ($line -match "^\s*([^:]+):\s*(.*)$") {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                $yamlMetadata[$key] = $value
            }
        }
    }

    # Extraire les metadonnees inline
    $inlineMetadata = @{}

    # Rechercher les tags (ex: #priority:high)
    $tagMatches = [regex]::Matches($content, '#([a-zA-Z0-9_-]+):([a-zA-Z0-9_-]+)')
    foreach ($match in $tagMatches) {
        $key = $match.Groups[1].Value
        $value = $match.Groups[2].Value
        $inlineMetadata[$key] = $value
    }

    # Rechercher les attributs entre parentheses (ex: (due:2024-05-15))
    $attrMatches = [regex]::Matches($content, '\(([a-zA-Z0-9_-]+):([^)]+)\)')
    foreach ($match in $attrMatches) {
        $key = $match.Groups[1].Value
        $value = $match.Groups[2].Value.Trim()
        $inlineMetadata[$key] = $value
    }

    # Fusionner les metadonnees
    $metadata = @{}
    foreach ($key in $yamlMetadata.Keys) {
        $metadata[$key] = $yamlMetadata[$key]
    }
    foreach ($key in $inlineMetadata.Keys) {
        $metadata[$key] = $inlineMetadata[$key]
    }

    # Ajouter des metadonnees de base sur le fichier
    $fileInfo = Get-Item -Path $FilePath
    $metadata["file_path"] = $FilePath
    $metadata["file_name"] = $fileInfo.Name
    $metadata["file_extension"] = $fileInfo.Extension
    $metadata["file_size"] = $fileInfo.Length
    $metadata["last_modified"] = $fileInfo.LastWriteTime.ToString("o")
    $metadata["created_at"] = $fileInfo.CreationTime.ToString("o")

    return $metadata
}

# Fonction pour ajouter des metadonnees a un fichier markdown
function Add-MarkdownMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [hashtable]$Metadata,

        [Parameter(Mandatory = $false)]
        [ValidateSet("YAML", "Inline", "Both")]
        [string]$Format = "YAML"
    )

    # Verifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return $false
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw

    # Ajouter les metadonnees selon le format specifie
    if ($Format -eq "YAML" -or $Format -eq "Both") {
        # Verifier si le fichier a deja un frontmatter YAML
        if ($content -match "^---\s*\n([\s\S]*?)\n---") {
            # Extraire le YAML existant
            $yamlContent = $matches[1]
            $yamlLines = $yamlContent -split "`n"

            # Mettre a jour ou ajouter les metadonnees
            $updatedYaml = @()
            $addedKeys = @()

            foreach ($line in $yamlLines) {
                if ($line -match "^\s*([^:]+):\s*(.*)$") {
                    $key = $matches[1].Trim()

                    # Si la cle existe dans les nouvelles metadonnees, la mettre a jour
                    if ($Metadata.ContainsKey($key)) {
                        $updatedYaml += "$($key): $($Metadata[$key])"
                        $addedKeys += $key
                    } else {
                        # Sinon, conserver la ligne existante
                        $updatedYaml += $line
                    }
                } else {
                    # Conserver les lignes qui ne sont pas des paires cle-valeur
                    $updatedYaml += $line
                }
            }

            # Ajouter les nouvelles metadonnees qui n'ont pas ete mises a jour
            foreach ($key in $Metadata.Keys) {
                if ($addedKeys -notcontains $key) {
                    $updatedYaml += "$($key): $($Metadata[$key])"
                }
            }

            # Remplacer le YAML existant
            $newYaml = $updatedYaml -join "`n"
            $content = $content -replace "^---\s*\n([\s\S]*?)\n---", "---`n$newYaml`n---"
        } else {
            # Creer un nouveau frontmatter YAML
            $yamlLines = @()
            foreach ($key in $Metadata.Keys) {
                $yamlLines += "$($key): $($Metadata[$key])"
            }
            $newYaml = $yamlLines -join "`n"
            $content = "---`n$newYaml`n---`n`n$content"
        }
    }

    if ($Format -eq "Inline" -or $Format -eq "Both") {
        # Ajouter les metadonnees inline a la fin du fichier
        $inlineLines = @()
        foreach ($key in $Metadata.Keys) {
            $inlineLines += "#$($key):$($Metadata[$key])"
        }
        $inlineMetadata = $inlineLines -join " "
        $content += "`n`n<!-- Metadata: $inlineMetadata -->"
    }

    # Ecrire le contenu mis a jour dans le fichier
    Set-Content -Path $FilePath -Value $content

    return $true
}

# Exporter les fonctions
Export-ModuleMember -Function Get-DocumentMetadata, Add-DocumentMetadata, Remove-DocumentMetadata, Get-MarkdownMetadata, Add-MarkdownMetadata
