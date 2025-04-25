# Get-ProjectSpecificConventions.ps1
# Script pour détecter les conventions spécifiques au projet dans un fichier markdown de roadmap

param (
    [Parameter(Mandatory = $true)]
    [string]$RoadmapFilePath
)

# Importer le module RoadmapParser
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapParser.psm1"
Import-Module $modulePath -Force

# Vérifier si le fichier existe
if (-not (Test-Path -Path $RoadmapFilePath)) {
    Write-Error "Le fichier '$RoadmapFilePath' n'existe pas."
    exit 1
}

# Lire le contenu du fichier
$content = Get-Content -Path $RoadmapFilePath -Encoding UTF8 -Raw

# Fonction pour détecter les conventions spécifiques au projet
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

    # Détecter les identifiants de tâches
    $taskIdPatterns = @(
        # Format numérique (1.2.3)
        '(?m)^\s*[-*+]\s*(?:\*\*)?(\d+(\.\d+)+)(?:\*\*)?\s',
        # Format alphanumérique (A.1.2)
        '(?m)^\s*[-*+]\s*(?:\*\*)?([A-Za-z]+(\.\d+)+)(?:\*\*)?\s',
        # Format avec préfixe (TASK-123)
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

    # Détecter les indicateurs de priorité
    $priorityPatterns = @(
        # Format [PRIORITY: HIGH]
        '(?m)\[PRIORITY:\s*([A-Z]+)\]',
        # Format (P1), (P2), etc.
        '(?m)\(P(\d+)\)',
        # Format !!! (haute priorité), !! (moyenne), ! (basse)
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

    # Détecter les indicateurs de statut spécifiques au projet
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

    # Détecter les sections spéciales
    $specialSectionPatterns = @(
        # Sections avec des titres spécifiques
        '(?m)^#+\s*(TODO|DONE|IN PROGRESS|BACKLOG|ICEBOX|NOTES|REFERENCES)',
        # Sections délimitées par des séparateurs
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

    # Détecter le format des métadonnées
    $metadataPatterns = @(
        # Format YAML front matter
        '(?ms)^---\s*\n(.*?)\n---\s*\n',
        # Format clé-valeur
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

# Analyser les conventions spécifiques au projet
Write-Host "Analyse des conventions spécifiques au projet dans: $RoadmapFilePath" -ForegroundColor Cyan
$conventions = Get-ProjectConventions -Content $content

# Afficher les résultats
Write-Host "`nConventions spécifiques au projet détectées:" -ForegroundColor Green

# Identifiants de tâches
Write-Host "`n1. Identifiants de tâches:" -ForegroundColor Yellow
if ($null -eq $conventions.TaskIdentifiers.Pattern) {
    Write-Host "  Aucun format d'identifiant de tâche spécifique détecté."
} else {
    Write-Host "  Format détecté: $($conventions.TaskIdentifiers.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.TaskIdentifiers.Examples) {
        Write-Host "    - $example"
    }
}

# Indicateurs de priorité
Write-Host "`n2. Indicateurs de priorité:" -ForegroundColor Yellow
if ($null -eq $conventions.PriorityIndicators.Pattern) {
    Write-Host "  Aucun indicateur de priorité spécifique détecté."
} else {
    Write-Host "  Format détecté: $($conventions.PriorityIndicators.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.PriorityIndicators.Examples) {
        Write-Host "    - $example"
    }
}

# Indicateurs de statut
Write-Host "`n3. Indicateurs de statut:" -ForegroundColor Yellow
if ($null -eq $conventions.StatusIndicators.Pattern) {
    Write-Host "  Aucun indicateur de statut spécifique détecté."
} else {
    Write-Host "  Format détecté: $($conventions.StatusIndicators.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.StatusIndicators.Examples) {
        Write-Host "    - $example"
    }
}

# Sections spéciales
Write-Host "`n4. Sections spéciales:" -ForegroundColor Yellow
if ($conventions.SpecialSections.Count -eq 0) {
    Write-Host "  Aucune section spéciale détectée."
} else {
    Write-Host "  Sections détectées:"
    foreach ($section in $conventions.SpecialSections) {
        Write-Host "    - $section"
    }
}

# Format des métadonnées
Write-Host "`n5. Format des métadonnées:" -ForegroundColor Yellow
if ($null -eq $conventions.MetadataFormat) {
    Write-Host "  Aucun format de métadonnées spécifique détecté."
} else {
    Write-Host "  Format détecté: $($conventions.MetadataFormat)"
}

Write-Host "`nAnalyse terminée." -ForegroundColor Cyan
