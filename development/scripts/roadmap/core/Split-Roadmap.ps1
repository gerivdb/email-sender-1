# Split-Roadmap.ps1
# Script pour sÃ©parer une roadmap volumineuse en fichiers distincts : actif et complÃ©tÃ©
# Tout en prÃ©servant le fichier original

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$SourceRoadmapPath = "projet\roadmaps\roadmap_complete_converted.md",

    [Parameter(Mandatory = $false)]
    [string]$ActiveRoadmapPath = "projet\roadmaps\active\roadmap_active.md",

    [Parameter(Mandatory = $false)]
    [string]$CompletedRoadmapPath = "projet\roadmaps\archive\roadmap_completed.md",

    [Parameter(Mandatory = $false)]
    [string]$SectionsArchivePath = "projet\roadmaps\archive\sections",

    [Parameter(Mandatory = $false)]
    [switch]$ArchiveCompletedSections,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
    }
}

function Test-FileExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$CreateIfNotExists,

        [Parameter(Mandatory = $false)]
        [string]$InitialContent = ""
    )

    if (-not (Test-Path -Path $Path)) {
        if ($CreateIfNotExists) {
            try {
                $folder = Split-Path -Path $Path -Parent
                if (-not (Test-Path -Path $folder)) {
                    New-Item -Path $folder -ItemType Directory -Force | Out-Null
                    Write-Log "Dossier crÃ©Ã©: $folder" -Level Info
                }

                Set-Content -Path $Path -Value $InitialContent -Encoding UTF8
                Write-Log "Fichier crÃ©Ã©: $Path" -Level Info
                return $true
            } catch {
                Write-Log "Erreur lors de la crÃ©ation du fichier $Path : $_" -Level Error
                return $false
            }
        } else {
            Write-Log "Le fichier $Path n'existe pas." -Level Warning
            return $false
        }
    }

    return $true
}

function Get-TaskStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskLine
    )

    if ($TaskLine -match '- \[x\]') {
        return "Completed"
    } elseif ($TaskLine -match '- \[ \]') {
        return "Active"
    } else {
        return "Unknown"
    }
}

function Get-SectionLevel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Line
    )

    if ($Line -match '^#{1,6}\s') {
        return ($Line -split ' ')[0].Length
    }

    return 0
}

function Get-SectionTitle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$HeaderLine
    )

    if ($HeaderLine -match '^#{1,6}\s+(.+)$') {
        return $Matches[1]
    }

    return ""
}

function Get-SectionId {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$HeaderLine
    )

    if ($HeaderLine -match '\*\*([0-9.]+)\*\*') {
        return $Matches[1]
    } elseif ($HeaderLine -match '([0-9.]+)') {
        return $Matches[1]
    }

    return ""
}

function Test-SectionCompleted {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$SectionContent
    )

    $taskLines = $SectionContent | Where-Object { $_ -match '- \[(x| )\]' }

    if ($taskLines.Count -eq 0) {
        return $false
    }

    $completedTasks = $taskLines | Where-Object { $_ -match '- \[x\]' }

    return ($completedTasks.Count -eq $taskLines.Count)
}

function Split-RoadmapContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Content
    )

    $activeContent = @()
    $completedContent = @()
    $sections = @{}
    $currentSection = @()
    $currentSectionId = ""
    $currentSectionTitle = ""
    $currentSectionLevel = 0
    $inSection = $false

    # Ajouter l'en-tÃªte au contenu actif
    $activeContent += "# Roadmap Active - EMAIL_SENDER_1"
    $activeContent += ""
    $activeContent += "Ce fichier contient les tÃ¢ches actives et Ã  venir de la roadmap."
    $activeContent += "GÃ©nÃ©rÃ© le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $activeContent += ""

    # Ajouter l'en-tÃªte au contenu complÃ©tÃ©
    $completedContent += "# Roadmap ComplÃ©tÃ©e - EMAIL_SENDER_1"
    $completedContent += ""
    $completedContent += "Ce fichier contient les tÃ¢ches complÃ©tÃ©es de la roadmap."
    $completedContent += "GÃ©nÃ©rÃ© le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $completedContent += ""

    foreach ($line in $Content) {
        $sectionLevel = Get-SectionLevel -Line $line

        # Si c'est un en-tÃªte de section
        if ($sectionLevel -gt 0) {
            # Si nous Ã©tions dans une section, finalisons-la
            if ($inSection) {
                $isCompleted = Test-SectionCompleted -SectionContent $currentSection

                # Stocker la section complÃ¨te
                $sections[$currentSectionId] = @{
                    Title       = $currentSectionTitle
                    Level       = $currentSectionLevel
                    Content     = $currentSection
                    IsCompleted = $isCompleted
                }

                # Ajouter la section au contenu appropriÃ©
                if ($isCompleted) {
                    $completedContent += $currentSection
                } else {
                    $activeContent += $currentSection
                }
            }

            # Commencer une nouvelle section
            $currentSectionTitle = Get-SectionTitle -HeaderLine $line
            $currentSectionId = Get-SectionId -HeaderLine $line
            $currentSectionLevel = $sectionLevel
            $currentSection = @($line)
            $inSection = $true
        } elseif ($inSection) {
            # Ajouter la ligne Ã  la section courante
            $currentSection += $line
        } else {
            # Ligne hors section (en-tÃªte du document)
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                $activeContent += $line
                $completedContent += $line
            }
        }
    }

    # Traiter la derniÃ¨re section
    if ($inSection) {
        $isCompleted = Test-SectionCompleted -SectionContent $currentSection

        # Stocker la section complÃ¨te
        $sections[$currentSectionId] = @{
            Title       = $currentSectionTitle
            Level       = $currentSectionLevel
            Content     = $currentSection
            IsCompleted = $isCompleted
        }

        # Ajouter la section au contenu appropriÃ©
        if ($isCompleted) {
            $completedContent += $currentSection
        } else {
            $activeContent += $currentSection
        }
    }

    return @{
        ActiveContent    = $activeContent
        CompletedContent = $completedContent
        Sections         = $sections
    }
}

