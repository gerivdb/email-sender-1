# Get-ProjectSpecificConventions.ps1
# Script pour dÃ©tecter les conventions spÃ©cifiques au projet dans un fichier markdown de roadmap

param (
    [Parameter(Mandatory = $true)]
    [string]$RoadmapFilePath
)

# Importer le module RoadmapParser
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapParser.psm1"
Import-Module $modulePath -Force

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $RoadmapFilePath)) {
    Write-Error "Le fichier '$RoadmapFilePath' n'existe pas."
    exit 1
}

# Lire le contenu du fichier
$content = Get-Content -Path $RoadmapFilePath -Encoding UTF8 -Raw

# Fonction pour dÃ©tecter les conventions spÃ©cifiques au projet
function Get-ProjectConventions {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $conventions = @{
        TaskIdentifiers = @{
            Pattern = $null
            Examples = @()
        }
        PriorityIndicators = @{
            Pattern = $null
            Examples = @()
        }
        StatusIndicators = @{
            Pattern = $null
            Examples = @()
        }
        SpecialSections = @()
        MetadataFormat = $null
    }

    # DÃ©tecter les identifiants de tÃ¢ches
    $taskIdPatterns = @(
        # Format numÃ©rique (1.2.3)
        '(?m)^\s*[-*+]\s*(?:\*\*)?(\d+(\.\d+)+)(?:\*\*)?\s',
        # Format alphanumÃ©rique (A.1.2)
        '(?m)^\s*[-*+]\s*(?:\*\*)?([A-Za-z]+(\.\d+)+)(?:\*\*)?\s',
        # Format avec prÃ©fixe (TASK-123)
        '(?m)^\s*[-*+]\s*(?:\*\*)?([A-Z]+-\d+)(?:\*\*)?\s'
    )

    foreach ($pattern in $taskIdPatterns) {
        $matches = [regex]::Matches($Content, $pattern)
        if ($matches.Count -gt 0) {
            $conventions.TaskIdentifiers.Pattern = $pattern
            $conventions.TaskIdentifiers.Examples = $matches | 
                                                  Select-Object -First 5 | 
                                                  ForEach-Object { $_.Groups[1].Value }
            break
        }
    }

    # DÃ©tecter les indicateurs de prioritÃ©
    $priorityPatterns = @(
        # Format [PRIORITY: HIGH]
        '(?m)\[PRIORITY:\s*([A-Z]+)\]',
        # Format (P1), (P2), etc.
        '(?m)\(P(\d+)\)',
        # Format !!! (haute prioritÃ©), !! (moyenne), ! (basse)
        '(?m)(!{1,3})'
    )

    foreach ($pattern in $priorityPatterns) {
        $matches = [regex]::Matches($Content, $pattern)
        if ($matches.Count -gt 0) {
            $conventions.PriorityIndicators.Pattern = $pattern
            $conventions.PriorityIndicators.Examples = $matches | 
                                                     Select-Object -First 5 | 
                                                     ForEach-Object { $_.Groups[1].Value }
            break
        }
    }

    # DÃ©tecter les indicateurs de statut spÃ©cifiques au projet
    $statusPatterns = @(
        # Format [STATUS: IN_PROGRESS]
        '(?m)\[STATUS:\s*([A-Z_]+)\]',
        # Format @in-progress, @completed, etc.
        '(?m)@([a-z-]+)',
        # Format #status:in-progress
        '(?m)#status:([a-z-]+)'
    )

    foreach ($pattern in $statusPatterns) {
        $matches = [regex]::Matches($Content, $pattern)
        if ($matches.Count -gt 0) {
            $conventions.StatusIndicators.Pattern = $pattern
            $conventions.StatusIndicators.Examples = $matches | 
                                                   Select-Object -First 5 | 
                                                   ForEach-Object { $_.Groups[1].Value }
            break
        }
    }

    # DÃ©tecter les sections spÃ©ciales
    $specialSectionPatterns = @(
        # Sections avec des titres spÃ©cifiques
        '(?m)^#+\s*(TODO|DONE|IN PROGRESS|BACKLOG|ICEBOX|NOTES|REFERENCES)',
        # Sections dÃ©limitÃ©es par des sÃ©parateurs
        '(?m)^-{3,}\s*([A-Z ]+)\s*-{3,}$'
    )

    foreach ($pattern in $specialSectionPatterns) {
        $matches = [regex]::Matches($Content, $pattern)
        if ($matches.Count -gt 0) {
            $conventions.SpecialSections += $matches | 
                                          Select-Object -First 5 | 
                                          ForEach-Object { $_.Groups[1].Value }
        }
    }

    # DÃ©tecter le format des mÃ©tadonnÃ©es
    $metadataPatterns = @(
        # Format YAML front matter
        '(?ms)^---\s*\n(.*?)\n---\s*\n',
        # Format clÃ©-valeur
        '(?m)^([A-Za-z]+):\s*(.+)$'
    )

    foreach ($pattern in $metadataPatterns) {
        $matches = [regex]::Matches($Content, $pattern)
        if ($matches.Count -gt 0) {
            $conventions.MetadataFormat = $pattern
            break
        }
    }

    return $conventions
}

