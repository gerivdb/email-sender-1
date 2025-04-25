<#
.SYNOPSIS
    Fonctions pour le parsing de fichiers markdown.

.DESCRIPTION
    Ce module contient des fonctions pour lire, analyser et parser des fichiers markdown,
    avec une attention particulière pour les roadmaps et les listes de tâches.

.NOTES
    Version:        1.0
    Author:         RoadmapParser Team
    Creation Date:  2023-08-17
#>

#region Fonctions de lecture de fichiers

<#
.SYNOPSIS
    Détecte l'encodage d'un fichier.

.DESCRIPTION
    Cette fonction tente de détecter automatiquement l'encodage d'un fichier
    en analysant ses premiers octets (BOM - Byte Order Mark) et son contenu.

.PARAMETER FilePath
    Chemin vers le fichier à analyser.

.EXAMPLE
    $encoding = Get-FileEncoding -FilePath "roadmap.md"

.OUTPUTS
    System.Text.Encoding
#>
function Get-FileEncoding {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Error "Le fichier '$FilePath' n'existe pas ou n'est pas un fichier."
            return $null
        }

        # Lire les premiers octets du fichier pour détecter le BOM
        $fileStream = [System.IO.File]::OpenRead($FilePath)
        $bytes = New-Object byte[] 4
        $fileStream.Read($bytes, 0, 4) | Out-Null
        $fileStream.Close()
        $fileStream.Dispose()

        # Détecter l'encodage basé sur le BOM
        if ($bytes.Length -ge 2) {
            # UTF-8 BOM (EF BB BF)
            if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes.Length -ge 3 -and $bytes[2] -eq 0xBF) {
                Write-Verbose "Encodage détecté: UTF-8 avec BOM"
                return [System.Text.Encoding]::UTF8
            }

            # UTF-16 LE BOM (FF FE)
            if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
                Write-Verbose "Encodage détecté: UTF-16 LE"
                return [System.Text.Encoding]::Unicode
            }

            # UTF-16 BE BOM (FE FF)
            if ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
                Write-Verbose "Encodage détecté: UTF-16 BE"
                return [System.Text.Encoding]::BigEndianUnicode
            }

            # UTF-32 LE BOM (FF FE 00 00)
            if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes.Length -ge 4 -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) {
                Write-Verbose "Encodage détecté: UTF-32 LE"
                return [System.Text.Encoding]::UTF32
            }

            # UTF-32 BE BOM (00 00 FE FF)
            if ($bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes.Length -ge 4 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
                Write-Verbose "Encodage détecté: UTF-32 BE"
                return [System.Text.Encoding]::GetEncoding("utf-32BE")
            }
        }

        # Si aucun BOM n'est détecté, essayer de deviner l'encodage en analysant le contenu
        # Lire un échantillon plus grand du fichier
        $sampleSize = [Math]::Min([int](Get-Item -Path $FilePath).Length, 1024)
        $fileStream = [System.IO.File]::OpenRead($FilePath)
        $bytes = New-Object byte[] $sampleSize
        $fileStream.Read($bytes, 0, $sampleSize) | Out-Null
        $fileStream.Close()
        $fileStream.Dispose()

        # Vérifier si le contenu est probablement UTF-8
        $isUtf8 = $true
        $i = 0
        while ($i -lt $bytes.Length) {
            # Vérifier les séquences UTF-8 valides
            if ($bytes[$i] -lt 0x80) {
                # ASCII (0xxxxxxx)
                $i++
            } elseif (($bytes[$i] -ge 0xC2) -and ($bytes[$i] -lt 0xE0) -and ($i + 1 -lt $bytes.Length)) {
                # 2-byte sequence (110xxxxx 10xxxxxx)
                if (($bytes[$i + 1] -ge 0x80) -and ($bytes[$i + 1] -lt 0xC0)) {
                    $i += 2
                } else {
                    $isUtf8 = $false
                    break
                }
            } elseif (($bytes[$i] -ge 0xE0) -and ($bytes[$i] -lt 0xF0) -and ($i + 2 -lt $bytes.Length)) {
                # 3-byte sequence (1110xxxx 10xxxxxx 10xxxxxx)
                if (($bytes[$i + 1] -ge 0x80) -and ($bytes[$i + 1] -lt 0xC0) -and
                    ($bytes[$i + 2] -ge 0x80) -and ($bytes[$i + 2] -lt 0xC0)) {
                    $i += 3
                } else {
                    $isUtf8 = $false
                    break
                }
            } elseif (($bytes[$i] -ge 0xF0) -and ($bytes[$i] -lt 0xF5) -and ($i + 3 -lt $bytes.Length)) {
                # 4-byte sequence (11110xxx 10xxxxxx 10xxxxxx 10xxxxxx)
                if (($bytes[$i + 1] -ge 0x80) -and ($bytes[$i + 1] -lt 0xC0) -and
                    ($bytes[$i + 2] -ge 0x80) -and ($bytes[$i + 2] -lt 0xC0) -and
                    ($bytes[$i + 3] -ge 0x80) -and ($bytes[$i + 3] -lt 0xC0)) {
                    $i += 4
                } else {
                    $isUtf8 = $false
                    break
                }
            } else {
                $isUtf8 = $false
                break
            }
        }

        if ($isUtf8) {
            Write-Verbose "Encodage détecté: UTF-8 sans BOM"
            return [System.Text.Encoding]::UTF8
        }

        # Vérifier si le contenu est probablement ASCII
        $isAscii = $true
        foreach ($byte in $bytes) {
            if ($byte -gt 0x7F) {
                $isAscii = $false
                break
            }
        }

        if ($isAscii) {
            Write-Verbose "Encodage détecté: ASCII"
            return [System.Text.Encoding]::ASCII
        }

        # Par défaut, supposer que c'est UTF-8 sans BOM
        Write-Verbose "Encodage par défaut: UTF-8 sans BOM"
        return [System.Text.Encoding]::UTF8
    } catch {
        Write-Error "Erreur lors de la détection de l'encodage: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Lit un fichier markdown avec détection automatique de l'encodage.

.DESCRIPTION
    Cette fonction lit un fichier markdown en détectant automatiquement son encodage
    et en gérant les BOM (Byte Order Mark).

.PARAMETER FilePath
    Chemin vers le fichier markdown à lire.

.PARAMETER Encoding
    Encodage à utiliser pour la lecture. Si non spécifié, l'encodage est détecté automatiquement.

.EXAMPLE
    $content = Read-MarkdownFile -FilePath "roadmap.md"

.OUTPUTS
    System.String[]
#>
function Read-MarkdownFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [System.Text.Encoding]$Encoding = $null
    )

    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Error "Le fichier '$FilePath' n'existe pas ou n'est pas un fichier."
            return $null
        }

        # Détecter l'encodage si non spécifié
        if ($null -eq $Encoding) {
            $Encoding = Get-FileEncoding -FilePath $FilePath

            if ($null -eq $Encoding) {
                Write-Error "Impossible de détecter l'encodage du fichier '$FilePath'."
                return $null
            }
        }

        # Lire le contenu du fichier avec l'encodage détecté
        $content = [System.IO.File]::ReadAllText($FilePath, $Encoding)

        # Normaliser les fins de ligne
        $content = $content -replace "`r`n", "`n"
        $content = $content -replace "`r", "`n"

        # Diviser le contenu en lignes
        $lines = $content -split "`n"

        return $lines
    } catch {
        Write-Error "Erreur lors de la lecture du fichier markdown: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Lit un fichier markdown et retourne son contenu sous forme d'objet structuré.

.DESCRIPTION
    Cette fonction lit un fichier markdown, détecte son encodage, et retourne son contenu
    sous forme d'un objet structuré contenant les lignes et les métadonnées du fichier.

.PARAMETER FilePath
    Chemin vers le fichier markdown à lire.

.PARAMETER Encoding
    Encodage à utiliser pour la lecture. Si non spécifié, l'encodage est détecté automatiquement.

.EXAMPLE
    $markdownContent = Get-MarkdownContent -FilePath "roadmap.md"

.OUTPUTS
    PSCustomObject
#>
function Get-MarkdownContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [System.Text.Encoding]$Encoding = $null
    )

    try {
        # Détecter l'encodage si non spécifié
        if ($null -eq $Encoding) {
            $Encoding = Get-FileEncoding -FilePath $FilePath

            if ($null -eq $Encoding) {
                Write-Error "Impossible de détecter l'encodage du fichier '$FilePath'."
                return $null
            }
        }

        # Lire le contenu du fichier
        $lines = Read-MarkdownFile -FilePath $FilePath -Encoding $Encoding

        if ($null -eq $lines) {
            return $null
        }

        # Créer un objet pour stocker le contenu et les métadonnées
        $markdownContent = [PSCustomObject]@{
            FilePath  = $FilePath
            Encoding  = $Encoding
            Lines     = $lines
            LineCount = $lines.Count
            HasBOM    = Test-FileBOM -FilePath $FilePath
            Metadata  = @{}
        }

        # Extraire les métadonnées YAML frontmatter si présentes
        if ($lines.Count -gt 0 -and $lines[0].Trim() -eq "---") {
            $endFrontMatter = $lines | Select-Object -Skip 1 | Select-String -Pattern "^---$" | Select-Object -First 1 -ExpandProperty LineNumber

            if ($endFrontMatter -gt 0) {
                $frontMatter = $lines[1..($endFrontMatter - 1)]
                $markdownContent.Metadata = ConvertFrom-YamlFrontMatter -FrontMatter $frontMatter
            }
        }

        return $markdownContent
    } catch {
        Write-Error "Erreur lors de la récupération du contenu markdown: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Vérifie si un fichier contient un BOM (Byte Order Mark).

.DESCRIPTION
    Cette fonction vérifie si un fichier contient un BOM (Byte Order Mark)
    en analysant ses premiers octets.

.PARAMETER FilePath
    Chemin vers le fichier à analyser.

.EXAMPLE
    $hasBOM = Test-FileBOM -FilePath "roadmap.md"

.OUTPUTS
    System.Boolean
#>
function Test-FileBOM {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Error "Le fichier '$FilePath' n'existe pas ou n'est pas un fichier."
            return $false
        }

        # Lire les premiers octets du fichier
        $fileStream = [System.IO.File]::OpenRead($FilePath)
        $bytes = New-Object byte[] 4
        $bytesRead = $fileStream.Read($bytes, 0, 4)
        $fileStream.Close()
        $fileStream.Dispose()

        # Si le fichier est vide, retourner false
        if ($bytesRead -eq 0) {
            return $false
        }

        # Vérifier les différents types de BOM
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            # UTF-8 BOM
            return $true
        }

        if ($bytes.Length -ge 2 -and (($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) -or ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF))) {
            # UTF-16 LE/BE BOM
            return $true
        }

        if ($bytes.Length -ge 4 -and
            (($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) -or
             ($bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF))) {
            # UTF-32 LE/BE BOM
            return $true
        }

        # Aucun BOM détecté
        return $false
    } catch {
        Write-Error "Erreur lors de la vérification du BOM: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Convertit le YAML frontmatter d'un fichier markdown en hashtable.

.DESCRIPTION
    Cette fonction convertit le YAML frontmatter d'un fichier markdown
    et retourne les métadonnées sous forme de hashtable.

.PARAMETER FrontMatter
    Lignes de texte contenant le YAML frontmatter.

.EXAMPLE
    $metadata = ConvertFrom-YamlFrontMatter -FrontMatter $frontMatterLines

.OUTPUTS
    System.Collections.Hashtable
#>
function ConvertFrom-YamlFrontMatter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$FrontMatter
    )

    try {
        $metadata = @{}

        # Vérifier si le tableau est vide ou ne contient que des espaces
        if ($null -eq $FrontMatter -or $FrontMatter.Count -eq 0 -or ($FrontMatter.Count -eq 1 -and [string]::IsNullOrWhiteSpace($FrontMatter[0]))) {
            return $metadata
        }

        foreach ($line in $FrontMatter) {
            if ([string]::IsNullOrWhiteSpace($line)) {
                continue
            }

            if ($line -match "^([^:]+):\s*(.*)$") {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()

                # Gérer les valeurs entre guillemets
                if ($value -match '^"(.*)"$' -or $value -match "^'(.*)'$") {
                    $value = $matches[1]
                }

                # Gérer les listes
                if ($value -match "^\[.*\]$") {
                    $value = $value.Trim("[]").Split(",") | ForEach-Object { $_.Trim() }
                }

                $metadata[$key] = $value
            }
        }

        return $metadata
    } catch {
        Write-Error "Erreur lors du parsing du YAML frontmatter: $_"
        return @{}
    }
}

#endregion

# Exporter les fonctions
Export-ModuleMember -Function Get-FileEncoding, Read-MarkdownFile, Get-MarkdownContent, Test-FileBOM, ConvertFrom-YamlFrontMatter