function Compress-CompletedSections {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Sections,

        [Parameter(Mandatory = $true)]
        [string]$ArchivePath
    )

    foreach ($sectionId in $Sections.Keys) {
        $section = $Sections[$sectionId]

        if ($section.IsCompleted -and -not [string]::IsNullOrEmpty($sectionId)) {
            $sectionFileName = "section_${sectionId}_$(($section.Title -replace '[\\\/\:\*\?\"\<\>\|]', '_')).md"
            $sectionFilePath = Join-Path -Path $ArchivePath -ChildPath $sectionFileName

            # CrÃ©er le contenu du fichier de section
            $sectionContent = @(
                "# Section $sectionId : $($section.Title)",
                "",
                "Section archivÃ©e le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
                "",
                "## Contenu",
                ""
            )

            $sectionContent += $section.Content

            # Sauvegarder le fichier de section
            Set-Content -Path $sectionFilePath -Value $sectionContent -Encoding UTF8
            Write-Log "Section archivÃ©e: $sectionId -> $sectionFilePath" -Level Info
        }
    }
}

# Fonction principale
function Split-Roadmap {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$ActivePath,

        [Parameter(Mandatory = $true)]
        [string]$CompletedPath,

        [Parameter(Mandatory = $false)]
        [string]$SectionsPath,

        [Parameter(Mandatory = $false)]
        [switch]$ArchiveSections,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # VÃ©rifier que le fichier source existe
    if (-not (Test-Path -Path $SourcePath)) {
        Write-Log "Le fichier source $SourcePath n'existe pas." -Level Error
        return $false
    }

    # VÃ©rifier si les fichiers de destination existent dÃ©jÃ 
    if ((Test-Path -Path $ActivePath) -or (Test-Path -Path $CompletedPath)) {
        if (-not $Force) {
            Write-Log "Les fichiers de destination existent dÃ©jÃ . Utilisez -Force pour les Ã©craser." -Level Warning
            return $false
        }
    }

    # Lire le contenu du fichier source
    try {
        # Essayer diffÃ©rents encodages
        try {
            $content = Get-Content -Path $SourcePath -Encoding UTF8 -ErrorAction Stop
        } catch {
            try {
                $content = Get-Content -Path $SourcePath -Encoding Default -ErrorAction Stop
            } catch {
                $content = [System.IO.File]::ReadAllLines($SourcePath)
            }
        }

        if ($null -eq $content -or $content.Count -eq 0) {
            Write-Log "Le fichier source est vide ou n'a pas pu Ãªtre lu correctement." -Level Error
            return $false
        }

        Write-Log "Fichier source lu: $SourcePath ($(($content | Measure-Object).Count) lignes)" -Level Info
    } catch {
        Write-Log "Erreur lors de la lecture du fichier source: $_" -Level Error
        return $false
    }

    # SÃ©parer le contenu
    $result = Split-RoadmapContent -Content $content

    # CrÃ©er les dossiers de destination si nÃ©cessaires
    $activeFolder = Split-Path -Path $ActivePath -Parent
    $completedFolder = Split-Path -Path $CompletedPath -Parent

    if (-not (Test-Path -Path $activeFolder)) {
        New-Item -Path $activeFolder -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path -Path $completedFolder)) {
        New-Item -Path $completedFolder -ItemType Directory -Force | Out-Null
    }

    # Sauvegarder les fichiers
    try {
        Set-Content -Path $ActivePath -Value $result.ActiveContent -Encoding UTF8
        Write-Log "Fichier actif crÃ©Ã©: $ActivePath ($(($result.ActiveContent | Measure-Object).Count) lignes)" -Level Info

        Set-Content -Path $CompletedPath -Value $result.CompletedContent -Encoding UTF8
        Write-Log "Fichier complÃ©tÃ© crÃ©Ã©: $CompletedPath ($(($result.CompletedContent | Measure-Object).Count) lignes)" -Level Info

        # Archiver les sections complÃ©tÃ©es si demandÃ©
        if ($ArchiveSections -and -not [string]::IsNullOrEmpty($SectionsPath)) {
            if (-not (Test-Path -Path $SectionsPath)) {
                New-Item -Path $SectionsPath -ItemType Directory -Force | Out-Null
            }

            Compress-CompletedSections -Sections $result.Sections -ArchivePath $SectionsPath
        }

        return $true
    } catch {
        Write-Log "Erreur lors de la sauvegarde des fichiers: $_" -Level Error
        return $false
    }
}

# ExÃ©cution principale
Write-Log "DÃ©marrage de la sÃ©paration de la roadmap..." -Level Info

$success = Split-Roadmap -SourcePath $SourceRoadmapPath `
    -ActivePath $ActiveRoadmapPath `
    -CompletedPath $CompletedRoadmapPath `
    -SectionsPath $SectionsArchivePath `
    -ArchiveSections:$ArchiveCompletedSections `
    -Force:$Force

if ($success) {
    Write-Log "SÃ©paration de la roadmap terminÃ©e avec succÃ¨s." -Level Info
} else {
    Write-Log "Ã‰chec de la sÃ©paration de la roadmap." -Level Error
}

