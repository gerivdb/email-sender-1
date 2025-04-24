<#
.SYNOPSIS
    Convertit un fichier markdown en structure d'objet PowerShell.

.DESCRIPTION
    La fonction ConvertFrom-MarkdownToObject lit un fichier markdown et le convertit en une structure d'objet PowerShell.
    Elle est spécialement conçue pour traiter les roadmaps au format markdown avec des tâches, des statuts et des identifiants.

.PARAMETER FilePath
    Chemin du fichier markdown à convertir.

.PARAMETER Encoding
    Encodage du fichier. Par défaut, UTF8.

.PARAMETER IncludeMetadata
    Indique si les métadonnées supplémentaires doivent être extraites et incluses dans les objets.

.PARAMETER CustomStatusMarkers
    Hashtable définissant des marqueurs de statut personnalisés et leur correspondance avec les statuts standard.

.EXAMPLE
    ConvertFrom-MarkdownToObject -FilePath ".\roadmap.md"
    Convertit le fichier roadmap.md en structure d'objet PowerShell.

.EXAMPLE
    ConvertFrom-MarkdownToObject -FilePath ".\roadmap.md" -Encoding "UTF8" -IncludeMetadata
    Convertit le fichier roadmap.md en structure d'objet PowerShell avec extraction des métadonnées.

.EXAMPLE
    $customMarkers = @{
        "o" = "InProgress";
        "?" = "Blocked"
    }
    ConvertFrom-MarkdownToObject -FilePath ".\roadmap.md" -CustomStatusMarkers $customMarkers
    Convertit le fichier roadmap.md en utilisant des marqueurs de statut personnalisés.

.OUTPUTS
    [PSCustomObject] Représentant la structure du document markdown.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-10