# Analyser les conventions spÃ©cifiques au projet
Write-Host "Analyse des conventions spÃ©cifiques au projet dans: $RoadmapFilePath" -ForegroundColor Cyan
$conventions = Get-ProjectConventions -Content $content

# Afficher les rÃ©sultats
Write-Host "`nConventions spÃ©cifiques au projet dÃ©tectÃ©es:" -ForegroundColor Green

# Identifiants de tÃ¢ches
Write-Host "`n1. Identifiants de tÃ¢ches:" -ForegroundColor Yellow
if ($null -eq $conventions.TaskIdentifiers.Pattern) {
    Write-Host "  Aucun format d'identifiant de tÃ¢che spÃ©cifique dÃ©tectÃ©."
} else {
    Write-Host "  Format dÃ©tectÃ©: $($conventions.TaskIdentifiers.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.TaskIdentifiers.Examples) {
        Write-Host "    - $example"
    }
}

# Indicateurs de prioritÃ©
Write-Host "`n2. Indicateurs de prioritÃ©:" -ForegroundColor Yellow
if ($null -eq $conventions.PriorityIndicators.Pattern) {
    Write-Host "  Aucun indicateur de prioritÃ© spÃ©cifique dÃ©tectÃ©."
} else {
    Write-Host "  Format dÃ©tectÃ©: $($conventions.PriorityIndicators.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.PriorityIndicators.Examples) {
        Write-Host "    - $example"
    }
}

# Indicateurs de statut
Write-Host "`n3. Indicateurs de statut:" -ForegroundColor Yellow
if ($null -eq $conventions.StatusIndicators.Pattern) {
    Write-Host "  Aucun indicateur de statut spÃ©cifique dÃ©tectÃ©."
} else {
    Write-Host "  Format dÃ©tectÃ©: $($conventions.StatusIndicators.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.StatusIndicators.Examples) {
        Write-Host "    - $example"
    }
}

# Sections spÃ©ciales
Write-Host "`n4. Sections spÃ©ciales:" -ForegroundColor Yellow
if ($conventions.SpecialSections.Count -eq 0) {
    Write-Host "  Aucune section spÃ©ciale dÃ©tectÃ©e."
} else {
    Write-Host "  Sections dÃ©tectÃ©es:"
    foreach ($section in $conventions.SpecialSections) {
        Write-Host "    - $section"
    }
}

# Format des mÃ©tadonnÃ©es
Write-Host "`n5. Format des mÃ©tadonnÃ©es:" -ForegroundColor Yellow
if ($null -eq $conventions.MetadataFormat) {
    Write-Host "  Aucun format de mÃ©tadonnÃ©es spÃ©cifique dÃ©tectÃ©."
} else {
    Write-Host "  Format dÃ©tectÃ©: $($conventions.MetadataFormat)"
}

Write-Host "`nAnalyse terminÃ©e." -ForegroundColor Cyan