#>
function ConvertFrom-MarkdownToObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("UTF8", "UTF7", "UTF32", "ASCII", "Unicode", "BigEndianUnicode", "Default")]
        [string]$Encoding = "UTF8",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,

        [Parameter(Mandatory = $false)]
        [hashtable]$CustomStatusMarkers
    )

    begin {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath)) {
            throw "Le fichier '$FilePath' n'existe pas."
        }

        # Fonction interne pour détecter l'encodage du fichier
        function Get-FileEncoding {
            param (
                [Parameter(Mandatory = $true)]
                [string]$FilePath
            )

            # Note: Nous utilisons directement les vérifications de BOM ci-dessous
            # sans utiliser cette liste d'encodages pour l'instant

            # Lire les premiers octets du fichier
            $bytes = [System.IO.File]::ReadAllBytes($FilePath)

            # Détecter le BOM (Byte Order Mark)
            if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
                return [System.Text.Encoding]::UTF8
            } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
                return [System.Text.Encoding]::BigEndianUnicode
            } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
                return [System.Text.Encoding]::Unicode
            } elseif ($bytes.Length -ge 4 -and $bytes[0] -eq 0 -and $bytes[1] -eq 0 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
                return [System.Text.Encoding]::UTF32
            }

            # Si pas de BOM, essayer de détecter l'encodage par analyse du contenu
            # Pour simplifier, on retourne UTF8 par défaut
            return [System.Text.Encoding]::UTF8
        }

        # Fonction interne pour convertir un marqueur de statut en valeur d'énumération
        function ConvertFrom-StatusMarker {
            param (
                [Parameter(Mandatory = $false)]
                [AllowEmptyString()]
                [string]$StatusMarker,

                [Parameter(Mandatory = $false)]
                [hashtable]$CustomMarkers
            )

            # Définir les marqueurs standard
            $standardMarkers = @{
                "x" = "Complete"; # Couvre aussi "X" dans le switch ci-dessous
                "~" = "InProgress";
                "!" = "Blocked";
                " " = "Incomplete";
                ""  = "Incomplete"
            }

            # Ajouter manuellement le cas "X" (majuscule)
            $statusMarker = $statusMarker.ToString()
            if ($statusMarker -eq "X") {
                $statusMarker = "x"
            }

            # Fusionner avec les marqueurs personnalisés si fournis
            if ($null -ne $CustomMarkers) {
                foreach ($key in $CustomMarkers.Keys) {
                    $standardMarkers[$key] = $CustomMarkers[$key]
                }
            }

            # Convertir le marqueur en statut
            if ($standardMarkers.ContainsKey($StatusMarker)) {
                return $standardMarkers[$StatusMarker]
            } else {
                return "Incomplete"
            }
        }

        # Fonction interne pour extraire les métadonnées d'une ligne
        function Get-LineMetadata {
            param (
                [Parameter(Mandatory = $true)]
                [string]$Line
            )

            $metadata = @{}

            # Extraire les dates (format: @date:YYYY-MM-DD)
            if ($Line -match '@date:(\d{4}-\d{2}-\d{2})') {
                $metadata["Date"] = [datetime]::ParseExact($matches[1], "yyyy-MM-dd", $null)
            }

            # Extraire les assignations (@personne)
            if ($Line -match '@([a-zA-Z0-9_-]+)(?:\s|$)') {
                $metadata["Assignee"] = $matches[1]
            }

            # Extraire les tags (#tag)
            $tags = @()
            $tagMatches = [regex]::Matches($Line, '#([a-zA-Z0-9_-]+)(?:\s|$)')
            foreach ($match in $tagMatches) {
                $tags += $match.Groups[1].Value
            }
            if ($tags.Count -gt 0) {
                $metadata["Tags"] = $tags
            }

            # Extraire les priorités (P1, P2, etc.)
            if ($Line -match '\b(P[0-9])\b') {
                $metadata["Priority"] = $matches[1]
            }

            return $metadata
        }
    }

    process {
        try {
            # Détecter l'encodage si nécessaire
            $actualEncoding = if ($Encoding -eq "Default") {
                $detected = Get-FileEncoding -FilePath $FilePath
                $detected.WebName
            } else {
                $Encoding
            }

            # Lire le contenu du fichier
            $content = Get-Content -Path $FilePath -Encoding $actualEncoding -Raw
            $lines = $content -split "`n"

            # Créer l'objet racine
            $rootObject = [PSCustomObject]@{
                Title       = "Document"
                Description = ""
                Items       = New-Object System.Collections.ArrayList
                Metadata    = @{}
            }

            # Variables pour suivre la structure
            $currentLevel = 0
            $parentStack = @($rootObject)
            $currentParent = $rootObject
            $idCounter = 1

            # Extraire le titre et la description
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]

                # Extraire le titre (première ligne commençant par #)
                if ($line -match '^#\s+(.+)$') {
                    $rootObject.Title = $matches[1]

                    # Extraire la description (lignes non vides après le titre jusqu'à la première section)
                    $descLines = @()
                    $j = $i + 1
                    while ($j -lt $lines.Count -and -not ($lines[$j] -match '^#{2,}\s+')) {
                        if (-not [string]::IsNullOrWhiteSpace($lines[$j])) {
                            $descLines += $lines[$j]
                        }
                        $j++
                    }

                    if ($descLines.Count -gt 0) {
                        $rootObject.Description = $descLines -join "`n"
                    }

                    break
                }
            }

            # Parser les lignes pour extraire les items
            foreach ($line in $lines) {
                # Ignorer les lignes vides
                if ([string]::IsNullOrWhiteSpace($line)) {
                    continue
                }

                # Détecter les tâches (lignes commençant par -, *, + avec ou sans case à cocher)
                if ($line -match '^(\s*)[-*+]\s*(?:\[([ xX~!])\])?\s*(?:\*\*([^*]+)\*\*)?\s*(.*)$') {
                    $indent = $matches[1].Length
                    $statusMarker = $matches[2]
                    $id = $matches[3]
                    $title = $matches[4]

                    # Déterminer le statut
                    $status = ConvertFrom-StatusMarker -StatusMarker $statusMarker -CustomMarkers $CustomStatusMarkers

                    # Si l'ID n'est pas spécifié, en générer un
                    if ([string]::IsNullOrEmpty($id)) {
                        $id = "$idCounter"
                        $idCounter++
                    }

                    # Extraire les métadonnées si demandé
                    $metadata = if ($IncludeMetadata) { Get-LineMetadata -Line $line } else { @{} }

                    # Créer l'objet item
                    $item = [PSCustomObject]@{
                        Id           = $id
                        Title        = $title
                        Status       = $status
                        Level        = [int]($indent / 2)  # Supposer 2 espaces par niveau
                        Items        = New-Object System.Collections.ArrayList
                        Metadata     = $metadata
                        OriginalText = $line
                    }

                    # Déterminer le parent en fonction de l'indentation
                    if ($indent -gt $currentLevel) {
                        # Niveau d'indentation supérieur, le parent est le dernier item ajouté
                        $parentStack += $currentParent
                        $currentParent = $parentStack[-1].Items[-1]
                        $currentLevel = $indent
                    } elseif ($indent -lt $currentLevel) {
                        # Niveau d'indentation inférieur, remonter dans l'arborescence
                        $levelDiff = [int](($currentLevel - $indent) / 2)
                        for ($i = 0; $i -lt $levelDiff; $i++) {
                            $parentStack = $parentStack[0..($parentStack.Count - 2)]
                        }
                        $currentParent = $parentStack[-1]
                        $currentLevel = $indent
                    }

                    # Ajouter l'item au parent
                    $currentParent.Items.Add($item) | Out-Null
                }
                # Détecter les titres (lignes commençant par #)
                elseif ($line -match '^(#+)\s+(.+)$') {
                    $level = $matches[1].Length - 1  # Niveau 0 pour le titre principal
                    $title = $matches[2]

                    # Créer l'objet section
                    $section = [PSCustomObject]@{
                        Title        = $title
                        Level        = $level
                        Items        = New-Object System.Collections.ArrayList
                        Metadata     = @{}
                        OriginalText = $line
                    }

                    # Réinitialiser la pile des parents jusqu'au niveau approprié
                    while ($parentStack.Count -gt $level) {
                        $parentStack = $parentStack[0..($parentStack.Count - 2)]
                    }

                    # Ajouter la section au parent approprié
                    if ($parentStack.Count -gt 0) {
                        $currentParent = $parentStack[-1]
                        $currentParent.Items.Add($section) | Out-Null
                    } else {
                        $rootObject.Items.Add($section) | Out-Null
                    }

                    # Mettre à jour le parent courant
                    $parentStack += $section
                    $currentParent = $section
                    $currentLevel = 0  # Réinitialiser le niveau d'indentation
                }
            }

            return $rootObject
        } catch {
            Write-Error "Erreur lors de la conversion du fichier markdown en objet: $_"
            throw
        }
    }

    end {
        # Nettoyage si nécessaire
    }
}
